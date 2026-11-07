-- ========================================
-- CeriumCore v1.11
-- Release version
-- By: MissGera x DeepSeek
-- id: 4266449440
-- YT: https://youtube.com/@missgeraa
-- Telegram Channel: https://t.me/korobkageri
-- ========================================
-- Made specifically for vforge.pythonanywhere.com
-- If you get banned, it's your fault, not ours.
-- Please read the README_EN.md or README.md file before using it for anything other than purely user-oriented purposes.
-- ========================================
-- Build Version: 11105
-- Lang type: mix
--EN, --RU, --mix — a combination of two or more languages
-- download url: vforge.pythonanywhere.com/pack/35
-- ========================================

local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local SCRIPTS_DIR = BASE_DIR .. 'cerium-scripts/'
local PLUGINS_CONFIG = BASE_DIR .. 'cerium-scripts/plugins_config.json'
local PLUGINS_LUA = BASE_DIR .. 'cerium-scripts/plugins.lua'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'

-- Пути для 1-го и 2-го движков
local GAME_DIR_V1 = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST_V1 = GAME_DIR_V1 .. 'common.zip'
local GAME_BACKUP_V1 = GAME_DIR_V1 .. 'common_backup.zip'

local GAME_DIR_V2 = '/data/user/0/com.sandboxol.blockymods/app_resourcesv2/'
local GAME_DST_V2 = GAME_DIR_V2 .. 'common.zip'
local GAME_BACKUP_V2 = GAME_DIR_V2 .. 'common_backup.zip'

local LOG_PATH = LOGS_DIR .. 'cerium.log'

local COL_TEXT   = {1.00, 1.00, 1.00, 1.00}
local COL_ACCENT = {0.30, 0.85, 0.85, 1.00}
local COL_DESC   = {0.80, 0.80, 0.80, 1.00}

local IMG_PANEL    = "cegui_main_page/top_toorbar_bg"
local IMG_ROW      = "shop/commodity"
local IMG_BTN      = "shop/buy_btn"

local PACKS_PER_PAGE = 6
local MAX_DESC_LENGTH = 200

local AUTHOR_NAME = string.char(77,105,115,115) .. "Gera"
local VERSION_STR = "v" .. string.char(49,46,49,49)       
local VFORGE_URL  = "vforge.pythonanywhere.com"

local function log(msg)
    local f = io.open(LOG_PATH, 'a')
    if f then f:write(os.date('%H:%M:%S') .. ' | ' .. tostring(msg) .. '\n') f:close() end
end

local function ensure_dir(path)
    local ok, lfs = pcall(require, 'lfs')
    if ok and lfs then pcall(function() lfs.mkdir(path) end) end
end

