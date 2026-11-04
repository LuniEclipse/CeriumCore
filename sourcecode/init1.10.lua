-- ========================================
-- CeriumCore v1.10
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
-- Build Version: 11005
-- Lang type: mix
--EN, --RU, --mix — a combination of two or more languages
-- download url: vforge.pythonanywhere.com/pack/35
-- ========================================

local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local SCRIPTS_DIR = BASE_DIR .. 'cerium-scripts/'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'
local GAME_DIR = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST = GAME_DIR .. 'common.zip'
local GAME_BACKUP = GAME_DIR .. 'common_backup.zip'
local LOG_PATH = LOGS_DIR .. 'cerium.log'

local COL_TEXT   = {1.00, 1.00, 1.00, 1.00}
local COL_ACCENT = {0.30, 0.85, 0.85, 1.00}
local COL_DESC   = {0.80, 0.80, 0.80, 1.00} -- Серый цвет для описания

local IMG_PANEL    = "cegui_main_page/top_toorbar_bg"
local IMG_ROW      = "shop/commodity"
local IMG_BTN      = "shop/buy_btn"

local PACKS_PER_PAGE = 6
local MAX_DESC_LENGTH = 50 -- Лимит на описание

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
log('=== CeriumCore v1.10 started ===')

if not file_exists(GAME_BACKUP) and file_exists(GAME_DST) then
    if copy_file(GAME_DST, GAME_BACKUP) then log('created backup') end
end

local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then return end

-- === Сканирование (с чтением описания) ===
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
                    local pack = {
                        index = index, folder = entry, zip = zip_path,
                        name = entry, version = '?', author = '', description = ''
                    }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            -- Читаем данные (с поддержкой разных ключей)
                            pack.name = data.name or data.title or entry
                            pack.version = tostring(data.version or data.v or '1.0')
                            pack.author = data.author or data.author_name or ''
                            pack.description = data.description or data.desc or ''
                            
                            -- Обрезаем описание, если оно слишком длинное
                            if #pack.description > MAX_DESC_LENGTH then
                                pack.description = string.sub(pack.description, 1, MAX_DESC_LENGTH) .. "..."
                            end
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

