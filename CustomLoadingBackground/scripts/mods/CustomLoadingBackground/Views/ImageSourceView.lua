local mod = get_mod("CustomLoadingBackground")

local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local definitions = mod:io_dofile("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageSourceViewDefinitions")

ImageSourceView = class("ImageSourceView", "BaseView")

ImageSourceView.init = function(self, settings)
    ImageSourceView.super.init(self, definitions, settings)
end

ImageSourceView.on_enter = function(self)
    ImageSourceView.super.on_enter(self)
    local load_local = false
    local ok, val = pcall(function() return mod:get("loadLocal") end)
    if ok and type(val) == "boolean" then
        load_local = val
    end
    local toggle = self._widgets_by_name.localImagesToggle
    if toggle then
        toggle.content.value = load_local
        toggle.content.text = load_local and "On" or "Off"
    end

    self._scroll_offset = 0
    self._visible_rows = 10
    self._all_urls = {}

    self._curated_scroll_offset = 0
    self._curated_visible_rows = 10
    self._all_curated = {}

    local builtin_curated = {}
    for _, u in pairs(mod.curatedLists) do table.insert(builtin_curated, { url = u[1], enabled = true, builtin = true }) end

    local ok_rows, stored = pcall(function() return mod:get("urls_rows") end)
    if ok_rows and type(stored) == "table" then
        for _, entry in ipairs(stored) do
            local url, enabled
            if type(entry) == "string" then
                url = entry; enabled = true
            elseif type(entry) == "table" then
                url = entry.url or entry[1]
                enabled = entry.enabled; if enabled == nil then enabled = true end
            end
            if url and url ~= "" then
                table.insert(self._all_urls, { url = url, enabled = enabled })
            end
        end
    end
    self:_refresh_url_rows()

    local ok_cur, stored_cur = pcall(function() return mod:get("curated_rows") end)
    local stored_builtin_enabled = {}
    local user_sequence = {}
    if ok_cur and type(stored_cur) == "table" then
        for _, entry in ipairs(stored_cur) do
            if type(entry) == "table" and entry.url and entry.url ~= "" then
                if entry.builtin then
                    stored_builtin_enabled[entry.url] = entry.enabled ~= false
                else
                    user_sequence[#user_sequence+1] = { url = entry.url, enabled = entry.enabled ~= false }
                end
            end
        end
    end
    for _, b in ipairs(builtin_curated) do
        local enabled = stored_builtin_enabled[b.url]
        if enabled ~= nil then b.enabled = enabled end
        table.insert(self._all_curated, { url = b.url, enabled = b.enabled, builtin = true })
    end
    for _, u in ipairs(user_sequence) do
        table.insert(self._all_curated, { url = u.url, enabled = u.enabled, builtin = false })
    end
    self:_refresh_curated_rows()

    self:_setup_input_legend()
end

function ImageSourceView:_persist_current_rows()
    local rows = {}
    for _, entry in ipairs(self._all_urls) do
        rows[#rows+1] = { url = entry.url, enabled = entry.enabled }
    end
    pcall(function() mod:set("urls_rows", rows) end)
    local crows = {}
    for _, entry in ipairs(self._all_curated) do
        crows[#crows+1] = { url = entry.url, enabled = entry.enabled, builtin = entry.builtin or false }
    end
    pcall(function() mod:set("curated_rows", crows) end)
end

ImageSourceView._handle_input = function (self, input_service, dt, t)
    ImageSourceView.super._handle_input(self, dt, t, input_service)
    local scroll_axis = input_service:get("scroll_axis")
    if scroll_axis and scroll_axis[2] ~= 0 then
        local delta = scroll_axis[2]
        local over_url = self._widgets_by_name.urlPanelScrollHotspot and self._widgets_by_name.urlPanelScrollHotspot.content.hotspot.is_hover
        local over_curated = self._widgets_by_name.curatedPanelScrollHotspot and self._widgets_by_name.curatedPanelScrollHotspot.content.hotspot.is_hover
        if not over_curated then
            for i=1,self._curated_visible_rows do
                local row = self._widgets_by_name["curatedRow"..i]
                local tog = self._widgets_by_name["curatedRow"..i.."Toggle"]
                local del = self._widgets_by_name["curatedRow"..i.."Delete"]
                if (row and row.content and row.content.hotspot and row.content.hotspot.is_hover) or
                   (tog and tog.content and tog.content.hotspot and tog.content.hotspot.is_hover) or
                   (del and del.content and del.content.hotspot and del.content.hotspot.is_hover) then
                    over_curated = true
                    break
                end
            end
        end
        local step = (delta > 0) and -1 or 1
        if over_url and #self._all_urls > self._visible_rows then
            local new_offset = self._scroll_offset + step
            if new_offset < 0 then new_offset = 0 end
            local max_offset = math.max(0, #self._all_urls - self._visible_rows)
            if new_offset > max_offset then new_offset = max_offset end
            if new_offset ~= self._scroll_offset then
                self._scroll_offset = new_offset
                self:_refresh_url_rows()
            end
        end
        if over_curated and #self._all_curated > self._curated_visible_rows then
            local new_offset_c = self._curated_scroll_offset + step
            if new_offset_c < 0 then new_offset_c = 0 end
            local max_offset_c = math.max(0, #self._all_curated - self._curated_visible_rows)
            if new_offset_c > max_offset_c then new_offset_c = max_offset_c end
            if new_offset_c ~= self._curated_scroll_offset then
                self._curated_scroll_offset = new_offset_c
                self:_refresh_curated_rows()
            end
        end
    end

    for name, widget in pairs(self._widgets_by_name) do
        if widget.content and widget.content.is_writing then
            if input_service:get("confirm_pressed") then
                local text = widget.content.input_text
                --mod:echo("Submitted: %s", text)
                widget.content.is_writing = false
            end
        elseif widget.content and widget.content.hotspot then
            local hotspot = widget.content.hotspot
            local callback_name = widget.content.callback_name

            if hotspot and hotspot.on_pressed and callback_name then
                self[callback_name](self, widget)
            end
        end
    end
end

ImageSourceView._setup_input_legend = function(self)
    self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
    local legend_inputs = self._definitions.legend_inputs

    for i = 1, #legend_inputs do
        local legend_input = legend_inputs[i]
        local on_pressed_callback = legend_input.on_pressed_callback
            and callback(self, legend_input.on_pressed_callback)

        self._input_legend_element:add_entry(
            legend_input.display_name,
            legend_input.input_action,
            legend_input.visibility_function,
            on_pressed_callback,
            legend_input.alignment
        )
    end
end

ImageSourceView._on_back_pressed = function(self)
    Managers.ui:close_view(self.view_name)
end

ImageSourceView._button_pressed = function(self, widget)
    if widget.content.value then
        widget.content.value = false
        widget.content.text = "Disabled"
    else
        widget.content.value = true
        widget.content.text = "Enabled"
    end
end

function ImageSourceView:_on_toggle_local_images(widget)
    if not widget or not widget.content then return end
    local new_val = not widget.content.value
    widget.content.value = new_val
    widget.content.text = new_val and "On" or "Off"
    pcall(function() mod:set("loadLocal", new_val) end)
end

function ImageSourceView:_on_add_url_clicked(widget)
    local input = self._widgets_by_name.urlAddInput
    if not input or not input.content then return end
    local raw = (input.content.input_text or "")
    local url = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" then return end
    local lower = url:lower()
    for _, entry in ipairs(self._all_urls) do
        if entry.url:lower() == lower then
            input.content.input_text = ""; input.content.caret_position = 0; return
        end
    end
    table.insert(self._all_urls, { url = url, enabled = true })
    if #self._all_urls > self._visible_rows then
        self._scroll_offset = #self._all_urls - self._visible_rows
    end
    self:_refresh_url_rows()
    self:_persist_current_rows()
    input.content.input_text = ""; input.content.caret_position = 0
end

function ImageSourceView:_on_add_curated_clicked(widget)
    local input = self._widgets_by_name.curatedAddInput
    if not input or not input.content then return end
    local raw = (input.content.input_text or "")
    local url = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" then return end
    local lower = url:lower()
    for _, entry in ipairs(self._all_curated) do
        if entry.url:lower() == lower then
            input.content.input_text = ""; input.content.caret_position = 0; return
        end
    end
    table.insert(self._all_curated, { url = url, enabled = true, builtin = false })
    if #self._all_curated > self._curated_visible_rows then
        self._curated_scroll_offset = #self._all_curated - self._curated_visible_rows
    end
    self:_refresh_curated_rows()
    self:_persist_current_rows()
    input.content.input_text = ""; input.content.caret_position = 0
end

function ImageSourceView:_on_toggle_url_row(widget)
    if not widget or not widget.content then return end
    local visible_index = widget.content.row_index
    if not visible_index then return end
    local data_index = self._scroll_offset + visible_index
    local entry = self._all_urls[data_index]
    if not entry then return end
    entry.enabled = not entry.enabled
    if entry.enabled == false then
        mod.unload_url_image(entry.url)
    else
        -- If re-enabled and wasn't loaded, next refresh_sources_from_view or periodic load will bring it back
    end
    self:_refresh_url_rows()
    self:_persist_current_rows()
end

function ImageSourceView:_on_delete_url_row(widget)
    if not widget or not widget.content then return end
    local visible_index = widget.content.row_index
    if not visible_index then return end
    local data_index = self._scroll_offset + visible_index
    local removed = self._all_urls[data_index]
    if removed then
        mod.unload_url_image(removed.url)
        table.remove(self._all_urls, data_index)
        if self._scroll_offset > 0 and self._scroll_offset >= #self._all_urls - self._visible_rows + 1 then
            self._scroll_offset = math.max(0, #self._all_urls - self._visible_rows)
        end
        self:_refresh_url_rows()
        self:_persist_current_rows()
    end
end

function ImageSourceView:_on_scroll_up(widget)
    if self._scroll_offset > 0 then
        self._scroll_offset = self._scroll_offset - 1
        self:_refresh_url_rows()
    end
end

function ImageSourceView:_on_scroll_down(widget)
    if (self._scroll_offset + self._visible_rows) < #self._all_urls then
        self._scroll_offset = self._scroll_offset + 1
        self:_refresh_url_rows()
    end
end

function ImageSourceView:_refresh_url_rows()
    for i=1,self._visible_rows do
        local data = self._all_urls[self._scroll_offset + i]
        local row_widget = self._widgets_by_name["urlRow"..i]
        local toggle_widget = self._widgets_by_name["urlRow"..i.."Toggle"]
        local delete_widget = self._widgets_by_name["urlRow"..i.."Delete"]
        if data then
            if row_widget and row_widget.content then
                row_widget.content.text = data.url
                row_widget.content.visible = true
            end
            if toggle_widget and toggle_widget.content then
                toggle_widget.content.value = data.enabled
                toggle_widget.content.state_text = data.enabled and "On" or "Off"
                toggle_widget.content.visible = true
                toggle_widget.content.row_index = i
            end
            if delete_widget and delete_widget.content then
                delete_widget.content.visible = true
                delete_widget.content.row_index = i
            end
        else
            if row_widget and row_widget.content then
                row_widget.content.text = ""
                row_widget.content.visible = false
            end
            if toggle_widget and toggle_widget.content then
                toggle_widget.content.visible = false
            end
            if delete_widget and delete_widget.content then
                delete_widget.content.visible = false
            end
        end
    end
    local up = self._widgets_by_name.urlScrollUp
    local down = self._widgets_by_name.urlScrollDown
    local overflow = #self._all_urls > self._visible_rows
    if up and up.content then
        up.content.disabled = (self._scroll_offset == 0)
        up.content.visible = overflow
    end
    if down and down.content then
        down.content.disabled = (self._scroll_offset + self._visible_rows) >= #self._all_urls
        down.content.visible = overflow
    end
    local last_row_index = math.min(self._visible_rows, #self._all_urls)
    if last_row_index == 0 then
        if up and up.content then up.content.visible = false end
        if down and down.content then down.content.visible = false end
        return
    end
end

function ImageSourceView:_on_toggle_curated_row(widget)
    if not widget or not widget.content then return end
    local visible_index = widget.content.row_index
    if not visible_index then return end
    local data_index = self._curated_scroll_offset + visible_index
    local entry = self._all_curated[data_index]
    if not entry then return end
    entry.enabled = not entry.enabled
    if entry.enabled == false then
        mod.unload_curated_source(entry.url)
    else
        if mod.fetch_curated_source then
            mod.fetch_curated_source(entry.url)
        else
            if mod.refresh_sources_from_view then
                mod.refresh_sources_from_view()
            end
        end
    end
    self:_refresh_curated_rows()
    self:_persist_current_rows()
end

function ImageSourceView:_on_curated_scroll_up(widget)
    if self._curated_scroll_offset > 0 then
        self._curated_scroll_offset = self._curated_scroll_offset - 1
        self:_refresh_curated_rows()
    end
end

function ImageSourceView:_on_curated_scroll_down(widget)
    if (self._curated_scroll_offset + self._curated_visible_rows) < #self._all_curated then
        self._curated_scroll_offset = self._curated_scroll_offset + 1
        self:_refresh_curated_rows()
    end
end

function ImageSourceView:_refresh_curated_rows()
    for i=1,self._curated_visible_rows do
        local data = self._all_curated[self._curated_scroll_offset + i]
        local row_widget = self._widgets_by_name["curatedRow"..i]
        local toggle_widget = self._widgets_by_name["curatedRow"..i.."Toggle"]
        local delete_widget = self._widgets_by_name["curatedRow"..i.."Delete"]
        if data then
            if row_widget and row_widget.content then
                row_widget.content.text = data.url
                row_widget.content.visible = true
            end
            if toggle_widget and toggle_widget.content then
                toggle_widget.content.value = data.enabled
                toggle_widget.content.state_text = data.enabled and "On" or "Off"
                toggle_widget.content.visible = true
                toggle_widget.content.row_index = i
            end
            if delete_widget and delete_widget.content then
                if data.builtin then
                    delete_widget.content.visible = false
                else
                    delete_widget.content.visible = true
                    delete_widget.content.row_index = i
                end
            end
        else
            if row_widget and row_widget.content then
                row_widget.content.text = ""
                row_widget.content.visible = false
            end
            if toggle_widget and toggle_widget.content then
                toggle_widget.content.visible = false
            end
            if delete_widget and delete_widget.content then
                delete_widget.content.visible = false
            end
        end
    end
    local up = self._widgets_by_name.curatedScrollUp
    local down = self._widgets_by_name.curatedScrollDown
    local overflow = #self._all_curated > self._curated_visible_rows
    if up and up.content then
        up.content.disabled = (self._curated_scroll_offset == 0)
        up.content.visible = overflow
    end
    if down and down.content then
        down.content.disabled = (self._curated_scroll_offset + self._curated_visible_rows) >= #self._all_curated
        down.content.visible = overflow
    end
end

function ImageSourceView:_on_delete_curated_row(widget)
    if not widget or not widget.content then return end
    local visible_index = widget.content.row_index
    if not visible_index then return end
    local data_index = self._curated_scroll_offset + visible_index
    local entry = self._all_curated[data_index]
    if not entry or entry.builtin then return end
    table.remove(self._all_curated, data_index)
    if self._curated_scroll_offset > 0 and self._curated_scroll_offset >= #self._all_curated - self._curated_visible_rows + 1 then
        self._curated_scroll_offset = math.max(0, #self._all_curated - self._curated_visible_rows)
    end
    self:_refresh_curated_rows()
    self:_persist_current_rows()
end

ImageSourceView._confirm_pressed = function(self)
    --mod:echo("Confirm pressed")
end

ImageSourceView._destroy_renderer = function(self)
    if self._offscreen_renderer then
        self._offscreen_renderer = nil
    end

    local world_data = self._offscreen_world

    if world_data then
        Managers.ui:destroy_renderer(world_data.renderer_name)
        ScriptWorld.destroy_viewport(world_data.world, world_data.viewport_name)
        Managers.ui:destroy_world(world_data.world)

        world_data = nil
    end
end

ImageSourceView.update = function(self, dt, t, input_service)
    ImageSourceView.super.update(self, dt, t, input_service)
end

ImageSourceView.draw = function(self, dt, t, input_service, layer)
    ImageSourceView.super.draw(self, dt, t, input_service, layer)
end

ImageSourceView._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
    ImageSourceView.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

ImageSourceView.on_exit = function(self)
    ImageSourceView.super.on_exit(self)

    local rows = {}
    for _, entry in ipairs(self._all_urls) do
        rows[#rows+1] = { url = entry.url, enabled = entry.enabled }
    end
    pcall(function() mod:set("urls_rows", rows) end)

    local crows = {}
    for _, entry in ipairs(self._all_curated) do
        crows[#crows+1] = { url = entry.url, enabled = entry.enabled, builtin = entry.builtin or false }
    end
    pcall(function() mod:set("curated_rows", crows) end)

    self:_destroy_renderer()
end

return ImageSourceView
