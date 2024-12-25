local mod = get_mod("CustomLoadingBackground")

local localServer = get_mod("DarktideLocalServer")
local backgroundImageTableLocal = mod:persistent_table("backgroundImageTableLocal", {})
local backgroundImageTableWeb = mod:persistent_table("backgroundImageTableWeb", {})
local backgroundImageTableCurated = mod:persistent_table("backgroundImageTableCurated", {})
local backgroundImageTableCuratedUrls = mod:persistent_table("backgroundImageTableCuratedUrls", {})
local backgroundImageTableAll = mod:persistent_table("backgroundImageTableAll", {})
local waitTime = 2 --too many requests to the local server seem to make it stop serving images
local lastTime = os.time()
local urls = mod:io_read_content_to_table("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/urls", "txt")
local curatedLists = {}

--copy and paste the table.append line below, replacing the url with any lists you want to add
table.append(curatedLists, {"https://raw.githubusercontent.com/tickbox/DarktideMods/main/CustomLoadingBackground/scripts/mods/CustomLoadingBackground/curatedurls.txt"})

local checkDependencies = function()
	if not localServer and mod:get("loadLocal") then
		mod:set("loadLocal", false)
		mod:echo('The mod "Darktide Local Server" is required to load images from the local folder. Disabling local image loading.')
		if not mod:get("loadWeb") or not mod:get("loadCurated") then
			mod:disable_all_hooks()
			mod:disable_all_commands()
		end
	end
end

local loadLocalImages = function ()
	if localServer then
		localServer.load_directory_textures("scripts/mods/CustomLoadingBackground/Images")
			:next(function(backgroundImageFiles)
				for k, v in pairs(backgroundImageFiles) do
					if table.size(v) == 4 and not backgroundImageTableLocal[k] then
						backgroundImageTableLocal[k] = v
					else
						Managers.url_loader:unload_texture(v.url)
					end
				end
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

local loadCuratedUrls = function()
	for _, url in pairs(curatedLists) do
		Managers.backend:url_request(url)
			:next(function(data)
				if data and data.body then
					for line in data.body:gmatch("[^\r\n]+") do
						if line ~= "" and line:sub(1, 2) ~= "--" and not backgroundImageTableCuratedUrls[line] then
							backgroundImageTableCuratedUrls[line] = { loaded = false } 
						end
					end
				end
			end)
			:catch(function(error)
				mod:dump({
					time = os.time(),
					url = url,
					path = path,
					status = error.status,
					body = error.body,
					description = error.description,
					headers = error.headers,
					response_time = error.response_time,
				}, string.format("Error loading curated urls from %s", url), 8)
			end)
	end
end

local loadCuratedImages = function()
	for url, loading in pairs(backgroundImageTableCuratedUrls) do
		if not loading.loaded and not backgroundImageTableCurated[url] then
			Managers.url_loader:load_texture(url)
				:next(function(data)
					if table.size(data) == 4 and not backgroundImageTableCurated[url] then
						backgroundImageTableCurated[url] = data
						backgroundImageTableCuratedUrls[url] = { loaded = true }
					else
						Managers.url_loader:unload_texture(url)
					end
				end)
				:catch(function(error)
					mod:dump(error, "Error loading curated image", 99)
				end)
		end
	end
	
end

local loadAllImages = function()
	if table.is_empty(backgroundImageTableLocal) and (mod:get("loadLocal")) then
		loadLocalImages()
	end
	if table.is_empty(backgroundImageTableWeb) and (mod:get("loadWeb")) then
		loadWebImages()
	end
	if table.is_empty(backgroundImageTableCurated) and (mod:get("loadCurated")) then
		if table.is_empty(backgroundImageTableCuratedUrls) then
			loadCuratedUrls()
			loadCuratedImages()
		else
			loadCuratedImages()
		end
	end
	table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableLocal)
	table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableWeb)
	table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableCurated)
end

local getRandomImage = function()
	local imageKeys = {}
	imageKeys = table.keys(backgroundImageTableAll)
	return backgroundImageTableAll[imageKeys[math.random(#imageKeys)]]
end

mod.on_all_mods_loaded = function ()
	checkDependencies() 
end

--will probably change this to hook after the backend has been initialized if it can load consistently
mod.update = function()
	if lastTime + waitTime < os.time() then
		loadAllImages()
		lastTime = os.time()
	end
end

mod.on_setting_changed = function(setting_id)
	if setting_id == "loadLocal" and mod:get("loadLocal") then
		loadLocalImages()
	elseif setting_id == "loadLocal" and not mod:get("loadLocal") then
		for k, v in pairs(backgroundImageTableLocal) do
			Managers.url_loader:unload_texture(v.url)
			backgroundImageTableLocal[k] = nil
			backgroundImageTableAll[k] = nil
		end
	elseif setting_id == "loadWeb" and mod:get("loadWeb") then
		loadWebImages()
	elseif setting_id == "loadWeb" and not mod:get("loadWeb") then
		for k, v in pairs(backgroundImageTableWeb) do
			Managers.url_loader:unload_texture(v.url)
			backgroundImageTableWeb[k] = nil
			backgroundImageTableAll[k] = nil
		end
	elseif setting_id == "loadCurated" and mod:get("loadCurated") then
		loadCuratedUrls()
		loadCuratedImages()
	elseif setting_id == "loadCurated" and not mod:get("loadCurated") then
		for k, v in pairs(backgroundImageTableCurated) do
			Managers.url_loader:unload_texture(v.url)
			backgroundImageTableCurated[k] = nil
			backgroundImageTableAll[k] = nil
		end
		for k, v in pairs(backgroundImageTableCuratedUrls) do
			backgroundImageTableCuratedUrls[k] = { loaded = false }
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
	if not table.is_empty(backgroundImageTableAll) then
		for k,v in pairs(table.keys(backgroundImageTableAll)) do
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
	local img = tonumber(p)
	if img and (not mod.showBG or (mod.showBG and img)) and img > 0 then
		if not table.is_empty(backgroundImageTableAll) and img <= table.size(backgroundImageTableAll) then
			local imgKey = table.keys(backgroundImageTableAll)[img]
			mod.showBG = true
			mod.BGTexture = backgroundImageTableAll[imgKey].texture
		else --is this still needed?
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