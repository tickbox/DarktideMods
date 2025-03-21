local mod = get_mod("Do I Know You")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_self",
				type = "checkbox",
				default_value = true,
				tooltip = "show_self_tooltip",
				title = "show_self_title",
			},
			{
				setting_id = "show_others",
				type = "checkbox",
				default_value = true,
				tooltip = "show_others_tooltip",
				title = "show_others_title",
			},
			{
				setting_id = "conditional_colors",
				type = "checkbox",
				default_value = false,
				tooltip = "conditional_colors_tooltip",
				title = "conditional_colors_title",
			},
			{
				setting_id = "win_bars",
				type = "checkbox",
				default_value = false,
				tooltip = "win_bars_tooltip",
				title = "win_bars_title",
			},
		},
	}
}
