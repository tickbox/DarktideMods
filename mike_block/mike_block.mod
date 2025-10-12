return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`mike_block` encountered an error loading the Darktide Mod Framework.")

		new_mod("mike_block", {
			mod_script       = "mike_block/scripts/mods/mike_block/mike_block",
			mod_data         = "mike_block/scripts/mods/mike_block/mike_block_data",
			mod_localization = "mike_block/scripts/mods/mike_block/mike_block_localization",
		})
	end,
	load_after = {
		"DarktideLocalServer",
		"Audio",
	},
	require = {
		"DarktideLocalServer",
		"Audio",
	},
	packages = {},
}
