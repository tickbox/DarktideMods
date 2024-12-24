local mod = get_mod("IMGONNAPUKE")

return {
	name = "IMGONNAPUKE",
	description = mod:localize("PUKE SETTINGS"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id      = "puke_volume",
				title           = "PUKE VOLUME",
				type            = "numeric",
				range           = { 0, 100 },
				tooltip         = "IM GONNA PUKE",
				default_value   = 100,
				decimals_number = 0,
			},
			{
				setting_id		= "puke_frequency",
				title			= "PUKE FREQUENCY",
				type			= "numeric",
				range			= { 0, 100 },
				tooltip			= "IM GONNA PUKE IM GONNA PUKE",
				default_value	= 100,
				decimals_number	= 0,
			},
			{
				setting_id		= "puke_group",
				title			= "PUKE TOGGLE",
				type			= "group",
				sub_widgets		= {
					{
						setting_id		= "setting_puke1",
						title			= "IM GONNA FUCKIN PUKE",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke2",
						title			= "IM GONNA PUKE IM GONNA PUKE",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke3",
						title			= "IM GONNA FUCKIN THROW UP",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke4",
						title			= "IM GONNA FUCKING PUKE PLEASE",
						type			= "checkbox",
						default_value	= true
					},
					{
						setting_id		= "setting_puke5",
						title			= "BLUH BLUH BLUH BLUH",
						type			= "checkbox",
						default_value	= true
					}
				}
			}
		},
	},
}
