local mod = get_mod("custom_hud_patch")

local show_world_markers = mod:get("show_world_markers") or true

function top_level_world_markers()
	local world_marker_widgets = {}
	if show_world_markers then
		world_marker_widgets = {
			setting_id = "show_world_markers",
			type = "checkbox",
			default_value = true,
			sub_widgets = {
				{
					setting_id = "show_smart_tagging",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "show_interaction",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "show_beacon",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "show_emote_wheel",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "show_nameplates",
					type = "checkbox",
					default_value = true,
				},
			}
		}
	else
		world_marker_widgets = {
			setting_id = "show_world_markers",
			type = "checkbox",
			default_value = true,
		}
	end

	return world_marker_widgets
end

return {
	name = "custom_hud_patch",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			top_level_world_markers()
		},
	},
}
