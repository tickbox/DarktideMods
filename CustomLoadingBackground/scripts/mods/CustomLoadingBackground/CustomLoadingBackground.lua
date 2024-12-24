local mod = get_mod("CustomLoadingBackground")

local localServer = get_mod("DarktideLocalServer")
local backgroundImageTableLocal = mod:persistent_table("backgroundImageTableLocal", {})
local backgroundImageTableWeb = mod:persistent_table("backgroundImageTableWeb", {})
local urls = mod:io_read_content_to_table("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/urls", "txt")

local checkDependencies = function()
	if not localServer and mod:get("loadLocal") then
		mod:set("loadLocal", false)
		mod:echo('The mod "Darktide Local Server" is required to load images from the local folder. Disabling local image loading.')
		if not mod:get("loadWeb") then
			mod:disable_all_hooks()
			mod:disable_all_commands()
		end
	end
end

local loadLocalImages = function ()
	if localServer then
		localServer.load_directory_textures("scripts/mods/CustomLoadingBackground/Images")
			:next(function(backgroundImageFiles)
				table.merge(backgroundImageTableLocal, backgroundImageFiles)
			end)
			:catch(function(error)
				mod:dtf(error,"Error loading images",99)
			end)
	else
		mod:echo('The mod "Darktide Local Server" is required to load images from the local folder.')
		mod:set("loadLocal", false)
	end
end

local loadWebImages = function ()
	for _, url in pairs(urls) do
		Managers.url_loader:load_texture(url)
			:next(function(data)
				--if the size is 4, the image is valid
				if table.size(data) == 4 and not backgroundImageTableWeb[url] then
					backgroundImageTableWeb[url] = data
				else
					--if the texture url is still in cache, it will not try to load again
					Managers.url_loader:unload_texture(url)
				end
			end)
			:catch(function(error)
				mod:dtf(error, "Error loading test image", 99)
			end)
	end
end

local loadAllImages = function()
	if (mod:get("loadLocal")) then
		loadLocalImages()
	end
	if (mod:get("loadWeb")) then
		loadWebImages()
	end
end

local getRandomImage = function()
	local imageKeys = {}
	local allBackgroundImages = {}
	table.merge(allBackgroundImages, backgroundImageTableLocal)
	table.merge(allBackgroundImages, backgroundImageTableWeb)
	imageKeys = table.keys(allBackgroundImages)
	return allBackgroundImages[imageKeys[math.random(#imageKeys)]]
end

mod.on_all_mods_loaded = function ()
	checkDependencies() 
	loadAllImages() --not really needed unless you manually reload mods
end

mod.on_game_state_changed = function(status, state)
	if table.is_empty(backgroundImageTableLocal) and mod:get("loadLocal") then
		loadLocalImages()
	end
	--need to add a check for all images loaded
	if table.is_empty(backgroundImageTableWeb) and mod:get("loadWeb") then
		loadWebImages()
	end
end

mod.on_setting_changed = function(setting_id)
	--mod:echo("Setting changed: " .. setting_id .. " to " .. tostring(mod:get(setting_id)))
	if setting_id == "loadLocal" and mod:get("loadLocal") then
		loadLocalImages()
	elseif setting_id == "loadLocal" and not mod:get("loadLocal") then
		for k, v in pairs(backgroundImageTableLocal) do
			Managers.url_loader:unload_texture(v.url)
			backgroundImageTableLocal[k] = nil
		end
	elseif setting_id == "loadWeb" and mod:get("loadWeb") then
		loadWebImages()
	elseif setting_id == "loadWeb" and not mod:get("loadWeb") then
		for k, v in pairs(backgroundImageTableWeb) do
			Managers.url_loader:unload_texture(v.url)
			backgroundImageTableWeb[k] = nil
		end
	end
end

mod:hook_safe("LoadingView", "on_enter", function(self)
	local randomImage = getRandomImage()
	if not randomImage then
		return
	end
	
	local backgroundWidget = self._widgets_by_name.background
	local backgroundStyle = backgroundWidget.style.style_id_1

	if not backgroundStyle.material_values then
        backgroundStyle.material_values = {}
    end

	--this is where the magic happens
	backgroundStyle.material_values.texture_map = randomImage.texture
end)

mod.showBG = false
mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Modules/BackgroundElement")

mod:hook("UIHud", "init", function(func, self, elements, visibility_groups, params)
	if not table.find_by_key(elements, "class_name", "BackgroundElement") then
		table.insert(elements, {
			class_name = "BackgroundElement",
			filename = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Modules/BackgroundElement",
			use_hud_scale = true,
			visibility_groups = { "alive" },
		})
	end

	return func(self, elements, visibility_groups, params)
end)

mod:command("bglist", "List all available backgrounds", function()
	local allBackgroundImages = {}
	table.merge(allBackgroundImages, backgroundImageTableLocal)
	table.merge(allBackgroundImages, backgroundImageTableWeb)
	if not table.is_empty(allBackgroundImages) then
		for k,v in pairs(table.keys(allBackgroundImages)) do
			mod:echo(k .. ": " .. v)
		end
	else
		mod:echo("No images loaded")
	end
end)

--[[
At some point there will be a command to show all images and select which to use.
For now it will just show a single image based on the index given.

Use /bglist to see the list of images and their index.

]] 
mod:command("bg", "View a background (usage: /bg # and /bg to close)", function(p)
	img = tonumber(p)
	if img and (not mod.showBG or (mod.showBG and img)) then
		local allBackgroundImages = {}
		table.merge(allBackgroundImages, backgroundImageTableLocal)
		table.merge(allBackgroundImages, backgroundImageTableWeb)
		if not table.is_empty(allBackgroundImages) and img <= table.size(allBackgroundImages) then
			local imgKey = table.keys(allBackgroundImages)[img]
			mod.showBG = true
			mod.BGTexture = allBackgroundImages[imgKey].texture
		else
			mod.showBG = true
			loadAllImages()
		end
	else
		mod.showBG = false
	end
 end)

 --is this really needed?
 mod:command("bgfolder", "Show the location of the folder where images are stored", function()
	mod:echo(localServer:get_root_mods_path():gsub('"', '') .. "\\CustomLoadingBackground\\scripts\\mods\\CustomLoadingBackground\\Images")
 end)