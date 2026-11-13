-- ========================================
-- CeriumCore v1.1
-- UI-меню текстурпаков для v2
-- Поддержка подпапок
-- Исходный код
-- ========================================

-- === Пути ===
local BASE_DIR = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
local TEXTURES_DIR = BASE_DIR .. 'cerium-texture/'
local LOGS_DIR = BASE_DIR .. 'logs/'
local CONFIG_PATH = BASE_DIR .. 'cerium_config.json'
local TEMP_ZIP = BASE_DIR .. 'texturepack.zip'

local GAME_DIR = '/data/user/0/com.sandboxol.blockymods/app_resources/'
local GAME_DST = GAME_DIR .. 'common.zip'

local LOG_PATH = LOGS_DIR .. 'cerium.log'

-- === Логирование ===
local function log(msg)
    local f = io.open(LOG_PATH, 'a')
    if f then
        f:write(os.date('%H:%M:%S') .. ' | ' .. tostring(msg) .. '\n')
        f:close()
    end
end

-- === Утилиты ===
local function ensure_dir(path)
    local ok, lfs = pcall(require, 'lfs')
    if ok and lfs then
        pcall(function() lfs.mkdir(path) end)
    end
end

local function file_exists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function read_file(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local content = f:read('*a')
    f:close()
    return content
end

local function write_file(path, content)
    local f = io.open(path, 'w')
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

ensure_dir(LOGS_DIR)
ensure_dir(TEXTURES_DIR)

log('=== CeriumCore started ===')

-- === cjson ===
local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then
    log('ERROR: cjson not available')
    return
end

-- === Сканирование подпапок ===
local function scan_packs()
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok or not lfs then
        log('ERROR: lfs not available')
        return {}
    end

    local packs = {}
    local index = 1

    -- Идём по папкам внутри cerium-texture/
    for entry in lfs.dir(TEXTURES_DIR) do
        if entry ~= '.' and entry ~= '..' then
            local entry_path = TEXTURES_DIR .. entry
            local attr = lfs.attributes(entry_path)

            if attr and attr.mode == 'directory' then
                -- Это папка пака
                local zip_path = entry_path .. '/texturepack.zip'
                local manifest_path = entry_path .. '/manifest.json'
                local logo_path = entry_path .. '/logo.png'

                if file_exists(zip_path) then
                    local pack = {
                        index = index,
                        folder = entry,
                        zip = zip_path,
                        manifest = manifest_path,
                        logo = logo_path,
                        name = entry,
                        version = '?',
                        description = '',
                        author = '',
                    }

                    local manifest_content = read_file(manifest_path)
                    if manifest_content then
                        local ok, data = pcall(cjson.decode, manifest_content)
                        if ok and data then
                            pack.name = data.name or entry
                            pack.version = data.version or '?'
                            pack.description = data.description or ''
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

-- === Применение пака ===
local function apply_pack(pack)
    if not file_exists(pack.zip) then
        log('ERROR: pack not found: ' .. pack.zip)
        return false
    end

    local data = read_file(pack.zip)
    if not data then
        log('ERROR: could not read pack')
        return false
    end

    write_file(TEMP_ZIP, data)
    write_file(GAME_DST, data)

    log('applied pack: ' .. pack.name)

    local config = {
        selected = pack.index,
        selected_name = pack.name,
        selected_folder = pack.folder,
    }
    write_file(CONFIG_PATH, cjson.encode(config))

    return true
end

-- === UI ===
if not UI or not Enum or not Enum.WidgetType then
    log('ERROR: UI not available')
    return
end

local function createText(text, x, y, w, h)
    local ok, widget = pcall(function()
        return UI:CreateGUIWidget(Enum.WidgetType.Text)
    end)
    if not ok or not widget then return nil end

    pcall(function() widget:setText(text) end)
    pcall(function() widget:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() widget:setSize(UDim2.new(w, 0, h, 0)) end)
    return widget
end

local function createButton(text, x, y, w, h, onClick)
    local ok, btn = pcall(function()
        return UI:CreateGUIWidget(Enum.WidgetType.Button)
    end)
    if not ok or not btn then return nil end

    pcall(function() btn:setText(text) end)
    pcall(function() btn:setPosition(UDim2.new(x, 0, y, 0)) end)
    pcall(function() btn:setSize(UDim2.new(w, 0, h, 0)) end)

    if onClick then
        btn.onMouseClick = function()
            onClick(btn)
        end
    end

    return btn
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
    if menuOpen then
        closeMenu()
        return
    end

    menuOpen = true
    menuElements = {}

    local title = createText("CeriumCore - Texture Packs", 0.05, 0.05, 0.9, 0.05)
    if title then
        UI.root:addChild(title)
        table.insert(menuElements, title)
    end

    local packs = scan_packs()
    log('found packs: ' .. #packs)

    local y = 0.15
    for _, pack in ipairs(packs) do
        local label = createText(
            pack.index .. '. ' .. pack.name .. ' v' .. pack.version .. ' (' .. pack.author .. ')',
            0.05, y, 0.6, 0.05
        )
        if label then
            UI.root:addChild(label)
            table.insert(menuElements, label)
        end

        local btn = createButton(
            "Apply",
            0.7, y, 0.2, 0.05,
            function()
                log('applying: ' .. pack.name)
                local ok = apply_pack(pack)
                if ok then
                    local status = createText(
                        "Applied: " .. pack.name,
                        0.05, 0.85, 0.9, 0.05
                    )
                    if status then
                        UI.root:addChild(status)
                        table.insert(menuElements, status)
                    end
                end
            end
        )
        if btn then
            UI.root:addChild(btn)
            table.insert(menuElements, btn)
        end

        y = y + 0.07
        if y > 0.8 then break end
    end

    local closeBtn = createButton(
        "Close",
        0.4, 0.9, 0.2, 0.05,
        function()
            closeMenu()
        end
    )
    if closeBtn then
        UI.root:addChild(closeBtn)
        table.insert(menuElements, closeBtn)
    end

    log('menu opened with ' .. #packs .. ' packs')
end

-- === Главная кнопка ===
local mainBtn = createButton(
    "CeriumCore",
    0.75, 0.02, 0.2, 0.05,
    function()
        openMenu()
    end
)
if mainBtn then
    UI.root:addChild(mainBtn)
    log('main button created')
end

log('=== CeriumCore finished ===')