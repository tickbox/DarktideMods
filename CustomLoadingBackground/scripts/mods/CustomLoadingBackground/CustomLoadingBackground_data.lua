local mod = get_mod("CustomLoadingBackground")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			--[[ {
				setting_id	= "groupLoading",
				type		= "group",
				sub_widgets = {
					{
						setting_id		= "loadLocal",
						type			= "checkbox",
						default_value	= false,
						tooltip			= "loadLocalTooltip"
					},
					{
						setting_id		= "loadWeb",
						type			= "checkbox",
						default_value	= false,
						tooltip			= "loadWebTooltip"
					},
					{
						setting_id		= "loadCurated",
						type			= "checkbox",
						default_value	= true,
						tooltip			= "loadCuratedTooltip"
					},
				}
			}, ]]
			{
				setting_id	= "groupCycleImages",
				type		= "group",
				sub_widgets = {
					{
						setting_id		= "cycleImageLoading",
						type			= "checkbox",
						default_value	= true,
						tooltip			= "cycleImageLoadingTooltip"
					},
					{
						setting_id		= "cycleImageLoadingInterval",
						type			= "numeric",
						default_value	= 5,
						range			= { 1, 60 },
						decimals_number	= 0,
					},
					{
						setting_id		= "cycleImageNext",
						type			= "keybind",
						default_value	= {},
						keybind_trigger	= "pressed",
						keybind_type	= "function_call",
						function_name	= "cycleImageNext",
					},
					{
						setting_id		= "cycleImagePrev",
						type			= "keybind",
						default_value	= {},
						keybind_trigger	= "pressed",
						keybind_type	= "function_call",
						function_name	= "cycleImagePrev",
					},
				}
			},
			{
				setting_id	= "groupSlideShow",
				type		= "group",
				sub_widgets = {
					{
						setting_id		= "slideshowInterval",
						type			= "numeric",
						default_value	= 8,
						range			= { 1, 60 },
						decimals_number	= 0,
					},
					{
						setting_id		= "toggleSlideShow",
						type			= "keybind",
						default_value	= {},
						keybind_trigger	= "pressed",
						keybind_type	= "function_call",
						function_name	= "toggleSlideShowView",
					},
				}
			},
		}
	}
}
