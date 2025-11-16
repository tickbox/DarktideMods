local mod = get_mod("custom_hud_patch")

mod:io_dofile("custom_hud_patch/scripts/mods/custom_hud_patch/modules/visible_elements")

local custom_hud = get_mod("custom_hud")

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
        mod.update_visibility_groups(e)
    end
    return func(self, peer_id, local_player_id, elements, visibility_groups)
end)


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

