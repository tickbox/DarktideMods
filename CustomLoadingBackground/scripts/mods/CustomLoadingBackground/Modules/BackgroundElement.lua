local mod = get_mod("CustomLoadingBackground")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local BackgroundElement = class("BackgroundElement", "HudElementBase")

local FrameSize = { RESOLUTION_LOOKUP.width / RESOLUTION_LOOKUP.scale, RESOLUTION_LOOKUP.height / RESOLUTION_LOOKUP.scale }
local BackgroundElementFrames

BackgroundElement.init = function(self, parent, draw_layer, start_scale)
    BackgroundElement.super.init(self, parent, draw_layer, start_scale, {
        scenegraph_definition = {
            screen = UIWorkspaceSettings.screen,
            BackgroundAnchor = {
                parent = "screen",
                horizontal_alignment = "center",
                vertical_alignment = "bottom",
                position = { -FrameSize[1] / 2, -FrameSize[2], 0 },
                size = { 0, 0 },
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
            }, "BackgroundAnchor"),
        },
    })

    BackgroundElementFrames = self._widgets_by_name.BackgroundWidget.style.BackgroundElementFrames
end

BackgroundElement.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    BackgroundElement.super.update(self, dt, t, ui_renderer, render_settings, input_service)

    if mod.showBG then
        BackgroundElementFrames.visible = true
    else
        BackgroundElementFrames.visible = false
    end

    if not BackgroundElementFrames.material_values then
        BackgroundElementFrames.material_values = {}
    end

    BackgroundElementFrames.material_values.texture_map = mod.BGTexture
end

return BackgroundElement