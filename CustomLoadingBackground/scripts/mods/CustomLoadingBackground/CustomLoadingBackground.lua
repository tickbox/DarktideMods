--needs a major refactor, but it works for now
local mod = get_mod("CustomLoadingBackground")

local localServer = get_mod("DarktideLocalServer")
local backgroundImageTableLocal = mod:persistent_table("backgroundImageTableLocal", {})
local backgroundImageTableWeb = mod:persistent_table("backgroundImageTableWeb", {})
local backgroundImageTableCurated = mod:persistent_table("backgroundImageTableCurated", {})
local backgroundImageTableCuratedUrls = mod:persistent_table("backgroundImageTableCuratedUrls", {})
local backgroundImageTableAll = mod:persistent_table("backgroundImageTableAll", {})
local waitTime = 2 --too many requests to the local server seem to make it stop serving images
local lastTime = os.time()
local waitTimeLoading = mod:get("cycleImageLoadingInterval")
local waitTimeSlideshow = mod:get("slideshowInterval")
local lastTimeSlideshow = os.time()
mod.cycleImageLoading = mod:get("cycleImageLoading")
local loadingView = false
local urls = mod:io_read_content_to_table("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/urls", "txt")
local curatedLists = {}

--copy and paste the table.append line below, replacing the url with any lists you want to add
table.append(curatedLists, {"https://raw.githubusercontent.com/tickbox/DarktideMods/main/CustomLoadingBackground/scripts/mods/CustomLoadingBackground/curatedurls.txt"})
table.append(curatedLists, {"https://raw.githubusercontent.com/Backup158/DarktideCustomLoadingBackgroundsList/refs/heads/main/urls.txt"})

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
	mod.imgKey = imageKeys[math.random(1, #imageKeys)]
	return backgroundImageTableAll[mod.imgKey]
end

mod.on_all_mods_loaded = function ()
	checkDependencies() 
end

mod.update = function()
	if lastTime + waitTime < os.time() and Managers.backend._initialized then
		loadAllImages()
		lastTime = os.time()
	end
	if lastTimeSlideshow + waitTimeSlideshow < os.time() and mod.slideshow and not loadingView then
		mod.cycleImageSlideshow()
		lastTimeSlideshow = os.time()
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
	--should probably add a check to not unload images that are in both web and curated lists
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
	elseif setting_id == "cycleImageLoadingInterval" then
		waitTimeLoading = mod:get("cycleImageLoadingInterval")
	elseif setting_id == "slideshowInterval" then
		waitTimeSlideshow = mod:get("slideshowInterval")
	end
end

mod:hook_safe("LoadingView", "on_enter", function(self)
	loadingView = true
	mod.showBG = true
	if mod:get("cycleImageLoading") then
		lastTimeSlideshow = os.time()
	end
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

mod:hook_safe("LoadingView", "update", function(self)
	if not mod.imgKey then
		return
	end

	if lastTimeSlideshow + waitTimeLoading < os.time() and mod.cycleImageLoading and loadingView then
		mod.cycleImageSlideshow()
		lastTimeSlideshow = os.time()
	end

	local backgroundWidget = self._widgets_by_name.background
	local backgroundStyle = backgroundWidget.style.style_id_1

	if not backgroundStyle.material_values then
        backgroundStyle.material_values = {}
    end

	backgroundStyle.material_values.texture_map = backgroundImageTableAll[mod.imgKey].texture
end)

mod:hook_safe("LoadingView", "on_exit", function(self)
	loadingView = false
	mod.showBG = false
	mod.slideshow = false
end)

mod.showBG = false
mod.slideshow = false

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
mod:command("bg", "View a background (usage: /bg #)", function(p)
	local img = tonumber(p)
	if img and (not mod.showBG or (mod.showBG and img)) and img > 0 then
		if not table.is_empty(backgroundImageTableAll) and img <= table.size(backgroundImageTableAll) then
			mod.imgKey = table.keys(backgroundImageTableAll)[img]
			mod.showBG = true
			mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		else --is this still needed?
			mod.showBG = true
			loadAllImages()
		end
		Managers.ui:open_view("SlideShow_View")
	elseif Managers.ui:view_instance("SlideShow_View") then
		Managers.ui:close_view("SlideShow_View")
		mod.showBG = false
		mod.slideshow = false
	else
		mod.showBG = false
		mod.slideshow = false
	end
 end)

 --is this really needed?
 mod:command("bgfolder", "Show the location of the folder where images are stored", function()
	mod:echo(localServer:get_root_mods_path():gsub('"', '') .. "\\CustomLoadingBackground\\scripts\\mods\\CustomLoadingBackground\\Images")
 end)

 mod:command("bgss", "Start a slideshow of all images (usage: /bgss to open)", function()
	mod.toggleSlideShowView()
 end)

local getNextImage = function(n)
	local imageKeys = {}
	imageKeys = table.keys(backgroundImageTableAll)
	local currentIndex = table.find(imageKeys, mod.imgKey)
	local nextIndex = currentIndex + n
	if nextIndex > #imageKeys then
		nextIndex = nextIndex - #imageKeys
	elseif nextIndex < 1 then
		nextIndex = #imageKeys - nextIndex
	end
	return imageKeys[nextIndex]
end

function mod.toggleBackground()
	if not loadingView then
		if not mod.showBG then
			local randomImage = getRandomImage()
			if not randomImage then
				return
			end
			mod.showBG = true
			mod.BGTexture = randomImage.texture
		else
			mod.showBG = false
		end
	end
end

function mod.cycleImageSlideshow()
	if mod.imgKey and mod.showBG and (mod.slideshow or mod.cycleImageLoading) then
		local imgCount = table.size(backgroundImageTableAll)
		mod.imgKey = getNextImage(math.random(1, imgCount))
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
	end
end

function mod.cycleImageNext()
	if mod.imgKey and mod.showBG then
		mod.imgKey = getNextImage(1)
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		lastTimeSlideshow = os.time()
	end
end

function mod.cycleImagePrev()
	if mod.imgKey and mod.showBG then
		mod.imgKey = getNextImage(-1)
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		lastTimeSlideshow = os.time()
	end
end

local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local WwiseGameSyncSettings = require("scripts/settings/wwise_game_sync/wwise_game_sync_settings")

mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/SlideShowView")

local SlideShowViewRegisteredCorrectly = mod:register_view({
	view_name = "SlideShow_View",
	view_settings = {
		init_view_function = function(ingame_ui_context)
			return true
		end,
		state_bound = true,
		path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/SlideShowView",
		class = "SlideShowView",
		disable_game_world = false,
		load_always = true,
		load_in_hub = true,
		game_world_blur = 0,
		enter_sound_events = {
			UISoundEvents.system_menu_enter,
		},
		exit_sound_events = {
			UISoundEvents.system_menu_exit,
		},
		wwise_states = {
			options = WwiseGameSyncSettings.state_groups.options.ingame_menu,
		},
	},
	view_transitions = {},
	view_options = {
		close_all = false,
		close_previous = false,
		close_transition_time = nil,
		transition_time = nil,
	},
})

mod.toggleSlideShowView = function()
	if
		not Managers.ui:has_active_view()
		and not Managers.ui:chat_using_input()
		and not Managers.ui:view_instance("SlideShow_View")
	then
		mod.showBG = true
		mod.slideshow = true
		
		local randomImage = getRandomImage()
		if not randomImage then
			return
		end
		lastTimeSlideshow = os.time()
		mod.BGTexture = randomImage.texture

		Managers.ui:open_view("SlideShow_View")
	elseif Managers.ui:view_instance("SlideShow_View") then
		Managers.ui:close_view("SlideShow_View")
		mod.showBG = false
		mod.slideshow = false
	end
end

mod:command("open_slideshow_view", "Open the slideshow view", function()
	mod.toggleSlideShowView()
end)