local mod = get_mod("custom_hud_patch")

local visible_elements = {}
local hidden_elements = {}

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

function mod.update_visibility_groups(element)
    local e = element
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