local mod = get_mod("custom_hud_patch")

local custom_hud = get_mod("custom_hud")

local visible_elements = {}
local hidden_elements = {}

mod.was_hud_hidden = custom_hud.is_hud_hidden

--[[===================================================
    Fixes
--===================================================]]

--fixes a bug when hud is off and toggling hud visibility while spectating could cause issues when player is alive again
mod:hook_safe("UIManager", "create_spectator_hud", function(...)
    mod.was_hud_hidden = custom_hud.is_hud_hidden
    if custom_hud.is_hud_hidden then custom_hud.is_hud_hidden = false end
end)
mod:hook_safe("UIManager", "destroy_spectator_hud", function(...)
    custom_hud:on_all_mods_loaded() --force custom_hud to run its recreate_hud function
    custom_hud.is_hud_hidden = mod.was_hud_hidden
end)

--prevents a crash caused by a race condition when the object has already been destroyed but is_alive is still called on it
mod:hook_require("scripts/ui/hud/elements/player_panel_base/hud_element_player_panel_base", function(HudElementPlayerPanelBase)
  mod:hook(HudElementPlayerPanelBase, "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
    local ok, err = pcall(func, self, dt, t, ui_renderer, render_settings, input_service)
    if not ok then
      local msg = tostring(err or "")
      if msg:find("is_alive") then
        self._extensions = nil
        self:_set_dead(true, true, ui_renderer)
        return
      end
    end
  end)
end)

--[[===================================================
    New Features
--===================================================]]

-- Allows certain HUD elements to remain visible when the HUD is toggled off
mod:hook("UIManager", "create_player_hud", function(func, self, peer_id, local_player_id, elements, visibility_groups)
    for _, e in ipairs(elements) do
        if table.contains(visible_elements, e.class_name) then
            table.insert(e.visibility_groups, "hide_hud")
        elseif table.contains(hidden_elements, e.class_name) then
            for i, v in ipairs(e.visibility_groups) do
                if v == "hide_hud" then
                    table.remove(e.visibility_groups, i)
                    break
                end
            end
        end
    end
    return func(self, peer_id, local_player_id, elements, visibility_groups)
end)

function mod.update_visible_elements()
    visible_elements = {}
    hidden_elements = {}
    if mod:get("show_world_markers") then
        table.insert(visible_elements, "HudElementWorldMarkers")
    else
        table.insert(hidden_elements, "HudElementWorldMarkers")
    end

    if mod:get("show_smart_tagging") then
        table.insert(visible_elements, "HudElementSmartTagging")
    else
        table.insert(hidden_elements, "HudElementSmartTagging")
    end

    if mod:get("show_interaction") then
        table.insert(visible_elements, "HudElementInteraction")
    else
        table.insert(hidden_elements, "HudElementInteraction")
    end

    if mod:get("show_beacon") then
        table.insert(visible_elements, "HudElementBeacon")
    else
        table.insert(hidden_elements, "HudElementBeacon")
    end

    if mod:get("show_emote_wheel") then
        table.insert(visible_elements, "HudElementEmoteWheel")
    else
        table.insert(hidden_elements, "HudElementEmoteWheel")
    end

    if mod:get("show_nameplates") then
        table.insert(visible_elements, "HudElementNameplates")
    else
        table.insert(hidden_elements, "HudElementNameplates")
    end
end

--[[===================================================
    Generic Mod Crap
--===================================================]]

function mod.on_setting_changed(setting_id)
    if setting_id == "show_world_markers" or
       setting_id == "show_smart_tagging" or
       setting_id == "show_interaction" or
       setting_id == "show_beacon" or
       setting_id == "show_emote_wheel" or
       setting_id == "show_nameplates" then
        mod.update_visible_elements()
        --custom_hud:on_all_mods_loaded()
    end
end

function mod.on_all_mods_loaded()
    mod.update_visible_elements()
end

