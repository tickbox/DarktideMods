-- Thanks to Seventeen Ducks in a trenchcoat for the CustomViewBoilerplate mod!
-- https://github.com/ronvoluted/darktide-mods/tree/c4db1d24eb9d973f70a2a7062e0fd557d4d4bc6a/CustomViewBoilerplate/scripts/mods/CustomViewBoilerplate
local mod = get_mod("CustomLoadingBackground")

local UIWidget = require("scripts/managers/ui/ui_widget")
local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local FrameSize = { RESOLUTION_LOOKUP.width / RESOLUTION_LOOKUP.scale, RESOLUTION_LOOKUP.height / RESOLUTION_LOOKUP.scale }
local BackgroundElementFrames

local definitions = {
    scenegraph_definition = {
        screen = {
            scale = "fit",
            size = {
                1920,
                1080,
            },
        },
        canvas = {
            parent = "screen",
            horizontal_alignment = "center",
            vertical_alignment = "center",
            size = {
                1920,
                1080,
            },
            position = {
                0,
                0,
                0,
            },
        },
    },
    widget_definitions = {
        BackgroundWidget = UIWidget.create_definition({
            {
                pass_type = "texture",
                style_id = "BackgroundElementFrames",
                style = {
                    size = FrameSize,
                    visible = false,
                }
            },
        }, "canvas")
    },
    legend_inputs = {
        {
            input_action = "back",
            on_pressed_callback = "_on_back_pressed",
            display_name = "loc_class_selection_button_back",
            alignment = "left_alignment",
        },
    },
}

SlideShowView = class("SlideShowView", "BaseView")

SlideShowView.init = function(self, settings)
    SlideShowView.super.init(self, definitions, settings)

    BackgroundElementFrames = self._widgets_by_name.BackgroundWidget.style.BackgroundElementFrames
end

SlideShowView.on_enter = function(self)
    SlideShowView.super.on_enter(self)

    self:_setup_input_legend()
end

SlideShowView._setup_input_legend = function(self)
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

SlideShowView._on_back_pressed = function(self)
    Managers.ui:close_view(self.view_name)
end

SlideShowView._destroy_renderer = function(self)
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

SlideShowView.update = function(self, dt, t, input_service)
    if mod.showBG then
        BackgroundElementFrames.visible = true
    else
        BackgroundElementFrames.visible = false
    end

    if not BackgroundElementFrames.material_values then
        BackgroundElementFrames.material_values = {}
    end

    BackgroundElementFrames.material_values.texture_map = mod.BGTexture

    return SlideShowView.super.update(self, dt, t, input_service)
end

SlideShowView.draw = function(self, dt, t, input_service, layer)
    SlideShowView.super.draw(self, dt, t, input_service, layer)
end

SlideShowView._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
    SlideShowView.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

SlideShowView.on_exit = function(self)
    SlideShowView.super.on_exit(self)

    self:_destroy_renderer()
end

return SlideShowView