local function file_exists(path)
    if not path then return false end
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function read_file(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local c = f:read('*a'); f:close()
    return c
end

local function write_file(path, content)
    local f = io.open(path, 'w')
    if not f then return false end
    f:write(content); f:close()
    return true
end

local function copy_file(src, dst)
    local data = read_file(src)
    if not data then return false end
    return write_file(dst, data)
end

ensure_dir(LOGS_DIR)
ensure_dir(TEXTURES_DIR)
ensure_dir(SCRIPTS_DIR)
log('=== CeriumCore ' .. VERSION_STR .. ' started ===')

if not file_exists(GAME_BACKUP_V1) and file_exists(GAME_DST_V1) then
    if copy_file(GAME_DST_V1, GAME_BACKUP_V1) then log('created backup v1') end
end
if not file_exists(GAME_BACKUP_V2) and file_exists(GAME_DST_V2) then
    if copy_file(GAME_DST_V2, GAME_BACKUP_V2) then log('created backup v2') end
end

local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then return end

-- === Градиентный текст ===
local function getGradientText(text, startColor, endColor)
    if not text or #text == 0 then return text end
    local result = ""
    local len = #text
    local r1 = tonumber(startColor:sub(3,4), 16) or 255
    local g1 = tonumber(startColor:sub(5,6), 16) or 255
    local b1 = tonumber(startColor:sub(7,8), 16) or 255
    local r2 = tonumber(endColor:sub(3,4), 16) or 255
    local g2 = tonumber(endColor:sub(5,6), 16) or 255
    local b2 = tonumber(endColor:sub(7,8), 16) or 255
    
    for i = 1, len do
        local char = text:sub(i, i)
        local t = (i - 1) / math.max(1, len - 1)
        local r = math.floor(r1 + (r2 - r1) * t)
        local g = math.floor(g1 + (g2 - g1) * t)
        local b = math.floor(b1 + (b2 - b1) * t)
        local colorHex = string.format("FF%02X%02X%02X", r, g, b)
        result = result .. "[colour='" .. colorHex .. "']" .. char
    end
    return result
end

-- === Работа с конфигом плагинов ===
local function get_active_plugins()
    local c = read_file(PLUGINS_CONFIG)
    if not c then return {} end
    local ok, data = pcall(cjson.decode, c)
    if ok and type(data) == "table" then return data end
    return {}
end

local function save_active_plugins(list)
    return write_file(PLUGINS_CONFIG, cjson.encode(list))
end

local function is_plugin_active(folder_name)
    local active = get_active_plugins()
    for _, v in ipairs(active) do
        if v == folder_name then return true end
    end
    return false
end

local function rebuild_plugins_lua()
    local active = get_active_plugins()
    local final_code = "-- Auto-generated by CeriumCore\n"
    final_code = final_code .. "pcall(function()\n"
    for _, folder in ipairs(active) do
        local script_path = SCRIPTS_DIR .. folder .. "/script.lua"
        local code = read_file(script_path)
        if code then
            final_code = final_code .. "-- START PLUGIN: " .. folder .. "\n"
            final_code = final_code .. "pcall(function()\n" .. code .. "\nend)\n"
            final_code = final_code .. "-- END PLUGIN: " .. folder .. "\n\n"
        end
    end
    final_code = final_code .. "end)\n"
    write_file(PLUGINS_LUA, final_code)
    log("Rebuilt plugins.lua with " .. #active .. " active plugins.")
end

-- === Сканирование ===
local function scan_packs()
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok or not lfs then return {} end
    local packs = {}
    local index = 1
    for entry in lfs.dir(TEXTURES_DIR) do
        if entry ~= '.' and entry ~= '..' then
            local entry_path = TEXTURES_DIR .. entry
            local attr = lfs.attributes(entry_path)
            if attr and attr.mode == 'directory' then
                local zip_path = entry_path .. '/texturepack.zip'
                if file_exists(zip_path) then
                    local pack = { index = index, folder = entry, zip = zip_path, name = entry, version = '?', author = '', description = '', engine = 1 }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            pack.name = data.name or data.title or entry
                            pack.version = tostring(data.version or data.v or '1.0')
                            pack.author = data.author or data.author_name or ''
                            pack.description = data.description or data.desc or ''
                            pack.engine = tonumber(data.engine) or 1
                            if #pack.description > MAX_DESC_LENGTH then pack.description = string.sub(pack.description, 1, MAX_DESC_LENGTH) .. "..." end
                        end
                    end
                    table.insert(packs, pack)
                    index = index + 1
                end
            end
        end
    end
    return packs
end

local function scan_scripts()
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok or not lfs then return {} end
    local scripts = {}
    local index = 1
    for entry in lfs.dir(SCRIPTS_DIR) do
        if entry ~= '.' and entry ~= '..' and entry ~= 'plugins.lua' and entry ~= 'plugins_config.json' then
            local entry_path = SCRIPTS_DIR .. entry
            local attr = lfs.attributes(entry_path)
            if attr and attr.mode == 'directory' then
                local script_path = entry_path .. '/script.lua'
                if file_exists(script_path) then
                    local script = { index = index, folder = entry, path = script_path, name = entry, version = '?', author = '', description = '' }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            script.name = data.name or entry
                            script.version = tostring(data.version or '1.0')
                            script.author = data.author or ''
                            script.description = data.description or ''
                        end
                    end
                    table.insert(scripts, script)
                    index = index + 1
                end
            end
        end
    end
    return scripts
end

local function get_active_pack()
    local c = read_file(CONFIG_PATH)
    if not c then return nil end
    local ok, data = pcall(cjson.decode, c)
    if ok and data and data.selected_folder then return data.selected_folder end
    return nil
end

local function apply_pack(pack)
    if not file_exists(pack.zip) then return false end
    local data = read_file(pack.zip)
    if not data then return false end
    write_file(TEMP_ZIP, data)
    
    -- Поддержка 1 и 2 движка
    if pack.engine == 2 then
        write_file(GAME_DST_V2, data)
    else
        write_file(GAME_DST_V1, data)
    end
    
    write_file(CONFIG_PATH, cjson.encode({ selected = pack.index, selected_name = pack.name, selected_folder = pack.folder, engine = pack.engine }))
    log('applied: ' .. pack.name .. ' for engine ' .. pack.engine)
    return true
end

-- === UI Утилиты ===
if not UI or not Enum or not Enum.WidgetType then return end
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local screenSize = GUIManager.Instance():getScreenSize()
local W = screenSize.x
local H = screenSize.y

local function showToast(msg)
    pcall(function()
        Lib.emitEvent(Event.EVENT_TOAST_TIP, "[colour='FF00FF00']" .. msg, 20, 60)
    end)
end

local bgCounter = 0
local function createBackground(name, x, y, w, h, image, alpha)
    bgCounter = bgCounter + 1
    local ok, wdg = pcall(function() return winMgr:createWindow("Engine/StaticImage", name .. "-bg-" .. bgCounter .. "-" .. winMgr:generateUniqueWindowName()) end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setProperty("FrameEnabled", false) end)
    pcall(function() wdg:setImage(image) end)
    pcall(function() wdg:setArea2({0, x}, {0, y}, {0, w}, {0, h}) end)
    pcall(function() wdg:setAlpha(0) end)
    pcall(function() wdg:setMousePassThroughEnabled(true) end)
    pcall(function() wdg:setDestroyedByParent(false) end)
    pcall(function() wdg:setVisible(true) end)
    return wdg
end

local function createText(text, x, y, w, h, col)
    local ok, wdg = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Text) end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setText(text) end)
    pcall(function() wdg:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() wdg:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then pcall(function() wdg:setTextColor(col) end) end
    pcall(function() wdg:setTextSize(18) end)
    pcall(function() wdg:setAlpha(0) end)
    return wdg
end

local function createButton(text, x, y, w, h, image, onClick)
    local ok, btn = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Button) end)
    if not ok or not btn then return nil end
    pcall(function() btn:setText(text) end)
    pcall(function() btn:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() btn:setSize(UDim2.new(w, 0, h, 0)) end)
    if image then
        pcall(function() btn:setProperty("NormalImage", image) end)
        pcall(function() btn:setProperty("PushedImage", image) end)
        pcall(function() btn:setProperty("HoverImage", image) end)
    end
    pcall(function() btn:setAlpha(0) end)
    if onClick then btn.onMouseClick = function() onClick(btn) end end
    return btn
