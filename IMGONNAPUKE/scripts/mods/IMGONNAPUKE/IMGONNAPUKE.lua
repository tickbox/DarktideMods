local mod = get_mod("IMGONNAPUKE")

local puke_volume = mod:get("puke_volume")
local puke_frequency = mod:get("puke_frequency")
local puke1 = mod:get("setting_puke1")
local puke2 = mod:get("setting_puke2")
local puke3 = mod:get("setting_puke3")
local puke4 = mod:get("setting_puke4")
local puke5 = mod:get("setting_puke5")
local puke_death = mod:get("puke_death")
local subtitles = mod:get("puke_subtitles")
local subtitle_duration = mod:get("puke_subtitle_duration")
local subtitles_element = Managers.ui:ui_constant_elements():element("ConstantElementSubtitles")
local puke = {}
local puke_subs = {}

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
	puke_death = mod:get("puke_death")
	puke = {}
	puke_subs = {}
	if puke1 then
		table.insert(puke, "audio/IMGONNAPUKE.mp3")
		table.insert(puke_subs, mod:localize("subtitle_puke1"))
	end
	if puke2 then
		table.insert(puke,"audio/IMGONNAPUKEIMGONNAPUKE.mp3")
		table.insert(puke_subs, mod:localize("subtitle_puke2"))
	end
	if puke3 then
		table.insert(puke,"audio/IMMAFUCKINTHROWUP.mp3")
		table.insert(puke_subs, mod:localize("subtitle_puke3"))
	end
	if puke4 then
		table.insert(puke,"audio/IMGONNAFUCKINGPUKE.mp3")
		table.insert(puke_subs, mod:localize("subtitle_puke4"))
	end
	if puke5 then
		table.insert(puke,"audio/BLUHBLUHBLUHBLUH.mp3")
		table.insert(puke_subs, mod:localize("subtitle_puke5"))
	end
end

mod.on_setting_changed = function()
	puke_update()
end

mod.on_enabled = function()
	puke_update()
end

mod.on_game_state_changed = function()
	--puke_update()
end


mod.on_all_mods_loaded = function()
	check_dependencies()

    Audio.hook_sound("play_beast_of_nurgle_vomit_aoe",
        function()
			if next(puke) then
				local pukeIndex = math.random(1,#puke)
				local randomPuke = puke[pukeIndex]
				local randomPukeSub = puke_subs[pukeIndex]
				
				if 100*math.random(0,1) <= puke_frequency then
					Audio.play_file(randomPuke, { volume = puke_volume })
					if subtitles then
						subtitles_element:_display_text_line(randomPukeSub, subtitle_duration)
					end
				end
			end

        end
    )

	if puke_death then
		Audio.hook_sound("play_beast_of_nurgle_dissolve",
			function()
				Audio.play_file("audio/broken.mp3", { volume = puke_volume })
				if subtitles then
					subtitles_element:_display_text_line(mod:localize("puke_subtitle_death"), subtitle_duration)
				end
			end
		)
	end
end