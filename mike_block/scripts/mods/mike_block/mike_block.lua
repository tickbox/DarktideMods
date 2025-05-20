local mod = get_mod("mike_block")

local Audio = get_mod("Audio")

local files = {}
for i = 1, 17 do
    files[#files + 1] = ("audio/mb%d.mp3"):format(i)
end

mod.on_all_mods_loaded = function()
    mod:hook_safe(CLASS.ExtensionSystemBase, "on_add_extension", function(_, _, unit, extension_name, p1)
        if extension_name == "ProjectileFxExtension" then
            if p1.projectile_template_name == "psyker_throwing_knives" then
                Audio.play_file(files[math.random(#files)], { volume = mod:get("volume") }, p1.owner_unit, mod:get("decay")/100)    
            end
        end
    end)
end