end

-- === Состояние ===
local menuOpen = false
local menuElements = {}
local animElements = {}
local allPacks = {}
local allScripts = {}
local currentPage = 1
local totalPages = 1
local currentMode = "textures"
local showCredits = false

local function clearElements()
    for _, el in ipairs(menuElements) do
        pcall(function() 
            el:setVisible(false)
            if winMgr and winMgr.destroyWindow then winMgr:destroyWindow(el) end
        end)
    end
    menuElements = {}
    animElements = {}
end

local function closeMenu()
    clearElements()
    menuOpen = false
    showCredits = false
    log('menu closed')
end

local function animateAppear()
    local time = 0
    World.Timer(1, function()
        if not menuOpen then return false end
        time = time + 1
        local progress = math.min(time / 10, 1)
        for _, data in ipairs(animElements) do
            pcall(function() data.el:setAlpha((data.targetAlpha or 0.85) * progress) end)
        end
        if progress >= 1 then return false end
        return true
    end)
end

local function copy_large_file(src_path, dst_path)
    local src_file = io.open(src_path, "rb")
    if not src_file then return false, "Read error" end
    local dst_file = io.open(dst_path, "wb")
    if not dst_file then src_file:close() return false, "Write error" end
    local total = 0
    while true do
        local chunk = src_file:read(1024 * 1024)
        if not chunk or #chunk == 0 then break end
        dst_file:write(chunk)
        total = total + #chunk
    end
    src_file:close(); dst_file:close()
    return true, total
