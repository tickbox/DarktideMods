return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`CustomLoadingBackground` encountered an error loading the Darktide Mod Framework.")

		new_mod("CustomLoadingBackground", {
			mod_script       = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/CustomLoadingBackground",
			mod_data         = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/CustomLoadingBackground_data",
			mod_localization = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/CustomLoadingBackground_localization",
		})
	end,
	load_after = {
		"DarktideLocalServer",
	},
	require = {},
	packages = {},
}
