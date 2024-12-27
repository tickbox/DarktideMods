local mod = get_mod("CustomLoadingBackground")

return {
	name = "CustomLoadingBackground",
	description = mod:localize("Toggle where to look for images to load"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id		= "loadLocal",
				title			= "Local Image Folder",
				type			= "checkbox",
				default_value	= false,
				tooltip			= "Load images from the CustomLoadingBackground\\Images folder"
			},
			{
				setting_id		= "loadWeb",
				title			= "Internet",
				type			= "checkbox",
				default_value	= false,
				tooltip			= "Load images hosted on the internet using URLs saved in the CustomLoadingBackground\\urls.txt file"
			},
			{
				setting_id		= "loadCurated",
				title			= "Curated",
				type			= "checkbox",
				default_value	= true,
			{
				setting_id	= "groupSlideShow",
				type		= "group",
				sub_widgets = {
					{
						setting_id		= "slideshowInterval",
						type			= "numeric",
						default_value	= 6,
						range			= { 1, 60 },
						decimals_number	= 0,
						tooltip			= "slideshowInterval"
					},
					{
						setting_id		= "toggleSlideShow",
						type			= "keybind",
						default_value	= {},
						keybind_trigger	= "pressed",
						keybind_type	= "function_call",
						function_name	= "toggleSlideShow",
					},
				}
			},
		}
	}
}
