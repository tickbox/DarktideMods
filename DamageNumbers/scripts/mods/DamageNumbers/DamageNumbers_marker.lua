local mod = get_mod("DamageNumbers")

local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local template = {}

local defaults = mod._default_settings or {
    text_size_base = 26,
    text_size_weak = 28,
    text_size_crit = 34,
    color_normal = { 255, 255, 230, 50 },
    color_weak = { 255, 255, 200, 80 },
    color_crit = { 255, 255, 80, 80 },
}

template.name = "damage_numbers_hit"
template.size = { 400, 200 }
template.unit_node = "ui_marker"
template.max_distance = 300
template.min_distance = 0

local function _base_text_style()
    local s = table.clone(UIFontSettings.hud_body)
    s.font_size = 26
    s.text_color = { 255, 255, 230, 50 }
    s.default_text_color = s.text_color
    s.drop_shadow = true
    s.offset = { 0, -24, 20 }
    s.default_offset = { 0, -24, 20 }
    s.size = { template.size[1], template.size[2] }
    s.horizontal_alignment = "center"
    s.vertical_alignment = "center"
    s.text_horizontal_alignment = "center"
    s.text_vertical_alignment = "center"
    return s
end

template.create_widget_defintion = function(_, scenegraph_id)
    return UIWidget.create_definition({
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            style = _base_text_style(),
            visibility_function = function(content, style)
                return content.text and content.text ~= ""
            end,
        },
    }, scenegraph_id)
end

template.on_enter = function(widget)
    local content = widget.content
    content.text = content.text or ""
    content._initted = true
end

template.update_function = function(parent, ui_renderer, widget, marker, _, dt, t)
    if not marker or not widget then
        return false
    end
    local data = marker.data or {}
    if data.use_world_position and data.hit_pos then
        if not marker._dn_worldpos_box then
            local p = data.hit_pos
            local x, y, z
            if type(p) == "userdata" and p.unbox then
                x, y, z = p:unbox()
            else
                local ok, vx = pcall(function() return Vector3 and Vector3.x and Vector3.x(p) end)
                if ok and vx then
                    x = vx; y = Vector3.y(p); z = Vector3.z(p)
                elseif type(p) == "table" then
                    x, y, z = p[1], p[2], p[3]
                end
            end
            if x and y and z then
                local lift = (data and data.lift) or 0.2
                marker._dn_worldpos_box = (Vector3Box and Vector3Box(x, y, z + lift)) or Vector3(x, y, z + lift)
            end
            marker._dn_worldpos_applied = true
        end
        if marker._dn_worldpos_box then
            marker.world_position = marker._dn_worldpos_box
            marker.use_world_position = true
            marker.unit = nil
            marker.unit_node = nil
            marker.node_index = -1
        end
    end
    local content = widget.content
    local style = widget.style.text
    data = marker.data or data or {}

    local cache = mod._settings_cache or {}
    if (cache.text_size_base == nil) and mod.refresh_settings_cache then
        mod.refresh_settings_cache()
        cache = mod._settings_cache or cache
    end

    marker._dn_elapsed = (marker._dn_elapsed or 0) + (dt or 0)
    local life = data.life or 1.0
    local age = marker._dn_elapsed
    local progress = math.clamp((life > 0 and age / life) or 0, 0, 1)

    local is_crit = data.crit and true or false
    local is_weak = data.weakspot and true or false
    local size_base = cache.text_size_base or defaults.text_size_base
    local size_weak = cache.text_size_weak or defaults.text_size_weak
    local size_crit = cache.text_size_crit or defaults.text_size_crit
    local color_normal = cache.color_normal or defaults.color_normal
    local color_weak = cache.color_weak or defaults.color_weak
    local color_crit = cache.color_crit or defaults.color_crit
    local color = is_crit and color_crit or (is_weak and color_weak or color_normal)
    local size = is_crit and size_crit or (is_weak and size_weak or size_base)

    style.font_size = size
    local text_color = style.text_color
    if text_color then
        text_color[1] = color[1] or 255
        text_color[2] = color[2] or 255
        text_color[3] = color[3] or 255
        text_color[4] = color[4] or 255
    end

    content.text = data.text or tostring(data.dmg or "")

    local rise_px = data.rise_px or 36
    local base_y = -(data.screen_offset_y_px or 24)
    local yoff = base_y - (age * rise_px)
    style.offset[1] = 0
    style.offset[2] = yoff

    local base_alpha = (color and color[1]) or 255
    local a = base_alpha
    if progress > 0.75 then
        a = math.floor(base_alpha * (1 - (progress - 0.75) / 0.25))
    end
    if text_color then
        text_color[1] = a
    end

    widget.alpha_multiplier = 1
    widget.visible = progress < 1
    marker.use_world_position = true

    if not marker._dn_life_applied then
        marker.life_time = life
        marker._dn_life_applied = true
    end

    if age >= life then
        widget.visible = false
        --marker.remove = true
        return true
    end

    return false
end

return template