end

local function copy_directory(src_dir, dst_dir)
    local lfs = require("lfs")
    pcall(function() lfs.mkdir(dst_dir) end)
    for file in lfs.dir(src_dir) do
        if file ~= "." and file ~= ".." then
            local src_path = src_dir .. "/" .. file
            local dst_path = dst_dir .. "/" .. file
            local attr = lfs.attributes(src_path)
            if attr then
                if attr.mode == "directory" then
                    copy_directory(src_path, dst_path)
                elseif attr.mode == "file" then
                    local src_f = io.open(src_path, "rb")
                    if src_f then
                        local dst_f = io.open(dst_path, "wb")
                        if dst_f then
                            while true do
                                local chunk = src_f:read(1024 * 1024)
                                if not chunk or #chunk == 0 then break end
                                dst_f:write(chunk)
                            end
                            dst_f:close()
                        end
                        src_f:close()
                    end
                end
            end
        end
    end
end

-- === Отрисовка страницы ===
local function renderPage()
    clearElements()
    local activePack = get_active_pack()
    local listData = (currentMode == "textures") and allPacks or allScripts

    -- 1. Фон
    local panel = createBackground("panel", 0.05*W, 0.03*H, 0.90*W, 0.94*H, IMG_PANEL, 0.85)
    if panel then UI.root:addChild(panel) table.insert(menuElements, panel) table.insert(animElements, {el = panel, targetAlpha = 0.85}) end

    -- 2. Заголовок
    local titleText = getGradientText("CeriumCore", "FF4DD8D8", "FFFFFFFF")
    local title = createText(titleText, 0.08, 0.05, 0.50, 0.08, nil)
    if title then UI.root:addChild(title) table.insert(menuElements, title) table.insert(animElements, {el = title, targetAlpha = 1}) end

    -- 3. Версия (правый верхний угол, но под панелью)
    local verText = getGradientText(VERSION_STR, "FF4DD8D8", "FFFFFFFF")
local ver = createText(verText, 0.25, 0.07, 0.15, 0.04, nil) -- Сдвинули x (0.25) и y (0.07)
if ver then 
    pcall(function() ver:setTextSize(14) end)
    UI.root:addChild(ver) table.insert(menuElements, ver) table.insert(animElements, {el = ver, targetAlpha = 1}) 
