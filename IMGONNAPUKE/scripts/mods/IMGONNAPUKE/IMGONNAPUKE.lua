local mod = get_mod("IMGONNAPUKE")

local puke_volume = mod:get("puke_volume")
local puke_frequency = mod:get("puke_frequency")
local puke1 = mod:get("setting_puke1")
local puke2 = mod:get("setting_puke2")
local puke3 = mod:get("setting_puke3")
local puke4 = mod:get("setting_puke4")
local puke5 = mod:get("setting_puke5")
local puke = {}




local LocalServer = get_mod("DarktideLocalServer")
local Audio
local check_dependencies = function()
	Audio = get_mod("Audio")
	if not LocalServer then
		mod:echo(
			'Required mod "Darktide Local Server" not found: Download from Nexus Mods and include in mod_load_order.txt'
		)
		mod:disable_all_hooks()
		mod:disable_all_commands()
	end
	if not Audio then
		mod:echo(
			'Required mod "Audio Plugin" not found: Download from Nexus Mods and include in mod_load_order.txt'
		)
		mod:disable_all_hooks()
		mod:disable_all_commands()
	end
end

local puke_update = function()
	puke_volume = mod:get("puke_volume")
	puke_frequency = mod:get("puke_frequency")
	puke1 = mod:get("setting_puke1")
	puke2 = mod:get("setting_puke2")
	puke3 = mod:get("setting_puke3")
	puke4 = mod:get("setting_puke4")
	puke5 = mod:get("setting_puke5")
	puke = {}
	if puke1 then
		table.insert(puke,"audio/IMGONNAPUKE.mp3")
	end
	if puke2 then
		table.insert(puke,"audio/IMGONNAPUKEIMGONNAPUKE.mp3")
	end
	if puke3 then
		table.insert(puke,"audio/IMMAFUCKINTHROWUP.mp3")
	end
	if puke4 then
		table.insert(puke,"audio/IMGONNAFUCKINGPUKE.mp3")
	end
	if puke5 then
		table.insert(puke,"audio/BLUHBLUHBLUHBLUH.mp3")
	end
end

mod.on_setting_changed = function()
	puke_update()
end

mod.on_enabled = function()
	puke_update()
end

mod.on_game_state_changed = function()
	puke_update()
end


mod.on_all_mods_loaded = function()
	check_dependencies()

    Audio.hook_sound("play_beast_of_nurgle_vomit_aoe",
        function()
			if next(puke) then
				local pukeIndex = math.random(1,#puke)
				local randomPuke = puke[pukeIndex]
				
				if 100*math.random(0,1) <= puke_frequency then
					Audio.play_file(randomPuke, { volume = puke_volume })
				end
			end

        end
    )
end