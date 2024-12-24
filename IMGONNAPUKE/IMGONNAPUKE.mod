return {
	run = function()
		fassert(rawget(_G, "IMGONNAPUKE"), "`IMGONNAPUKE` encountered an error loading the Darktide Mod Framework.")

		new_mod("IMGONNAPUKE", {
			mod_script       = "IMGONNAPUKE/scripts/mods/IMGONNAPUKE/IMGONNAPUKE",
			mod_data         = "IMGONNAPUKE/scripts/mods/IMGONNAPUKE/IMGONNAPUKE_data",
			mod_localization = "IMGONNAPUKE/scripts/mods/IMGONNAPUKE/IMGONNAPUKE_localization",
		})
	end,
	packages = {},
}
