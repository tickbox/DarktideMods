local mod = get_mod("CustomLoadingBackground")

local localServer = get_mod("DarktideLocalServer")

local backgroundImageTableLocal = mod:persistent_table("backgroundImageTableLocal", {})
local backgroundImageTableWeb = mod:persistent_table("backgroundImageTableWeb", {})
local backgroundImageTableCurated = mod:persistent_table("backgroundImageTableCurated", {})
local backgroundImageTableCuratedUrls = mod:persistent_table("backgroundImageTableCuratedUrls", {})
local backgroundImageTableAll = mod:persistent_table("backgroundImageTableAll", {})

local imageEnabled = mod:persistent_table("imageEnabled", {})

mod._queue_mode = true
mod._image_queue = mod._image_queue or {}
mod._available_pool = mod._available_pool or {}
mod._queue_target_size = 3
mod._queue_loading = mod._queue_loading or {}
mod._queue_initialized = false
mod._queue_index = mod._queue_index or 1
mod._queue_pending_next = false
mod._queue_gen = mod._queue_gen or 0

local _queue_compact
local waitTime = 2 --too many requests to the local server seem to make it stop serving images
local lastTime = os.time()
local waitTimeLoading = mod:get("cycleImageLoadingInterval")
local waitTimeSlideshow = mod:get("slideshowInterval")
local lastTimeSlideshow = os.time()
mod.cycleImageLoading = mod:get("cycleImageLoading")
local loadingView = false

mod.curatedLists = {}
table.insert(mod.curatedLists, {"https://raw.githubusercontent.com/tickbox/DarktideMods/main/CustomLoadingBackground/scripts/mods/CustomLoadingBackground/curatedurls.txt", true})
table.insert(mod.curatedLists, {"https://raw.githubusercontent.com/Backup158/DarktideCustomLoadingBackgroundsList/refs/heads/main/urls.txt", true})

local function _disabled_set()
	local list = mod:get("disabledImageKeys") or {}
	local set = {}
	for i = 1, #list do set[list[i]] = true end
	return set
end

local function _prioritize_list(list)
	local set = _disabled_set()
	local arr = {}
	for i = 1, #list do arr[i] = list[i] end
	table.sort(arr, function(a, b)
		local a_en = not set[a]
		local b_en = not set[b]
		if a_en == b_en then
			return tostring(a) < tostring(b)
		end
		return a_en and not b_en
	end)
	return arr
end

