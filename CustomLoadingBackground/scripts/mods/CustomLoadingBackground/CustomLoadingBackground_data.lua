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
				default_value	= true,
				tooltip			= "Load images hosted on the internet using URLs saved in the CustomLoadingBackground\\urls.txt file"
			},
		}
	}
}
