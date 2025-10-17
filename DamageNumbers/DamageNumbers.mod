return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`DamageNumbers` encountered an error loading the Darktide Mod Framework.")

		new_mod("DamageNumbers", {
			mod_script       = "DamageNumbers/scripts/mods/DamageNumbers/DamageNumbers",
			mod_data         = "DamageNumbers/scripts/mods/DamageNumbers/DamageNumbers_data",
			mod_localization = "DamageNumbers/scripts/mods/DamageNumbers/DamageNumbers_localization",
		})
	end,
	load_after = {
	},
	require = {
	},
	packages = {},
}
