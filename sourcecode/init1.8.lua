-- ========================================
-- CeriumCore v1.8
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
-- Build Version: 11805
-- Lang type: mix
--EN, --RU, --mix — a combination of two or more languages
-- download url: vforge.pythonanywhere.com/pack/35
-- ========================================

local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'
local GAME_DIR = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST = GAME_DIR .. 'common.zip'
local GAME_BACKUP = GAME_DIR .. 'common_backup.zip' -- Наш бэкап оригинальных текстур
local LOG_PATH = LOGS_DIR .. 'cerium.log'

local COL_TEXT   = {1.00, 1.00, 1.00, 1.00}
local COL_ACCENT = {0.30, 0.85, 0.85, 1.00}

local IMG_PANEL    = "cegui_main_page/top_toorbar_bg"
local IMG_ROW      = "shop/commodity"
local IMG_BTN      = "shop/buy_btn"

local PACKS_PER_PAGE = 6

local function log(msg)
    local f = io.open(LOG_PATH, 'a')
    if f then f:write(os.date('%H:%M:%S') .. ' | ' .. tostring(msg) .. '\n') f:close() end
end

local function ensure_dir(path)
    local ok, lfs = pcall(require, 'lfs')
    if ok and lfs then pcall(function() lfs.mkdir(path) end) end
end

local function file_exists(path)
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
log('=== CeriumCore v1.8 started ===')

-- 12. Бэкап оригинального common.zip при первом запуске
if not file_exists(GAME_BACKUP) and file_exists(GAME_DST) then
    if copy_file(GAME_DST, GAME_BACKUP) then
        log('created backup: ' .. GAME_BACKUP)
    else
        log('ERROR: failed to create backup')
    end
end

local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then
    log('ERROR: cjson not available')
    return
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
                    local pack = {
                        index = index, folder = entry, zip = zip_path,
                        name = entry, version = '?', author = '', description = '',
                    }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            pack.name = data.name or entry
                            pack.version = data.version or '?'
                            pack.author = data.author or ''
                            pack.description = data.description or ''
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

-- === Чтение конфига (для индикатора) ===
local function get_active_pack()
    local c = read_file(CONFIG_PATH)
    if not c then return nil end
    local ok, data = pcall(cjson.decode, c)
    if ok and data and data.selected_folder then
        return data.selected_folder
    end
    return nil
end

-- === Применение ===
local function apply_pack(pack)
    if not file_exists(pack.zip) then return false end
    local data = read_file(pack.zip)
    if not data then return false end
    write_file(TEMP_ZIP, data)
    write_file(GAME_DST, data)
    write_file(CONFIG_PATH, cjson.encode({
        selected = pack.index,
        selected_name = pack.name,
        selected_folder = pack.folder,
    }))
    log('applied: ' .. pack.name)
    return true
end

-- === 9. Тосты ===
local function showToast(msg)
    -- Используем игровое событие тоста
    pcall(function()
        Lib.emitEvent(Event.EVENT_TOAST_TIP, "[colour='FF00FF00']" .. msg, 20, 60)
    end)
end

if not UI or not Enum or not Enum.WidgetType then
    log('ERROR: UI not available')
    return
end

local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local screenSize = GUIManager.Instance():getScreenSize()
local W = screenSize.x
local H = screenSize.y

-- === Фон через Engine/StaticImage ===
local bgCounter = 0
local function createBackground(name, x, y, w, h, image, alpha)
    bgCounter = bgCounter + 1
    local ok, wdg = pcall(function()
        return winMgr:createWindow("Engine/StaticImage",
            name .. "-bg-" .. bgCounter .. "-" .. winMgr:generateUniqueWindowName())
    end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setProperty("FrameEnabled", false) end)
    pcall(function() wdg:setImage(image) end)
    pcall(function() wdg:setArea2({0, x}, {0, y}, {0, w}, {0, h}) end)
    pcall(function() wdg:setAlpha(0) end) -- 8. Начинаем с прозрачного для анимации
    pcall(function() wdg:setMousePassThroughEnabled(true) end)
    pcall(function() wdg:setDestroyedByParent(false) end)
    pcall(function() wdg:setVisible(true) end)
    return wdg