local function persist_enabled_state()
	local disabled = {}
	for k, v in pairs(imageEnabled) do
		if v == false then
			disabled[#disabled+1] = k
		end
	end
	mod:set("disabledImageKeys", disabled)
end

mod.persist_enabled_state = persist_enabled_state

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
				local keys = table.keys(backgroundImageFiles)
				keys = _prioritize_list(keys)
				for _, k in ipairs(keys) do
					local v = backgroundImageFiles[k]
					if table.size(v) == 4 and not backgroundImageTableLocal[k] then
						backgroundImageTableLocal[k] = v
					else
						if v and v.url then Managers.url_loader:unload_texture(v.url) end
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

local function _enabled_url_rows()
	local ok, rows = pcall(function() return mod:get("urls_rows") end)
	if not ok or type(rows) ~= "table" then return {} end
	local out = {}
	for _, r in ipairs(rows) do
		if type(r) == "table" then
			local u = r.url or r[1]
			local en = r.enabled; if en == nil then en = true end
			if u and u ~= "" and en then out[#out+1] = u end
		elseif type(r) == "string" and r ~= "" then
			out[#out+1] = r
		end
	end
	return out
end

local loadWebImages = function ()
	if mod._queue_mode and not mod._manager_full_load then return end
	local active = _enabled_url_rows()
	if #active == 0 then return end
	local ordered = _prioritize_list(active)
	local existing = {}
	for k,_ in pairs(backgroundImageTableWeb) do existing[k] = true end
	for _, url in ipairs(ordered) do
		existing[url] = nil
		if not backgroundImageTableWeb[url] then
			if imageEnabled[url] == false and not mod._manager_full_load then
				backgroundImageTableWeb[url] = nil
			else
				Managers.url_loader:load_texture(url)
					:next(function(data)
						if table.size(data) == 4 and not backgroundImageTableWeb[url] and (imageEnabled[url] ~= false or mod._manager_full_load) then
							backgroundImageTableWeb[url] = data
						else
							Managers.url_loader:unload_texture(url)
						end
					end)
					:catch(function(error)
						mod:dtf(error, "Error loading web image", 99)
					end)
			end
		end
	end
	for stale,_ in pairs(existing) do
		local tex = backgroundImageTableWeb[stale]
		if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
		backgroundImageTableWeb[stale] = nil
		backgroundImageTableAll[stale] = nil
	end
end

local function _enabled_curated_rows()
	local ok, rows = pcall(function() return mod:get("curated_rows") end)
	local out_builtin = {}
	local out_user = {}
	if ok and type(rows) == "table" then
		for _, r in ipairs(rows) do
			if type(r) == "table" and r.url and r.url ~= "" then
				local en = r.enabled; if en == nil then en = true end
				if en then
					if r.builtin then out_builtin[#out_builtin+1] = r.url else out_user[#out_user+1] = r.url end
				end
			end
		end
	end
	local builtin_fixed = {}
	for _, u in pairs(mod.curatedLists) do table.insert(builtin_fixed, u[1]) end
	local ordered = {}
	local set_builtin = {}
	for _, u in ipairs(out_builtin) do set_builtin[u] = true end
	for _, b in ipairs(builtin_fixed) do if set_builtin[b] then ordered[#ordered+1] = b end end
	for _, u in ipairs(out_user) do ordered[#ordered+1] = u end
	return ordered
end

local loadCuratedUrls = function()
    local sources = _enabled_curated_rows()
    if #sources == 0 then return end
    local existing_source = {}
    for k, meta in pairs(backgroundImageTableCuratedUrls) do
        if meta and meta.is_source then
            existing_source[k] = true
        end
    end
    for _, src in ipairs(sources) do
        existing_source[src] = nil
        if not backgroundImageTableCuratedUrls[src] or not backgroundImageTableCuratedUrls[src].queried then
            Managers.backend:url_request(src)
                :next(function(data)
                    if data and data.body then
                        for line in data.body:gmatch("[^\r\n]+") do
                            if line ~= "" and line:sub(1,2) ~= "--" then
                                local existing = backgroundImageTableCuratedUrls[line]
                                if not existing then
                                    backgroundImageTableCuratedUrls[line] = { loaded = false, source = src }
                                elseif existing and not existing.source then
                                    existing.source = src
                                end
                            end
                        end
                        backgroundImageTableCuratedUrls[src] = { queried = true, is_source = true }
                    end
                end)
                :catch(function(error)
                    mod:dump(error, string.format("Error loading curated urls from %s", src), 8)
                end)
        end
    end
    for stale,_ in pairs(existing_source) do
        local meta = backgroundImageTableCuratedUrls[stale]
        if meta and meta.is_source then
            backgroundImageTableCuratedUrls[stale] = nil
        end
    end
end

local loadCuratedImages = function()
	if mod._queue_mode and not mod._manager_full_load then return end
	local keys = table.keys(backgroundImageTableCuratedUrls)
	keys = _prioritize_list(keys)
	for _, url in ipairs(keys) do
		local loading = backgroundImageTableCuratedUrls[url]
		if loading
			and not loading.is_source
			and not loading.loaded
			and not backgroundImageTableCurated[url]
			and backgroundImageTableCuratedUrls[url]  -- guard instead of goto
		then
			local current_loading_ref = loading
			Managers.url_loader:load_texture(url)
				:next(function(data)
					local meta_now = backgroundImageTableCuratedUrls[url]
					if not meta_now or meta_now ~= current_loading_ref then
						if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
						return
					end
					if table.size(data) == 4
						and not backgroundImageTableCurated[url]
						and (imageEnabled[url] ~= false or mod._manager_full_load)
					then
						backgroundImageTableCurated[url] = data
						backgroundImageTableCuratedUrls[url].loaded = true
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
    loadWebImages()
	loadCuratedUrls()
    loadCuratedImages()
    table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableLocal)
    table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableWeb)
    table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableCurated)

	local persisted = mod:get("disabledImageKeys") or {}
	for i = 1, #persisted do
		local key = persisted[i]
		if backgroundImageTableAll[key] ~= nil then
			imageEnabled[key] = false
		end
	end

	for k,_ in pairs(backgroundImageTableAll) do
		if imageEnabled[k] == nil then imageEnabled[k] = true end
	end

	mod._last_active_web_sources = _enabled_url_rows()
	mod._last_active_curated_sources = _enabled_curated_rows()
end

local function _enabled_image_keys()
	local keys = {}
	for k,_ in pairs(backgroundImageTableAll) do
		if imageEnabled[k] then
			keys[#keys+1] = k
		end
	end
	return keys
end

function mod.refresh_sources_from_view()
    local function list_to_set(t)
        local s = {}
        for _, v in ipairs(t or {}) do s[v] = true end
        return s
    end
    local prev_web = list_to_set(mod._last_active_web_sources)
    local prev_cur = list_to_set(mod._last_active_curated_sources)
    local new_web_arr = _enabled_url_rows()
    local new_cur_arr = _enabled_curated_rows()
    local new_web = list_to_set(new_web_arr)
    local new_cur = list_to_set(new_cur_arr)
    local changed = false
    for k,_ in pairs(prev_web) do if not new_web[k] then changed = true break end end
    if not changed then for k,_ in pairs(new_web) do if not prev_web[k] then changed = true break end end end
    if not changed then for k,_ in pairs(prev_cur) do if not new_cur[k] then changed = true break end end end
    if not changed then for k,_ in pairs(new_cur) do if not prev_cur[k] then changed = true break end end end
    if not changed then return false end

    for url,_ in pairs(prev_web) do
        if not new_web[url] then
            local tex = backgroundImageTableWeb[url]
            if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
            backgroundImageTableWeb[url] = nil
            backgroundImageTableAll[url] = nil
        end
    end
    for src,_ in pairs(prev_cur) do
        if not new_cur[src] then
            for url, meta in pairs(backgroundImageTableCuratedUrls) do
                if meta and meta.source == src then
                    if meta.loaded and backgroundImageTableCurated[url] then
                        local tex = backgroundImageTableCurated[url]
                        if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
                        backgroundImageTableCurated[url] = nil
                        backgroundImageTableAll[url] = nil
                    end
                    backgroundImageTableCuratedUrls[url] = nil
                end
            end
            backgroundImageTableCuratedUrls[src] = nil
        end
    end

	if mod._queue_mode then
		loadCuratedUrls()
		_rebuild_available_pool()
		if #mod._image_queue == 0 and mod.ensure_queue_seeded then mod.ensure_queue_seeded() end
	else
		loadWebImages()
		loadCuratedUrls()
		loadCuratedImages()
	end

	if not mod._queue_mode then
		local active_keys = {}
		for k,_ in pairs(backgroundImageTableLocal) do active_keys[k] = true end
		for k,_ in pairs(backgroundImageTableWeb) do active_keys[k] = true end
		for k,_ in pairs(backgroundImageTableCurated) do active_keys[k] = true end
		for k,_ in pairs(backgroundImageTableAll) do if not active_keys[k] then backgroundImageTableAll[k] = nil end end
		table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableLocal)
		table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableWeb)
		table.add_missing_recursive(backgroundImageTableAll, backgroundImageTableCurated)
		local persisted_disabled = mod:get("disabledImageKeys") or {}
		local disabled_lookup = {}
		for i=1,#persisted_disabled do disabled_lookup[persisted_disabled[i]] = true end
		for key,_ in pairs(backgroundImageTableAll) do
			if disabled_lookup[key] then imageEnabled[key] = false end
		end
		for k,_ in pairs(backgroundImageTableAll) do if imageEnabled[k] == nil then imageEnabled[k] = true end end
		for k,_ in pairs(imageEnabled) do if not backgroundImageTableAll[k] then imageEnabled[k] = nil end end
		persist_enabled_state()
	else
		local persisted_disabled = mod:get("disabledImageKeys") or {}
		for i=1,#persisted_disabled do
			local key = persisted_disabled[i]
			imageEnabled[key] = false
		end
		for k,v in pairs(imageEnabled) do
			if v ~= false and not backgroundImageTableAll[k] then
				imageEnabled[k] = nil
			end
		end
		persist_enabled_state()
	end
    persist_enabled_state()
    mod._last_active_web_sources = new_web_arr
    mod._last_active_curated_sources = new_cur_arr
    return true
end

local function _pick_random_enabled_key()
	local keys = _enabled_image_keys()
	if #keys == 0 then return nil end
	return keys[math.random(1, #keys)]
end

local getRandomImage = function()
	if mod._queue_mode then
		if mod.ensure_queue_seeded then mod.ensure_queue_seeded() end
		if #mod._image_queue > 0 then
			local first = mod._image_queue[1]
			mod.imgKey = first.key
			return first.data
		else
			return nil
		end
	end
	local key = _pick_random_enabled_key()
	if not key then
		mod:echo("No enabled images available. Use /bgmanage to enable some.")
		return nil
	end
	mod.imgKey = key
	return backgroundImageTableAll[key]
end

function mod.ensure_queue_seeded()
	if not mod._queue_mode then return end
	if not Managers.backend or not Managers.backend._initialized then return end
	if #mod._available_pool == 0 then _rebuild_available_pool() end
	if #mod._image_queue >= mod._queue_target_size then return end
	local attempts = 0
	while #mod._image_queue < mod._queue_target_size and #mod._available_pool > 0 do
		attempts = attempts + 1
		local idx = math.random(1, #mod._available_pool)
		local url = table.remove(mod._available_pool, idx)
		_load_url_into_queue(url)
		if attempts > 10 then break end
	end
	mod._queue_initialized = true
	if not mod.imgKey and #mod._image_queue > 0 then
		mod._queue_index = 1
		local e = mod._image_queue[1]
		mod.imgKey = e.key
		mod.BGTexture = e.data.texture
	end
end

mod.on_all_mods_loaded = function ()
	checkDependencies() 
	if not mod:get("clb_initialized_sources") then
		local changed = false
		
		if localServer and mod:get("loadLocal") ~= true then
			mod:set("loadLocal", true)
			changed = true
		end
		
		local existing_curated = mod:get("curated_rows")
		if not existing_curated or #existing_curated == 0 then
			local default_curated = {}
			for _, entry in ipairs(mod.curatedLists) do
				local url = entry[1]
				if url and url ~= "" then
					default_curated[#default_curated+1] = { url = url, enabled = true, builtin = true }
				end
			end
			if #default_curated > 0 then
				mod:set("curated_rows", default_curated)
				changed = true
			end
		end
		if changed then
			mod:set("clb_initialized_sources", true)
			pcall(function() loadCuratedUrls() end)

			if not mod._queue_mode then
				pcall(function() loadAllImages() end)
			end
		else
			mod:set("clb_initialized_sources", true)
		end
	end
	
	if mod._queue_mode then
		for k, tex in pairs(backgroundImageTableWeb) do
			if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
			backgroundImageTableWeb[k] = nil
			backgroundImageTableAll[k] = nil
		end
		for k, tex in pairs(backgroundImageTableCurated) do
			if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
			backgroundImageTableCurated[k] = nil
			backgroundImageTableAll[k] = nil
		end
		
		mod._image_queue = {}
		mod._available_pool = {}
		mod._queue_index = 1
		mod._queue_gen = (mod._queue_gen + 1) % 1000000
		if _rebuild_available_pool then _rebuild_available_pool() end
		mod._queue_initialized = false
	end
end

function mod.get_all_background_images()
	return backgroundImageTableAll
end

function mod.get_manager_loading_status()
	if not mod._manager_full_load then
		return { active = false, loaded = 0, total = 0, done = true, inflight = 0, failed = 0 }
	end
	local total, loaded, failed = 0, 0, 0
	
	local web_rows = _enabled_url_rows()
	for i=1,#web_rows do
		local url = web_rows[i]
		total = total + 1
		local ent = backgroundImageTableWeb[url]
		if ent and ent.texture then loaded = loaded + 1 end
	end
	
	for url, meta in pairs(backgroundImageTableCuratedUrls) do
		if meta then
			total = total + 1
			if meta.failed then failed = failed + 1 end
			local ent = backgroundImageTableCurated[url]
			if ent and ent.texture then loaded = loaded + 1 end
		end
	end
	
	for _, ent in pairs(backgroundImageTableLocal) do
		total = total + 1
		if ent and ent.texture then loaded = loaded + 1 end
	end
	local inflight = mod._manager_inflight or 0
	local done = (total > 0) and (loaded + failed >= total) and inflight == 0
	return { active = true, loaded = loaded, total = total, done = done, inflight = inflight, failed = failed }
end

function mod.notify_images_populated()
	local view = Managers.ui and Managers.ui:view_instance("CLBImageManagerView")
	if view then
		if view._rebuild_cards then
			view:_rebuild_cards()
		elseif view._rebuild_rows then
			view:_rebuild_rows()
		end
	end
end


mod.update = function(self, dt)
	if mod._manager_full_load and Managers.backend._initialized then
		loadAllImages()
		lastTime = os.time()
	elseif lastTime + waitTime < os.time() and Managers.backend._initialized then
		if mod._queue_mode and not mod._manager_full_load then
			if not mod._queue_initialized then
				loadCuratedUrls()
				_rebuild_available_pool()
				for i=1,mod._queue_target_size do
					if #mod._available_pool == 0 then _rebuild_available_pool() end
					if #mod._available_pool == 0 then break end
					local idx = math.random(1, #mod._available_pool)
					local url = table.remove(mod._available_pool, idx)
					_load_url_into_queue(url)
				end
				mod._queue_initialized = true
			else
				loadCuratedUrls()
			end
		else
			loadAllImages()
		end
		lastTime = os.time()
	end
	if lastTimeSlideshow + waitTimeSlideshow < os.time() and mod.slideshow and not loadingView then
		mod.cycleImageSlideshow()
		lastTimeSlideshow = os.time()
	end

	if mod._slideshow_waiting_first and mod.slideshow and not mod.BGTexture then
		local img = getRandomImage()
		if img and img.texture then
			mod.BGTexture = img.texture
			mod._slideshow_waiting_first = nil
			lastTimeSlideshow = os.time()
		end
	end

	if not mod._manager_populated_once and not table.is_empty(backgroundImageTableAll) then
		mod._manager_populated_once = true
		mod.notify_images_populated()
	end

	if mod._slideshow_wait_frames then
		local ui = Managers.ui
		if ui and not ui:view_instance("dmf_options_view") then
			mod._slideshow_wait_frames = mod._slideshow_wait_frames - 1
			if mod._slideshow_wait_frames <= 0 then
				if not ui:chat_using_input() and not ui:view_instance("SlideShow_View") then
					pcall(function() mod.toggleSlideShowView() end)
				end
				mod._slideshow_wait_frames = nil
			end
		else
			mod._slideshow_wait_frames = 2
		end
	end

	if mod._pending_open_imv then
		local data = mod._pending_open_imv
		local view_name = data.view_name or "CLBImageManagerView"
		data.next_time = data.next_time - (dt or 0)
		if data.next_time <= 0 then
			data.attempts = data.attempts + 1
			local ui = Managers.ui
			if ui and ui:view_instance("dmf_options_view") then
				data.next_time = 0.1
				return
			end

			if ui and not ui:view_instance(view_name) and not ui:chat_using_input() then
				local context = { can_exit = true }
				local ok, err = pcall(function() ui:open_view(view_name, nil, nil, nil, nil, context) end)
				if not ok then
					if view_name ~= "CLBImageManagerViewStub" then
						data.view_name = "CLBImageManagerViewStub"
						data.next_time = 0.2
						data.attempts = 0
						return
					end
				end
			end
			if ui and ui:view_instance(view_name) then
				mod._pending_open_imv = nil
			elseif data.attempts >= 12 then
				mod._pending_open_imv = nil
			else
				data.next_time = 0.2
			end
		end
	end

	if mod._pending_full_unload and #mod._pending_full_unload.list > 0 then
		local batch = mod._pending_full_unload.batch or 40
		for i=1,batch do
			local url = table.remove(mod._pending_full_unload.list)
			if not url then break end
			pcall(function() Managers.url_loader:unload_texture(url) end)
		end
		if #mod._pending_full_unload.list == 0 then
			if mod._pending_clear_tables then
				for k,_ in pairs(backgroundImageTableWeb) do backgroundImageTableWeb[k] = nil end
				for k,_ in pairs(backgroundImageTableCurated) do backgroundImageTableCurated[k] = nil end
				for k,_ in pairs(backgroundImageTableLocal) do backgroundImageTableLocal[k] = nil end
				for k,_ in pairs(backgroundImageTableAll) do backgroundImageTableAll[k] = nil end
				mod._pending_clear_tables = nil
				pcall(function() _rebuild_available_pool() end)
				if Managers.backend and Managers.backend._initialized then
					pcall(function() mod.ensure_queue_seeded() end)
				end
				persist_enabled_state()
			end
			mod._pending_full_unload = nil
		end
	end

	if mod._pending_queue_purge then
		mod._pending_queue_purge = mod._pending_queue_purge - 1
		if mod._pending_queue_purge <= 0 then
			if mod._queue_mode and mod._queue_purge_all then
				mod:_queue_purge_all()
			end
			mod._pending_queue_purge = nil
		end
	end
end

mod.on_setting_changed = function(setting_id)
    if setting_id == "loadLocal" then
        if mod:get("loadLocal") then
            loadLocalImages()
        else
            for k, v in pairs(backgroundImageTableLocal) do
                Managers.url_loader:unload_texture(v.url)
                backgroundImageTableLocal[k] = nil
                backgroundImageTableAll[k] = nil
            end
        end
    elseif setting_id == "cycleImageLoadingInterval" then
        waitTimeLoading = mod:get("cycleImageLoadingInterval")
    elseif setting_id == "cycleImageLoading" then
        mod.cycleImageLoading = mod:get("cycleImageLoading")
    elseif setting_id == "slideshowInterval" then
        waitTimeSlideshow = mod:get("slideshowInterval")
    else
        return
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
	if not mod.imgKey then return end
	if lastTimeSlideshow + waitTimeLoading < os.time() and mod.cycleImageLoading and loadingView then
		mod.cycleImageSlideshow()
		lastTimeSlideshow = os.time()
	end
	local backgroundWidget = self._widgets_by_name.background
	local backgroundStyle = backgroundWidget.style.style_id_1
	if not backgroundStyle.material_values then backgroundStyle.material_values = {} end
	local entry = backgroundImageTableAll[mod.imgKey]
	if not entry and mod._queue_mode then
		for i=1,#mod._image_queue do
			local e = mod._image_queue[i]
			if e.key == mod.imgKey then entry = e.data break end
		end
	end
	if entry and entry.texture then
		backgroundStyle.material_values.texture_map = entry.texture
	end
end)

mod:hook_safe("LoadingView", "on_exit", function(self)
	loadingView = false
	mod.showBG = false
	mod.slideshow = false
	if mod._queue_mode and _queue_compact then _queue_compact() end
end)

--[[ These commands are disabled in favor of the Image Manager UI
mod:command("bglist", "List all available backgrounds", function()
	if not table.is_empty(backgroundImageTableAll) then
		for k,v in pairs(table.keys(backgroundImageTableAll)) do
			mod:echo(k .. ": " .. v)
		end
	else
		mod:echo("No images loaded")
	end
end)

mod:command("bg", "View a background (usage: /bg #)", function(p)
	local img = tonumber(p)
	if img and (not mod.showBG or (mod.showBG and img)) and img > 0 then
		if not table.is_empty(backgroundImageTableAll) and img <= table.size(backgroundImageTableAll) then
			mod.imgKey = table.keys(backgroundImageTableAll)[img]
			mod.showBG = true
			mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		else -- queue mode fallback: ensure queue seeded and pick first when available
			if mod._queue_mode then
				mod.showBG = true
				mod.ensure_queue_seeded()
				local imgdata = getRandomImage()
				if imgdata then mod.BGTexture = imgdata.texture end
			else
				mod.showBG = true
				loadAllImages()
			end
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

 mod:command("bgfolder", "Show the location of the folder where images are stored", function()
	mod:echo(localServer:get_root_mods_path():gsub('"', '') .. "\\CustomLoadingBackground\\scripts\\mods\\CustomLoadingBackground\\Images")
 end)
 ]]

 mod:command("bgss", "Start a slideshow of all images (usage: /bgss to open)", function()
	mod.toggleSlideShowView()
 end)

local getNextImage = function(n)
	local imageKeys = _enabled_image_keys()
	if #imageKeys == 0 then return nil end
	local currentIndex = table.find(imageKeys, mod.imgKey) or 1
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
	if not (mod.slideshow or mod.cycleImageLoading) then return end
	if mod._queue_mode then
		_advance_queue()
		if mod.slideshow and mod._image_queue and mod._image_queue[mod._queue_index] then
			local e = mod._image_queue[mod._queue_index]
			if e and e.data and e.data.texture then
				mod.BGTexture = e.data.texture
			end
		end
		return
	end
	if mod.imgKey and mod.showBG then
		local enabledKeys = _enabled_image_keys()
		if #enabledKeys == 0 then mod.showBG = false return end
		if #enabledKeys == 1 then
			mod.imgKey = enabledKeys[1]
		else
			local currentIndex = table.find(enabledKeys, mod.imgKey) or 1
			local newIndex = currentIndex
			while newIndex == currentIndex do newIndex = math.random(1, #enabledKeys) end
			mod.imgKey = enabledKeys[newIndex]
		end
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
	end
end

function mod.cycleImageNext()
	do
		local ui = Managers and Managers.ui
		local view = ui and ui:view_instance("CLBImageManagerView")
		if view and view._on_next_image then
			view:_on_next_image()
			return
		end
	end
	if mod._queue_mode and mod.showBG then
		_advance_queue()
		lastTimeSlideshow = os.time()
		return
	end
	if mod.imgKey and mod.showBG then
		local enabledKeys = _enabled_image_keys()
		if #enabledKeys == 0 then return end
		local idx = table.find(enabledKeys, mod.imgKey) or 1
		idx = idx + 1
		if idx > #enabledKeys then idx = 1 end
		mod.imgKey = enabledKeys[idx]
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		lastTimeSlideshow = os.time()
	end
end

function mod.cycleImagePrev()
	do
		local ui = Managers and Managers.ui
		local view = ui and ui:view_instance("CLBImageManagerView")
		if view and view._on_prev_image then
			view:_on_prev_image()
			return
		end
	end
	if mod._queue_mode and mod.showBG then
		if mod._queue_prev then mod._queue_prev() end
		lastTimeSlideshow = os.time()
		return
	end
	if mod.imgKey and mod.showBG then
		local enabledKeys = _enabled_image_keys()
		if #enabledKeys == 0 then return end
		local idx = table.find(enabledKeys, mod.imgKey) or 1
		idx = idx - 1
		if idx < 1 then idx = #enabledKeys end
		mod.imgKey = enabledKeys[idx]
		mod.BGTexture = backgroundImageTableAll[mod.imgKey].texture
		lastTimeSlideshow = os.time()
	end
end

function mod.toggleImageEnabled(key)
	if imageEnabled[key] == nil then imageEnabled[key] = true end
	imageEnabled[key] = not imageEnabled[key]
	if not imageEnabled[mod.imgKey] then
		mod.cycleImageNext()
	end
	persist_enabled_state()
end

function mod.enableAllImages()
	for k,_ in pairs(backgroundImageTableAll) do
		imageEnabled[k] = true
	end
	persist_enabled_state()
end

function mod.disableAllImages()
	for k,_ in pairs(backgroundImageTableAll) do
		imageEnabled[k] = false
	end
	mod.showBG = false
	persist_enabled_state()
end

mod.toggleImageManagerView = function()
	local view_name = mod._use_im_stub and "CLBImageManagerViewStub" or "CLBImageManagerView"
    local ui = Managers.ui
    if not ui then
        return
    end
	if view_name == "CLBImageManagerView" then
		local path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageManagerView"
		local src = mod:io_read_content(path)
		if not src then
			mod:echo("[CLB] Preflight: could not read view file: " .. tostring(path))
		else
			local load_fn = (Mods and Mods.lua and Mods.lua.loadstring) or loadstring
			local fn, err = load_fn(src, path)
			if not fn then
				mod:echo("[CLB] Falling back to stub view due to preflight error. See chat log for details.")
				mod._use_im_stub = true
				view_name = "CLBImageManagerViewStub"
			end
		end
	end
	if ui:view_instance(view_name) then
		ui:close_view(view_name)
        return
    end
	if ui:view_instance("dmf_options_view") then
		mod._open_im_after_dmf_close = view_name
		mod._restore_dmf_after_im = true
		ui:close_view("dmf_options_view")
		return
	end

	if ui:view_instance("system_view") then
		local context = { can_exit = true }
		local ok, err = pcall(function() ui:open_view(view_name, nil, nil, nil, nil, context) end)
		if not ok then
			mod._pending_open_imv = { attempts = 0, next_time = 0.2, view_name = view_name }
		end
		return
	end
	if ui:has_active_view() or ui:chat_using_input() then
        return
    end
    if mod._pending_open_imv then
        return
    end
	mod._pending_open_imv = { attempts = 0, next_time = 0, view_name = view_name }
	if not mod._manager_full_load then
		mod._enter_full_load_for_manager()
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
	local ui = Managers and Managers.ui
	if not ui then
		return
	end
	if not SlideShowViewRegisteredCorrectly then
		pcall(function()
			mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/SlideShowView")
			SlideShowViewRegisteredCorrectly = mod:register_view({
				view_name = "SlideShow_View",
				view_settings = {
					init_view_function = function() return true end,
					state_bound = true,
					path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/SlideShowView",
					class = "SlideShowView",
					load_always = true,
					load_in_hub = true,
				},
				view_transitions = {},
				view_options = { close_all = false, close_previous = false },
			})
		end)
	end
	if ui:view_instance("SlideShow_View") then
		ui:close_view("SlideShow_View")
		mod.showBG = false
		mod.slideshow = false
		return
	end
	if ui:chat_using_input() then
		return
	end
	if ui:view_instance("dmf_options_view") then
	    ui:close_view("dmf_options_view")
	    mod._slideshow_wait_frames = 2
	end
	if ui:view_instance("system_view") then
		pcall(function() ui:close_view("system_view") end)
	end
	mod.showBG = true
	mod.slideshow = true
	
	if mod._queue_mode then
		if not mod._slideshow_prev_target_size then
			mod._slideshow_prev_target_size = mod._queue_target_size
		end
		local desired = 10
		if mod._queue_target_size < desired then
			mod._queue_target_size = desired
			if mod._queue_initialized and #mod._image_queue < mod._queue_target_size then
				local fill_attempts = 0
				while #mod._image_queue < mod._queue_target_size and fill_attempts < 20 do
					fill_attempts = fill_attempts + 1
					if #mod._available_pool == 0 then _rebuild_available_pool() end
					if #mod._available_pool == 0 then break end
					local idx = math.random(1, #mod._available_pool)
					local url = table.remove(mod._available_pool, idx)
					_load_url_into_queue(url)
				end
			end
		end
	end
	local randomImage = getRandomImage()
	if not randomImage then
		if mod.ensure_queue_seeded then pcall(function() mod.ensure_queue_seeded() end) end
		mod._slideshow_waiting_first = true
		local ok, err = pcall(function()
			ui:open_view("SlideShow_View")
		end)
		return
	end
	lastTimeSlideshow = os.time()
	mod.BGTexture = randomImage.texture
	if not ui:view_instance("SlideShow_View") then
		if not mod._fallback_slideshow_registered then
			mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views")
			local view_def = {
				view_name = "CLBSlideShowDebugView",
				view_settings = {
					init_view_function = function() return true end,
					state_bound = true,
					path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/SlideShowView",
					class = "SlideShowView",
					load_always = true,
					load_in_hub = true,
				},
				view_transitions = {},
				view_options = { close_all = false, close_previous = false },
			}
			local ok_reg, reg_err = pcall(function() mod:register_view(view_def) end)
			mod._fallback_slideshow_registered = ok_reg
		end
		pcall(function() ui:open_view("CLBSlideShowDebugView") end)
		if ui:view_instance("CLBSlideShowDebugView") then
			--mod:echo("[CLB] Opened fallback debug slideshow view.")
		else
			--mod:echo("[CLB] Failed to open fallback debug slideshow view.")
		end
	end
end

mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageSourceView")

local ImageSourceViewRegisteredCorrectly = mod:register_view({
	view_name = "ImageSourceView",
	view_settings = {
		init_view_function = function(ingame_ui_context)
			return true
		end,
		state_bound = true,
		path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageSourceView",
		class = "ImageSourceView",
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

mod.toggleImageSourceView = function()
	if
		not Managers.ui:has_active_view()
		and not Managers.ui:chat_using_input()
		and not Managers.ui:view_instance("ImageSourceView")
	then
		Managers.ui:open_view("ImageSourceView")
	elseif Managers.ui:view_instance("dmf_options_view") then
		Managers.ui:close_view("dmf_options_view")
		Managers.ui:open_view("ImageSourceView")
	elseif Managers.ui:view_instance("ImageSourceView") then
		Managers.ui:close_view("ImageSourceView")
	end
end

mod:command("open_options_view", "Open the options view", function()
	mod.toggleImageSourceView()
end)

mod:command("bgmanage", "Open the image manager to enable/disable backgrounds", function()
    mod.toggleImageManagerView()
end)

mod:hook_safe("UIManager", "close_view", function(self, view_name)
	if view_name == "ImageSourceView" then
		local changed = mod.refresh_sources_from_view()
		if changed then
			--mod:echo("[CLB] Image sources changed; images reloaded.")
		end
		Managers.ui:open_view("dmf_options_view")
	end
	if view_name == "dmf_options_view" and mod._open_im_after_dmf_close then
		local next_view = mod._open_im_after_dmf_close
		mod._open_im_after_dmf_close = nil
		if Managers.ui:view_instance("system_view") then
			pcall(function() Managers.ui:close_view("system_view") end)
		end
		local context = { can_exit = true }
		local ok, err = pcall(function() Managers.ui:open_view(next_view, nil, nil, nil, nil, context) end)
		if ok and (next_view == "CLBImageManagerView" or next_view == "CLBImageManagerViewStub") and not mod._manager_full_load then
			pcall(function() mod._enter_full_load_for_manager() end)
		end
	end

	if (view_name == "CLBImageManagerView" or view_name == "CLBImageManagerViewStub") then
		if mod._manager_full_load then
			mod._exit_full_load_for_manager()
		end
		if mod._restore_dmf_after_im then
			mod._restore_dmf_after_im = nil
			pcall(function() Managers.ui:open_view("dmf_options_view") end)
		end
	end

	if view_name == "SlideShow_View" or view_name == "CLBSlideShowDebugView" then
		if mod._restore_dmf_after_slideshow then
			mod._restore_dmf_after_slideshow = nil
			pcall(function() Managers.ui:open_view("dmf_options_view") end)
			--mod:echo("[CLB] Returned to Options (slideshow opened from options button).")
		else
			--mod:echo("[CLB] Slideshow closed.")
		end
		if mod._queue_mode and mod._slideshow_prev_target_size then
			mod._queue_target_size = mod._slideshow_prev_target_size
			mod._slideshow_prev_target_size = nil
		end
		if mod._queue_mode and mod._image_queue and #mod._image_queue > 0 then
			mod._pending_queue_purge = 2
		end
	end
end)

mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageManagerView")

local ImageManagerViewRegisteredCorrectly = mod:register_view({
	view_name = "CLBImageManagerView",
	view_settings = {
		init_view_function = function(ingame_ui_context) return true end,
		state_bound = true,
		path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageManagerView",
		class = "ImageManagerView",
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

-- Stub view registration for isolation testing (disabled by default)
mod:add_require_path("CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageManagerViewStub")
local ImageManagerViewStubRegistered = mod:register_view({
    view_name = "CLBImageManagerViewStub",
    view_settings = {
        init_view_function = function() return true end,
        state_bound = true,
        path = "CustomLoadingBackground/scripts/mods/CustomLoadingBackground/Views/ImageManagerViewStub",
        class = "ImageManagerViewStub",
        disable_game_world = false,
        load_always = true,
        load_in_hub = true,
        game_world_blur = 0,
        enter_sound_events = { UISoundEvents.system_menu_enter },
        exit_sound_events = { UISoundEvents.system_menu_exit },
        wwise_states = { options = WwiseGameSyncSettings.state_groups.options.ingame_menu },
    },
    view_transitions = {},
    view_options = { close_all = false, close_previous = false },
})

-- Debug flag to switch between real and stub
mod._use_im_stub = false


do
	local dmf = get_mod("DMF")
	if dmf then
		mod:hook_safe(dmf, "create_mod_options_settings", function(dmf_self, options_templates)
			local opts = options_templates
			if not opts or not opts.categories or not opts.settings then return end

			local known_labels = {
				mod:localize("groupLoading"),
				mod:localize("groupCycleImages"),
				mod:localize("groupSlideShow"),
				mod:localize("loadLocal"),
				mod:localize("loadWeb"),
				mod:localize("loadCurated"),
				mod:localize("cycleImageLoading"),
				mod:localize("cycleImageNext"),
				mod:localize("cycleImagePrev"),
				mod:localize("slideshowInterval"),
				mod:localize("toggleSlideShow"),
			}

			local my_category = nil

			for _, s in ipairs(opts.settings) do
				if s and s.widget_type == "group_header" and (s.group_name == mod:get_name() or s.group_name == "CustomLoadingBackground") then
					my_category = s.category
					break
				end
			end

			for _, s in ipairs(opts.settings) do
				if s and s.category and s.display_name then
					for _, lbl in ipairs(known_labels) do
						if lbl and s.display_name == lbl then
							my_category = s.category
							break
						end
					end
				end
				if my_category then break end
			end

			if not my_category then
				local localized_name = mod:localize("mod_name")
				for _, cat in ipairs(opts.categories) do
					if cat and ((cat.display_name == localized_name)
						or (cat.display_name == "CustomLoadingBackground")
						or (type(cat.display_name) == "string" and string.lower(cat.display_name) == string.lower(localized_name))) then
						my_category = cat.display_name
						break
					end
				end
			end
			if not my_category then return end

			local label_key = "clb_open_image_manager"
			local loc = mod.localize and mod:localize(label_key)
			local label = (loc == nil or loc == label_key) and "Open Image Manager" or loc
			local label_with_arrow = label .. "  ›"

			local existing_index = nil
			for i, s in ipairs(opts.settings) do
				if s and s.category == my_category and (s.display_name == label or s.display_name == label_with_arrow) then
					existing_index = i
					break
				end
			end

			local target_index = nil
			local group_label = mod:localize("groupCycleImages")
			for i, s in ipairs(opts.settings) do
				if s and s.category == my_category and s.display_name == group_label then
					target_index = i
					break
				end
			end

			local entry = existing_index and opts.settings[existing_index] or {
				widget_type = "button",
				display_name = label,
				category = my_category,
				ignore_focus = true,
				tooltip_text = "Open the image manager",
				button_text = "Open",
				pressed_function = function(parent, widget, entry)
					local clb = get_mod("CustomLoadingBackground")
					if clb and clb.toggleImageManagerView then
						clb.toggleImageManagerView()
					end
				end,
			}

			entry.widget_type = "button"
			entry.display_name = label
			entry.button_text = "Open"

			if existing_index then
				table.remove(opts.settings, existing_index)
				if target_index and existing_index < target_index then
					target_index = target_index - 1
				end
			end

			local sources_label_key = "clb_image_sources"
			local sources_label_loc = mod.localize and mod:localize(sources_label_key)
			local sources_label = (sources_label_loc == nil or sources_label_loc == sources_label_key) and "Image Sources" or sources_label_loc
			local sources_label_with_arrow = sources_label .. "  ›"

			for i = #opts.settings, 1, -1 do
				local s = opts.settings[i]
				if s and s.category == my_category and (s.display_name == sources_label or s.display_name == sources_label_with_arrow) then
					table.remove(opts.settings, i)
					if target_index and i < target_index then target_index = target_index - 1 end
				end
			end
			local sources_entry = {
				widget_type = "button",
				display_name = sources_label,
				category = my_category,
				ignore_focus = true,
				tooltip_text = "Open image sources options",
				button_text = "Open",
				pressed_function = function(parent, widget, entry)
					local ui = Managers.ui
					if ui:view_instance("dmf_options_view") then
						ui:close_view("dmf_options_view")
					end
					local context = { can_exit = true }
					pcall(function() ui:open_view("ImageSourceView", nil, nil, nil, nil, context) end)
				end,
			}

			if target_index then
				table.insert(opts.settings, target_index, entry)
				table.insert(opts.settings, target_index, sources_entry)
			else
				opts.settings[#opts.settings + 1] = sources_entry
				opts.settings[#opts.settings + 1] = entry
			end

			local slideshow_label_interval = mod:localize("slideshowInterval")
			local slideshow_label_toggle = mod:localize("toggleSlideShow")
			local insert_at = nil
			for i, s in ipairs(opts.settings) do
				if s and s.category == my_category and (s.display_name == slideshow_label_interval or s.display_name == slideshow_label_toggle) then
					insert_at = i
					break
				end
			end
			local slideshow_button_label_key = "clb_open_slideshow"
			local loc_slideshow_btn = mod:localize(slideshow_button_label_key)
			local slideshow_btn_label = (loc_slideshow_btn == slideshow_button_label_key and "Open Slideshow" or loc_slideshow_btn)
			local already_present = false
			for _, s in ipairs(opts.settings) do
					if s and s.category == my_category and (s.display_name == slideshow_btn_label or s.setting_id == "clb_slideshow_open_button") then
					already_present = true
					break
				end
			end
			if insert_at and not already_present then
				local function slideshow_button_logic(source_tag)
					local clb = get_mod("CustomLoadingBackground")
					if not clb then return end
					local ui = Managers and Managers.ui
					clb._slideshow_btn_clicks = (clb._slideshow_btn_clicks or 0) + 1
					if ui and ui:view_instance("dmf_options_view") then
						clb._restore_dmf_after_slideshow = true
						ui:close_view("dmf_options_view")
						clb._slideshow_wait_frames = 2
						return
					end
					if ui and ui:view_instance("system_view") then
						pcall(function() ui:close_view("system_view") end)
					end
					if clb.toggleSlideShowView then
						clb.toggleSlideShowView()
					end
				end
				local slideshow_entry = {
					widget_type = "button",
					setting_id = "clb_slideshow_open_button",
					display_name = "",
					category = my_category,
					tooltip_text = "Open the slideshow",
					button_text = "Open Slideshow",
					callback = function(...) slideshow_button_logic("callback") end,
					pressed_function = function(...) slideshow_button_logic("pressed_function") end,
					save = "none",
				}
				if insert_at > 1 then
					table.insert(opts.settings, insert_at, slideshow_entry)
				else
					table.insert(opts.settings, slideshow_entry)
				end
			end
		end)
		
		mod:hook_require("dmf/scripts/mods/dmf/modules/ui/options/mod_options", function()
			--
		end)

		mod:hook_require("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_content_blueprints", function(blueprints)
			if type(blueprints) == "table" and blueprints.button and type(blueprints.button.init) == "function" then
				local orig_init = blueprints.button.init
				blueprints.button.init = function(parent, widget, entry, callback_name, changed_callback_name)
					orig_init(parent, widget, entry, callback_name, changed_callback_name)
					if entry and entry.button_text then
						widget.content.button_text = entry.button_text
					end
				end
			end
		end)

		local dmf_mod = get_mod("DMF")
		if dmf_mod and not mod._patched_dmf_io_dofile then
			mod:hook(dmf_mod, "io_dofile", function(func, self, path, ...)
				local result = func(self, path, ...)
				if path == "dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_content_blueprints" and type(result) == "table" then
					local blueprints = result
					if blueprints.button and type(blueprints.button.init) == "function" then
						local orig_init = blueprints.button.init
						blueprints.button.init = function(parent, widget, entry, callback_name, changed_callback_name)
							orig_init(parent, widget, entry, callback_name, changed_callback_name)
							if entry and entry.button_text then
								widget.content.button_text = entry.button_text
							end
						end
					end
				end
				return result
			end)
			mod._patched_dmf_io_dofile = true
		end
	end
end

function mod.unload_url_image(url)
	if not url or url == "" then return end
	local tex = backgroundImageTableWeb[url]
	if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
	backgroundImageTableWeb[url] = nil
	local ctex = backgroundImageTableCurated[url]
	if ctex and ctex.url then pcall(function() Managers.url_loader:unload_texture(ctex.url) end) end
	backgroundImageTableCurated[url] = nil
	local cmeta = backgroundImageTableCuratedUrls[url]
	if cmeta and not cmeta.is_source then cmeta.loaded = false end
	backgroundImageTableAll[url] = nil
	imageEnabled[url] = nil
	if mod.imgKey == url then
		local nextKey = _pick_random_enabled_key and _pick_random_enabled_key() or nil
		if nextKey then
			mod.imgKey = nextKey
			mod.BGTexture = backgroundImageTableAll[nextKey] and backgroundImageTableAll[nextKey].texture or nil
		else
			mod.imgKey = nil
			mod.BGTexture = nil
			mod.showBG = false
			mod.slideshow = false
		end
	end
end

function mod.unload_curated_source(source_url)
	if not source_url or source_url == "" then return end
	local to_remove = {}
	for url, meta in pairs(backgroundImageTableCuratedUrls) do
		if meta and meta.source == source_url and not meta.is_source then
			to_remove[#to_remove+1] = url
		end
	end
	for i=1,#to_remove do
		local url = to_remove[i]
		local tex = backgroundImageTableCurated[url]
		if tex and tex.url then pcall(function() Managers.url_loader:unload_texture(tex.url) end) end
		backgroundImageTableCurated[url] = nil
		backgroundImageTableAll[url] = nil
		imageEnabled[url] = nil
		backgroundImageTableCuratedUrls[url] = nil
		if mod.imgKey == url then
			mod.imgKey = nil
			mod.BGTexture = nil
			mod.showBG = false
			mod.slideshow = false
		end
	end
	backgroundImageTableCuratedUrls[source_url] = nil
end

function mod.fetch_curated_source(source_url)
	if not source_url or source_url == "" then return end
	local meta = backgroundImageTableCuratedUrls[source_url]
	if meta and meta.is_source and meta.queried then
		return
	end
	Managers.backend:url_request(source_url)
		:next(function(data)
			if data and data.body then
				for line in data.body:gmatch("[^\r\n]+") do
					if line ~= "" and line:sub(1,2) ~= "--" then
						local existing = backgroundImageTableCuratedUrls[line]
						if not existing then
							backgroundImageTableCuratedUrls[line] = { loaded = false, source = source_url }
						elseif existing and not existing.source then
							existing.source = source_url
						end
					end
				end
				backgroundImageTableCuratedUrls[source_url] = { queried = true, is_source = true }
			end
		end)
		:catch(function(error)
			mod:dump(error, string.format("Error fetching curated urls from %s", source_url), 8)
		end)
end

mod.fetch_curated_source = mod.fetch_curated_source or function(url)
	if not url or url == "" then return end
	backgroundImageTableCuratedUrls[url] = nil
end

_gather_enabled_remote_urls = function()
	local urls_out = {}
	if not mod._applied_persisted_disabled then
		local persisted = mod:get("disabledImageKeys") or {}
		for i=1,#persisted do
			local key = persisted[i]
			if imageEnabled[key] ~= false then imageEnabled[key] = false end
		end
		mod._applied_persisted_disabled = true
	end
	local web_rows = _enabled_url_rows()
	for i=1,#web_rows do
		local u = web_rows[i]
		if imageEnabled[u] ~= false then
			urls_out[#urls_out+1] = u
		end
	end
	for url, meta in pairs(backgroundImageTableCuratedUrls) do
		if meta and not meta.is_source and imageEnabled[url] ~= false then
			urls_out[#urls_out+1] = url
		end
	end
	return urls_out
end

_rebuild_available_pool = function()
	mod._available_pool = {}
	local seen_in_queue = {}
	for i=1,#mod._image_queue do
		local entry = mod._image_queue[i]
		if entry and entry.key then
			seen_in_queue[entry.key] = true
		end
	end
	local all_urls = _gather_enabled_remote_urls()
	for i=1,#all_urls do
		local u = all_urls[i]
		if not seen_in_queue[u] then
			mod._available_pool[#mod._available_pool+1] = u
		end
	end
end

_load_url_into_queue = function(url)
	if not url or url == "" then return end
	if mod._queue_loading[url] then return end
	mod._queue_loading[url] = true
	local load_gen = mod._queue_gen
	Managers.url_loader:load_texture(url)
		:next(function(data)
			mod._queue_loading[url] = nil
			if load_gen ~= mod._queue_gen then
				if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
				return
			end
			if imageEnabled[url] == false then
				if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
				return
			end
			if table.size(data) == 4 then
				for i=1,#mod._image_queue do if mod._image_queue[i].key == url then return end end
				mod._image_queue[#mod._image_queue+1] = { key = url, data = data }
				backgroundImageTableAll[url] = data
				if imageEnabled[url] == nil then imageEnabled[url] = true end
				if not mod.imgKey then
					mod.imgKey = url
					mod.BGTexture = data.texture
					mod.showBG = true
				end
				if mod._queue_mode and not loadingView and #mod._image_queue > mod._queue_target_size then
					_queue_compact()
				end
			else
				if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
			end
		end)
		:catch(function(err)
			mod._queue_loading[url] = nil
			mod:dump(err, "Queue load error", 1)
		end)
end

local function _queue_select(idx)
	local q = mod._image_queue
	if idx < 1 then idx = 1 end
	if idx > #q then idx = #q end
	mod._queue_index = idx
	local entry = q[idx]
	if entry then
		mod.imgKey = entry.key
		mod.BGTexture = entry.data.texture
		mod.showBG = true
		if mod.slideshow then
			lastTimeSlideshow = os.time()
		end
	else
		mod.imgKey = nil
		mod.BGTexture = nil
	end
end

_advance_queue = function()
	local q = mod._image_queue
	if #q == 0 then return end
	if mod._queue_index < #q then
		_queue_select(mod._queue_index + 1)
		return
	end
	if #mod._available_pool == 0 then _rebuild_available_pool() end
	if #mod._available_pool == 0 then
		_rebuild_available_pool()
		if #mod._available_pool == 0 then return end
	end
	local idx = math.random(1, #mod._available_pool)
	local url = table.remove(mod._available_pool, idx)
	mod._queue_pending_next = true
	local orig_loading = mod._queue_loading[url]
	if not orig_loading then
		mod._queue_loading[url] = true
		Managers.url_loader:load_texture(url)
			:next(function(data)
				mod._queue_loading[url] = nil
				if imageEnabled[url] == false then if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end return end
				if table.size(data) == 4 then
					-- Prevent duplicates
					for i=1,#q do if q[i].key == url then return end end
					q[#q+1] = { key = url, data = data }
					backgroundImageTableAll[url] = data
					if imageEnabled[url] == nil then imageEnabled[url] = true end
					if mod._queue_pending_next then
						mod._queue_pending_next = false
						_queue_select(#q)
					end
					if mod._queue_mode and not loadingView and #mod._image_queue > mod._queue_target_size then
						_queue_compact()
					end
				else
					if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
				end
			end)
			:catch(function(err)
				mod._queue_loading[url] = nil
				mod._queue_pending_next = false
				mod:dump(err, "Queue load error (advance)", 1)
			end)
	end
end

function mod._queue_prev()
	if mod._queue_index > 1 then
		_queue_select(mod._queue_index - 1)
	end
end

_queue_compact = function()
	local q = mod._image_queue
	if #q == 0 then return end
	mod._queue_gen = (mod._queue_gen + 1) % 1000000
	local compact = {}
	local current_entry = q[mod._queue_index]
	if not current_entry then
		current_entry = q[#q]
		mod._queue_index = #q
	end
	compact[1] = current_entry
	local needed_future = mod._queue_target_size - 1
	local i = mod._queue_index + 1
	while needed_future > 0 and i <= #q do
		compact[#compact+1] = q[i]
		needed_future = needed_future - 1
		i = i + 1
	end
	local kept = {}
	for _,e in ipairs(compact) do kept[e.key] = true end
	for _,e in ipairs(q) do
		if e and not kept[e.key] then
			if e.data and e.data.url then pcall(function() Managers.url_loader:unload_texture(e.data.url) end) end
			if e.key then
				backgroundImageTableAll[e.key] = nil
				imageEnabled[e.key] = nil
			end
		end
	end
	mod._image_queue = compact
	mod._queue_index = 1
	_queue_select(1)
	_rebuild_available_pool()
	while #mod._image_queue < mod._queue_target_size and #mod._available_pool > 0 do
		local ridx = math.random(1, #mod._available_pool)
		local url = table.remove(mod._available_pool, ridx)
		_load_url_into_queue(url)
	end
end

--[[ 
mod:command("bgqueue", "Show queue state (debug)", function()
	mod:echo(string.format("[CLB] Queue gen=%s size=%d index=%d target=%d loading=%d pool=%d", tostring(mod._queue_gen), #mod._image_queue, mod._queue_index, mod._queue_target_size, table.size(mod._queue_loading), #mod._available_pool))
	for i, e in ipairs(mod._image_queue) do
		local mark = (i == mod._queue_index) and "*" or " "
		mod:echo(string.format("  %s[%d] %s", mark, i, tostring(e.key)))
	end
end)

mod:command("bgcounts", "Show image table counts (debug)", function()
	mod:echo(string.format("[CLB] mode=%s full_load=%s web=%d curated=%d curatedMeta=%d local=%d all=%d queue=%d enabled=%d", 
		mod._queue_mode and "queue" or "bulk", tostring(mod._manager_full_load), table.size(backgroundImageTableWeb), table.size(backgroundImageTableCurated), table.size(backgroundImageTableCuratedUrls), table.size(backgroundImageTableLocal), table.size(backgroundImageTableAll), #mod._image_queue, (function() local c=0 for k,_ in pairs(imageEnabled) do if imageEnabled[k] then c=c+1 end end return c end)()))
end)

mod:command("bgpending", "Show pending deferred unload status", function()
	if mod._pending_full_unload then
		mod:echo(string.format("[CLB] Pending unload remaining=%d batch=%s", #mod._pending_full_unload.list, tostring(mod._pending_full_unload.batch)))
	else
		mod:echo("[CLB] No pending unload.")
	end
end)

mod:command("bgdis", "Display disabled image keys", function()
	local disabled = mod:get("disabledImageKeys") or {}
	if #disabled == 0 then
		mod:echo("[CLB] No disabled image keys.")
	else
		table.sort(disabled)
		mod:echo(string.format("[CLB] Disabled image keys (%d):", #disabled))
		for i=1,#disabled do
			mod:echo("  " .. tostring(disabled[i]))
		end
	end
end)
 ]]

function mod._enter_full_load_for_manager()
	if mod._manager_full_load then return end
	if not mod._purge_queue_textures then
		function mod._purge_queue_textures()
			if not mod._image_queue then return end
			local purged_keys = {}
			local purged = 0
			for i=1,#mod._image_queue do
				local e = mod._image_queue[i]
				if e and e.data and e.data.url then
					pcall(function() Managers.url_loader:unload_texture(e.data.url) end)
					purged = purged + 1
					purged_keys[e.key] = true
				end
			end
			for k,_ in pairs(purged_keys) do
				local agg = backgroundImageTableAll[k]
				if agg and agg.texture then
					backgroundImageTableAll[k] = nil
				end
				if mod.imgKey == k then
					mod.imgKey = nil
					mod.BGTexture = nil
				end
			end
			mod._image_queue = {}
			mod._available_pool = {}
			mod._queue_index = 1
			mod._queue_initialized = false
			mod._queue_gen = (mod._queue_gen + 1) % 1000000
		end
	end
	mod._purge_queue_textures()
	mod._manager_full_load = true
	mod._manager_full_gen = (mod._manager_full_gen or 0) + 1
	if mod:get("loadLocal") then
		pcall(function() loadLocalImages() end)
	end
	pcall(function() loadCuratedUrls() end)

	local function force_load_url(url, is_curated)
		if not url or url == "" then return end
		mod._manager_inflight = (mod._manager_inflight or 0) + 1
		if is_curated then
			if backgroundImageTableCurated[url] then return end
		else
			if backgroundImageTableWeb[url] then return end
		end
		local gen = mod._manager_full_gen
		Managers.url_loader:load_texture(url)
			:next(function(data)
				if gen ~= mod._manager_full_gen or not mod._manager_full_load then
					if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
					mod._manager_inflight = math.max(0, (mod._manager_inflight or 1) - 1)
					return
				end
				if table.size(data) == 4 then
					if is_curated then
						backgroundImageTableCurated[url] = data
						local meta = backgroundImageTableCuratedUrls[url]; if meta then meta.failed = false end
					else
						backgroundImageTableWeb[url] = data
					end
					backgroundImageTableAll[url] = data
					if imageEnabled[url] == nil then imageEnabled[url] = true end
				else
					if data and data.url then pcall(function() Managers.url_loader:unload_texture(data.url) end) end
					if is_curated then local meta = backgroundImageTableCuratedUrls[url]; if meta then meta.failed = true end end
				end
				mod._manager_inflight = math.max(0, (mod._manager_inflight or 1) - 1)
			end)
			:catch(function(err)
				mod:dump(err, "Force load error", 1)
				if is_curated then local meta = backgroundImageTableCuratedUrls[url]; if meta then meta.failed = true end end
				mod._manager_inflight = math.max(0, (mod._manager_inflight or 1) - 1)
			end)
	end

	local web_rows = _enabled_url_rows()
	for i=1,#web_rows do
		force_load_url(web_rows[i], false)
	end

	for url, meta in pairs(backgroundImageTableCuratedUrls) do
		if meta then meta.failed = false; force_load_url(url, true) end
	end
end

function mod._exit_full_load_for_manager()
	if not mod._manager_full_load then return end
	mod._manager_full_load = false
	mod._manager_inflight = 0
	mod._manager_full_gen = (mod._manager_full_gen or 0) + 1
	mod._pending_full_unload = mod._pending_full_unload or { list = {}, start_time = os.time(), batch = 40 }
	local pend = mod._pending_full_unload
	for key, data in pairs(backgroundImageTableAll) do
		if data and data.url then
			pend.list[#pend.list+1] = data.url
		end
	end
	mod._pending_clear_tables = true
	mod._image_queue = {}
	mod._available_pool = {}
	mod._queue_index = 1
	mod._queue_initialized = false
	mod._queue_gen = (mod._queue_gen + 1) % 1000000
end

function mod._queue_purge_all()
	local q = mod._image_queue or {}
	for _, e in ipairs(q) do
		if e and e.data and e.data.url then pcall(function() Managers.url_loader:unload_texture(e.data.url) end) end
		if e and e.key then
			backgroundImageTableAll[e.key] = nil
			if imageEnabled[e.key] ~= false then imageEnabled[e.key] = nil end
		end
	end
	mod._image_queue = {}
	mod._available_pool = {}
	mod._queue_index = 1
	mod.imgKey = nil
	mod.BGTexture = nil
	mod._queue_initialized = false
end