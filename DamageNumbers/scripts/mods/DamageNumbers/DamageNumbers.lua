local mod = get_mod("DamageNumbers")

local breed = require("scripts/utilities/breed")

local DEFAULT_LIFETIME = 1.8
local DEFAULT_RISE_PX = 42

local DEFAULT_SETTINGS = {
    lifetime_seconds = DEFAULT_LIFETIME,
    rise_speed_px = DEFAULT_RISE_PX,
    vertical_lift_m = 0.2,
    screen_offset_y_px = 24,
    text_size_base = 26,
    text_size_weak = 28,
    text_size_crit = 34,
    color_normal = { 255, 255, 230, 50 },
    color_weak = { 255, 255, 200, 80 },
    color_crit = { 255, 255, 80, 80 },
    show_base_hits = true,
    show_weak_hits = true,
    show_crit_hits = true,
    show_type_boss = true,
    show_type_elite = true,
    show_type_special = true,
    show_type_captain = true,
    show_type_minion = true,
}

mod._default_settings = DEFAULT_SETTINGS

mod._settings_cache = mod._settings_cache or {}

local function _value_or_default(setting_id, default_value)
    if not (mod.get and setting_id) then
        return default_value
    end

    local ok, value = pcall(mod.get, mod, setting_id)
    if not ok or value == nil then
        return default_value
    end

    return value
end

local function _refresh_color(cache_key, r_setting, g_setting, b_setting, defaults)
    local cache = mod._settings_cache
    local color = cache[cache_key]
    if not color then
        color = { defaults[1], defaults[2], defaults[3], defaults[4] }
        cache[cache_key] = color
    end

    color[1] = defaults[1]
    color[2] = _value_or_default(r_setting, defaults[2])
    color[3] = _value_or_default(g_setting, defaults[3])
    color[4] = _value_or_default(b_setting, defaults[4])
end

function mod.refresh_settings_cache()
    local cache = mod._settings_cache or {}
    mod._settings_cache = cache

    cache.lifetime_seconds = _value_or_default("lifetime_seconds", DEFAULT_SETTINGS.lifetime_seconds)
    cache.rise_speed_px = _value_or_default("rise_speed_px", DEFAULT_SETTINGS.rise_speed_px)
    cache.vertical_lift_m = _value_or_default("vertical_lift_m", DEFAULT_SETTINGS.vertical_lift_m)
    cache.screen_offset_y_px = _value_or_default("screen_offset_y_px", DEFAULT_SETTINGS.screen_offset_y_px)

    cache.text_size_base = _value_or_default("text_size_base", DEFAULT_SETTINGS.text_size_base)
    cache.text_size_weak = _value_or_default("text_size_weak", DEFAULT_SETTINGS.text_size_weak)
    cache.text_size_crit = _value_or_default("text_size_crit", DEFAULT_SETTINGS.text_size_crit)

    cache.show_base_hits = _value_or_default("show_base_hits", DEFAULT_SETTINGS.show_base_hits)
    cache.show_weak_hits = _value_or_default("show_weak_hits", DEFAULT_SETTINGS.show_weak_hits)
    cache.show_crit_hits = _value_or_default("show_crit_hits", DEFAULT_SETTINGS.show_crit_hits)
    cache.show_type_boss = _value_or_default("show_type_boss", DEFAULT_SETTINGS.show_type_boss)
    cache.show_type_elite = _value_or_default("show_type_elite", DEFAULT_SETTINGS.show_type_elite)
    cache.show_type_special = _value_or_default("show_type_special", DEFAULT_SETTINGS.show_type_special)
    cache.show_type_captain = _value_or_default("show_type_captain", DEFAULT_SETTINGS.show_type_captain)
    cache.show_type_minion = _value_or_default("show_type_minion", DEFAULT_SETTINGS.show_type_minion)

    _refresh_color("color_normal", "color_normal_r", "color_normal_g", "color_normal_b", DEFAULT_SETTINGS.color_normal)
    _refresh_color("color_weak", "color_weak_r", "color_weak_g", "color_weak_b", DEFAULT_SETTINGS.color_weak)
    _refresh_color("color_crit", "color_crit_r", "color_crit_g", "color_crit_b", DEFAULT_SETTINGS.color_crit)
