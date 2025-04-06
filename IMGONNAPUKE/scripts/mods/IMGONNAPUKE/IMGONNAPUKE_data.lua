local mod = get_mod("IMGONNAPUKE")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id      = "puke_volume",
				type            = "numeric",
				range           = { 0, 100 },
				default_value   = 100,
				decimals_number = 0,
			},
			{
				setting_id		= "puke_frequency",
				type			= "numeric",
				range			= { 0, 100 },
				default_value	= 100,
				decimals_number	= 0,
			},
			{
				setting_id		= "puke_subtitles",
				type			= "checkbox",
				default_value	= true,
			},
			{
				setting_id		= "puke_subtitle_duration",
				type			= "numeric",
				range			= { 0, 10 },
				default_value	= 3,
				decimals_number	= 0,
			},
			{
				setting_id 		= "puke_death",
				type 			= "checkbox",
				default_value 	= true,
			},
			{
				setting_id		= "puke_group",
				type			= "group",
				sub_widgets		= {
					{
						setting_id		= "setting_puke1",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke2",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke3",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke4",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke5",
						type			= "checkbox",
						default_value	= true
					}
				}
			},
		},
	},
}
