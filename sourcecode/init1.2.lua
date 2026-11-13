-- ========================================
-- CeriumCore v1.2 — красивое меню
-- Тёмно-бирюзовый фон, крупный UI
-- ========================================

local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'
local GAME_DIR = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST = GAME_DIR .. 'common.zip'
local LOG_PATH = LOGS_DIR .. 'cerium.log'

-- === Цвета (тёмно-бирюзовый) ===
local COL_BG      = {0.05, 0.18, 0.20, 0.95}   -- фон меню
local COL_HEADER  = {0.10, 0.30, 0.33, 1.00}   -- плашка заголовка
local COL_BTN     = {0.15, 0.55, 0.58, 1.00}   -- кнопка Apply
local COL_BTN_RED = {0.55, 0.20, 0.20, 1.00}   -- кнопка Close
local COL_TEXT    = {1.00, 1.00, 1.00, 1.00}   -- белый текст
local COL_ACCENT  = {0.30, 0.85, 0.85, 1.00}   -- бирюзовый акцент

-- === Логи ===
local function log(msg)
    local f = io.open(LOG_PATH, 'a')
    if f then
        f:write(os.date('%H:%M:%S') .. ' | ' .. tostring(msg) .. '\n')
        f:close()
    end
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
    local c = f:read('*a')
    f:close()
    return c
end

local function write_file(path, content)
    local f = io.open(path, 'w')
    if not f then return false end
    f:write(content); f:close()
    return true
end

ensure_dir(LOGS_DIR)
ensure_dir(TEXTURES_DIR)
log('=== CeriumCore v1.2 started ===')

local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then
    log('ERROR: cjson not available')
    return
end

-- === Сканирование паков ===
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
                        index = index,
                        folder = entry,
                        zip = zip_path,
                        name = entry,
                        version = '?',
                        author = '',
                    }
                    local mc = read_file(entry_path .. '/manifest.json')
                    if mc then
                        local ok, data = pcall(cjson.decode, mc)
                        if ok and data then
                            pack.name = data.name or entry
                            pack.version = data.version or '?'
                            pack.author = data.author or ''
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

-- === UI ===
if not UI or not Enum or not Enum.WidgetType then
    log('ERROR: UI not available')
    return
end

local function setBg(widget, col)
    pcall(function() widget:SetBackgroundColor(col) end)
end

local function setTextColor(widget, col)
    pcall(function() widget:SetTextColor(col) end)
end

local function createText(text, x, y, w, h, col)
    local ok, wdg = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Text) end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setText(text) end)
    pcall(function() wdg:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() wdg:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then setTextColor(wdg, col) end
    return wdg
end

local function createButton(text, x, y, w, h, col, onClick)
    local ok, btn = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Button) end)
    if not ok or not btn then return nil end
    pcall(function() btn:setText(text) end)
    pcall(function() btn:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() btn:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then setBg(btn, col) end
    setTextColor(btn, COL_TEXT)
    if onClick then btn.onMouseClick = function() onClick(btn) end end
    return btn
end

local function createImage(x, y, w, h, col)
    local ok, img = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Image) end)
    if not ok or not img then return nil end
    pcall(function() img:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() img:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then setBg(img, col) end
    return img
end

-- === Меню ===
local menuOpen = false
local menuElements = {}

local function closeMenu()
    for _, el in ipairs(menuElements) do
        pcall(function() el:setVisible(false) end)
    end
    menuElements = {}
    menuOpen = false
    log('menu closed')
end

local function openMenu()
    if menuOpen then closeMenu() return end
    menuOpen = true
    menuElements = {}

    -- ФОН
    local bg = createImage(0.05, 0.08, 0.90, 0.84, COL_BG)
    if bg then UI.root:addChild(bg) table.insert(menuElements, bg) end

    -- ПЛАШКА ЗАГОЛОВКА
    local hdr = createImage(0.05, 0.08, 0.90, 0.08, COL_HEADER)
    if hdr then UI.root:addChild(hdr) table.insert(menuElements, hdr) end

    -- ЗАГОЛОВОК
    local title = createText("CeriumCore", 0.10, 0.09, 0.50, 0.06, COL_ACCENT)
    if title then UI.root:addChild(title) table.insert(menuElements, title) end

    -- Подзаголовок
    local sub = createText("Texture Packs", 0.60, 0.10, 0.30, 0.04, COL_TEXT)
    if sub then UI.root:addChild(sub) table.insert(menuElements, sub) end

    -- Сканируем
    local packs = scan_packs()
    log('found packs: ' .. #packs)

    local y = 0.18
    local row_h = 0.08
    local row_gap = 0.02

    for _, pack in ipairs(packs) do
        -- строка
        local row = createImage(0.07, y, 0.86, row_h, {0.08, 0.22, 0.25, 0.85})
        if row then UI.root:addChild(row) table.insert(menuElements, row) end

        -- название
        local label = createText(
            pack.index .. ". " .. pack.name .. "  v" .. pack.version,
            0.09, y + 0.02, 0.55, 0.04, COL_TEXT
        )
        if label then UI.root:addChild(label) table.insert(menuElements, label) end

        -- автор
        if pack.author ~= '' then
            local au = createText("by " .. pack.author, 0.09, y + 0.045, 0.55, 0.03, COL_ACCENT)
            if au then UI.root:addChild(au) table.insert(menuElements, au) end
        end

        -- Apply
        local btn = createButton("APPLY", 0.75, y + 0.015, 0.16, 0.05, COL_BTN, function()
            log('applying: ' .. pack.name)
            if apply_pack(pack) then
                local s = createText("Applied: " .. pack.name, 0.10, 0.86, 0.80, 0.04, COL_ACCENT)
                if s then UI.root:addChild(s) table.insert(menuElements, s) end
            end
        end)
        if btn then UI.root:addChild(btn) table.insert(menuElements, btn) end

        y = y + row_h + row_gap
        if y > 0.80 then break end
    end

    -- Close
    local closeBtn = createButton("CLOSE", 0.40, 0.86, 0.20, 0.05, COL_BTN_RED, function()
        closeMenu()
    end)
    if closeBtn then UI.root:addChild(closeBtn) table.insert(menuElements, closeBtn) end

    log('menu opened, packs=' .. #packs)
end

-- === Главная кнопка ===
local mainBtn = createButton("CeriumCore", 0.75, 0.02, 0.20, 0.05, COL_BTN, function()
    openMenu()
end)
if mainBtn then UI.root:addChild(mainBtn) log('main button created') end

log('=== CeriumCore v1.2 finished ===')