end

    -- 4. Ссылка на VForge (левый нижний угол)
    local vforgeText = getGradientText("Link VForge", "FF4DD8D8", "FFFFFFFF")
    local vforgeBtn = createButton(vforgeText, 0.07, 0.90, 0.12, 0.05, IMG_BTN, function()
        pcall(function()
            CGame.instance:getShellInterface():copyToClipboard("https://" .. VFORGE_URL, "CeriumCore")
        end)
        showToast("Ссылка на VForge скопирована!")
    end)
    if vforgeBtn then 
        pcall(function() vforgeBtn:setTextSize(14) end)
        UI.root:addChild(vforgeBtn) table.insert(menuElements, vforgeBtn) table.insert(animElements, {el = vforgeBtn, targetAlpha = 1}) 
    end

    -- 5. Кнопки
    local modeBtnText = (currentMode == "textures") and "SCRIPTS" or "TEXTURES"
    local modeBtn = createButton(modeBtnText, 0.25, 0.11, 0.15, 0.05, IMG_BTN, function()
        currentMode = (currentMode == "textures") and "scripts" or "textures"
        currentPage = 1
        renderPage()
    end)
    if modeBtn then UI.root:addChild(modeBtn) table.insert(menuElements, modeBtn) table.insert(animElements, {el = modeBtn, targetAlpha = 1}) end

    -- Credits Button
    local creditsBtn = createButton("CREDITS", 0.42, 0.11, 0.15, 0.05, IMG_BTN, function()
        showCredits = not showCredits
        renderPage()
    end)
    if creditsBtn then UI.root:addChild(creditsBtn) table.insert(menuElements, creditsBtn) table.insert(animElements, {el = creditsBtn, targetAlpha = 1}) end

    if showCredits then
        -- Окно кредитов
        local crBg = createBackground("creditsBg", 0.20*W, 0.20*H, 0.60*W, 0.60*H, IMG_PANEL, 0.95)
        if crBg then UI.root:addChild(crBg) table.insert(menuElements, crBg) table.insert(animElements, {el = crBg, targetAlpha = 0.95}) end
        
        local crTitle = createText(getGradientText("CERIUMCORE", "FF4DD8D8", "FFFFFFFF"), 0.25, 0.25, 0.50, 0.08, nil)
        if crTitle then UI.root:addChild(crTitle) table.insert(menuElements, crTitle) table.insert(animElements, {el = crTitle, targetAlpha = 1}) end

        local authorTxt = "[colour='FFFFFFFF']Created by: [colour='FF00FF00']" .. AUTHOR_NAME
        local a = createText(authorTxt, 0.25, 0.35, 0.50, 0.05)
        if a then UI.root:addChild(a) table.insert(menuElements, a) table.insert(animElements, {el = a, targetAlpha = 1}) end

        local siteTxt = "[colour='FFFFFFFF']VForge: [colour='FF4DD8D8']" .. VFORGE_URL
        local s = createText(siteTxt, 0.25, 0.42, 0.50, 0.05)
        if s then UI.root:addChild(s) table.insert(menuElements, s) table.insert(animElements, {el = s, targetAlpha = 1}) end

        local tgTxt = "[colour='FFFFFFFF']YouTube: [colour='FF4DD8D8']@MissGera"
        local t = createText(tgTxt, 0.25, 0.49, 0.50, 0.05)
        if t then UI.root:addChild(t) table.insert(menuElements, t) table.insert(animElements, {el = t, targetAlpha = 1}) end

        -- Закрыть кредиты (крестик)
        local closeCr = createButton("X", 0.72, 0.22, 0.05, 0.05, IMG_BTN, function()
            showCredits = false
            renderPage()
        end)
        if closeCr then UI.root:addChild(closeCr) table.insert(menuElements, closeCr) table.insert(animElements, {el = closeCr, targetAlpha = 1}) end
    end

    if currentMode == "textures" and not showCredits then
        local resetBtn = createButton("RESET", 0.08, 0.11, 0.15, 0.05, IMG_BTN, function()
            if copy_file(GAME_BACKUP_V1, GAME_DST_V1) and copy_file(GAME_BACKUP_V2, GAME_DST_V2) then
                os.remove(CONFIG_PATH)
                log('reset to vanilla')
                showToast("Восстановлены оригинальные текстуры!")
                renderPage()
            else
                showToast("Ошибка при восстановлении")
            end
        end)
        if resetBtn then UI.root:addChild(resetBtn) table.insert(menuElements, resetBtn) table.insert(animElements, {el = resetBtn, targetAlpha = 1}) end

        local copyBtn = createButton("COPY ZIP", 0.76, 0.11, 0.15, 0.05, IMG_BTN, function()
            showToast("Копирование началось, подождите...")
            local time = 0
            World.Timer(1, function()
                time = time + 1
                if time == 10 then
                    local dst = BASE_DIR .. "common_copy.zip"
                    local ok, result = copy_large_file(GAME_DST_V1, dst)
                    if ok then showToast("Скопировано " .. math.floor(result / 1024 / 1024) .. " МБ!") else showToast("Ошибка: " .. tostring(result)) end
                end
                return time < 10
            end)
        end)
        if copyBtn then UI.root:addChild(copyBtn) table.insert(menuElements, copyBtn) table.insert(animElements, {el = copyBtn, targetAlpha = 1}) end
    end

