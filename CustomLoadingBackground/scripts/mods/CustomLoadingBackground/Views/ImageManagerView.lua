local mod = get_mod("CustomLoadingBackground")
--mod:echo("[CLB] Loading ImageManagerView.lua")

local UIWidget = require("scripts/managers/ui/ui_widget")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")

local ENABLE_THUMBS = true
local ENABLE_PAGING = true
local ENABLE_BATCH_ACTIONS = false
local USE_GRID_VIEW = false
local USE_CAROUSEL_VIEW = true
local THUMB_SIZE = 96
local THUMB_ASPECT = 9/16
local ROW_HEIGHT = 56
local PADDING = 4
local LIST_WIDTH = 600
local MAX_ROWS = 15

local GRID_COLS = 4
local GRID_ROWS = 3
local GRID_H_GAP = 16
local GRID_V_GAP = 16
local GRID_WIDTH = 1520
local GRID_HEIGHT = 780
local CARD_W = math.floor((GRID_WIDTH - (GRID_COLS - 1) * GRID_H_GAP) / GRID_COLS)
local CARD_H = math.floor((GRID_HEIGHT - (GRID_ROWS - 1) * GRID_V_GAP) / GRID_ROWS)
local MAX_CARDS = GRID_COLS * GRID_ROWS

local width = RESOLUTION_LOOKUP.width / RESOLUTION_LOOKUP.scale
local height = RESOLUTION_LOOKUP.height / RESOLUTION_LOOKUP.scale
local panelTitleSize = UIWorkspaceSettings.top_panel.size[2]
local panelBottomSize = UIWorkspaceSettings.bottom_panel.size[2]
local margin = 20

local BASE_W, BASE_H = 1920, 1080
local ui_scale = math.min(width / BASE_W, height / BASE_H)

local CENTER_W = math.floor(1100 * ui_scale)
local CENTER_H = math.floor(700 * ui_scale)
local STACK_W = math.floor(460 * ui_scale)
local STACK_H = math.floor(720 * ui_scale)
local SPACING_X = math.floor(110 * ui_scale)
local Y_OFFSET = math.floor(40 * ui_scale)
local SIDE_Y = math.floor(20 * ui_scale)
local LABEL_H = math.max(24, math.floor(28 * ui_scale))
local BUTTON_W = math.max(180, math.floor(220 * ui_scale))
local BUTTON_H = math.max(28, math.floor(36 * ui_scale))

