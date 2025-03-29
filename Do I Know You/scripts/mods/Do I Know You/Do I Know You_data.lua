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
			{
				setting_id = "true_level_settings",
				type = "group",
				title = "true_level_settings_title",
				sub_widgets = {
					{
						setting_id = "tls_end_view",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_end_view_tooltip",
						title = "tls_end_view_title",
					},
					{
						setting_id = "tls_group_finder",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_group_finder_tooltip",
						title = "tls_group_finder_title",
					},
					{
						setting_id = "tls_inspect_player",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_inspect_player_tooltip",
						title = "tls_inspect_player_title",
					},
					{
						setting_id = "tls_inventory",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_inventory_tooltip",
						title = "tls_inventory_title",
					},
					{
						setting_id = "tls_lobby",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_lobby_tooltip",
						title = "tls_lobby_title",
					},
					{
						setting_id = "tls_nameplate",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_nameplate_tooltip",
						title = "tls_nameplate_title",
					},
					{
						setting_id = "tls_social_menu",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_social_menu_tooltip",
						title = "tls_social_menu_title",
					},
					{
						setting_id = "tls_team_panel",
						type = "checkbox",
						default_value = true,
						tooltip = "tls_team_panel_tooltip",
						title = "tls_team_panel_title",
					},
				},
			}
		},
	}
}
