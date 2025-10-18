local mod = get_mod("DamageNumbers")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "group_main",
                type = "group",
                title = "group_main_title",
                sub_widgets = {
                    {
                        setting_id     = "toggle_enabled_key",
                        type           = "keybind",
                        default_value  = {},
                        keybind_trigger= "pressed",
                        keybind_type   = "function_call",
                        function_name  = "toggleEnabled",
                        tooltip        = "toggle_enabled_tooltip",
                        title          = "toggle_enabled_title",
                    },
                },
            },
            {
                setting_id = "group_behavior",
                type = "group",
                title = "group_behavior_title",
                sub_widgets = {
                    {
                        setting_id    = "lifetime_seconds",
                        type          = "numeric",
                        default_value = 1.8,
                        range         = { 0.2, 5.0 },
                        decimals_number = 1,
                        tooltip       = "lifetime_seconds_tt",
                        title         = "lifetime_seconds_title",
                    },
                    {
                        setting_id    = "rise_speed_px",
                        type          = "numeric",
                        default_value = 42,
                        range         = { 10, 200 },
                        decimals_number = 0,
                        tooltip       = "rise_speed_px_tt",
                        title         = "rise_speed_px_title",
                    },
                    {
                        setting_id    = "screen_offset_y_px",
                        type          = "numeric",
                        default_value = 24,
                        range         = { 0, 200 },
                        decimals_number = 0,
                        tooltip       = "screen_offset_y_px_tt",
                        title         = "screen_offset_y_px_title",
                    },
                    {
                        setting_id    = "vertical_lift_m",
                        type          = "numeric",
                        default_value = 0.2,
                        range         = { 0.0, 1.0 },
                        decimals_number = 2,
                        tooltip       = "vertical_lift_m_tt",
                        title         = "vertical_lift_m_title",
                    },
                },
            },
            --[[ {
                setting_id = "group_appearance",
                type = "group",
                title = "group_appearance_title",
                sub_widgets = {
                    {
                        setting_id    = "text_size_base",
                        type          = "numeric",
                        default_value = 26,
                        range         = { 12, 64 },
                        decimals_number = 0,
                        tooltip       = "text_size_base_tt",
                        title         = "text_size_base_title",
                    },
                    {
                        setting_id    = "text_size_weak",
                        type          = "numeric",
                        default_value = 28,
                        range         = { 12, 64 },
                        decimals_number = 0,
                        tooltip       = "text_size_weak_tt",
                        title         = "text_size_weak_title",
                    },
                    {
                        setting_id    = "text_size_crit",
                        type          = "numeric",
                        default_value = 34,
                        range         = { 12, 64 },
                        decimals_number = 0,
                        tooltip       = "text_size_crit_tt",
                        title         = "text_size_crit_title",
                    },
                    {
                        setting_id = "group_colors",
                        type = "group",
                        title = "group_colors_title",
                        sub_widgets = {
                            { setting_id = "color_normal_r", type = "numeric", default_value = 255, range = {0,255}, decimals_number = 0, title = "color_normal_r_title" },
                            { setting_id = "color_normal_g", type = "numeric", default_value = 230, range = {0,255}, decimals_number = 0, title = "color_normal_g_title" },
                            { setting_id = "color_normal_b", type = "numeric", default_value = 50,  range = {0,255}, decimals_number = 0, title = "color_normal_b_title" },
                            { setting_id = "color_weak_r", type = "numeric", default_value = 255, range = {0,255}, decimals_number = 0, title = "color_weak_r_title" },
                            { setting_id = "color_weak_g", type = "numeric", default_value = 200, range = {0,255}, decimals_number = 0, title = "color_weak_g_title" },
                            { setting_id = "color_weak_b", type = "numeric", default_value = 80,  range = {0,255}, decimals_number = 0, title = "color_weak_b_title" },
                            { setting_id = "color_crit_r", type = "numeric", default_value = 255, range = {0,255}, decimals_number = 0, title = "color_crit_r_title" },
                            { setting_id = "color_crit_g", type = "numeric", default_value = 80,  range = {0,255}, decimals_number = 0, title = "color_crit_g_title" },
                            { setting_id = "color_crit_b", type = "numeric", default_value = 80,  range = {0,255}, decimals_number = 0, title = "color_crit_b_title" },
                        }
                    },
                },
            }, ]]
        },
    },
}