end

-- === Текст ===
local function createText(text, x, y, w, h, col)
    local ok, wdg = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Text) end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setText(text) end)
    pcall(function() wdg:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() wdg:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then pcall(function() wdg:setTextColor(col) end) end
    -- Увеличение шрифта (если API поддерживает)
    pcall(function() wdg:setTextSize(18) end)
    pcall(function() wdg:setAlpha(0) end) -- для анимации
    return wdg
end

-- === Кнопка ===
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
    pcall(function() btn:setAlpha(0) end) -- для анимации
    if onClick then btn.onMouseClick = function() onClick(btn) end end
    return btn
end

-- === Состояние ===
local menuOpen = false
local menuElements = {}
local animElements = {}
local allPacks = {}
local currentPage = 1
local totalPages = 1

local function clearElements()
    for _, el in ipairs(menuElements) do
        pcall(function() el:setVisible(false) end)
    end
    menuElements = {}
    animElements = {}
end

local function closeMenu()
    clearElements()
    menuOpen = false
    log('menu closed')
end

-- 8. Анимация появления
local function animateAppear()
    local time = 0
    World.Timer(1, function()
        if not menuOpen then return false end
        time = time + 1
        local progress = math.min(time / 10, 1) -- 10 кадров ~ 0.15 сек
        for _, data in ipairs(animElements) do
            pcall(function() data.el:setAlpha((data.targetAlpha or 0.85) * progress) end)
        end
        if progress >= 1 then return false end
        return true
    end)
end

-- === Отрисовка страницы ===
local function renderPage()
    clearElements()
    local activePack = get_active_pack()

    -- Панель
    local panel = createBackground("panel", 0.05*W, 0.03*H, 0.90*W, 0.94*H, IMG_PANEL, 0.85)
    if panel then 
        UI.root:addChild(panel) 
        table.insert(menuElements, panel) 
        table.insert(animElements, {el = panel, targetAlpha = 0.85})
    end

    -- Заголовок
    local title = createText("CeriumCore", 0.08, 0.05, 0.50, 0.08, COL_ACCENT)
    if title then 
        UI.root:addChild(title) 
        table.insert(menuElements, title) 
        table.insert(animElements, {el = title, targetAlpha = 1})
    end

    -- Кнопка RESET (в левом верхнем углу)
    local resetBtn = createButton("RESET", 0.08, 0.11, 0.15, 0.05, IMG_BTN, function()
        if not file_exists(GAME_BACKUP) then
            showToast("Ошибка: бэкап не найден!")
            return
        end
        if copy_file(GAME_BACKUP, GAME_DST) then
            -- Удаляем конфиг, чтобы сбросить индикатор
            os.remove(CONFIG_PATH) 
            log('reset to vanilla')
            showToast("Восстановлены оригинальные текстуры!")
            renderPage() -- Перерисовываем меню
        else
            showToast("Ошибка при восстановлении")
        end
    end)
    if resetBtn then 
        UI.root:addChild(resetBtn) 
        table.insert(menuElements, resetBtn) 
        table.insert(animElements, {el = resetBtn, targetAlpha = 1})
    end

    local y = 0.20
    local row_h = 0.10

    local startIdx = (currentPage - 1) * PACKS_PER_PAGE + 1
    local endIdx = startIdx + PACKS_PER_PAGE - 1
    if endIdx > #allPacks then endIdx = #allPacks end

    for i = startIdx, endIdx do
        local pack = allPacks[i]
        local rowIndex = i - startIdx + 1
        local isActive = (activePack == pack.folder)

        -- Фон строки
        local rowBg = createBackground("row" .. rowIndex,
            0.06*W, (y - 0.01)*H, 0.88*W, (row_h - 0.01)*H,
            IMG_ROW, isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15))
        if rowBg then 
            UI.root:addChild(rowBg) 
            table.insert(menuElements, rowBg)
            table.insert(animElements, {el = rowBg, targetAlpha = isActive and 0.5 or ((rowIndex % 2 == 0) and 0.35 or 0.15)})
        end

        -- Название пака
        local displayName = pack.index .. ". " .. pack.name .. " v" .. pack.version
        if isActive then displayName = displayName .. " [ACTIVE]" end
        
        local label = createText(displayName, 0.09, y, 0.55, 0.06, isActive and COL_ACCENT or COL_TEXT)
        if label then 
            UI.root:addChild(label) 
            table.insert(menuElements, label)
            table.insert(animElements, {el = label, targetAlpha = 1})
        end

        if pack.author ~= '' then
            local au = createText("by " .. pack.author, 0.09, y + 0.05, 0.55, 0.04, COL_ACCENT)
            if au then 
                UI.root:addChild(au) 
                table.insert(menuElements, au)
                table.insert(animElements, {el = au, targetAlpha = 1})
            end
        end

        -- Кнопка APPLY
        local btnText = isActive and "ACTIVE" or "APPLY"
        local btn = createButton(btnText, 0.72, y + 0.01, 0.20, 0.06, IMG_BTN, function()
            if isActive then return end -- Если уже активно, ничего не делаем
            log('applying: ' .. pack.name)
            if apply_pack(pack) then
                showToast("Применён пак: " .. pack.name)
                renderPage() -- Перерисовываем, чтобы обновить индикатор
            else
                showToast("Ошибка применения пака")
            end
        end)
        if btn then 
            UI.root:addChild(btn) 
            table.insert(menuElements, btn)
            table.insert(animElements, {el = btn, targetAlpha = 1})
            if isActive then pcall(function() btn:setEnabled(false) end) end
        end

        y = y + row_h
    end

    -- Пагинация
    if totalPages > 1 then
        local pageText = createText("Стр. " .. currentPage .. " / " .. totalPages, 0.40, 0.85, 0.20, 0.05, COL_TEXT)
        if pageText then 
            UI.root:addChild(pageText) 
            table.insert(menuElements, pageText)
            table.insert(animElements, {el = pageText, targetAlpha = 1})
        end

        if currentPage > 1 then
            local prevBtn = createButton("<", 0.30, 0.85, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage - 1
                renderPage()
            end)
            if prevBtn then 
                UI.root:addChild(prevBtn) 
                table.insert(menuElements, prevBtn)
                table.insert(animElements, {el = prevBtn, targetAlpha = 1})
            end
        end

        if currentPage < totalPages then
            local nextBtn = createButton(">", 0.64, 0.85, 0.06, 0.06, IMG_BTN, function()
                currentPage = currentPage + 1
                renderPage()
            end)
            if nextBtn then 
                UI.root:addChild(nextBtn) 
                table.insert(menuElements, nextBtn)
                table.insert(animElements, {el = nextBtn, targetAlpha = 1})
            end
        end
    end

    -- Кнопка CLOSE
    local closeBtn = createButton("CLOSE", 0.40, 0.92, 0.20, 0.06, IMG_BTN, function()
        closeMenu()
    end)
    if closeBtn then 
        UI.root:addChild(closeBtn) 
        table.insert(menuElements, closeBtn)
        table.insert(animElements, {el = closeBtn, targetAlpha = 1})
    end

    -- Запускаем анимацию
    animateAppear()
end

-- === Открытие ===
local function openMenu()
    if menuOpen then closeMenu() return end
    menuOpen = true

    allPacks = scan_packs()
    totalPages = math.ceil(#allPacks / PACKS_PER_PAGE)
    if totalPages < 1 then totalPages = 1 end
    currentPage = 1

    log('found packs: ' .. #allPacks .. ', pages: ' .. totalPages)
    renderPage()
end

-- === Главная кнопка ===
local mainBtn = createButton("CeriumCore", 0.75, 0.02, 0.20, 0.05, IMG_BTN, function()
    openMenu()
end)
if mainBtn then 
    UI.root:addChild(mainBtn) 
    pcall(function() mainBtn:setAlpha(1) end) -- Главная кнопка всегда видима
    log('main button created') 
end

log('=== CeriumCore v1.8 finished ===')