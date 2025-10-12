local mod = get_mod("mike_block")

return {
	name = "mike_block",
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "volume",
				type = "numeric",
				range = { 0, 100 },
				default_value = 100,
				decimals_number = 0,
			},
			{
				setting_id = "decay",
				tooltip = "How fast the volume will decay",
				type = "numeric",
				range = { 0, 5 },
				default_value = 3,
				decimals_number = 0,
			}
		}
	}
}
