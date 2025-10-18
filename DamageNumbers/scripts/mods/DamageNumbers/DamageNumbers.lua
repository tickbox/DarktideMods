local mod = get_mod("DamageNumbers")

local DEFAULT_LIFETIME = 1.8
local DEFAULT_RISE_PX = 42

local function _world_markers_ready()
    local ui = Managers.ui
    if not ui then return false end
    local hud = ui:get_hud()
    local wm = hud and hud:element("HudElementWorldMarkers")
    return wm ~= nil and wm._marker_templates ~= nil
end

local function _vec_xyz(vec)
    if not vec then return nil, nil, nil end

    if type(vec) == "userdata" and vec.unbox then
        return vec:unbox()
    end

    local ok, x = pcall(function() return Vector3 and Vector3.x and Vector3.x(vec) end)
    if ok and x then
        local y = Vector3.y(vec)
        local z = Vector3.z(vec)
        return x, y, z
    end

    if type(vec) == "table" then
        return vec[1], vec[2], vec[3]
    end
    return nil, nil, nil
end

local POOL_SIZE = 64
local DAMAGE_MARKER_PREFIX = "damage_numbers_hit#"
mod._type_counter = mod._type_counter or 0
local function _pooled_marker_type()
    mod._type_counter = (mod._type_counter % POOL_SIZE) + 1
    return string.format("%s%d", DAMAGE_MARKER_PREFIX, mod._type_counter)
end

local function _spawn_damage_marker(damage, attacked_unit, is_crit, hit_weakspot, hit_world_position, attack_direction)
    if not mod._enabled then return end
    if not attacked_unit or not Unit.alive(attacked_unit) then return end
    local t = (Managers.time and Managers.time:time("main")) or os.clock()
    local data = {
        dmg = math.floor((tonumber(damage) or 0) + 0.5),
        crit = is_crit and true or false,
        weakspot = hit_weakspot and true or false,
        start_t = t,
        life = (mod.get and mod:get("lifetime_seconds")) or DEFAULT_LIFETIME,
        rise_px = (mod.get and mod:get("rise_speed_px")) or DEFAULT_RISE_PX,
        lift = (mod.get and mod:get("vertical_lift_m")) or 0.2,
        rand_x = (math.random() * 0.6 - 0.3),
        hit_pos = hit_world_position,
        use_world_position = hit_world_position ~= nil,
        hit_dir = attack_direction,
    }
    local marker_type = _pooled_marker_type()

    local ui = Managers.ui
    local hud = ui and ui:get_hud()
    local wm = hud and hud:element("HudElementWorldMarkers")

    if wm and wm.event_add_world_marker_unit then
        wm:event_add_world_marker_unit(marker_type, attacked_unit, nil, data)
    else
        Managers.event:trigger("add_world_marker_unit", marker_type, attacked_unit, nil, data)
    end
end

--[[
    ... args:
    damage_profile,
    attacked_unit,
    attacking_unit,
    attack_direction,
    hit_world_position,
    hit_weakspot,
    damage,
    attack_result,
    attack_type,
    damage_efficiency,
    is_critical_strike
]]
mod:hook_safe(AttackReportManager, "add_attack_result", function(self, ...)
    local damage_profile,
        attacked_unit,
        attacking_unit,
        attack_direction,
        hit_world_position,
        hit_weakspot,
        damage,
        attack_result,
        attack_type,
        damage_efficiency,
        is_critical_strike = ...
    
    local dmg = tonumber(damage) or 0
    if dmg > 0 and Managers.player:local_player(1).player_unit == attacking_unit then
        _spawn_damage_marker(dmg, attacked_unit, is_critical_strike, hit_weakspot, hit_world_position, attack_direction)
    end
end)

mod._enabled = mod._enabled ~= false

function mod.toggleEnabled()
    mod._enabled = not mod._enabled
    mod:echo("Damage numbers " .. (mod._enabled and "ENABLED" or "DISABLED"))
end

function mod.reset_settings_to_defaults()
    local defaults = {
        lifetime_seconds = 1.8,
        rise_speed_px = 42,
        vertical_lift_m = 0.2,
        text_size_base = 26,
        text_size_weak = 28,
        text_size_crit = 34,
        color_normal_r = 255,
        color_normal_g = 230,
        color_normal_b = 50,
        color_weak_r = 255,
        color_weak_g = 200,
        color_weak_b = 80,
        color_crit_r = 255,
        color_crit_g = 80,
        color_crit_b = 80,
        toggle_enabled_key = {},
    }
    for k, v in pairs(defaults) do
        pcall(function() mod:set(k, v) end)
    end
    mod._enabled = true
    mod:echo("Damage Numbers: settings reset to defaults.")
end

mod:command("dmgnums_reset", "Reset Damage Numbers settings to defaults.", function()
    mod.reset_settings_to_defaults()
end)

local DamageNumbersMarker = mod:io_dofile("DamageNumbers/scripts/mods/DamageNumbers/DamageNumbers_marker")

mod:hook_safe(CLASS.HudElementWorldMarkers, "init", function(self)
    self._marker_templates[DamageNumbersMarker.name] = DamageNumbersMarker
    for i = 1, POOL_SIZE do
        local name = string.format("%s%d", DAMAGE_MARKER_PREFIX, i)
        self._marker_templates[name] = DamageNumbersMarker
    end
end)

mod:hook_safe(CLASS.HudElementWorldMarkers, "event_add_world_marker_unit", function(self, marker_type, unit, callback, data)
    if type(marker_type) == "string" and string.find(marker_type, "^" .. DAMAGE_MARKER_PREFIX) then
        local markers = self._markers_by_type and self._markers_by_type[marker_type]
        if not markers or not data or not data.hit_pos then return end

        for i = #markers, 1, -1 do
            local m = markers[i]
            if m and m.unit == unit then
                m.data = data or m.data or {}
                local life = (m.data and m.data.life) or 1.6
                m.life_time = life
                m._dn_elapsed = 0
                local x, y, z = _vec_xyz(m.data.hit_pos)
                if x and y and z then
                    local lift = (m.data and m.data.lift) or 0.2
                    local box = (Vector3Box and Vector3Box(x, y, z + lift)) or Vector3(x, y, z + lift)
                    m.world_position = box
                    m._dn_worldpos_box = box
                    m.use_world_position = true
                    m.unit_node = nil
                    m.node_index = -1
                end
                break
            end
        end
    end
end)


