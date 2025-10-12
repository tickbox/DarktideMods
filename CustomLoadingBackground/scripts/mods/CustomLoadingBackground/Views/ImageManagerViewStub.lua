local mod = get_mod("CustomLoadingBackground")
mod:echo("[CLB] Loading ImageManagerViewStub.lua")

local UIWidget = require("scripts/managers/ui/ui_widget")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local definitions = {
    scenegraph_definition = {
        screen = { scale = "fit", size = {1920,1080} },
        canvas = { parent = "screen", horizontal_alignment = "center", vertical_alignment = "center", size = {800,600}, position = {0,0,0} },
        title = { parent = "canvas", size = {800,60}, position = {0,0,1} },
    },
    widget_definitions = {
        title = UIWidget.create_definition({
            { pass_type = "text", value = "Image Manager STUB", value_id = "title", style_id = "title", style = { font_size = 40, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } }
        }, "title")
    },
    legend_inputs = {
        { input_action = "back", on_pressed_callback = "_on_back_pressed", display_name = "loc_class_selection_button_back", alignment = "left_alignment" },
    }
}

ImageManagerViewStub = class("ImageManagerViewStub", "BaseView")

function ImageManagerViewStub:init(settings)
    ImageManagerViewStub.super.init(self, definitions, settings)
end

function ImageManagerViewStub:on_enter()
    ImageManagerViewStub.super.on_enter(self)
    self:_setup_input_legend()
end

function ImageManagerViewStub:_setup_input_legend()
    self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
    local legend_inputs = self._definitions.legend_inputs or {}
    for i = 1, #legend_inputs do
        local li = legend_inputs[i]
        local cb = li.on_pressed_callback and callback(self, li.on_pressed_callback)
        self._input_legend_element:add_entry(li.display_name, li.input_action, li.visibility_function, cb, li.alignment)
    end
end

function ImageManagerViewStub:_on_back_pressed()
    Managers.ui:close_view(self.view_name)
end

return ImageManagerViewStub