-- === Сканирование скриптов ===
local function scan_scripts()
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok or not lfs then return {} end
    local scripts = {}
    local index = 1
    for entry in lfs.dir(SCRIPTS_DIR) do
        if entry ~= '.' and entry ~= '..' then
            local entry_path = SCRIPTS_DIR .. entry
            local attr = lfs.attributes(entry_path)
            if attr and attr.mode == 'directory' then
                local script_path = entry_path .. '/script.lua'
                if file_exists(script_path) then
                    local script = { index = index, folder = entry, path = script_path, name = entry, version = '?', author = '' }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            script.name = data.name or entry
                            script.version = tostring(data.version or '1.0')
                            script.author = data.author or ''
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
    write_file(GAME_DST, data)
    write_file(CONFIG_PATH, cjson.encode({ selected = pack.index, selected_name = pack.name, selected_folder = pack.folder }))
    log('applied: ' .. pack.name)
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

    local panel = createBackground("panel", 0.05*W, 0.03*H, 0.90*W, 0.94*H, IMG_PANEL, 0.85)
    if panel then UI.root:addChild(panel) table.insert(menuElements, panel) table.insert(animElements, {el = panel, targetAlpha = 0.85}) end

    local title = createText("CeriumCore", 0.08, 0.05, 0.50, 0.08, COL_ACCENT)
    if title then UI.root:addChild(title) table.insert(menuElements, title) table.insert(animElements, {el = title, targetAlpha = 1}) end

    local modeBtnText = (currentMode == "textures") and "SCRIPTS" or "TEXTURES"
    local modeBtn = createButton(modeBtnText, 0.25, 0.11, 0.15, 0.05, IMG_BTN, function()
        currentMode = (currentMode == "textures") and "scripts" or "textures"
        currentPage = 1
        renderPage()
    end)
    if modeBtn then UI.root:addChild(modeBtn) table.insert(menuElements, modeBtn) table.insert(animElements, {el = modeBtn, targetAlpha = 1}) end

    if currentMode == "textures" then
        local resetBtn = createButton("RESET", 0.08, 0.11, 0.15, 0.05, IMG_BTN, function()
            if not file_exists(GAME_BACKUP) then showToast("Ошибка: бэкап не найден!") return end
            if copy_file(GAME_BACKUP, GAME_DST) then
                os.remove(CONFIG_PATH)
                log('reset to vanilla')
                showToast("Восстановлены оригинальные текстуры!")
                renderPage()
            else
                showToast("Ошибка при восстановлении")
            end
        end)
        if resetBtn then UI.root:addChild(resetBtn) table.insert(menuElements, resetBtn) table.insert(animElements, {el = resetBtn, targetAlpha = 1}) end

        local copyBtn = createButton("COPY ZIP", 0.42, 0.11, 0.15, 0.05, IMG_BTN, function()
            showToast("Копирование началось, подождите...")
            local time = 0
            World.Timer(1, function()
                time = time + 1
                if time == 10 then
                    local dst = BASE_DIR .. "common_copy.zip"
                    local ok, result = copy_large_file(GAME_DST, dst)
                    if ok then showToast("Скопировано " .. math.floor(result / 1024 / 1024) .. " МБ!") else showToast("Ошибка: " .. tostring(result)) end
                end
                return time < 10
            end)
        end)
        if copyBtn then UI.root:addChild(copyBtn) table.insert(menuElements, copyBtn) table.insert(animElements, {el = copyBtn, targetAlpha = 1}) end

        local dumpBtn = createButton("DUMP RES", 0.58, 0.11, 0.15, 0.05, IMG_BTN, function()
            showToast("Копирование папки началось...")
            local time = 0
            World.Timer(1, function()
                time = time + 1
                if time == 10 then
                    local dst = BASE_DIR .. "app_resources_dumpmax/"
                    local src = '/data/user/0/com.sandboxol.blockymods/app_resources'
                    local ok, err = pcall(copy_directory, src, dst)
                    if ok then showToast("Дамп папки завершен!") else showToast("Ошибка дампа: " .. tostring(err)) end
                end
                return time < 10
            end)
        end)
        if dumpBtn then UI.root:addChild(dumpBtn) table.insert(menuElements, dumpBtn) table.insert(animElements, {el = dumpBtn, targetAlpha = 1}) end
    end

    local y = 0.20
    local row_h = 0.11 -- Чуть увеличили высоту строки, чтобы влезло описание

    local startIdx = (currentPage - 1) * PACKS_PER_PAGE + 1
    local endIdx = startIdx + PACKS_PER_PAGE - 1
    if endIdx > #listData then endIdx = #listData end

    for i = startIdx, endIdx do
        local item = listData[i]
        local rowIndex = i - startIdx + 1
        local isActive = (currentMode == "textures") and (activePack == item.folder)

        local rowBg = createBackground("row" .. rowIndex, 0.06*W, (y - 0.01)*H, 0.88*W, (row_h - 0.01)*H, IMG_ROW, isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15))
        if rowBg then UI.root:addChild(rowBg) table.insert(menuElements, rowBg) table.insert(animElements, {el = rowBg, targetAlpha = isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15)}) end

        -- 1. Название пака (Сдвиг x=0.09, так как логотипов больше нет)
        local displayName = item.index .. ". " .. item.name .. " v" .. item.version
        if isActive then displayName = displayName .. " [ACTIVE]" end
        
        local label = createText(displayName, 0.09, y, 0.60, 0.05, isActive and COL_ACCENT or COL_TEXT)
        if label then UI.root:addChild(label) table.insert(menuElements, label) table.insert(animElements, {el = label, targetAlpha = 1}) end

        -- 2. Автор
        if item.author ~= '' then
            local au = createText("by " .. item.author, 0.09, y + 0.04, 0.60, 0.03, COL_ACCENT)
            if au then UI.root:addChild(au) table.insert(menuElements, au) table.insert(animElements, {el = au, targetAlpha = 1}) end
        end

        -- 3. Описание (только для текстур)
        if currentMode == "textures" and item.description ~= '' then
            local descY = y + (item.author ~= '' and 0.07 or 0.04)
            local desc = createText(item.description, 0.09, descY, 0.60, 0.03, COL_DESC)
            if desc then 
                pcall(function() desc:setTextSize(14) end) -- Шрифт чуть меньше
                UI.root:addChild(desc) table.insert(menuElements, desc) table.insert(animElements, {el = desc, targetAlpha = 1}) 
            end
        end

        -- Кнопка действия
        local btnText = "APPLY"
        if currentMode == "textures" then btnText = isActive and "ACTIVE" or "APPLY" else btnText = "RUN" end

        local btn = createButton(btnText, 0.72, y + 0.02, 0.20, 0.06, IMG_BTN, function()
            if currentMode == "textures" then
                if isActive then return end
                if apply_pack(item) then
                    showToast("Применён пак: " .. item.name)
                    renderPage()
                else
                    showToast("Ошибка применения")
                end
            end
        end)
        
        if btn then 
            UI.root:addChild(btn) table.insert(menuElements, btn) table.insert(animElements, {el = btn, targetAlpha = 1})
            if currentMode == "textures" and isActive then pcall(function() btn:setEnabled(false) end) end
        end

        y = y + row_h
    end

    if totalPages > 1 then
        local pageText = createText("Стр. " .. currentPage .. " / " .. totalPages, 0.40, 0.88, 0.20, 0.05, COL_TEXT)
        if pageText then UI.root:addChild(pageText) table.insert(menuElements, pageText) table.insert(animElements, {el = pageText, targetAlpha = 1}) end

        if currentPage > 1 then
            local prevBtn = createButton("<", 0.30, 0.88, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage - 1
                renderPage()
            end)
            if prevBtn then UI.root:addChild(prevBtn) table.insert(menuElements, prevBtn) table.insert(animElements, {el = prevBtn, targetAlpha = 1}) end
        end

        if currentPage < totalPages then
            local nextBtn = createButton(">", 0.64, 0.88, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage + 1
                renderPage()
            end)
            if nextBtn then UI.root:addChild(nextBtn) table.insert(menuElements, nextBtn) table.insert(animElements, {el = nextBtn, targetAlpha = 1}) end
        end
    end

    local closeBtn = createButton("CLOSE", 0.40, 0.94, 0.20, 0.06, IMG_BTN, function()
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