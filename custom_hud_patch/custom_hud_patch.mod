return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`custom_hud_patch` encountered an error loading the Darktide Mod Framework.")

		new_mod("custom_hud_patch", {
			mod_script       = "custom_hud_patch/scripts/mods/custom_hud_patch/custom_hud_patch",
			mod_data         = "custom_hud_patch/scripts/mods/custom_hud_patch/custom_hud_patch_data",
			mod_localization = "custom_hud_patch/scripts/mods/custom_hud_patch/custom_hud_patch_localization",
		})
	end,
	packages = {},
}
