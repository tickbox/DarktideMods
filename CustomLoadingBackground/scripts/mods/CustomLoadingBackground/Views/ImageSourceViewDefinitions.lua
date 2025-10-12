local mod = get_mod("CustomLoadingBackground")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local TextInputPassTemplates = require("scripts/ui/pass_templates/text_input_pass_templates")

local FrameSize = { RESOLUTION_LOOKUP.width / RESOLUTION_LOOKUP.scale, RESOLUTION_LOOKUP.height / RESOLUTION_LOOKUP.scale }
local width = RESOLUTION_LOOKUP.width / RESOLUTION_LOOKUP.scale
local height = RESOLUTION_LOOKUP.height / RESOLUTION_LOOKUP.scale
local margin = 20
local panelTitleSize = UIWorkspaceSettings.top_panel.size[2]
local panelBottomSize = UIWorkspaceSettings.bottom_panel.size[2]

local availH = height - (margin * 2) - panelTitleSize - panelBottomSize
local localPanelH = 70
local gapH = math.floor(margin * 0.5)
local listPanelH = math.floor((availH - localPanelH - (gapH * 2)) / 2)

local optionButtons = {}

local scenegraph_definition = {
    screen = {
        size = {
            width,
            height,
        },
        scale = "fit",
    },
    panelTitle = {
        parent = "screen",
        size = {
            width,
            panelTitleSize,
        },
        position = {
            0,
            0,
            0,
        },
    },
    panelTitleText = {
        parent = "panelTitle",
        size = {
            width,
            panelTitleSize,
        },
        position = {
            0,
            0,
            0,
        },
    },
    panelOptions = {
        parent = "screen",
        size = {
            width - (margin * 2),
            localPanelH,
        },
        position = {
            margin,
            margin + panelTitleSize,
            0,
        },
    },
    localLabelNode = {
        parent = "panelOptions",
        size = { 320, 28 },
        position = { 12, 32 + 6, 2 },
    },
    localToggleNode = {
        parent = "panelOptions",
        size = { 80, 28 },
        position = { 12 + 320 + 12, 32 + 6, 2 },
    },
    panelURL = {
        parent = "screen",
        size = {
            width - (margin * 2),
            listPanelH,
        },
        position = {
            margin,
            margin + panelTitleSize + localPanelH + gapH,
            0,
        },
    },
    urlAddLabelNode = {
        parent = "panelURL",
        size = { 200, 28 },
        position = { 12, 32 + 6, 2 },
    },
    urlAddInputNode = {
        parent = "panelURL",
        size = { (width - (margin * 2)) - 200 - 12 - 40 - 24, 32 },
        position = { 12 + 200 + 12, 32 + 4, 2 },
    },
    urlAddButtonNode = {
        parent = "panelURL",
        size = { 40, 32 },
        position = { (width - (margin * 2)) - 40 - 12, 32 + 4, 2 },
    },
    urlScrollUpNode = { parent = "urlRow1Node", size = {24,24}, position = { (width - (margin * 2) - 24) - 24 - 24 - 4, 1, 4 } },
    urlScrollDownNode = { parent = "urlRow10Node", size = {24,24}, position = { (width - (margin * 2) - 24) - 24 - 24 - 4, 1, 4 } },

    urlRow1Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (0 * 30), 2 } },
    urlRow2Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (1 * 30), 2 } },
    urlRow3Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (2 * 30), 2 } },
    urlRow4Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (3 * 30), 2 } },
    urlRow5Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (4 * 30), 2 } },
    urlRow6Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (5 * 30), 2 } },
    urlRow7Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (6 * 30), 2 } },
    urlRow8Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (7 * 30), 2 } },
    urlRow9Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (8 * 30), 2 } },
    urlRow10Node = { parent = "panelURL", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (9 * 30), 2 } },
    
    urlRow1ToggleNode = { parent = "urlRow1Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow2ToggleNode = { parent = "urlRow2Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow3ToggleNode = { parent = "urlRow3Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow4ToggleNode = { parent = "urlRow4Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow5ToggleNode = { parent = "urlRow5Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow6ToggleNode = { parent = "urlRow6Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow7ToggleNode = { parent = "urlRow7Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow8ToggleNode = { parent = "urlRow8Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow9ToggleNode = { parent = "urlRow9Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    urlRow10ToggleNode = { parent = "urlRow10Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    
    urlRow1DeleteNode = { parent = "urlRow1Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow2DeleteNode = { parent = "urlRow2Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow3DeleteNode = { parent = "urlRow3Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow4DeleteNode = { parent = "urlRow4Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow5DeleteNode = { parent = "urlRow5Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow6DeleteNode = { parent = "urlRow6Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow7DeleteNode = { parent = "urlRow7Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow8DeleteNode = { parent = "urlRow8Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow9DeleteNode = { parent = "urlRow9Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    urlRow10DeleteNode = { parent = "urlRow10Node", size = { 24, 24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    
    panelCurated = {
        parent = "screen",
        size = {
            width - (margin * 2),
            listPanelH,
        },
        position = {
            margin,
            margin + panelTitleSize + localPanelH + gapH + listPanelH + gapH,
            0,
        },
    },
    
    optionsTitle = {
        parent = "panelOptions",
        size = { width - (margin * 2), 32 },
        position = { 0, 0, 2 },
    },
    urlTitle = {
        parent = "panelURL",
        size = { width - (margin * 2), 32 },
        position = { 0, 4, 2 },
    },
    curatedTitle = {
        parent = "panelCurated",
        size = { width - (margin * 2), 32 },
        position = { 0, 4, 2 },
    },
    curatedAddLabelNode = {
        parent = "panelCurated",
        size = { 260, 28 },
        position = { 12, 32 + 6, 2 },
    },
    curatedAddInputNode = {
        parent = "panelCurated",
        size = { (width - (margin * 2)) - 260 - 12 - 40 - 24, 32 },
        position = { 12 + 260 + 12, 32 + 4, 2 },
    },
    curatedAddButtonNode = {
        parent = "panelCurated",
        size = { 40, 32 },
        position = { (width - (margin * 2)) - 40 - 12, 32 + 4, 2 },
    },
    
    curatedScrollUpNode = { parent = "curatedRow1Node", size = {24,24}, position = { (width - (margin * 2) - 24) - 24 - 24 - 4, 1, 4 } },
    curatedScrollDownNode = { parent = "curatedRow10Node", size = {24,24}, position = { (width - (margin * 2) - 24) - 24 - 24 - 4, 1, 4 } },
    
    curatedRow1Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (0 * 30), 2 } },
    curatedRow2Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (1 * 30), 2 } },
    curatedRow3Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (2 * 30), 2 } },
    curatedRow4Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (3 * 30), 2 } },
    curatedRow5Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (4 * 30), 2 } },
    curatedRow6Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (5 * 30), 2 } },
    curatedRow7Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (6 * 30), 2 } },
    curatedRow8Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (7 * 30), 2 } },
    curatedRow9Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (8 * 30), 2 } },
    curatedRow10Node = { parent = "panelCurated", size = { width - (margin * 2) - 24, 26 }, position = { 12, 32 + 6 + 40 + (9 * 30), 2 } },
    
    curatedRow1ToggleNode = { parent = "curatedRow1Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow2ToggleNode = { parent = "curatedRow2Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow3ToggleNode = { parent = "curatedRow3Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow4ToggleNode = { parent = "curatedRow4Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow5ToggleNode = { parent = "curatedRow5Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow6ToggleNode = { parent = "curatedRow6Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow7ToggleNode = { parent = "curatedRow7Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow8ToggleNode = { parent = "curatedRow8Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow9ToggleNode = { parent = "curatedRow9Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    curatedRow10ToggleNode = { parent = "curatedRow10Node", size = { 24, 24 }, position = { 0, 1, 3 } },
    
    curatedRow1DeleteNode = { parent = "curatedRow1Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow2DeleteNode = { parent = "curatedRow2Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow3DeleteNode = { parent = "curatedRow3Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow4DeleteNode = { parent = "curatedRow4Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow5DeleteNode = { parent = "curatedRow5Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow6DeleteNode = { parent = "curatedRow6Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow7DeleteNode = { parent = "curatedRow7Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow8DeleteNode = { parent = "curatedRow8Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow9DeleteNode = { parent = "curatedRow9Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
    curatedRow10DeleteNode = { parent = "curatedRow10Node", size = { 24,24 }, position = { (width - (margin * 2) - 24) - 24, 1, 3 } },
}

local widget_definitions = {
    BackgroundWidget = UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "OptionsBackgroundElementFrames",
            style = {
                scale = fit,
                color = {
                    160,
                    0,
                    0,
                    0
                },
            },
        },
    }, "screen"),
    panelTitleBG = UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "OptionsBackgroundElementFrames",
            scale_to_material = true,
            style = {
                color = {
                    100,
                    0,
                    0,
                    0
                },
            },
        },
    }, "panelTitle"),
    panelTitleTextText = UIWidget.create_definition({
        {
            value_id = "text",
            pass_type = "text",
            style_id = "text",
            value = mod:localize("mod_name"),
            style = {
                font_size = 55,
                font_type = "machine_medium",
                material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                text_color = { 255, 255, 255, 255},
                offset = { 0, 0, 1 },
            },
        },
    }, "panelTitle"),
    panelCuratedBG = UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "CuratedBG",
            scale_to_material = true,
            style = {
                color = {
                    100,
                    0,
                    0,
                    0
                },
                scale = "fit",
                offset = {
                    0,
                    0,
                    1
                },
            },
        },
    }, "panelCurated"),
    panelURLBG = UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "CuratedBG",
            scale_to_material = true,
            style = {
                color = {
                    100,
                    0,
                    0,
                    0
                },
                scale = "fit",
                offset = {
                    0,
                    0,
                    1
                },
            },
        },
    }, "panelURL"),
    urlPanelScrollHotspot = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
    }, "panelURL", { hotspot = {} }),
    panelOptionsBG = UIWidget.create_definition({
        {
            pass_type = "rect",
            style = {
                color = {
                    100,
                    0,
                    0,
                    0
                },
                scale = "fit",
                offset = {
                    0,
                    0,
                    1
                },
            },
        },
    }, "panelOptions"),
    localImagesLabel = UIWidget.create_definition({
    curatedPanelScrollHotspot = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
    }, "panelCurated", { hotspot = {} }),
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Load local images",
            style = {
                font_size = 22,
                font_type = "machine_medium",
                text_color = {255,255,255,255},
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                offset = { 0, 0, 2 },
            }
        }
    }, "localLabelNode"),
    localImagesToggle = UIWidget.create_definition({
        {
            pass_type = "hotspot",
            content_id = "hotspot",
        },
        {
            pass_type = "rect",
            style_id = "bg",
            style = {
                color = {255,60,60,60},
                offset = {0,0,0},
            },
            change_function = function(content, style)
                if content.value then
                    style.color = {255,90,140,90}
                else
                    style.color = {255,60,60,60}
                end
            end,
        },
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "On",
            style = {
                font_size = 20,
                font_type = "machine_medium",
                text_color = {255,255,255,255},
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                offset = {0,0,2},
            }
        },
    }, "localToggleNode", {
        hotspot = {},
        callback_name = "_on_toggle_local_images",
        value = false,
        text = "Off",
    }),
    urlAddLabel = UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Add Image URL",
            style = {
                font_size = 22,
                font_type = "machine_medium",
                text_color = {255,255,255,255},
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                offset = {0,0,2},
            }
        }
    }, "urlAddLabelNode"),
    urlAddInput = UIWidget.create_definition(
        TextInputPassTemplates.simple_input_field,
        "urlAddInputNode",
        {
            input_text = "",
            placeholder = "Enter URL here",
            is_writing = false,
        }
    ),
    urlAddButton = UIWidget.create_definition({
        {
            pass_type = "hotspot",
            content_id = "hotspot",
        },
        {
            pass_type = "rect",
            style = { color = {255,70,70,70}, offset = {0,0,0} },
        },
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "+",
            style = {
                font_size = 26,
                font_type = "machine_medium",
                text_color = {255,255,255,255},
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                offset = {0,0,2},
            }
        },
    }, "urlAddButtonNode", {
        hotspot = {},
        callback_name = "_on_add_url_clicked",
    }),
    urlScrollUp = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,70,70,70} } }, { pass_type = "text", value_id = "glyph", value = "", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlScrollUpNode", { hotspot = {}, callback_name = "_on_scroll_up", glyph = "" }),
    urlScrollDown = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,70,70,70} } }, { pass_type = "text", value_id = "glyph", value = "", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlScrollDownNode", { hotspot = {}, callback_name = "_on_scroll_down", glyph = "" }),
    
    urlRow1 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow1Node"),
    urlRow2 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow2Node"),
    urlRow3 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow3Node"),
    urlRow4 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow4Node"),
    urlRow5 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow5Node"),
    urlRow6 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow6Node"),
    urlRow7 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow7Node"),
    urlRow8 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow8Node"),
    urlRow9 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow9Node"),
    urlRow10 = UIWidget.create_definition({ { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "urlRow10Node"),
    
    urlRow1Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow1ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=1}),
    urlRow2Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow2ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=2}),
    urlRow3Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow3ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=3}),
    urlRow4Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow4ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=4}),
    urlRow5Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow5ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=5}),
    urlRow6Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow6ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=6}),
    urlRow7Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow7ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=7}),
    urlRow8Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow8ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=8}),
    urlRow9Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow9ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=9}),
    urlRow10Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On" , style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "urlRow10ToggleNode", {hotspot={}, callback_name="_on_toggle_url_row", value=true, state_text="On", row_index=10}),
    
    urlRow1Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow1DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=1}),
    urlRow2Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow2DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=2}),
    urlRow3Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow3DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=3}),
    urlRow4Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow4DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=4}),
    urlRow5Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow5DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=5}),
    urlRow6Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow6DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=6}),
    urlRow7Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow7DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=7}),
    urlRow8Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow8DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=8}),
    urlRow9Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow9DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=9}),
    urlRow10Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "urlRow10DeleteNode", {hotspot={}, callback_name="_on_delete_url_row", row_index=10}),
    
    panelOptionsTitle = UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Local Images",
            style = {
                font_size = 26,
                font_type = "machine_medium",
                material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                text_color = {255, 255, 255, 255},
                offset = { 12, 0, 2 },
            },
        },
    }, "optionsTitle"),
    panelURLTitle = UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Image URLs",
            style = {
                font_size = 26,
                font_type = "machine_medium",
                material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                text_color = {255, 255, 255, 255},
                offset = { 12, 0, 2 },
            },
        },
    }, "urlTitle"),
    panelCuratedTitle = UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Curated Lists",
            style = {
                font_size = 26,
                font_type = "machine_medium",
                material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                text_color = {255, 255, 255, 255},
                offset = { 12, 0, 2 },
            },
        },
    }, "curatedTitle"),
    curatedAddLabel = UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "Add Curated List URL",
            style = {
                font_size = 22,
                font_type = "machine_medium",
                text_color = {255,255,255,255},
                text_horizontal_alignment = "left",
                text_vertical_alignment = "center",
                offset = {0,0,2},
            }
        }
    }, "curatedAddLabelNode"),
    curatedAddInput = UIWidget.create_definition(
        TextInputPassTemplates.simple_input_field,
        "curatedAddInputNode",
        {
            input_text = "",
            placeholder = "Enter curated list URL",
            is_writing = false,
        }
    ),
    curatedAddButton = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
        { pass_type = "rect", style = { color = {255,70,70,70}, offset = {0,0,0} } },
        { pass_type = "text", value_id = "text", style_id = "text", value = "+", style = { font_size = 26, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center", offset = {0,0,2} } },
    }, "curatedAddButtonNode", { hotspot = {}, callback_name = "_on_add_curated_clicked" }),
    curatedScrollUp = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,70,70,70} } }, { pass_type = "text", value_id = "glyph", value = "", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedScrollUpNode", { hotspot = {}, callback_name = "_on_curated_scroll_up", glyph = "" }),
    curatedScrollDown = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,70,70,70} } }, { pass_type = "text", value_id = "glyph", value = "", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedScrollDownNode", { hotspot = {}, callback_name = "_on_curated_scroll_down", glyph = "" }),
    
    curatedRow1 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow1Node", { hotspot = {} }),
    curatedRow2 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow2Node", { hotspot = {} }),
    curatedRow3 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow3Node", { hotspot = {} }),
    curatedRow4 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow4Node", { hotspot = {} }),
    curatedRow5 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow5Node", { hotspot = {} }),
    curatedRow6 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow6Node", { hotspot = {} }),
    curatedRow7 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow7Node", { hotspot = {} }),
    curatedRow8 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow8Node", { hotspot = {} }),
    curatedRow9 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow9Node", { hotspot = {} }),
    curatedRow10 = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {60,0,0,0}, offset = {0,0,0} } }, { pass_type = "text", value_id = "text", style = { font_size = 20, font_type = "machine_medium", text_color = {255,230,230,230}, text_horizontal_alignment = "left", text_vertical_alignment = "center", offset = {28,0,2} }, value = "" } }, "curatedRow10Node", { hotspot = {} }),
    
    curatedRow1Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow1ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=1}),
    curatedRow2Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow2ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=2}),
    curatedRow3Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow3ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=3}),
    curatedRow4Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow4ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=4}),
    curatedRow5Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow5ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=5}),
    curatedRow6Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow6ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=6}),
    curatedRow7Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow7ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=7}),
    curatedRow8Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow8ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=8}),
    curatedRow9Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow9ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=9}),
    curatedRow10Toggle = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style_id = "bg", style = { color = {255,40,40,40} }, change_function = function(c,s) s.color = c.value and {255,90,140,90} or {255,40,40,40} end }, { pass_type = "text", value_id = "state_text", value = "On", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" }, change_function=function(content,style) style.text_color = content.value and {255,255,255,255} or {255,200,200,200}; content.state_text = content.value and "On" or "Off" end } }, "curatedRow10ToggleNode", {hotspot={}, callback_name="_on_toggle_curated_row", value=true, state_text="On", row_index=10}),
    
    curatedRow1Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow1DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=1}),
    curatedRow2Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow2DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=2}),
    curatedRow3Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow3DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=3}),
    curatedRow4Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow4DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=4}),
    curatedRow5Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow5DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=5}),
    curatedRow6Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow6DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=6}),
    curatedRow7Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow7DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=7}),
    curatedRow8Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow8DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=8}),
    curatedRow9Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow9DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=9}),
    curatedRow10Delete = UIWidget.create_definition({ { pass_type = "hotspot", content_id = "hotspot" }, { pass_type = "rect", style = { color = {255,90,40,40} } }, { pass_type = "text", value = "X", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center" } } }, "curatedRow10DeleteNode", {hotspot={}, callback_name="_on_delete_curated_row", row_index=10}),
}

local legend_inputs = {
    {
        input_action = "back",
        on_pressed_callback = "_on_back_pressed",
        display_name = "loc_class_selection_button_back",
        alignment = "left_alignment",
    },
}

return {
    scenegraph_definition = scenegraph_definition,
    widget_definitions = widget_definitions,
    legend_inputs = legend_inputs,
}