end

mod.refresh_settings_cache()

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
    local cache = mod._settings_cache or {}
    if (not cache.lifetime_seconds) and mod.refresh_settings_cache then
        mod.refresh_settings_cache()
        cache = mod._settings_cache or cache
    end
    local t = (Managers.time and Managers.time:time("main")) or os.clock()
    local dmg_value = math.floor((tonumber(damage) or 0) + 0.5)
    local base_text = tostring(dmg_value)
    if is_crit then
        base_text = base_text .. "!"
    end
    local data = {
        dmg = dmg_value,
        crit = is_crit and true or false,
        weakspot = hit_weakspot and true or false,
        start_t = t,
        life = cache.lifetime_seconds or DEFAULT_SETTINGS.lifetime_seconds,
        rise_px = cache.rise_speed_px or DEFAULT_SETTINGS.rise_speed_px,
        lift = cache.vertical_lift_m or DEFAULT_SETTINGS.vertical_lift_m,
        screen_offset_y_px = cache.screen_offset_y_px or DEFAULT_SETTINGS.screen_offset_y_px,
        hit_pos = hit_world_position,
        use_world_position = hit_world_position ~= nil,
        hit_dir = attack_direction,
        text = base_text,
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
        local attacked_unit_breed = breed.unit_breed_or_nil(attacked_unit)
        if not attacked_unit_breed then return end

        local unit_data = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
        local is_boss = false
        if unit_data and unit_data.breed then
            local ok, b = pcall(function() return unit_data:breed() end)
            if ok and b then is_boss = b.is_boss or false end
        elseif attacked_unit_breed then
            is_boss = attacked_unit_breed.is_boss or false
        end

        local attacked_unit_type = attacked_unit_breed and (breed.enemy_type(attacked_unit_breed) or attacked_unit_breed.breed_type) or nil

        local is_crit = is_critical_strike and true or false
        local is_weak = (not is_crit) and (hit_weakspot and true or false)

        local cache = mod._settings_cache or {}
        if (cache.show_base_hits == nil) and mod.refresh_settings_cache then
            mod.refresh_settings_cache()
            cache = mod._settings_cache or cache
        end

        local show_base = cache.show_base_hits ~= false
        local show_weak = cache.show_weak_hits ~= false
        local show_crit = cache.show_crit_hits ~= false
        local show_boss    = cache.show_type_boss ~= false
        local show_elite   = cache.show_type_elite ~= false
        local show_special = cache.show_type_special ~= false
        local show_captain = cache.show_type_captain ~= false
        local show_minion  = cache.show_type_minion ~= false

        local allow_type = true
        if is_boss then
            allow_type = show_boss ~= false
        elseif attacked_unit_type == "elite" then
            allow_type = show_elite ~= false
        elseif attacked_unit_type == "special" then
            allow_type = show_special ~= false
        elseif attacked_unit_type == "captain" then
            allow_type = show_captain ~= false
        else
            allow_type = show_minion ~= false
        end

        if not allow_type then
            return
        end

        if (is_crit and show_crit == false)
            or (is_weak and show_weak == false)
            or (not is_crit and not is_weak and show_base == false) then
            return
        end

        _spawn_damage_marker(dmg, attacked_unit, is_crit, hit_weakspot, hit_world_position, attack_direction)
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
        show_base_hits = true,
        show_weak_hits = true,
        show_crit_hits = true,
        show_type_boss = true,
        show_type_elite = true,
        show_type_special = true,
        show_type_captain = true,
        show_type_minion = true,
    }
    for k, v in pairs(defaults) do
        pcall(function() mod:set(k, v) end)
    end
    mod._enabled = true
    if mod.refresh_settings_cache then
        mod.refresh_settings_cache()
    end
    mod:echo("Damage Numbers: settings reset to defaults.")
end

mod:command("dmgnums_reset", "Reset Damage Numbers settings to defaults.", function()
    mod.reset_settings_to_defaults()
end)

function mod.on_setting_changed(_)
    if mod.refresh_settings_cache then
        mod.refresh_settings_cache()
    end
end

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