local dumpBtn = createButton("DUMP RES", 0.59, 0.11, 0.15, 0.05, IMG_BTN, function()
    showToast("Копирование папки началось...")
    local time = 0
    World.Timer(1, function()
        time = time + 1
        if time == 10 then
            local dst = BASE_DIR .. "app_resources_dump/"
            local src = '/data/user/0/com.sandboxol.blockymods/app_resources'
            local ok, err = pcall(copy_directory, src, dst)
            if ok then showToast("Дамп папки завершен!") else showToast("Ошибка дампа: " .. tostring(err)) end
        end
        return time < 10
    end)
end)
if dumpBtn then UI.root:addChild(dumpBtn) table.insert(menuElements, dumpBtn) table.insert(animElements, {el = dumpBtn, targetAlpha = 1}) end

    local y = 0.18
    local row_h = 0.12

    local startIdx = (currentPage - 1) * PACKS_PER_PAGE + 1
    local endIdx = startIdx + PACKS_PER_PAGE - 1
    if endIdx > #listData then endIdx = #listData end

    if not showCredits then
        for i = startIdx, endIdx do
            local item = listData[i]
            local rowIndex = i - startIdx + 1
            local isActive = false
            
            if currentMode == "textures" then
                isActive = (activePack == item.folder)
            else
                isActive = is_plugin_active(item.folder)
            end

            local rowBg = createBackground("row" .. rowIndex, 0.06*W, (y - 0.01)*H, 0.88*W, (row_h - 0.01)*H, IMG_ROW, isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15))
            if rowBg then UI.root:addChild(rowBg) table.insert(menuElements, rowBg) table.insert(animElements, {el = rowBg, targetAlpha = isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15)}) end

            -- Название
            local displayName = item.index .. ". " .. item.name .. " v" .. item.version
            if item.engine == 2 then displayName = displayName .. " [V2]" end
            if isActive then displayName = displayName .. " [ACTIVE]" end
            local colorTag = isActive and "FF00FF00" or "FFFFFFFF"
            local finalName = "[colour='" .. colorTag .. "']" .. displayName
            
            local label = createText(finalName, 0.09, y, 0.60, 0.04)
            if label then UI.root:addChild(label) table.insert(menuElements, label) table.insert(animElements, {el = label, targetAlpha = 1}) end

            -- Автор
            if item.author ~= '' then
                local authorText = "[colour='FF4DD8D8']by " .. item.author
                local au = createText(authorText, 0.09, y + 0.04, 0.60, 0.03)
                if au then UI.root:addChild(au) table.insert(menuElements, au) table.insert(animElements, {el = au, targetAlpha = 1}) end
            end

            -- Описание
            if item.description ~= '' then
                local descY = y + (item.author ~= '' and 0.075 or 0.045)
                local descText = "[colour='FFAAAAAA']" .. item.description
                local desc = createText(descText, 0.09, descY, 0.60, 0.04)
                if desc then 
                    pcall(function() desc:setTextSize(14) end)
                    UI.root:addChild(desc) table.insert(menuElements, desc) table.insert(animElements, {el = desc, targetAlpha = 1}) 
                end
            end

            -- Кнопка действия
            local btnText = "APPLY"
            if currentMode == "textures" then 
                btnText = isActive and "ACTIVE" or "APPLY" 
            else 
                btnText = isActive and "STOP" or "RUN" 
            end

            local btn = createButton(btnText, 0.72, y + 0.03, 0.20, 0.06, IMG_BTN, function()
                if currentMode == "textures" then
                    if isActive then return end
                    if apply_pack(item) then
                        showToast("Применён пак: " .. item.name)
                        renderPage()
                    else
                        showToast("Ошибка применения")
                    end
                else
                    local active_list = get_active_plugins()
                    if isActive then
                        for k, v in ipairs(active_list) do
                            if v == item.folder then table.remove(active_list, k) break end
                        end
                        save_active_plugins(active_list)
                        rebuild_plugins_lua()
                        showToast("Плагин отключен: " .. item.name)
                    else
                        table.insert(active_list, item.folder)
                        save_active_plugins(active_list)
                        rebuild_plugins_lua()
                        showToast("Плагин активирован! Перезайдите в игру.")
                    end
                    renderPage()
                end
            end)
            
            if btn then 
                UI.root:addChild(btn) table.insert(menuElements, btn) table.insert(animElements, {el = btn, targetAlpha = 1})
                if currentMode == "textures" and isActive then pcall(function() btn:setEnabled(false) end) end
            end

            y = y + row_h
        end
    end

    if totalPages > 1 and not showCredits then
        local pageText = createText("Стр. " .. currentPage .. " / " .. totalPages, 0.40, 0.84, 0.20, 0.05, COL_TEXT)
        if pageText then UI.root:addChild(pageText) table.insert(menuElements, pageText) table.insert(animElements, {el = pageText, targetAlpha = 1}) end

        if currentPage > 1 then
            local prevBtn = createButton("<", 0.30, 0.84, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage - 1
                renderPage()
            end)
            if prevBtn then UI.root:addChild(prevBtn) table.insert(menuElements, prevBtn) table.insert(animElements, {el = prevBtn, targetAlpha = 1}) end
        end

        if currentPage < totalPages then
            local nextBtn = createButton(">", 0.64, 0.84, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage + 1
                renderPage()
            end)
            if nextBtn then UI.root:addChild(nextBtn) table.insert(menuElements, nextBtn) table.insert(animElements, {el = nextBtn, targetAlpha = 1}) end
        end
    end

    local closeBtn = createButton("CLOSE", 0.40, 0.92, 0.20, 0.06, IMG_BTN, function()
        closeMenu()
    end)
    if closeBtn then UI.root:addChild(closeBtn) table.insert(menuElements, closeBtn) table.insert(animElements, {el = closeBtn, targetAlpha = 1}) end

    animateAppear()
