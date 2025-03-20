return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Do I Know You` encountered an error loading the Darktide Mod Framework.")

		new_mod("Do I Know You", {
			mod_script       = "Do I Know You/scripts/mods/Do I Know You/Do I Know You",
			mod_data         = "Do I Know You/scripts/mods/Do I Know You/Do I Know You_data",
			mod_localization = "Do I Know You/scripts/mods/Do I Know You/Do I Know You_localization",
		})
	end,
	packages = {},
}
