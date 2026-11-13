-- ========================================
-- CeriumCore v1.4 — меню со скроллом
-- ========================================

local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'
local GAME_DIR = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST = GAME_DIR .. 'common.zip'
local LOG_PATH = LOGS_DIR .. 'cerium.log'

local COL_TEXT   = {1.00, 1.00, 1.00, 1.00}
local COL_ACCENT = {0.30, 0.85, 0.85, 1.00}

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

ensure_dir(LOGS_DIR)
ensure_dir(TEXTURES_DIR)
log('=== CeriumCore v1.4 started ===')

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
                        name = entry, version = '?', author = '',
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

if not UI or not Enum or not Enum.WidgetType then
    log('ERROR: UI not available')
    return
end

-- === Создание виджетов ===
local function createText(text, x, y, w, h, col)
    local ok, wdg = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Text) end)
    if not ok or not wdg then return nil end
    pcall(function() wdg:setText(text) end)
    pcall(function() wdg:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() wdg:setSize(UDim2.new(w, 0, h, 0)) end)
    if col then pcall(function() wdg:setTextColor(col) end) end
    return wdg
end

local function createButton(text, x, y, w, h, onClick)
    local ok, btn = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Button) end)
    if not ok or not btn then return nil end
    pcall(function() btn:setText(text) end)
    pcall(function() btn:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() btn:setSize(UDim2.new(w, 0, h, 0)) end)
    if onClick then btn.onMouseClick = function() onClick(btn) end end
    return btn
end

-- === Меню со скроллом ===
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

    -- Заголовок (фиксированный, вне скролла)
    local title = createText("CeriumCore", 0.08, 0.06, 0.50, 0.06, COL_ACCENT)
    if title then UI.root:addChild(title) table.insert(menuElements, title) end

    local sub = createText("Texture Packs", 0.55, 0.07, 0.35, 0.04, COL_TEXT)
    if sub then UI.root:addChild(sub) table.insert(menuElements, sub) end

    -- === СКРОЛЛ ===
    local scroll = UI:CreateGUIWidget(Enum.WidgetType.ScrollableView)
    if not scroll then
        log('ERROR: could not create ScrollableView')
        return
    end
    pcall(function() scroll:setPosition(UDim2.new(0.05, 0, 0.14, 0)) end)
    pcall(function() scroll:setSize(UDim2.new(0.90, 0, 0.70, 0)) end)
    pcall(function() UI.root:addChild(scroll) end)
    table.insert(menuElements, scroll)

    -- === Паки внутри скролла ===
    local packs = scan_packs()
    log('found packs: ' .. #packs)

    -- Внутри ScrollableView координаты — от 0, а не от 0.05
    -- каждый пак — строка высотой 0.08 (внутри scroll)
    local y = 0.02
    local row_h = 0.08

    for _, pack in ipairs(packs) do
        -- Текст: номер + имя + версия
        local label = createText(
            pack.index .. ". " .. pack.name .. "  v" .. pack.version,
            0.02, y, 0.60, 0.03
        )
        if label then
            pcall(function() scroll:addChild(label) end)
        end

        -- Автор
        if pack.author ~= '' then
            local au = createText("by " .. pack.author, 0.02, y + 0.03, 0.60, 0.025, COL_ACCENT)
            if au then pcall(function() scroll:addChild(au) end) end
        end

        -- Кнопка Apply
        local btn = createButton("APPLY", 0.68, y + 0.005, 0.28, 0.05, function()
            log('applying: ' .. pack.name)
            if apply_pack(pack) then
                local s = createText("Applied: " .. pack.name, 0.10, 0.86, 0.80, 0.04, COL_ACCENT)
                if s then UI.root:addChild(s) table.insert(menuElements, s) end
            end
        end)
        if btn then pcall(function() scroll:addChild(btn) end) end

        y = y + row_h
    end

    -- Close (фиксированный, вне скролла)
    local closeBtn = createButton("CLOSE", 0.40, 0.87, 0.20, 0.05, function()
        closeMenu()
    end)
    if closeBtn then UI.root:addChild(closeBtn) table.insert(menuElements, closeBtn) end

    log('menu opened, packs=' .. #packs)
end

-- === Главная кнопка ===
local mainBtn = createButton("CeriumCore", 0.75, 0.02, 0.20, 0.05, function()
    openMenu()
end)
if mainBtn then UI.root:addChild(mainBtn) log('main button created') end

log('=== CeriumCore v1.4 finished ===')