end

-- === Открытие ===
local function openMenu()
    if menuOpen then closeMenu() return end
    menuOpen = true
    currentMode = "textures"
    allPacks = scan_packs()
    allScripts = scan_scripts()
    totalPages = math.ceil(#allPacks / PACKS_PER_PAGE)
    if totalPages < 1 then totalPages = 1 end
    currentPage = 1
    renderPage()
end

-- === Главная кнопка ===
local mainBtn = createButton("CeriumCore", 0.75, 0.02, 0.20, 0.05, IMG_BTN, function()
    openMenu()
end)
if mainBtn then UI.root:addChild(mainBtn) pcall(function() mainBtn:setAlpha(1) end) end


-- ========================================
-- CERIUM PLUGIN SYSTEM HOOK (ЗАГРУЗКА)
-- ========================================
pcall(function()
    local f = io.open(PLUGINS_LUA, "r")
    if f then
        local code = f:read("*a")
        f:close()
        
        local loader = rawget(_G, "loadstring") or rawget(_G, "load")
        if loader then
            local func, load_err = loader(code, "cerium_plugins")
            if func then
                local ok, run_err = pcall(func)
                if not ok then log("Plugin runtime error: " .. tostring(run_err)) end
            else
                log("Load error: " .. tostring(load_err))
            end
        end
    end
end)