local legend_inputs_list = {
    { input_action = "back", on_pressed_callback = "_on_back_pressed", display_name = "loc_class_selection_button_back", alignment = "left_alignment" },
}
--[[ if ENABLE_PAGING then
    if USE_CAROUSEL_VIEW then
        legend_inputs_list[#legend_inputs_list+1] = { input_action = "navigate_secondary_right", on_pressed_callback = "_on_next_image", display_name = "loc_clb_action_page_next", alignment = "right_alignment" }
        legend_inputs_list[#legend_inputs_list+1] = { input_action = "navigate_secondary_left", on_pressed_callback = "_on_prev_image", display_name = "loc_clb_action_page_prev", alignment = "right_alignment" }
    else
        legend_inputs_list[#legend_inputs_list+1] = { input_action = "navigate_secondary_right", on_pressed_callback = "_on_next_page", display_name = "loc_clb_action_page_next", alignment = "right_alignment" }
        legend_inputs_list[#legend_inputs_list+1] = { input_action = "navigate_secondary_left", on_pressed_callback = "_on_prev_page", display_name = "loc_clb_action_page_prev", alignment = "right_alignment" }
    end
end ]]

local definitions = {
    scenegraph_definition = {
        screen = { scale = "fit", size = { width, height } },
        canvas = {
            parent = "screen",
            horizontal_alignment = "left",
            vertical_alignment = "top",
            size = { width, height },
            position = { 0, 0, 0 },
        },
        panel_title = { parent = "canvas", size = { width, panelTitleSize }, position = { 0, 0, 0 } },
        panel_title_text = { parent = "panel_title", size = { width, panelTitleSize }, position = { 0, 0, 1 } },
        list_area = { parent = "canvas", size = { LIST_WIDTH, (ROW_HEIGHT) * MAX_ROWS }, position = { 40, panelTitleSize + margin, 1 } },
        grid_area = { parent = "canvas", size = { GRID_WIDTH, GRID_HEIGHT }, position = { (width - GRID_WIDTH) / 2, panelTitleSize + margin + 30, 1 } },
        carousel_area = { parent = "canvas", size = { width, height - panelTitleSize - panelBottomSize - (margin * 2) }, position = { 0, panelTitleSize + margin, 1 } },
        center_area = { parent = "carousel_area", size = { CENTER_W, CENTER_H }, position = { (width - CENTER_W) / 2, Y_OFFSET, 1 } },
        left_stack_area = { parent = "carousel_area", size = { STACK_W, STACK_H }, position = { SPACING_X, SIDE_Y, 1 } },
        right_stack_area = { parent = "carousel_area", size = { STACK_W, STACK_H }, position = { width - SPACING_X - STACK_W, SIDE_Y, 1 } },
        center_label = { parent = "carousel_area", size = { CENTER_W, LABEL_H }, position = { (width - CENTER_W) / 2, Y_OFFSET + CENTER_H + math.floor(12 * ui_scale), 1 } },
        center_button = { parent = "carousel_area", size = { CENTER_W, BUTTON_H }, position = { (width - CENTER_W) / 2, Y_OFFSET + CENTER_H + math.floor(12 * ui_scale) + LABEL_H + math.floor(8 * ui_scale), 1 } },
    footer = { parent = "canvas", size = { LIST_WIDTH, 30 }, position = { width - LIST_WIDTH - margin, height - panelBottomSize + math.floor((panelBottomSize - 30) / 2), 1 } },
    footer_enable = { parent = "footer", size = { 140, 30 }, position = { LIST_WIDTH - 290, -4, 2 } },
    footer_disable = { parent = "footer", size = { 140, 30 }, position = { LIST_WIDTH - 145, -4, 2 } },
    },
    widget_definitions = {
        title_bg = UIWidget.create_definition({
            { pass_type = "rect", style_id = "bg", style = { color = { 100, 0, 0, 0 } } },
        }, "panel_title"),
        title = UIWidget.create_definition({
            { pass_type = "text", value = mod:localize("clb_manager_title"), value_id = "text", style_id = "text",
              style = { font_size = 55, font_type = "machine_medium", material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                        text_horizontal_alignment = "center", text_vertical_alignment = "center", text_color = {255,255,255,255} } },
        }, "panel_title_text"),
        footer = UIWidget.create_definition({
            { pass_type = "text", value = "", value_id = "counts", style_id = "counts", style = { font_size = 20, font_type = "machine_medium", text_color = {200,200,200,255}, text_horizontal_alignment = "left", text_vertical_alignment = "center" } },
        }, "footer"),
        enable_all_button = UIWidget.create_definition({
            { pass_type = "hotspot", content_id = "hotspot" },
            { pass_type = "rect", style_id = "bg", style = { size = { 140, 30 }, color = {255, 60, 200, 60}, offset = { 0, 0, 0 } },
              change_function = function(content, style)
                  local hs = content.hotspot
                  local base = content.base_color or {255,60,200,60}
                  local r,g,b = base[2], base[3], base[4]
                  if hs.is_pressed then
                      r,g,b = math.max(0,r-10), math.max(0,g-20), math.max(0,b-10)
                  elseif hs.is_hover then
                      r,g,b = math.min(255,r+20), math.min(255,g+20), math.min(255,b+20)
                  end
                  style.color = {255, r, g, b}
              end },
            { pass_type = "text", value = mod:localize("clb_action_enable_all"), value_id = "text", style_id = "text",
              style = { font_size = 18, font_type = "machine_medium", text_color = {245,245,245,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = {140,30}, offset = {0,0,1} } },
        }, "footer_enable", { base_color = {255, 60, 200, 60} }),
        disable_all_button = UIWidget.create_definition({
            { pass_type = "hotspot", content_id = "hotspot" },
            { pass_type = "rect", style_id = "bg", style = { size = { 140, 30 }, color = {255, 200, 60, 60}, offset = { 0, 0, 0 } },
              change_function = function(content, style)
                  local hs = content.hotspot
                  local base = content.base_color or {255,200,60,60}
                  local r,g,b = base[2], base[3], base[4]
                  if hs.is_pressed then
                      r,g,b = math.max(0,r-20), math.max(0,g-10), math.max(0,b-10)
                  elseif hs.is_hover then
                      r,g,b = math.min(255,r+20), math.min(255,g+20), math.min(255,b+20)
                  end
                  style.color = {255, r, g, b}
              end },
            { pass_type = "text", value = mod:localize("clb_action_disable_all"), value_id = "text", style_id = "text",
              style = { font_size = 18, font_type = "machine_medium", text_color = {245,245,245,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = {140,30}, offset = {0,0,1} } },
        }, "footer_disable", { base_color = {255, 200, 60, 60} }),
        center_url = UIWidget.create_definition({
            { pass_type = "hotspot", content_id = "hotspot", style_id = "hotspot", style = { size = { CENTER_W, LABEL_H }, offset = { 0, 0, 25 } } },
            { pass_type = "text", value = "", value_id = "label", style_id = "label", style = { font_size = 18, font_type = "machine_medium", text_color = {230,230,230,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = { CENTER_W, LABEL_H }, offset = { 0, 0, 26 } },
              change_function = function(content, style)
                  local hs = content.hotspot
                  if hs and hs.is_hover then
                      style.text_color = {255,255,255,255}
                  else
                      style.text_color = {230,230,230,255}
                  end
              end },
        }, "center_label"),
        center_toggle_button = UIWidget.create_definition({
            { pass_type = "hotspot", content_id = "hotspot", style_id = "hotspot", style = { size = { BUTTON_W, BUTTON_H }, offset = { (CENTER_W - BUTTON_W) / 2, 0, 2 } } },
            { pass_type = "rect", style_id = "bg", style = { size = { BUTTON_W, BUTTON_H }, offset = { (CENTER_W - BUTTON_W) / 2, 0, 1 }, color = { 90, 30, 60, 30 } } },
            { pass_type = "text", value = "", value_id = "label", style_id = "label", style = { font_size = 18, font_type = "machine_medium", text_color = { 240, 240, 240, 255 }, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = { BUTTON_W, BUTTON_H }, offset = { (CENTER_W - BUTTON_W) / 2, 0, 3 } } },
        }, "center_button"),
        loading_progress = UIWidget.create_definition({
            { pass_type = "rect", style_id = "bg", style = { size = { math.max(260, math.floor(400 * ui_scale)), 60 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2, panelTitleSize + margin + 4, 20 }, color = { 170, 8, 8, 8 }, visible = true } },
            { pass_type = "rect", style_id = "frame", style = { size = { math.max(260, math.floor(400 * ui_scale)), 60 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2, panelTitleSize + margin + 4, 21 }, color = { 50, 255, 255, 255 }, visible = true } },
            { pass_type = "rect", style_id = "inner", style = { size = { math.max(260, math.floor(400 * ui_scale)) - 6, 60 - 6 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2 + 3, panelTitleSize + margin + 7, 22 }, color = { 140, 15, 15, 15 }, visible = true } },
            { pass_type = "rect", style_id = "bar_bg", style = { size = { math.max(260, math.floor(400 * ui_scale)) - 20, 14 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2 + 10, panelTitleSize + margin + 42, 23 }, color = { 120, 35, 35, 35 }, visible = true } },
            { pass_type = "rect", style_id = "bar_fill", style = { size = { 0, 14 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2 + 10, panelTitleSize + margin + 42, 24 }, color = { 220, 60, 160, 60 }, visible = true } },
            { pass_type = "text", value = "", value_id = "label", style_id = "label", style = { font_size = 22, font_type = "machine_medium", text_color = {230,230,230,255}, text_horizontal_alignment = "center", text_vertical_alignment = "top", size = { math.max(260, math.floor(400 * ui_scale)) - 20, 34 }, offset = { (width - math.max(260, math.floor(400 * ui_scale))) / 2 + 10, panelTitleSize + margin + 8, 24 } } },
        }, "canvas"),
    },
    legend_inputs = legend_inputs_list,
}

local function predefine_rows()
    for i = 1, MAX_ROWS do
        local y = (i - 1) * ROW_HEIGHT
        local thumb_h = math.floor(THUMB_SIZE * THUMB_ASPECT)
        local passes = {
            { pass_type = "hotspot", content_id = "toggle_hotspot", style_id = "toggle_hotspot", style = { size = { LIST_WIDTH, ROW_HEIGHT }, offset = { 0, y, 5 } } },
            { pass_type = "rect", style_id = "row_bg", style = { color = { 60, 15, 15, 15 }, size = { LIST_WIDTH, ROW_HEIGHT }, offset = { 0, y, 0 } } },
        }
        if ENABLE_THUMBS then
            passes[#passes+1] = { pass_type = "texture", style_id = "thumb", style = { size = { THUMB_SIZE, thumb_h }, offset = { 4, y + (ROW_HEIGHT - thumb_h)/2, 1 }, color = {255,255,255,255}, visible = false } }
        end
        passes[#passes+1] = { pass_type = "text", value_id = "label", style_id = "label", value = "", style = { font_size = 18, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "left", text_vertical_alignment = "center", size = { LIST_WIDTH - 96 - (ENABLE_THUMBS and (THUMB_SIZE + 8) or 0), ROW_HEIGHT }, offset = { (ENABLE_THUMBS and (THUMB_SIZE + 12) or 8), y, 1 } } }
        passes[#passes+1] = { pass_type = "rect", style_id = "toggle_rect", style = { size = { 88, ROW_HEIGHT - 12 }, offset = { LIST_WIDTH - 96, y + 6, 1 }, color = {200,160,40,40} } }
        passes[#passes+1] = { pass_type = "text", value_id = "toggle_label", style_id = "toggle_label", value = "", style = { font_size = 14, font_type = "machine_medium", text_color = {255,255,255,255}, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = { 88, ROW_HEIGHT - 12 }, offset = { LIST_WIDTH - 96, y + 6, 2 } } }
        local content = {
            toggle_hotspot = {},
            label = "",
            toggle_label = "",
            enabled = false,
            image_key = nil,
            row_index = i,
            active = false,
            thumb = nil,
        }
        definitions.widget_definitions["row_" .. i] = UIWidget.create_definition(passes, "list_area", content)
    end
end

if not USE_GRID_VIEW and not USE_CAROUSEL_VIEW then
    predefine_rows()
end

local function predefine_cards()
    for i = 1, (MAX_CARDS) do
        local row = math.floor((i - 1) / GRID_COLS)
        local col = (i - 1) % GRID_COLS
        local x = col * (CARD_W + GRID_H_GAP)
        local y = row * (CARD_H + GRID_V_GAP)
        local passes = {
            { pass_type = "hotspot", content_id = "card_hotspot", style_id = "card_hotspot", style = { size = { CARD_W, CARD_H }, offset = { x, y, 5 } } },
            { pass_type = "rect", style_id = "card_bg", style = { color = { 60, 10, 10, 10 }, size = { CARD_W, CARD_H }, offset = { x, y, 0 } } },
        }
        if ENABLE_THUMBS then
            passes[#passes+1] = { pass_type = "texture", style_id = "thumb", style = { size = { CARD_W, CARD_H }, offset = { x, y, 1 }, color = {255,255,255,255}, visible = false } }
        end
        passes[#passes+1] = { pass_type = "rect", style_id = "label_bg", style = { color = { 140, 0, 0, 0 }, size = { CARD_W, 26 }, offset = { x, y + CARD_H - 26, 2 } } }
        passes[#passes+1] = { pass_type = "text", value_id = "label", style_id = "label", value = "", style = { font_size = 16, font_type = "machine_medium", text_color = {230,230,230,255}, text_horizontal_alignment = "left", text_vertical_alignment = "center", size = { CARD_W - 10, 26 }, offset = { x + 6, y + CARD_H - 26, 3 } } }
        passes[#passes+1] = { pass_type = "rect", style_id = "pill_bg", style = { size = { 90, 24 }, offset = { x + CARD_W - 94, y + 4, 2 }, color = { 200, 30, 120, 30 } } }
        passes[#passes+1] = { pass_type = "text", value_id = "pill_label", style_id = "pill_label", value = "", style = { font_size = 14, font_type = "machine_medium", text_color = { 255, 255, 255, 255 }, text_horizontal_alignment = "center", text_vertical_alignment = "center", size = { 90, 24 }, offset = { x + CARD_W - 94, y + 4, 3 } } }
        local content = { card_hotspot = {}, label = "", pill_label = "", image_key = nil, enabled = false, active = false, thumb = nil }
        definitions.widget_definitions["card_" .. i] = UIWidget.create_definition(passes, "grid_area", content)
    end
end

if USE_GRID_VIEW then
    predefine_cards()
end

local STACK_COUNT = 1
local STACK_SCALES = { 0.9, 0.88, 0.86 }
local STACK_ANGLES_L = { -6, -10, -14 }
local STACK_ANGLES_R = { 6, 10, 14 }
local STACK_X_OFF_L = { math.floor(-220 * ui_scale), math.floor(-180 * ui_scale), math.floor(-130 * ui_scale) }
local STACK_X_OFF_R = { math.floor(220 * ui_scale), math.floor(180 * ui_scale), math.floor(130 * ui_scale) }
local STACK_Y_OFF = { math.floor(0 * ui_scale), math.floor(18 * ui_scale), math.floor(28 * ui_scale) }
local STRIP_WIDTH = math.floor(140 * ui_scale)
local STRIP_HEIGHT_SCALE = 0.92
local UV_LEFT_STRIP = { {0, 0}, {0.18, 1} }
local UV_RIGHT_STRIP = { {0.82, 0}, {1, 1} }

local function predefine_carousel()
    definitions.widget_definitions["carousel_center"] = UIWidget.create_definition({
        { pass_type = "rect", style_id = "shadow", style = { size = { CENTER_W+14, CENTER_H+10 }, offset = { -7, 4, 8 }, color = { 80, 0, 0, 0 }, visible = false } },
        { pass_type = "rect", style_id = "frame_outer", style = { size = { CENTER_W+14, CENTER_H+14 }, offset = { -7, -7, 9 }, color = { 170, 16, 24, 16 }, visible = false } },
        { pass_type = "rect", style_id = "frame_inner", style = { size = { CENTER_W+8, CENTER_H+8 }, offset = { -4, -4, 10 }, color = { 200, 46, 66, 46 }, visible = false } },
        { pass_type = "rect", style_id = "bevel_top", style = { size = { CENTER_W+4, 8 }, offset = { -2, -4, 11 }, color = { 130, 160, 200, 160 }, visible = false } },
        { pass_type = "rect", style_id = "bevel_bottom", style = { size = { CENTER_W+4, 8 }, offset = { -2, CENTER_H - 4, 11 }, color = { 130, 10, 15, 10 }, visible = false } },
        { pass_type = "texture", style_id = "img", style = { size = { CENTER_W, CENTER_H }, offset = { 0, 0, 12 }, visible = false, pivot = { CENTER_W/2, CENTER_H/2 } } },
        { pass_type = "hotspot", content_id = "hotspot", style_id = "hs", style = { size = { CENTER_W, CENTER_H }, offset = { 0, 0, 13 } } },
    }, "center_area", { hotspot = {} })

    for i = STACK_COUNT, 1, -1 do
        local scale = STACK_SCALES[i]
        local full_w, full_h = math.floor(CENTER_W * scale), math.floor(CENTER_H * scale)
        local l_off_x = (CENTER_W/2) - full_w - (CENTER_W/2) + STACK_X_OFF_L[i]
        local r_off_x = (CENTER_W/2) + (CENTER_W/2) - 0 + STACK_X_OFF_R[i]
        local y_off = math.floor((CENTER_H - full_h) / 2)

        local function metallic_frame_passes(x, y, w, h, angle, z)
            return {
                { pass_type = "rect", style_id = "frame_outer", style = { size = { w+14, h+14 }, offset = { x-7, y-7, z }, color = { 170, 16, 24, 16 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "frame_inner", style = { size = { w+8, h+8 }, offset = { x-4, y-4, z+1 }, color = { 200, 46, 66, 46 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "bevel_top", style = { size = { w+4, 8 }, offset = { x-2, y-4, z+2 }, color = { 130, 160, 200, 160 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "bevel_bottom", style = { size = { w+4, 8 }, offset = { x-2, y+h-4, z+2 }, color = { 130, 10, 15, 10 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "texture", style_id = "img", style = { size = { w, h }, offset = { x, y, z+3 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "pulse", style = { size = { w, h }, offset = { x, y, z+4 }, angle = angle, pivot = { w/2, h/2 }, color = { 0, 220, 220, 220 }, visible = false } },
            }
        end

        local function strip_passes_left(x, y, w, h, angle, z)
            return {
                { pass_type = "rect", style_id = "frame_outer", style = { size = { w+8, h+8 }, offset = { x-4, y-4, z }, color = { 170, 16, 24, 16 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "frame_inner", style = { size = { w+4, h+4 }, offset = { x-2, y-2, z+1 }, color = { 200, 46, 66, 46 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "texture", style_id = "img", style = { size = { w, h }, offset = { x, y, z+2 }, angle = angle, pivot = { w/2, h/2 }, visible = false, uvs = UV_LEFT_STRIP } },
            }
        end

        local function strip_passes_right(x, y, w, h, angle, z)
            return {
                { pass_type = "rect", style_id = "frame_outer", style = { size = { w+8, h+8 }, offset = { x-4, y-4, z }, color = { 170, 16, 24, 16 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "rect", style_id = "frame_inner", style = { size = { w+4, h+4 }, offset = { x-2, y-2, z+1 }, color = { 200, 46, 66, 46 }, angle = angle, pivot = { w/2, h/2 }, visible = false } },
                { pass_type = "texture", style_id = "img", style = { size = { w, h }, offset = { x, y, z+2 }, angle = angle, pivot = { w/2, h/2 }, visible = false, uvs = UV_RIGHT_STRIP } },
            }
        end

        if i == 1 then
            local z = 5 + (STACK_COUNT - i)
            local passes_left = metallic_frame_passes(l_off_x, y_off, full_w, full_h, STACK_ANGLES_L[i] * math.pi/180, z)
            local passes_right = metallic_frame_passes(r_off_x, y_off, full_w, full_h, STACK_ANGLES_R[i] * math.pi/180, z)
            passes_left[#passes_left+1] = { pass_type = "hotspot", content_id = "hotspot", style_id = "hs", style = { size = { full_w, full_h }, offset = { l_off_x, y_off, z+5 } } }
            passes_right[#passes_right+1] = { pass_type = "hotspot", content_id = "hotspot", style_id = "hs", style = { size = { full_w, full_h }, offset = { r_off_x, y_off, z+5 } } }
            definitions.widget_definitions["carousel_left_" .. i] = UIWidget.create_definition(passes_left, "center_area", { hotspot = {} })
            definitions.widget_definitions["carousel_right_" .. i] = UIWidget.create_definition(passes_right, "center_area", { hotspot = {} })
        else
            local strip_h = math.floor(CENTER_H * STRIP_HEIGHT_SCALE)
            local y_strip = y_off + math.floor((full_h - strip_h) / 2)
            local z = 5 + (STACK_COUNT - i)
            definitions.widget_definitions["carousel_left_" .. i] = UIWidget.create_definition(strip_passes_left(l_off_x, y_strip, STRIP_WIDTH, strip_h, STACK_ANGLES_L[i] * math.pi/180, z), "center_area")
            definitions.widget_definitions["carousel_right_" .. i] = UIWidget.create_definition(strip_passes_right(r_off_x, y_strip, STRIP_WIDTH, strip_h, STACK_ANGLES_R[i] * math.pi/180, z), "center_area")
        end
    end
    do
        definitions.widget_definitions["carousel_center_ghost"] = UIWidget.create_definition({
            { pass_type = "rect", style_id = "frame_outer", style = { size = { CENTER_W+14, CENTER_H+14 }, offset = { -7, -7, 15 }, color = { 170, 16, 24, 16 }, visible = false } },
            { pass_type = "rect", style_id = "frame_inner", style = { size = { CENTER_W+8, CENTER_H+8 }, offset = { -4, -4, 16 }, color = { 200, 46, 66, 46 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_top", style = { size = { CENTER_W+4, 8 }, offset = { -2, -4, 17 }, color = { 130, 160, 200, 160 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_bottom", style = { size = { CENTER_W+4, 8 }, offset = { -2, CENTER_H - 4, 17 }, color = { 130, 10, 15, 10 }, visible = false } },
            { pass_type = "texture", style_id = "img", style = { size = { CENTER_W, CENTER_H }, offset = { 0, 0, 18 }, visible = false, pivot = { CENTER_W/2, CENTER_H/2 } } },
        }, "center_area")
        local i = 1
        local scale = STACK_SCALES[i]
        local w, h = math.floor(CENTER_W * scale), math.floor(CENTER_H * scale)
        local l_off_x = (CENTER_W/2) - w - (CENTER_W/2) + STACK_X_OFF_L[i]
        local r_off_x = (CENTER_W/2) + (CENTER_W/2) + STACK_X_OFF_R[i]
        local y_off = math.floor((CENTER_H - h) / 2)
        local z = 15
        local function side_passes(x, y)
            return {
                { pass_type = "rect", style_id = "frame_outer", style = { size = { w+14, h+14 }, offset = { x-7, y-7, z }, color = { 170, 16, 24, 16 }, visible = false, pivot = { w/2, h/2 } } },
                { pass_type = "rect", style_id = "frame_inner", style = { size = { w+8, h+8 }, offset = { x-4, y-4, z+1 }, color = { 200, 46, 66, 46 }, visible = false, pivot = { w/2, h/2 } } },
                { pass_type = "rect", style_id = "bevel_top", style = { size = { w+4, 8 }, offset = { x-2, y-4, z+2 }, color = { 130, 160, 200, 160 }, visible = false, pivot = { w/2, h/2 } } },
                { pass_type = "rect", style_id = "bevel_bottom", style = { size = { w+4, 8 }, offset = { x-2, y+h-4, z+2 }, color = { 130, 10, 15, 10 }, visible = false, pivot = { w/2, h/2 } } },
                { pass_type = "texture", style_id = "img", style = { size = { w, h }, offset = { x, y, z+3 }, visible = false, pivot = { w/2, h/2 } } },
            }
        end
        definitions.widget_definitions["carousel_side_ghost_l"] = UIWidget.create_definition(side_passes(l_off_x, y_off), "center_area")
        definitions.widget_definitions["carousel_side_ghost_r"] = UIWidget.create_definition(side_passes(r_off_x, y_off), "center_area")
    end
    do
        local i = 1
        local scale = STACK_SCALES[i]
        local full_w, full_h = math.floor(CENTER_W * scale), math.floor(CENTER_H * scale)
        local l_off_x = (CENTER_W/2) - full_w - (CENTER_W/2) + STACK_X_OFF_L[i]
        local r_off_x = (CENTER_W/2) + (CENTER_W/2) + STACK_X_OFF_R[i]
        local y_off = math.floor((CENTER_H - full_h) / 2)
        local z = 14
        local passes_left = {
            { pass_type = "rect", style_id = "frame_outer", style = { size = { full_w+14, full_h+14 }, offset = { l_off_x-7, y_off-7, z }, color = { 170, 16, 24, 16 }, angle = STACK_ANGLES_L[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "frame_inner", style = { size = { full_w+8, full_h+8 }, offset = { l_off_x-4, y_off-4, z+1 }, color = { 200, 46, 66, 46 }, angle = STACK_ANGLES_L[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_top", style = { size = { full_w+4, 8 }, offset = { l_off_x-2, y_off-4, z+2 }, color = { 130, 160, 200, 160 }, angle = STACK_ANGLES_L[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_bottom", style = { size = { full_w+4, 8 }, offset = { l_off_x-2, y_off+full_h-4, z+2 }, color = { 130, 10, 15, 10 }, angle = STACK_ANGLES_L[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "texture", style_id = "img", style = { size = { full_w, full_h }, offset = { l_off_x, y_off, z+3 }, angle = STACK_ANGLES_L[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
        }
        local passes_right = {
            { pass_type = "rect", style_id = "frame_outer", style = { size = { full_w+14, full_h+14 }, offset = { r_off_x-7, y_off-7, z }, color = { 170, 16, 24, 16 }, angle = STACK_ANGLES_R[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "frame_inner", style = { size = { full_w+8, full_h+8 }, offset = { r_off_x-4, y_off-4, z+1 }, color = { 200, 46, 66, 46 }, angle = STACK_ANGLES_R[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_top", style = { size = { full_w+4, 8 }, offset = { r_off_x-2, y_off-4, z+2 }, color = { 130, 160, 200, 160 }, angle = STACK_ANGLES_R[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "rect", style_id = "bevel_bottom", style = { size = { full_w+4, 8 }, offset = { r_off_x-2, y_off+full_h-4, z+2 }, color = { 130, 10, 15, 10 }, angle = STACK_ANGLES_R[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
            { pass_type = "texture", style_id = "img", style = { size = { full_w, full_h }, offset = { r_off_x, y_off, z+3 }, angle = STACK_ANGLES_R[i] * math.pi/180, pivot = { full_w/2, full_h/2 }, visible = false } },
        }
        definitions.widget_definitions["carousel_left_incoming"] = UIWidget.create_definition(passes_left, "center_area")
        definitions.widget_definitions["carousel_right_incoming"] = UIWidget.create_definition(passes_right, "center_area")
    end
end

if USE_CAROUSEL_VIEW then
    predefine_carousel()
end

ImageManagerView = class("ImageManagerView", "BaseView") 

ImageManagerView.init = function(self, settings)
    ImageManagerView.super.init(self, definitions, settings)

    self._rows = {}
    self._image_all = mod:persistent_table("backgroundImageTableAll", {})
    self._image_enabled = mod:persistent_table("imageEnabled", {})
    self._retry_timer = 0
    self._page = 1
    self._carousel_idx = 1
    self._pulse_t = 0
    self._anim = { active = false }
end

ImageManagerView.on_enter = function(self)
    ImageManagerView.super.on_enter(self)
    self._page = 1
    pcall(function()
        local strings = {
            loc_clb_action_page_next = mod:localize("clb_action_page_next"),
            loc_clb_action_page_prev = mod:localize("clb_action_page_prev"),
        }
        Managers.localization:add_localized_strings(strings)
    end)
    self:_setup_input_legend()
    local ok, err = pcall(function()
        if USE_CAROUSEL_VIEW then self:_rebuild_carousel() elseif USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
    end)
    if not ok then mod:echo("[CLB] ImageManagerView row build error: " .. tostring(err)) end
end

function ImageManagerView:_setup_input_legend()
    self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
    local legend_inputs = self._definitions.legend_inputs or {}
    for i = 1, #legend_inputs do
        local li = legend_inputs[i]
        local cb = li.on_pressed_callback and callback(self, li.on_pressed_callback)
        local vis = li.visibility_function or function() return true end
        local ok, err = pcall(function()
            self._input_legend_element:add_entry(li.display_name, li.input_action, vis, cb, li.alignment)
        end)
        if not ok then
            mod:echo("[CLB] Legend add_entry failed for action " .. tostring(li.input_action) .. ": " .. tostring(err))
        end
    end
end

function ImageManagerView:_on_back_pressed()
    Managers.ui:close_view(self.view_name)
end

function ImageManagerView:_enable_all()
    for k,_ in pairs(self._image_all) do self._image_enabled[k] = true end
    if USE_CAROUSEL_VIEW then self:_rebuild_carousel() elseif USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
    if mod.persist_enabled_state then pcall(mod.persist_enabled_state) end
end

function ImageManagerView:_disable_all()
    for k,_ in pairs(self._image_all) do self._image_enabled[k] = false end
    if USE_CAROUSEL_VIEW then self:_rebuild_carousel() elseif USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
    if mod.persist_enabled_state then pcall(mod.persist_enabled_state) end
end

function ImageManagerView:_invert_selection()
    for k,_ in pairs(self._image_all) do self._image_enabled[k] = not self._image_enabled[k] end
    self:_rebuild_rows()
end

function ImageManagerView:_on_enable_all() self:_enable_all() end
function ImageManagerView:_on_disable_all() self:_disable_all() end
function ImageManagerView:_on_invert() self:_invert_selection() end

function ImageManagerView:_on_next_page()
    local total = table.size(self._image_all or {})
    local page_size = USE_GRID_VIEW and MAX_CARDS or MAX_ROWS
    local total_pages = math.max(1, math.ceil(total / page_size))
    if self._page < total_pages then
        self._page = self._page + 1
        if USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
    end
end

function ImageManagerView:_on_prev_page()
    if self._page > 1 then
        self._page = self._page - 1
        if USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
    end
end

function ImageManagerView:_on_next_image()
    local keys = table.keys(self._image_all or {}) or {}
    table.sort(keys)
    if #keys == 0 then return end
    if self:_start_carousel_anim(1) then return end
    self._carousel_idx = (self._carousel_idx or 1) + 1
    if self._carousel_idx > #keys then self._carousel_idx = 1 end
    self:_rebuild_carousel()
end

function ImageManagerView:_on_prev_image()
    local keys = table.keys(self._image_all or {}) or {}
    table.sort(keys)
    if #keys == 0 then return end
    if self:_start_carousel_anim(-1) then return end
    self._carousel_idx = (self._carousel_idx or 1) - 1
    if self._carousel_idx < 1 then self._carousel_idx = #keys end
    self:_rebuild_carousel()
end

function ImageManagerView:_refresh_row_states()
    local localized_enabled = mod:localize("clb_row_enabled")
    local localized_disabled = mod:localize("clb_row_disabled")
    for _, row in ipairs(self._rows) do
        if row.content.active then
            local key = row.content.image_key
            local enabled = key and (self._image_enabled[key] ~= false)
            row.content.enabled = enabled
            row.content.toggle_label = enabled and localized_enabled or localized_disabled
        end
    end
end

function ImageManagerView:_rebuild_rows()
    self._rows = {}
    if not self._image_all or type(self._image_all) ~= "table" then
        return
    end
    local keys = table.keys(self._image_all) or {}
    table.sort(keys)

    local total = #keys
    local total_pages = math.max(1, math.ceil(total / MAX_ROWS))
    if self._page < 1 then self._page = 1 end
    if self._page > total_pages then self._page = total_pages end

    local start_index = (self._page - 1) * MAX_ROWS + 1
    local end_index = start_index + MAX_ROWS - 1

    local localized_enabled = mod:localize("clb_row_enabled")
    local localized_disabled = mod:localize("clb_row_disabled")
    local enabled_count = 0

    local slice_count = 0
    for row_i = 1, MAX_ROWS do
        local widget = self._widgets_by_name["row_" .. row_i]
        if widget then
            local key_index = start_index + row_i - 1
            local key = keys[key_index]
            if key then
                slice_count = slice_count + 1
                widget.content.active = true
                widget.content.label = key
                widget.content.image_key = key
                widget.content.enabled = self._image_enabled[key] ~= false
                if widget.content.enabled then enabled_count = enabled_count + 1 end
                widget.content.toggle_label = widget.content.enabled and localized_enabled or localized_disabled
                local entry = self._image_all[key]
                if ENABLE_THUMBS and widget.style and widget.style.thumb then
                    local entry = self._image_all[key]
                    local tex = entry and entry.texture
                    if tex then
                        widget.content.thumb = tex
                        widget.style.thumb.visible = true
                        widget.style.thumb.material_values = widget.style.thumb.material_values or {}
                        widget.style.thumb.material_values.texture_map = tex
                    else
                        widget.content.thumb = nil
                        widget.style.thumb.visible = false
                    end
                end
            else
                widget.content.active = false
                widget.content.label = ""
                widget.content.image_key = nil
                widget.content.toggle_label = ""
                widget.content.enabled = false
                if ENABLE_THUMBS and widget.style and widget.style.thumb then
                    widget.content.thumb = nil
                    widget.style.thumb.visible = false
                end
            end
            self._rows[#self._rows+1] = widget

            if widget.style and widget.style.row_bg then
                if (row_i % 2) == 0 then
                    widget.style.row_bg.color = { 70, 25, 25, 25 }
                else
                    widget.style.row_bg.color = { 50, 15, 15, 15 }
                end
            end
        end
    end

    if #keys == 0 then
        local placeholder = self._widgets_by_name.row_1
        if placeholder then
            placeholder.content.active = true
            placeholder.content.label = mod:localize("clb_manager_placeholder")
            placeholder.content.toggle_label = "--"
            if ENABLE_THUMBS and placeholder.style and placeholder.style.thumb then
                placeholder.style.thumb.visible = false
            end
        end
    end

    self._last_image_count = #keys
    self._last_enabled_count = enabled_count
    self:_update_counts_text()
end

function ImageManagerView:_rebuild_cards()
    self._rows = {}
    if not self._image_all or type(self._image_all) ~= "table" then
        self._last_image_count = 0
        self._last_enabled_count = 0
        self:_update_counts_text()
        return
    end

    local keys = table.keys(self._image_all) or {}
    table.sort(keys)

    local total = #keys
    local total_pages = math.max(1, math.ceil(total / MAX_CARDS))
    if self._page < 1 then self._page = 1 end
    if self._page > total_pages then self._page = total_pages end

    local start_index = (self._page - 1) * MAX_CARDS + 1

    local localized_enabled = mod:localize("clb_row_enabled")
    local localized_disabled = mod:localize("clb_row_disabled")
    local enabled_count = 0

    for i = 1, MAX_CARDS do
        local widget = self._widgets_by_name["card_" .. i]
        if widget then
            local key = keys[start_index + i - 1]
            if key then
                widget.content.active = true
                widget.content.image_key = key
                local enabled = (self._image_enabled[key] ~= false)
                widget.content.enabled = enabled
                widget.content.pill_label = enabled and localized_enabled or localized_disabled
                if widget.style and widget.style.pill_bg then
                    widget.style.pill_bg.color = enabled and {200,40,160,40} or {200,160,40,40}
                end
                widget.content.label = key
                if ENABLE_THUMBS and widget.style and widget.style.thumb then
                    local entry = self._image_all[key]
                    local tex = entry and entry.texture
                    if tex then
                        widget.content.thumb = tex
                        widget.style.thumb.visible = true
                        widget.style.thumb.material_values = widget.style.thumb.material_values or {}
                        widget.style.thumb.material_values.texture_map = tex
                    else
                        widget.content.thumb = nil
                        widget.style.thumb.visible = false
                    end
                end
                if enabled then enabled_count = enabled_count + 1 end
            else
                widget.content.active = false
                widget.content.image_key = nil
                widget.content.label = ""
                widget.content.pill_label = ""
                if ENABLE_THUMBS and widget.style and widget.style.thumb then
                    widget.style.thumb.visible = false
                    widget.content.thumb = nil
                end
            end
            self._rows[#self._rows+1] = widget
        end
    end

    self._last_image_count = total
    self._last_enabled_count = enabled_count
    self:_update_counts_text()
end

function ImageManagerView:_rebuild_carousel()
    if not USE_CAROUSEL_VIEW then return end
    local keys = table.keys(self._image_all or {}) or {}
    table.sort(keys)
    local total = #keys
    if total == 0 then
        self._last_image_count = 0
        self._last_enabled_count = 0
        self:_update_counts_text()
        return
    end
    if not self._carousel_idx or self._carousel_idx < 1 or self._carousel_idx > total then
        self._carousel_idx = 1
    end

    local function set_tex(widget, tex)
        if not widget or not widget.style then return end
        if widget.style.img then
            if tex then
                widget.style.img.visible = true
                widget.style.img.material_values = widget.style.img.material_values or {}
                widget.style.img.material_values.texture_map = tex
            else
                widget.style.img.visible = false
            end
        end
        local show = tex ~= nil
        if widget.style.border then widget.style.border.visible = show end
        if widget.style.border2 then widget.style.border2.visible = show end
        if widget.style.frame_outer then widget.style.frame_outer.visible = show end
        if widget.style.frame_inner then widget.style.frame_inner.visible = show end
        if widget.style.bevel_top then widget.style.bevel_top.visible = show end
        if widget.style.bevel_bottom then widget.style.bevel_bottom.visible = show end
        if widget.style.shadow then widget.style.shadow.visible = show end
        if widget.style.orn_tl then widget.style.orn_tl.visible = show end
        if widget.style.orn_tr then widget.style.orn_tr.visible = show end
        if widget.style.orn_bl then widget.style.orn_bl.visible = show end
        if widget.style.orn_br then widget.style.orn_br.visible = show end
    end

    local center_w = self._widgets_by_name.carousel_center
    local center_key = keys[self._carousel_idx]
    local center_entry = self._image_all[center_key]
    set_tex(center_w, center_entry and center_entry.texture)
    local url_widget = self._widgets_by_name.center_url
    if url_widget then
        url_widget.content.label = tostring(center_key or "")
    end
    local btn = self._widgets_by_name.center_toggle_button
    if btn then
        local is_enabled = (self._image_enabled[center_key] ~= false)
        btn.content.label = is_enabled and mod:localize("clb_row_enabled") or mod:localize("clb_row_disabled")
        if btn.style and btn.style.bg then
            btn.style.bg.color = is_enabled and { 120, 40, 160, 40 } or { 120, 160, 40, 40 } -- green vs red
        end
    end

    for i = 1, STACK_COUNT do
        local idx = ((self._carousel_idx - i - 1) % total) + 1
        local w = self._widgets_by_name["carousel_left_" .. i]
        local key = keys[idx]
        local entry = key and self._image_all[key]
        set_tex(w, entry and entry.texture)
        if w and w.style and w.style.pulse then w.style.pulse.visible = false end
    end
    for i = 1, STACK_COUNT do
        local idx = ((self._carousel_idx + i - 1) % total) + 1
        local w = self._widgets_by_name["carousel_right_" .. i]
        local key = keys[idx]
        local entry = key and self._image_all[key]
        set_tex(w, entry and entry.texture)
        if w and w.style and w.style.pulse then w.style.pulse.visible = false end
    end
    local l_in = self._widgets_by_name.carousel_left_incoming
    local r_in = self._widgets_by_name.carousel_right_incoming
    local c_ghost = self._widgets_by_name.carousel_center_ghost
    local l_ghost = self._widgets_by_name.carousel_side_ghost_l
    local r_ghost = self._widgets_by_name.carousel_side_ghost_r
    local function _hide_incoming(w)
        if not w or not w.style then return end
        if w.style.img then w.style.img.visible = false end
        if w.style.frame_outer then w.style.frame_outer.visible = false end
        if w.style.frame_inner then w.style.frame_inner.visible = false end
        if w.style.bevel_top then w.style.bevel_top.visible = false end
        if w.style.bevel_bottom then w.style.bevel_bottom.visible = false end
    end
    _hide_incoming(l_in)
    _hide_incoming(r_in)
    _hide_incoming(c_ghost)
    _hide_incoming(l_ghost)
    _hide_incoming(r_ghost)

    self._last_image_count = total
    local enabled = 0
    for k,_ in pairs(self._image_all) do if self._image_enabled[k] ~= false then enabled = enabled + 1 end end
    self._last_enabled_count = enabled
    self:_update_counts_text()
end

ImageManagerView.update = function(self, dt, t, input_service)
    self._pulse_t = (self._pulse_t or 0) + dt
    do
        local w = self._widgets_by_name.loading_progress
        if w then
            local status = mod.get_manager_loading_status and mod.get_manager_loading_status() or { active=false }
            local inflight = status.inflight or 0
            if status.active and (inflight > 0 or not status.done) then
                local loaded, total = status.loaded or 0, status.total or 0
                local pct = 0
                if total == 0 then
                    w.content.label = mod:localize("clb_loading_progress_wait") or "Loading image lists..."
                else
                    pct = math.min(1, loaded / math.max(1,total))
                    local pct_int = math.floor(pct * 100)
                    w.content.label = string.format("Loading Images: %d / %d (%d%%)", loaded, total, pct_int)
                end
                local pulse = 0.5 + 0.5 * math.sin((self._pulse_t or 0) * 2.5)
                local base_alpha = 150 + math.floor(60 * pulse)
                if w.style then
                    if w.style.bg and w.style.bg.color then w.style.bg.color[1] = base_alpha end
                    if w.style.label and w.style.label.text_color then w.style.label.text_color[1] = 255 end
                    local bar_bg = w.style.bar_bg
                    local bar_fill = w.style.bar_fill
                    if bar_bg and bar_fill then
                        local full_w = bar_bg.size and bar_bg.size[1] or 300
                        local current = bar_fill.size and bar_fill.size[1] or 0
                        local target = math.floor(full_w * pct)
                        local lerp_speed = 12
                        local new_w = math.floor(current + (target - current) * math.min(1, lerp_speed * dt))
                        bar_fill.size[1] = new_w
                        local g = 60 + math.floor(140 * pct)
                        local r = 200 - math.floor(120 * pct)
                        local b = 60
                        bar_fill.color[2], bar_fill.color[3], bar_fill.color[4] = r, g, b
                    end
                    if w.style.frame then w.style.frame.visible = true end
                    if w.style.inner then w.style.inner.visible = true end
                    if w.style.bar_bg then w.style.bar_bg.visible = true end
                    if w.style.bar_fill then w.style.bar_fill.visible = true end
                end
                if w.style and w.style.label then w.style.label.visible = true end
                local footer = self._widgets_by_name.footer
                if footer and footer.style and footer.style.counts then
                    footer.style.counts.visible = false
                end
            else
                if w.style then
                    if w.style.bg then w.style.bg.visible = false end
                    if w.style.frame then w.style.frame.visible = false end
                    if w.style.inner then w.style.inner.visible = false end
                    if w.style.bar_bg then w.style.bar_bg.visible = false end
                    if w.style.bar_fill then w.style.bar_fill.visible = false end
                    if w.style.label then w.style.label.visible = false end
                end
                local footer = self._widgets_by_name.footer
                if footer and footer.style and footer.style.counts then
                    footer.style.counts.visible = true
                end
            end
        end
    end
    local current_count = (self._image_all and table.size(self._image_all)) or 0
    if not self._last_image_count or current_count ~= self._last_image_count then
        self._retry_timer = (self._retry_timer or 0) + dt
        if self._retry_timer > 0.25 then
            self._retry_timer = 0
            local ok, err = pcall(function()
                if USE_CAROUSEL_VIEW then self:_rebuild_carousel() elseif USE_GRID_VIEW then self:_rebuild_cards() else self:_rebuild_rows() end
            end)
        end
    end
    local localized_enabled = mod:localize("clb_row_enabled")
    local localized_disabled = mod:localize("clb_row_disabled")
    local enabled_count = 0
    if USE_CAROUSEL_VIEW then
        if self._anim and self._anim.active then
            self:_animate_carousel(dt)
            return ImageManagerView.super.update(self, dt, t, input_service)
        end
        local left1 = self._widgets_by_name["carousel_left_1"]
        local right1 = self._widgets_by_name["carousel_right_1"]
        local l_hs = left1 and left1.content and left1.content.hotspot
        local r_hs = right1 and right1.content and right1.content.hotspot
        if l_hs and l_hs.on_pressed then self:_on_prev_image() end
        if r_hs and r_hs.on_pressed then self:_on_next_image() end
        local alpha = math.floor((0.35 + 0.30 * (0.5 + 0.5 * math.sin((self._pulse_t or 0) * 3.0))) * 255)
        left1 = self._widgets_by_name["carousel_left_1"]
        right1 = self._widgets_by_name["carousel_right_1"]
        l_hs = left1 and left1.content and left1.content.hotspot
        r_hs = right1 and right1.content and right1.content.hotspot
        if left1 and left1.style and left1.style.pulse then
            left1.style.pulse.visible = l_hs and l_hs.is_hover and left1.style.img and left1.style.img.visible or false
            if left1.style.pulse.visible then left1.style.pulse.color[1] = alpha end
        end
        if right1 and right1.style and right1.style.pulse then
            right1.style.pulse.visible = r_hs and r_hs.is_hover and right1.style.img and right1.style.img.visible or false
            if right1.style.pulse.visible then right1.style.pulse.color[1] = alpha end
        end
        do
            local url_w = self._widgets_by_name.center_url
            if url_w and url_w.content and url_w.content.hotspot then
                local hs = url_w.content.hotspot
                if hs.on_pressed then
                    local text = tostring(url_w.content.label or "")
                    if #text > 0 then
                        local ok = false
                        if Clipboard and Clipboard.put then
                            ok = pcall(function() Clipboard.put(text) end)
                        end
                        if ok then
                            mod:notify(mod:localize("clb_manager_copied_to_clipboard"))
                        else
                            mod:notify(mod:localize("clb_manager_copy_failed_fallback"))
                        end
                    end
                end
            end
        end
        local btn = self._widgets_by_name.center_toggle_button
        if btn and btn.content and btn.content.hotspot then
            if btn.style and btn.style.bg then
                btn.style.bg.color[1] = btn.content.hotspot.is_hover and 120 or 90
            end
            if btn.content.hotspot.on_pressed then
            local keys = table.keys(self._image_all or {}) or {}
            table.sort(keys)
            local center_key = keys[self._carousel_idx or 1]
            if center_key then
                local currently_disabled = (self._image_enabled[center_key] == false)
                self._image_enabled[center_key] = currently_disabled and true or false
                local is_enabled = (self._image_enabled[center_key] ~= false)
                btn.content.label = is_enabled and mod:localize("clb_row_enabled") or mod:localize("clb_row_disabled")
                if btn.style and btn.style.bg then
                    btn.style.bg.color = is_enabled and { 120, 40, 160, 40 } or { 120, 160, 40, 40 }
                end
                self:_update_counts_text()
                if mod.persist_enabled_state then pcall(mod.persist_enabled_state) end
            end
        end
    end
    elseif USE_GRID_VIEW then
        for _, card in ipairs(self._rows) do
            if card.content.active then
                local hs = card.content.card_hotspot
                if hs and hs.on_pressed then
                    local key = card.content.image_key
                    if key then
                        local currently_disabled = (self._image_enabled[key] == false)
                        self._image_enabled[key] = currently_disabled and nil or false
                        local enabled = self._image_enabled[key] ~= false
                        card.content.enabled = enabled
                        card.content.pill_label = enabled and localized_enabled or localized_disabled
                        if card.style and card.style.pill_bg then
                            card.style.pill_bg.color = enabled and {200,40,160,40} or {200,160,40,40}
                        end
                    end
                end
                if card.content.enabled then enabled_count = enabled_count + 1 end
                if card.style and card.style.card_bg and hs then
                    card.style.card_bg.color[1] = hs.is_hover and 100 or 60
                end
            end
        end
    else
        for _, row in ipairs(self._rows) do
            if row.content.active then
                local hotspot = row.content.toggle_hotspot
                if hotspot and hotspot.on_pressed then
                    local key = row.content.image_key
                    if key then
                        local currently_disabled = (self._image_enabled[key] == false)
                        if currently_disabled then
                            self._image_enabled[key] = nil
                        else
                            self._image_enabled[key] = false
                        end
                        local enabled = self._image_enabled[key] ~= false
                        row.content.enabled = enabled
                        row.content.toggle_label = enabled and localized_enabled or localized_disabled
                    end
                end
                if row.content.enabled then enabled_count = enabled_count + 1 end
                if row.style and row.style.toggle_rect then
                    row.style.toggle_rect.color = row.content.enabled and {200,40,160,40} or {200,160,40,40}
                end
                if row.style and row.style.row_bg and hotspot then
                    row.style.row_bg.color[1] = hotspot.is_hover and 100 or 60
                end
            end
        end
    end
    local enable_widget = self._widgets_by_name.enable_all_button
    if enable_widget and enable_widget.content and enable_widget.content.hotspot then
        local hs = enable_widget.content.hotspot
        if hs.on_pressed then
            self:_enable_all()
        end
    end
    local disable_widget = self._widgets_by_name.disable_all_button
    if disable_widget and disable_widget.content and disable_widget.content.hotspot then
        local hs2 = disable_widget.content.hotspot
        if hs2.on_pressed then
            self:_disable_all()
        end
    end
    if enabled_count ~= self._last_enabled_count then
        self._last_enabled_count = enabled_count
        self:_update_counts_text()
    end
    return ImageManagerView.super.update(self, dt, t, input_service)
end

local function _apply_frame_geom(widget, w, h, x, y, angle)
    if not widget or not widget.style then return end
    local s = widget.style
    local function set_pass(pass, size, offset, ang, with_pivot)
        local st = s[pass]
        if st then
            if size then st.size = { size[1], size[2] } end
            if offset then
                local z = (st.offset and st.offset[3]) or 0
                st.offset = { offset[1], offset[2], z }
            end
            if with_pivot then st.pivot = { (size and size[1] or w)/2, (size and size[2] or h)/2 } end
            if ang ~= nil then st.angle = ang end
        end
    end
    set_pass("img", { w, h }, { x, y }, angle, true)
    set_pass("frame_outer", { w+14, h+14 }, { x-7, y-7 }, angle, true)
    set_pass("frame_inner", { w+8, h+8 }, { x-4, y-4 }, angle, true)
    set_pass("bevel_top", { w+4, 8 }, { x-2, y-4 }, angle, true)
    set_pass("bevel_bottom", { w+4, 8 }, { x-2, y+h-4 }, angle, true)
    if s.shadow then
        s.shadow.size = { w+14, h+10 }
        local z = (s.shadow.offset and s.shadow.offset[3]) or 0
        s.shadow.offset = { x-7, y+4, z }
    end
    if s.pulse then s.pulse.visible = false end
end

function ImageManagerView:_start_carousel_anim(dir)
    if not USE_CAROUSEL_VIEW then return false end
    local keys = table.keys(self._image_all or {}) or {}
    table.sort(keys)
    local total = #keys
    if total == 0 then return false end
    local center_idx = self._carousel_idx or 1
    local function index_plus(i, delta)
        return ((i - 1 + delta) % total) + 1
    end
    local prev_idx = index_plus(center_idx, -1)
    local next_idx = index_plus(center_idx, 1)

    local center_w = self._widgets_by_name.carousel_center
    local left_w = self._widgets_by_name.carousel_left_1
    local right_w = self._widgets_by_name.carousel_right_1
    local left_in = self._widgets_by_name.carousel_left_incoming
    local right_in = self._widgets_by_name.carousel_right_incoming
    local c_ghost = self._widgets_by_name.carousel_center_ghost
    local l_ghost = self._widgets_by_name.carousel_side_ghost_l
    local r_ghost = self._widgets_by_name.carousel_side_ghost_r
    if not (center_w and left_w and right_w and left_in and right_in and c_ghost and l_ghost and r_ghost) then return false end

    local c_entry = self._image_all[keys[center_idx]]
    local p_entry = self._image_all[keys[prev_idx]]
    local n_entry = self._image_all[keys[next_idx]]
    if not (c_entry and c_entry.texture and p_entry and p_entry.texture and n_entry and n_entry.texture) then
        return false
    end

    local scale = STACK_SCALES[1]
    local small_w, small_h = math.floor(CENTER_W * scale), math.floor(CENTER_H * scale)
    local l_x = (CENTER_W/2) - small_w - (CENTER_W/2) + STACK_X_OFF_L[1]
    local r_x = (CENTER_W/2) + (CENTER_W/2) + STACK_X_OFF_R[1]
    local y_small = math.floor((CENTER_H - small_h) / 2)

    local from_center = { w = CENTER_W, h = CENTER_H, x = 0, y = 0, a = 0 }
    local to_left   = { w = small_w, h = small_h, x = l_x, y = y_small, a = STACK_ANGLES_L[1] * math.pi/180 }
    local to_right  = { w = small_w, h = small_h, x = r_x, y = y_small, a = STACK_ANGLES_R[1] * math.pi/180 }
    local from_left = { w = small_w, h = small_h, x = l_x, y = y_small, a = STACK_ANGLES_L[1] * math.pi/180 }
    local from_right= { w = small_w, h = small_h, x = r_x, y = y_small, a = STACK_ANGLES_R[1] * math.pi/180 }
    local to_center = { w = CENTER_W, h = CENTER_H, x = 0, y = 0, a = 0 }

    local function _hide_center_frames_alpha()
        local s = center_w.style
        if not s then return {} end
        local fields = {"frame_outer","frame_inner","bevel_top","bevel_bottom","shadow"}
        local backup = {}
        for _,key in ipairs(fields) do
            local st = s[key]
            if st and st.color then
                backup[key] = st.color[1]
                st.color[1] = 0
            end
        end
        return backup
    end
    local function _restore_center_frames_alpha(backup)
        if not backup then return end
        local s = center_w.style
        if not s then return end
        for key,alpha in pairs(backup) do
            local st = s[key]
            if st and st.color then
                st.color[1] = alpha
            end
        end
    end

    if dir == 1 then
        local function hide_all(w)
            if not w or not w.style then return end
            if w.style.img then w.style.img.visible = false end
            if w.style.frame_outer then w.style.frame_outer.visible = false end
            if w.style.frame_inner then w.style.frame_inner.visible = false end
            if w.style.bevel_top then w.style.bevel_top.visible = false end
            if w.style.bevel_bottom then w.style.bevel_bottom.visible = false end
        end
        hide_all(left_w); hide_all(center_w); hide_all(right_w)
        local alpha_backup = _hide_center_frames_alpha()
        self._anim = {
            active = true, dir = 1, t = 0, duration = 0.25,
            moves = {},
            finalize = function(view)
                _restore_center_frames_alpha(alpha_backup)
                local new_idx = ((center_idx) % total) + 1
                view._carousel_idx = new_idx
                view:_rebuild_carousel()
            end,
        }
        local function show_tex(w, tex)
            if not w or not w.style then return end
            if w.style.img then
                w.style.img.visible = true
                w.style.img.material_values = w.style.img.material_values or {}
                w.style.img.material_values.texture_map = tex
            end
            if w.style.frame_outer then w.style.frame_outer.visible = true end
            if w.style.frame_inner then w.style.frame_inner.visible = true end
            if w.style.bevel_top then w.style.bevel_top.visible = true end
            if w.style.bevel_bottom then w.style.bevel_bottom.visible = true end
        end
        show_tex(c_ghost, c_entry.texture)
        show_tex(r_ghost, n_entry.texture)
        table.insert(self._anim.moves, { widget = c_ghost, from = from_center, to = to_left })
        table.insert(self._anim.moves, { widget = r_ghost, from = from_right,  to = to_center })
        local in_right_idx = index_plus(center_idx, 2)
        local in_right_entry = self._image_all[keys[in_right_idx]]
        if in_right_entry and in_right_entry.texture then
            if right_in.style then
                if right_in.style.img then
                    right_in.style.img.visible = true
                    right_in.style.img.material_values = right_in.style.img.material_values or {}
                    right_in.style.img.material_values.texture_map = in_right_entry.texture
                end
                if right_in.style.frame_outer then right_in.style.frame_outer.visible = true end
                if right_in.style.frame_inner then right_in.style.frame_inner.visible = true end
                if right_in.style.bevel_top then right_in.style.bevel_top.visible = true end
                if right_in.style.bevel_bottom then right_in.style.bevel_bottom.visible = true end
            end
            local start_off = { w = small_w, h = small_h, x = r_x + 160, y = y_small, a = STACK_ANGLES_R[1] * math.pi/180 }
            _apply_frame_geom(right_in, start_off.w, start_off.h, start_off.x, start_off.y, start_off.a)
            table.insert(self._anim.moves, { widget = right_in, from = start_off, to = to_right })
        end
        return true
    elseif dir == -1 then
        local function hide_all(w)
            if not w or not w.style then return end
            if w.style.img then w.style.img.visible = false end
            if w.style.frame_outer then w.style.frame_outer.visible = false end
            if w.style.frame_inner then w.style.frame_inner.visible = false end
            if w.style.bevel_top then w.style.bevel_top.visible = false end
            if w.style.bevel_bottom then w.style.bevel_bottom.visible = false end
        end
        hide_all(right_w); hide_all(center_w); hide_all(left_w)
        local alpha_backup = _hide_center_frames_alpha()
        self._anim = {
            active = true, dir = -1, t = 0, duration = 0.25,
            moves = {},
            finalize = function(view)
                _restore_center_frames_alpha(alpha_backup)
                local new_idx = ((center_idx - 2) % total) + 1
                view._carousel_idx = new_idx
                view:_rebuild_carousel()
            end,
        }
        local function show_tex(w, tex)
            if not w or not w.style then return end
            if w.style.img then
                w.style.img.visible = true
                w.style.img.material_values = w.style.img.material_values or {}
                w.style.img.material_values.texture_map = tex
            end
            if w.style.frame_outer then w.style.frame_outer.visible = true end
            if w.style.frame_inner then w.style.frame_inner.visible = true end
            if w.style.bevel_top then w.style.bevel_top.visible = true end
            if w.style.bevel_bottom then w.style.bevel_bottom.visible = true end
        end
        show_tex(c_ghost, c_entry.texture)
        show_tex(l_ghost, p_entry.texture)
        table.insert(self._anim.moves, { widget = c_ghost, from = from_center, to = to_right })
        table.insert(self._anim.moves, { widget = l_ghost, from = from_left,   to = to_center })
        local in_left_idx = index_plus(center_idx, -2)
        local in_left_entry = self._image_all[keys[in_left_idx]]
        if in_left_entry and in_left_entry.texture then
            if left_in.style then
                if left_in.style.img then
                    left_in.style.img.visible = true
                    left_in.style.img.material_values = left_in.style.img.material_values or {}
                    left_in.style.img.material_values.texture_map = in_left_entry.texture
                end
                if left_in.style.frame_outer then left_in.style.frame_outer.visible = true end
                if left_in.style.frame_inner then left_in.style.frame_inner.visible = true end
                if left_in.style.bevel_top then left_in.style.bevel_top.visible = true end
                if left_in.style.bevel_bottom then left_in.style.bevel_bottom.visible = true end
            end
            local start_off = { w = small_w, h = small_h, x = l_x - 160, y = y_small, a = STACK_ANGLES_L[1] * math.pi/180 }
            _apply_frame_geom(left_in, start_off.w, start_off.h, start_off.x, start_off.y, start_off.a)
            table.insert(self._anim.moves, { widget = left_in, from = start_off, to = to_left })
        end
        return true
    end
    return false
end

function ImageManagerView:_animate_carousel(dt)
    local anim = self._anim
    if not anim or not anim.active then return end
    anim.t = anim.t + dt
    local t = anim.t / (anim.duration or 0.25)
    if t > 1 then t = 1 end
    local a = t * t * (3 - 2 * t)
    for i = 1, #anim.moves do
        local mv = anim.moves[i]
        local f, to = mv.from, mv.to
        local w = f.w + (to.w - f.w) * a
        local h = f.h + (to.h - f.h) * a
        local x = f.x + (to.x - f.x) * a
        local y = f.y + (to.y - f.y) * a
        local ang = f.a + (to.a - f.a) * a
        _apply_frame_geom(mv.widget, math.floor(w), math.floor(h), math.floor(x), math.floor(y), ang)
    end
    if anim.t >= (anim.duration or 0.25) then
        anim.active = false
        if anim.finalize then anim.finalize(self) end
        local l_in = self._widgets_by_name.carousel_left_incoming
        local r_in = self._widgets_by_name.carousel_right_incoming
        local function _hide_incoming(w)
            if not w or not w.style then return end
            if w.style.img then w.style.img.visible = false end
            if w.style.frame_outer then w.style.frame_outer.visible = false end
            if w.style.frame_inner then w.style.frame_inner.visible = false end
            if w.style.bevel_top then w.style.bevel_top.visible = false end
            if w.style.bevel_bottom then w.style.bevel_bottom.visible = false end
        end
        _hide_incoming(l_in)
        _hide_incoming(r_in)
    end
end

function ImageManagerView:_update_counts_text()
    local total = (self._image_all and table.size(self._image_all)) or (self._last_image_count or 0)
    local enabled = 0
    if self._image_all then
        for k,_ in pairs(self._image_all) do
            if self._image_enabled[k] ~= false then
                enabled = enabled + 1
            end
        end
    else
        enabled = self._last_enabled_count or 0
    end
    local counts_widget = self._widgets_by_name.footer
    if counts_widget then
        local loading = false
        if mod.get_manager_loading_status then
            local s = mod.get_manager_loading_status() or { active=false }
            local inflight = s.inflight or 0
            if s.active and (inflight > 0 or not s.done) then
                loading = true
            end
        end
        local ok, localized = pcall(function() return mod:localize("clb_counts", enabled, total) end)
        if not ok or not localized or localized == "" then
            localized = string.format("Enabled %d / %d", enabled, total)
        end
        counts_widget.content.counts = localized
        if counts_widget.style and counts_widget.style.counts then
            counts_widget.style.counts.visible = not loading
        end
    end
end

return ImageManagerView
