-- ========================================
-- × CeriumCore v1.12.1 Nova
-- • Pre-release version
-- • By: MissGera, DeepSeek x Claude
-- • id: 4266449440
-- • YT: https://youtube.com/@missgeraa
-- × Telegram Channel: https://t.me/korobkageri
-- ========================================
-- Made specifically for vforge.pythonanywhere.com
-- If you get banned, it's your fault, not ours.
-- Please read the README_EN.md or README.md file before using it for anything other than purely user-oriented purposes.
-- ========================================
-- × Build Version: 11212
-- • Lang type: mix
-- × download url: vforge.pythonanywhere.com/pack/35
-- ========================================

local P = {}   --> пути и константы
local U = {}   --> утилиты
local S = {}   --> состояние
local C = {}   --> ядро (паки, плагины, задачи)
local X = {}   --> UI-тулкит
local SCR = {} --> экраны
local SDK = {} --> Cerium SDK для плагинов

local unpack = (type(table) == 'table' and type(table.unpack) == 'function') and table.unpack or function() return nil end
local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min
local sfmt = string.format

do
    local prev = rawget(_G, "__CERIUM_CORE__")
    if type(prev) == "table" and type(prev.destroy) == "function" then pcall(prev.destroy) end
end

-- ========================================
-- ПУТИ
-- ========================================
P.BASE      = '/storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20151633/'
P.TEX       = P.BASE .. 'cerium-texture/'
P.SCR       = P.BASE .. 'cerium-scripts/'
P.PLUG_CFG  = P.SCR .. 'plugins_config.json'
P.PLUG_LUA  = P.SCR .. 'plugins.lua'
P.LOGS      = P.BASE .. 'logs/'
P.LOG       = P.LOGS .. 'cerium.log'
P.CFG       = P.BASE .. 'cerium_config.json'
P.TEMP_ZIP  = P.BASE .. 'texturepack.zip'          -- наследие 1.11 (чистится в Tools)
P.GAME = {
    [1] = { dir = '/data/user/0/com.sandboxol.blockymods/app_resources/' },
    [2] = { dir = '/data/user/0/com.sandboxol.blockymods/app_resourcesv2/' },
}
for _, g in pairs(P.GAME) do g.dst = g.dir .. 'common.zip'; g.bak = g.dir .. 'common_backup.zip' end
P.DUMP_SRC  = '/data/user/0/com.sandboxol.blockymods/app_resources'
P.DUMP_DST  = P.BASE .. 'app_resources_dump/'

P.IMG_PANEL = "cegui_main_page/top_toorbar_bg"
P.IMG_ROW   = "shop/commodity"
P.IMG_BTN   = "shop/buy_btn"

P.PER_PACKS   = 6
P.PER_PLUGINS = 5
P.PER_PROFILES = 6
P.PER_TOOLS   = 9
P.MAX_DESC    = 200
P.MAX_PROFILES = 6
P.LOG_MAX     = 200000

P.AUTHOR  = string.char(77,105,115,115) .. "Gera"
P.VER_NUM = string.char(49,46,49,50)
P.VER     = "v" .. P.VER_NUM
P.BUILD   = 11200
P.VFORGE  = "vforge.pythonanywhere.com"
P.TG      = "t.me/korobkageri"
P.YT      = "youtube.com/@missgeraa"

-- ========================================
-- УТИЛИТЫ
-- ========================================
function U.clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end

function U.log(msg, lvl)
    local f = io.open(P.LOG, 'a')
    if f then
        f:write(os.date('%H:%M:%S') .. ' | ' .. (lvl and ('[' .. lvl .. '] ') or '') .. tostring(msg) .. '\n')
        f:close()
    end
end

function U.tb(e)
    if debug and debug.traceback then return debug.traceback(tostring(e), 2) end
    return tostring(e)
end

U.errors = {}
function U.safe(fn, tag, ...)
    local args, n = { ... }, select('#', ...)
    local ok, res = xpcall(function() return fn(unpack(args, 1, n)) end, U.tb)
    if not ok then
        U.log('callback error [' .. tostring(tag) .. ']: ' .. tostring(res), 'E')
        U.errors[#U.errors + 1] = tostring(tag) .. ': ' .. (tostring(res):match('^[^\n]*') or '')
        if #U.errors > 12 then table.remove(U.errors, 1) end
    end
    return ok, res
end

-- --- файлы ---
local lfs_ok, lfs = pcall(require, 'lfs')
if not lfs_ok then lfs = nil end

function U.exists(path)
    if not path then return false end
    local f = io.open(path, 'rb')
    if f then f:close() return true end
    return false
end
function U.read(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local c = f:read('*a'); f:close()
    return c
end
function U.write(path, content)
    local f = io.open(path, 'wb')
    if not f then return false end
    f:write(content); f:close()
    return true
end
function U.size(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local s = f:seek('end'); f:close()
    return s
end
function U.attr(path)
    if not lfs then return nil end
    local ok, a = pcall(lfs.attributes, path)
    if ok then return a end
    return nil
end
function U.is_dir(path) local a = U.attr(path); return a ~= nil and a.mode == 'directory' end
function U.mkdir(path) if lfs then pcall(lfs.mkdir, path) end end
function U.listdir(path)
    local out = {}
    if not lfs then return out end
    local ok, iter, dobj = pcall(lfs.dir, path)
    if not ok or not iter then return out end
    pcall(function()
        for e in iter, dobj do
            if e ~= '.' and e ~= '..' then out[#out + 1] = e end
        end
    end)
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
function U.tail(path, bytes)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local size = f:seek('end')
    f:seek('set', max(0, size - bytes))
    local c = f:read('*a'); f:close()
    return c, size
end

-- --- UTF-8 (безопасная обрезка и оценка ширины) ---
local U8 = "[\1-\127\194-\244][\128-\191]*"
function U.chars(s)
    local t = {}
    for ch in tostring(s):gmatch(U8) do t[#t + 1] = ch end
    return t
end
function U.cw(ch)
    local b = ch:byte(1)
    if b < 128 then
        if ch == ' ' then return 0.32 end
        if ch:match('[%.,;:!|iIl%-]') then return 0.34 end
        if ch:match('[A-Z0-9MW]') then return 0.62 end
        return 0.52
    elseif b < 224 then return 0.6 end
    return 1.0
end
function U.fit(s, maxpx, fs)
    s = tostring(s)
    local chars, limit, total = U.chars(s), maxpx / fs, 0
    for i = 1, #chars do total = total + U.cw(chars[i]) end
    if total <= limit then return s end
    local out, acc, dots = {}, 0, 3 * 0.34
    for i = 1, #chars do
        local w = U.cw(chars[i])
        if acc + w + dots > limit then break end
        acc = acc + w; out[#out + 1] = chars[i]
    end
    return table.concat(out) .. '...'
end
function U.sub(s, n)
    local c = U.chars(s)
    if #c <= n then return tostring(s) end
    return table.concat(c, '', 1, n)
end
function U.wrap(s, maxpx, fs, maxlines)
    local limit, lines, line, lw, sp = maxpx / fs, {}, '', 0, 0.32
    local function wlen(w) local t = 0; for _, c in ipairs(U.chars(w)) do t = t + U.cw(c) end return t end
    for word in tostring(s):gmatch('%S+') do
        local ww = wlen(word)
        if ww > limit then
            if line ~= '' then lines[#lines + 1] = line; line, lw = '', 0 end
            local buf, bw = {}, 0
            for _, c in ipairs(U.chars(word)) do
                local w = U.cw(c)
                if bw + w > limit then lines[#lines + 1] = table.concat(buf); buf, bw = {}, 0 end
                buf[#buf + 1] = c; bw = bw + w
            end
            line, lw = table.concat(buf), bw
        elseif line == '' then line, lw = word, ww
        elseif lw + sp + ww <= limit then line = line .. ' ' .. word; lw = lw + sp + ww
        else lines[#lines + 1] = line; line, lw = word, ww end
    end
    if line ~= '' then lines[#lines + 1] = line end
    if maxlines and #lines > maxlines then
        local keep = {}
        for i = 1, maxlines do keep[i] = lines[i] end
        keep[maxlines] = U.fit(keep[maxlines] .. ' ...', maxpx, fs)
        lines = keep
    end
    return lines
end

-- --- цвет / форматирование ---
function U.col(hex, s) return "[colour='" .. hex .. "']" .. s end
function U.esc(s)
    s = tostring(s or '')
    s = s:gsub('[\r\n]+', ' ')
    s = s:gsub('%[', '(')
    s = s:gsub('%]', ')')
    return s
end
function U.grad(text, c1, c2)
    local chars = U.chars(text)
    local n = #chars
    if n == 0 then return text end
    local function comp(h, i) return tonumber(h:sub(i, i + 1), 16) or 255 end
    local r1, g1, b1 = comp(c1, 3), comp(c1, 5), comp(c1, 7)
    local r2, g2, b2 = comp(c2, 3), comp(c2, 5), comp(c2, 7)
    local out = {}
    for i = 1, n do
        local t = (i - 1) / max(1, n - 1)
        out[#out + 1] = sfmt("[colour='FF%02X%02X%02X']", floor(r1 + (r2 - r1) * t), floor(g1 + (g2 - g1) * t), floor(b1 + (b2 - b1) * t)) .. chars[i]
    end
    return table.concat(out)
end
function U.fsize(b)
    b = tonumber(b) or 0
    if b >= 1073741824 then return sfmt('%.2f GB', b / 1073741824)
    elseif b >= 1048576 then return sfmt('%.1f MB', b / 1048576)
    elseif b >= 1024 then return sfmt('%.0f KB', b / 1024) end
    return sfmt('%.0f B', b)
end
function U.initials(name)
    local c = U.chars(name:gsub('[^%w\128-\255]', ''))
    if #c == 0 then return '?' end
    local s = c[1] .. (c[2] or '')
    return s:upper()
end
function U.hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end
function U.shortdate(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return '-' end
    return os.date('%d.%m %H:%M', ts)
end

-- ========================================
-- ЛОКАЛИЗАЦИЯ
-- ========================================
S.STR = {
    en = {
        nav_packs = 'PACKS', nav_plugins = 'PLUGINS', nav_profiles = 'PROFILES', nav_tools = 'TOOLS', nav_log = 'LOG', nav_settings = 'SETTINGS',
        close = 'CLOSE', apply = 'APPLY', active = 'ACTIVE', on = 'ON', off = 'OFF', run = 'RUN', delete = 'DELETE', cancel = 'CANCEL',
        yes = 'YES', no = 'NO', refresh = 'REFRESH', copy = 'COPY', clear = 'CLEAR', load = 'LOAD', save = 'SAVE', undo = 'UNDO',
        busy = 'Another operation is running, wait...',
        side_active = 'Active pack', side_none = 'vanilla', side_plugins = 'Plugins on: %d',
        packs_sub = '%d packs  -  %s', packs_none = 'Nothing found in cerium-texture/', packs_none2 = 'Download packs on VForge and put them into cerium-texture/<name>/texturepack.zip',
        sort = 'SORT: %s', filter = 'SHOW: %s',
        sort_az = 'A-Z', sort_za = 'Z-A', sort_new = 'NEW', sort_size = 'SIZE', sort_fav = 'FAV',
        flt_all = 'ALL', flt_fav = 'FAV', flt_v1 = 'V1', flt_v2 = 'V2',
        fav = 'FAV', unfav = 'FAV',
        bad_zip = 'BAD ZIP', engine_tag = 'V%d',
        applying = 'Applying: %s', applied = 'Applied: %s', apply_fail = 'Apply failed: %s', cancelled = 'Cancelled',
        need_backup = 'Backup of original files is being created, try again in a moment',
        drift_warn = 'Game files differ from "%s" (game update?)', reapply = 'RE-APPLY',
        nothing_undo = 'Nothing to undo', reset_title = 'Restore original textures?', reset_body = 'Original common.zip (from backup) will be restored for all engines.',
        reset_ok = 'Original textures restored', reset_fail = 'No backup found, nothing to restore', resetting = 'Restoring originals',
        plug_sub = '%d plugins  -  %d enabled', plug_none = 'No plugins found in cerium-scripts/', plug_none2 = 'Folder: cerium-scripts/<name>/script.lua (+ manifest.json)',
        safe = 'SAFE MODE: %s', safe_on_t = 'Safe mode ON: plugins will not start next time', safe_off_t = 'Safe mode OFF',
        st_ok = 'RUNNING', st_err = 'ERROR', st_off = 'OFF', st_pending = 'ON (restart)', st_safe = 'SAFE MODE',
        plug_enabled = 'Plugin enabled: %s (restart or press RUN)', plug_disabled = 'Plugin disabled: %s',
        plug_run_ok = 'Plugin started: %s', plug_run_err = 'Plugin error: %s',
        prof_sub = '%d / %d profiles', prof_new = 'SAVE CURRENT SETUP', prof_new_d = 'Pack + enabled plugins', prof_saved = 'Profile saved: %s', prof_max = 'Profile limit reached',
        prof_loaded = 'Profile loaded: %s', prof_del = 'Profile deleted', prof_pack = 'Pack: %s', prof_plug = 'Plugins: %d', prof_none = 'No profiles yet',
        prof_none2 = 'Set up a pack and plugins, then save them here',
        tools_sub = 'Maintenance and utilities', 
        t_reset = 'Restore originals', t_reset_d = 'Put the original game textures back (all engines).',
        t_rescan = 'Rescan', t_rescan_d = 'Reload packs and plugins from disk.',
        t_verify = 'Verify packs', t_verify_d = 'Check every texturepack.zip for a valid ZIP header.',
        t_copy = 'Copy game ZIP', t_copy_d = 'Copy current common.zip to the download folder.',
        t_dump = 'Dump resources', t_dump_d = 'Copy the whole app_resources folder to the download folder.',
        t_store = 'Storage info', t_store_d = 'Sizes of packs, backups and temp files.',
        t_diag = 'Diagnostics', t_diag_d = 'Copy a full report to the clipboard.',
        t_clean = 'Clean temp files', t_clean_d = 'Delete old temp ZIPs left by earlier versions.',
        verify_res = 'Verified: %d ok, %d broken', rescanned = 'Rescanned: %d packs, %d plugins',
        copying = 'Copying game ZIP', copy_ok = 'Copied: %s', copy_fail = 'Copy failed: %s', dumping = 'Dumping resources', dump_ok = 'Dump finished (%d files)', dump_conf = 'Dump can be large and slow. Continue?',
        diag_ok = 'Report copied to clipboard', clean_ok = 'Removed %d temp files (%s)',
        store_title = 'Storage', st_line_packs = 'Packs: %d  (%s)', st_line_bak = 'Backup V%d: %s', st_line_game = 'Game ZIP V%d: %s', st_missing = 'missing',
        log_sub = 'Last lines of cerium.log', log_empty = '(log is empty)', log_cleared = 'Log cleared', log_copied = 'Log copied',
        log_conf = 'Clear the log file?',
        set_sub = 'Look, behaviour and credits', set_lang = 'Language', set_theme = 'Theme', set_scale = 'Text layout', set_anim = 'Animations',
        set_corner = 'Launcher corner', set_hud = 'FPS overlay', set_safe = 'Safe mode (no plugins)', set_autofix = 'Auto-fix after game update',
        corner1 = 'TL', corner2 = 'TR', corner3 = 'BL', corner4 = 'BR', scale1 = 'S', scale2 = 'M', scale3 = 'L',
        cr_by = 'Created by: ', cr_site = 'VForge', cr_copy_site = 'COPY SITE', cr_copy_tg = 'COPY TG', cr_copy_yt = 'COPY YT',
        link_copied = 'Link copied', page = '%d / %d', hud_fps = 'FPS %d', hud_avg = 'avg %d', hud_min = 'min %d', hud_na = 'FPS n/a',
        sidebar_link = 'VFORGE LINK', ok = 'OK',
    },
    ru = {
        nav_packs = 'ПАКИ', nav_plugins = 'ПЛАГИНЫ', nav_profiles = 'ПРОФИЛИ', nav_tools = 'ИНСТРУМЕНТЫ', nav_log = 'ЛОГ', nav_settings = 'НАСТРОЙКИ',
        close = 'ЗАКРЫТЬ', apply = 'ПРИМЕНИТЬ', active = 'АКТИВЕН', on = 'ВКЛ', off = 'ВЫКЛ', run = 'ПУСК', delete = 'УДАЛИТЬ', cancel = 'ОТМЕНА',
        yes = 'ДА', no = 'НЕТ', refresh = 'ОБНОВИТЬ', copy = 'КОПИЯ', clear = 'ОЧИСТИТЬ', load = 'ЗАГРУЗИТЬ', save = 'СОХРАНИТЬ', undo = 'ОТМЕНА ПАКА',
        busy = 'Идёт другая операция, подождите...',
        side_active = 'Активный пак', side_none = 'оригинал', side_plugins = 'Плагинов вкл: %d',
        packs_sub = 'Паков: %d  -  %s', packs_none = 'В cerium-texture/ ничего не найдено', packs_none2 = 'Скачайте паки на VForge и положите в cerium-texture/<имя>/texturepack.zip',
        sort = 'СОРТ: %s', filter = 'ПОКАЗ: %s',
        sort_az = 'А-Я', sort_za = 'Я-А', sort_new = 'НОВЫЕ', sort_size = 'РАЗМЕР', sort_fav = 'ИЗБР',
        flt_all = 'ВСЕ', flt_fav = 'ИЗБР', flt_v1 = 'V1', flt_v2 = 'V2',
        fav = 'ИЗБР', unfav = 'ИЗБР',
        bad_zip = 'БИТЫЙ ZIP', engine_tag = 'V%d',
        applying = 'Применяю: %s', applied = 'Применён пак: %s', apply_fail = 'Ошибка применения: %s', cancelled = 'Отменено',
        need_backup = 'Создаётся резервная копия оригинала, повторите через пару секунд',
        drift_warn = 'Файлы игры отличаются от "%s" (обновление игры?)', reapply = 'ПЕРЕПРИМЕНИТЬ',
        nothing_undo = 'Нечего отменять', reset_title = 'Вернуть оригинальные текстуры?', reset_body = 'Оригинальный common.zip (из бэкапа) будет восстановлен для всех движков.',
        reset_ok = 'Восстановлены оригинальные текстуры', reset_fail = 'Бэкап не найден, восстанавливать нечего', resetting = 'Восстановление оригинала',
        plug_sub = 'Плагинов: %d  -  включено: %d', plug_none = 'В cerium-scripts/ плагинов нет', plug_none2 = 'Папка: cerium-scripts/<имя>/script.lua (+ manifest.json)',
        safe = 'БЕЗОП. РЕЖИМ: %s', safe_on_t = 'Безопасный режим ВКЛ: плагины не запустятся при следующем входе', safe_off_t = 'Безопасный режим ВЫКЛ',
        st_ok = 'РАБОТАЕТ', st_err = 'ОШИБКА', st_off = 'ВЫКЛ', st_pending = 'ВКЛ (перезайти)', st_safe = 'БЕЗОП. РЕЖИМ',
        plug_enabled = 'Плагин включён: %s (перезайдите или нажмите ПУСК)', plug_disabled = 'Плагин отключён: %s',
        plug_run_ok = 'Плагин запущен: %s', plug_run_err = 'Ошибка плагина: %s',
        prof_sub = 'Профилей: %d / %d', prof_new = 'СОХРАНИТЬ НАБОР', prof_new_d = 'Пак + включённые плагины', prof_saved = 'Профиль сохранён: %s', prof_max = 'Достигнут лимит профилей',
        prof_loaded = 'Профиль загружен: %s', prof_del = 'Профиль удалён', prof_pack = 'Пак: %s', prof_plug = 'Плагинов: %d', prof_none = 'Профилей пока нет',
        prof_none2 = 'Настройте пак и плагины, затем сохраните набор здесь',
        tools_sub = 'Обслуживание и утилиты',
        t_reset = 'Вернуть оригинал', t_reset_d = 'Вернуть оригинальные текстуры игры (все движки).',
        t_rescan = 'Пересканировать', t_rescan_d = 'Перечитать паки и плагины с диска.',
        t_verify = 'Проверка паков', t_verify_d = 'Проверить заголовок ZIP у каждого texturepack.zip.',
        t_copy = 'Копия ZIP игры', t_copy_d = 'Скопировать текущий common.zip в папку загрузок.',
        t_dump = 'Дамп ресурсов', t_dump_d = 'Скопировать всю папку app_resources в папку загрузок.',
        t_store = 'Хранилище', t_store_d = 'Размеры паков, бэкапов и временных файлов.',
        t_diag = 'Диагностика', t_diag_d = 'Скопировать полный отчёт в буфер обмена.',
        t_clean = 'Чистка временных', t_clean_d = 'Удалить старые временные ZIP от прошлых версий.',
        verify_res = 'Проверено: %d ок, %d битых', rescanned = 'Пересканировано: паков %d, плагинов %d',
        copying = 'Копирование ZIP игры', copy_ok = 'Скопировано: %s', copy_fail = 'Ошибка копирования: %s', dumping = 'Дамп ресурсов', dump_ok = 'Дамп завершён (файлов: %d)', dump_conf = 'Дамп может быть большим и долгим. Продолжить?',
        diag_ok = 'Отчёт скопирован в буфер обмена', clean_ok = 'Удалено временных файлов: %d (%s)',
        store_title = 'Хранилище', st_line_packs = 'Паки: %d  (%s)', st_line_bak = 'Бэкап V%d: %s', st_line_game = 'ZIP игры V%d: %s', st_missing = 'нет',
        log_sub = 'Последние строки cerium.log', log_empty = '(лог пуст)', log_cleared = 'Лог очищен', log_copied = 'Лог скопирован',
        log_conf = 'Очистить файл лога?',
        set_sub = 'Внешний вид, поведение и авторы', set_lang = 'Язык', set_theme = 'Тема', set_scale = 'Расположение текста', set_anim = 'Анимации',
        set_corner = 'Угол лаунчера', set_hud = 'FPS-оверлей', set_safe = 'Безопасный режим (без плагинов)', set_autofix = 'Автоисправление после обновления игры',
        corner1 = 'ЛВ', corner2 = 'ПВ', corner3 = 'ЛН', corner4 = 'ПН', scale1 = 'S', scale2 = 'M', scale3 = 'L',
        cr_by = 'Автор: ', cr_site = 'VForge', cr_copy_site = 'КОПИЯ САЙТА', cr_copy_tg = 'КОПИЯ TG', cr_copy_yt = 'КОПИЯ YT',
        link_copied = 'Ссылка скопирована', page = '%d / %d', hud_fps = 'FPS %d', hud_avg = 'ср %d', hud_min = 'мин %d', hud_na = 'FPS н/д',
        sidebar_link = 'ССЫЛКА VFORGE', ok = 'ОК',
    },
}

S.THEMES = {
    { id = 'cyan',    acc = 'FF4DD8D8', acc2 = 'FFFFFFFF', rgb = { 0.30, 0.85, 0.85 }, en = 'CYAN',    ru = 'БИРЮЗА' },
    { id = 'violet',  acc = 'FFB28CFF', acc2 = 'FFFFE0FF', rgb = { 0.70, 0.55, 1.00 }, en = 'VIOLET',  ru = 'ФИОЛЕТ' },
    { id = 'emerald', acc = 'FF4ADE80', acc2 = 'FFE6FFF0', rgb = { 0.29, 0.87, 0.50 }, en = 'EMERALD', ru = 'ИЗУМРУД' },
    { id = 'amber',   acc = 'FFFBBF24', acc2 = 'FFFFF3C4', rgb = { 0.98, 0.75, 0.14 }, en = 'AMBER',   ru = 'ЯНТАРЬ' },
    { id = 'rose',    acc = 'FFFB7185', acc2 = 'FFFFE0E6', rgb = { 0.98, 0.44, 0.52 }, en = 'ROSE',    ru = 'РОЗА' },
}
S.C_OK, S.C_WARN, S.C_ERR, S.C_DIM, S.C_TXT = 'FF4ADE80', 'FFFBBF24', 'FFFB7185', 'FFA0A8B4', 'FFFFFFFF'

S.cfg = {}
S.packs, S.scripts = {}, {}
S.plug = {}            -- folder -> {status=, err=}
S.activeList = {}
S.page = { packs = 1, plugins = 1, profiles = 1, tools = 1 }
S.tab = 'packs'
S.menuOpen = false
S.drift = {}           -- engine -> folder
S.dead = false

local function tr(key, ...)
    local lang = (S.cfg.lang == 'en') and 'en' or 'ru'
    local s = (S.STR[lang] and S.STR[lang][key]) or S.STR.en[key] or key
    if select('#', ...) > 0 then
        local ok, r = pcall(sfmt, s, ...)
        if ok then return r end
    end
    return s
end
function S.theme() return S.THEMES[U.clamp(floor(tonumber(S.cfg.theme) or 1), 1, #S.THEMES)] end
function S.accent() return S.theme().acc end

-- ========================================
-- JSON / КОНФИГ
-- ========================================
local cjson_ok, cjson = pcall(require, 'cjson')
if not cjson_ok or not cjson then
    U.mkdir(P.LOGS); U.log('cjson is not available, CeriumCore stopped', 'E')
    return
end

S.DEFAULTS = {
    lang = 'ru', theme = 1, scale = 2, anim = true, corner = 2, hud = false, safe_mode = false, autofix = false,
    sort = 'az', filter = 'all', favorites = {}, history = {}, profiles = {}, sel = {}, profile_seq = 0,
}
function C.loadConfig()
    local data = {}
    local c = U.read(P.CFG)
    if c then
        local ok, d = pcall(cjson.decode, c)
        if ok and type(d) == 'table' then data = d end
    end
    for k, v in pairs(S.DEFAULTS) do
        if data[k] == nil then data[k] = (type(v) == 'table') and {} or v end
    end
    -- нормализация типов после JSON
    if data.lang ~= 'en' then data.lang = 'ru' end
    data.theme = U.clamp(floor(tonumber(data.theme) or 1), 1, #S.THEMES)
    data.scale = U.clamp(floor(tonumber(data.scale) or 2), 1, 3)
    data.corner = U.clamp(floor(tonumber(data.corner) or 2), 1, 4)
    -- наследие 1.11: selected_folder/engine -> sel
    if type(data.sel) ~= 'table' then data.sel = {} end
    if data.selected_folder and not data.sel.e1 and not data.sel.e2 then
        local e = (tonumber(data.engine) == 2) and 'e2' or 'e1'
        data.sel[e] = data.selected_folder
    end
    S.cfg = data
end
function C.saveConfig()
    local ok, err = pcall(function() return U.write(P.CFG, cjson.encode(S.cfg)) end)
    if not ok then U.log('saveConfig: ' .. tostring(err), 'E') end
end
function C.isFav(folder) return S.cfg.favorites[folder] == true end

-- ========================================
-- СКАНИРОВАНИЕ ПАКОВ И ПЛАГИНОВ
-- ========================================
function C.zipValid(path)
    local f = io.open(path, 'rb')
    if not f then return false end
    local h = f:read(4); f:close()
    return h == 'PK\3\4' or h == 'PK\5\6'
end
function C.pngValid(path)
    local f = io.open(path, 'rb')
    if not f then return false end
    local h = f:read(8)
    local size = f:seek('end'); f:close()
    return h == '\137PNG\r\n\26\n' and size and size > 0 and size < 3 * 1048576
end

function C.scanPacks()
    local packs = {}
    for _, entry in ipairs(U.listdir(P.TEX)) do
        local dir = P.TEX .. entry
        if U.is_dir(dir) then
            local zip = dir .. '/texturepack.zip'
            if U.exists(zip) then
                local p = { index = #packs + 1, folder = entry, dir = dir, zip = zip, name = entry, version = '?', author = '', description = '', engine = 1 }
                local mc = U.read(dir .. '/manifest.json')
                local previewName
                if mc then
                    local ok, d = pcall(cjson.decode, mc)
                    if ok and type(d) == 'table' then
                        p.name = tostring(d.name or d.title or entry)
                        p.version = tostring(d.version or d.v or '1.0')
                        p.author = tostring(d.author or d.author_name or '')
                        p.description = tostring(d.description or d.desc or '')
                        p.engine = (tonumber(d.engine) == 2) and 2 or 1
                        previewName = d.preview
                    end
                end
                if #U.chars(p.description) > P.MAX_DESC then p.description = U.sub(p.description, P.MAX_DESC) .. '...' end
                local a = U.attr(zip)
                p.size = (a and a.size) or U.size(zip) or 0
                p.mtime = (a and a.modification) or 0
                p.valid = C.zipValid(zip)
                for _, n in ipairs({ previewName, 'preview.png', 'icon.png' }) do
                    if type(n) == 'string' and n ~= '' and not n:find('[/\\]') and U.exists(dir .. '/' .. n) then p.preview = dir .. '/' .. n; break end
                end
                packs[#packs + 1] = p
            end
        end
    end
    return packs
end

function C.scanScripts()
    local out = {}
    for _, entry in ipairs(U.listdir(P.SCR)) do
        if entry ~= 'plugins.lua' and entry ~= 'plugins_config.json' then
            local dir = P.SCR .. entry
            if U.is_dir(dir) and U.exists(dir .. '/script.lua') then
                local s = { index = #out + 1, folder = entry, path = dir .. '/script.lua', name = entry, version = '?', author = '', description = '' }
                local mc = U.read(dir .. '/manifest.json')
                if mc then
                    local ok, d = pcall(cjson.decode, mc)
                    if ok and type(d) == 'table' then
                        s.name = tostring(d.name or entry)
                        s.version = tostring(d.version or '1.0')
                        s.author = tostring(d.author or '')
                        s.description = tostring(d.description or '')
                    end
                end
                if #U.chars(s.description) > P.MAX_DESC then s.description = U.sub(s.description, P.MAX_DESC) .. '...' end
                out[#out + 1] = s
            end
        end
    end
    return out
end

function C.findPack(folder)
    for _, p in ipairs(S.packs) do if p.folder == folder then return p end end
    return nil
end
function C.activeFor(p) return S.cfg.sel['e' .. p.engine] == p.folder end
function C.selectedName()
    local parts = {}
    for e = 1, 2 do
        local f = S.cfg.sel['e' .. e]
        if f then
            local p = C.findPack(f)
            parts[#parts + 1] = (p and p.name or f) .. (e == 2 and ' [V2]' or '')
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, ' + ')
end

function C.viewPacks()
    local out, flt = {}, S.cfg.filter
    for _, p in ipairs(S.packs) do
        if flt == 'all' or (flt == 'fav' and C.isFav(p.folder)) or (flt == 'v1' and p.engine == 1) or (flt == 'v2' and p.engine == 2) then
            out[#out + 1] = p
        end
    end
    local mode = S.cfg.sort
    table.sort(out, function(a, b)
        local an, bn = a.name:lower(), b.name:lower()
        if mode == 'za' then if an ~= bn then return an > bn end
        elseif mode == 'new' then if a.mtime ~= b.mtime then return a.mtime > b.mtime end
        elseif mode == 'size' then if a.size ~= b.size then return a.size > b.size end
        elseif mode == 'fav' then
            local fa, fb = C.isFav(a.folder), C.isFav(b.folder)
            if fa ~= fb then return fa end
        end
        if an ~= bn then return an < bn end
        return a.folder < b.folder
    end)
    return out
end

-- активные плагины (формат plugins_config.json совместим с 1.11)
function C.loadActive()
    local c = U.read(P.PLUG_CFG)
    S.activeList = {}
    if c then
        local ok, d = pcall(cjson.decode, c)
        if ok and type(d) == 'table' then
            for _, v in ipairs(d) do if type(v) == 'string' then S.activeList[#S.activeList + 1] = v end end
        end
    end
end
function C.isPluginOn(folder)
    for _, v in ipairs(S.activeList) do if v == folder then return true end end
    return false
end
function C.saveActive()
    U.write(P.PLUG_CFG, cjson.encode(S.activeList))
    -- plugins.lua оставляем для совместимости с 1.11 (сам он больше не нужен)
    local parts = { "-- Auto-generated by CeriumCore " .. P.VER .. "\npcall(function()\n" }
    for _, folder in ipairs(S.activeList) do
        local code = U.read(P.SCR .. folder .. '/script.lua')
        if code then
            parts[#parts + 1] = "-- START PLUGIN: " .. folder .. "\npcall(function()\n" .. code .. "\nend)\n-- END PLUGIN: " .. folder .. "\n\n"
        end
    end
    parts[#parts + 1] = "end)\n"
    U.write(P.PLUG_LUA, table.concat(parts))
end
function C.rescan()
    S.packs = C.scanPacks()
    S.scripts = C.scanScripts()
    C.checkDrift()
end

-- ========================================
-- DRIFT: игра могла перезаписать common.zip
-- ========================================
function C.checkDrift()
    S.drift = {}
    for e = 1, 2 do
        local f = S.cfg.sel['e' .. e]
        if f then
            local p = C.findPack(f)
            local g = P.GAME[e]
            if p and U.exists(g.dst) then
                local gs = U.size(g.dst)
                if gs and gs ~= p.size then S.drift[e] = f end
            end
        end
    end
    if X.refreshLauncher then X.refreshLauncher() end
end
function C.hasDrift() return next(S.drift) ~= nil end

-- ========================================
-- HEARTBEAT (один World.Timer на всё: анимации, задачи, копирование, HUD)
-- ========================================
local hb = { started = false, tick = 0, tasks = {}, tickers = {} }
S.hb = hb
-- [FIX] ensureHB теперь не падает, если World или World.Timer недоступны,
-- и НЕ считает World.Timer готовым, если он вернул false/nil.
local function ensureHB()
    if hb.started then return true end
    local okW, world = pcall(function() return World end)
    if not okW or type(world) ~= 'table' then return false end
    local okT, timer = pcall(function() return world.Timer end)
    if not okT or type(timer) ~= 'function' then return false end
    local ok = pcall(function()
        timer(1, function()
            if S.dead then return false end
            hb.tick = hb.tick + 1
            local keep, run = {}, {}
            for _, t in ipairs(hb.tasks) do
                if hb.tick >= t.at then run[#run + 1] = t else keep[#keep + 1] = t end
            end
            hb.tasks = keep
            for _, t in ipairs(run) do U.safe(t.fn, 'task') end
            local cur = hb.tickers
            hb.tickers = {}
            for _, fn in ipairs(cur) do
                local ok2, res = pcall(fn)
                if ok2 and res then hb.tickers[#hb.tickers + 1] = fn
                elseif not ok2 then U.log('ticker error: ' .. tostring(res), 'E') end
            end
            return true
        end)
    end)
    if not ok then return false end
    hb.started = true
    return true
end
local function later(ticks, fn)
    if ensureHB() then hb.tasks[#hb.tasks + 1] = { at = hb.tick + ticks, fn = fn } return true end
    return false
end
local function addTicker(fn)
    if ensureHB() then hb.tickers[#hb.tickers + 1] = fn return true end
    return false
end
S.later, S.addTicker, S.ensureHB = later, addTicker, ensureHB

-- ========================================
-- ТОСТЫ / СТАТУС
-- ========================================
function C.toast(msg, kind)
    local c = (kind == 'err') and 'FFFF5555' or ((kind == 'warn') and 'FFFFC845' or 'FF00FF00')
    -- [FIX] Event / Lib могут ещё не существовать — полностью в pcall
    pcall(function()
        if Lib and Event and Event.EVENT_TOAST_TIP then
            Lib.emitEvent(Event.EVENT_TOAST_TIP, "[colour='" .. c .. "']" .. U.esc(msg), 20, 60)
        end
    end)
end
function S.status(msg, kind)
    kind = kind or 'info'
    U.log('status: ' .. tostring(msg), kind == 'err' and 'E' or (kind == 'warn' and 'W' or nil))
    if S.menuOpen and X.drawStatus then
        S.statusMsg = { text = msg, kind = kind, at = hb.tick }
        X.drawStatus()
        local at = hb.tick
        later(90, function()
            if S.statusMsg and S.statusMsg.at == at then S.statusMsg = nil; if S.menuOpen then X.drawStatus() end end
        end)
    else
        C.toast(msg, kind)
    end
end

function C.copyText(text)
    local ok = pcall(function() CGame.instance:getShellInterface():copyToClipboard(text, "CeriumCore") end)
    return ok
end

-- ========================================
-- ЗАДАЧИ КОПИРОВАНИЯ (куски по тикам, tmp + rename, прогресс)
-- ========================================
C.job = nil
function C.copySync(src, dst)
    local fi = io.open(src, 'rb'); if not fi then return false end
    local fo = io.open(dst, 'wb'); if not fo then fi:close() return false end
    local ok = true
    while true do
        local d = fi:read(1048576)
        if not d or #d == 0 then break end
        if not fo:write(d) then ok = false break end
    end
    fi:close(); fo:close()
    return ok
end

-- ========================================
-- [FIX 1.12.1] Полная замена файла за один шаг (как в 1.11, но с защитой)
-- Убираем .ctmp, os.rename и size mismatch. Копируем через U.read/U.write,
-- потому что game принимает только ПОЛНЫЙ файл, а не куски.
-- ========================================

function C.jobStart(spec)
    if C.job then S.status(tr('busy'), 'warn') return false end
    local total = 0
    for _, st in ipairs(spec.steps) do
        st.size = st.size or U.size(st.src) or 0
        total = total + st.size
    end
    C.job = { spec = spec, i = 0, total = max(total, 1), done = 0, cancel = false }
    if not spec.silent and S.menuOpen and X.showProgress then X.showProgress(spec.title) end

    -- Сначала читаем ВСЕ шаги в память (как в 1.11). Если пак > 64 МБ — 
    -- идём через потоковый буфер, чтобы не упасть по OOM.
    local chunks = {}
    for idx, st in ipairs(spec.steps) do
        if st.size > 64 * 1048576 then
            -- Большой файл: копируем прямо в dst, но без .ctmp и без rename
            local fi = io.open(st.src, 'rb')
            if not fi then
                C.job = nil
                S.status(tr('apply_fail', 'read error: ' .. tostring(st.src)), 'err')
                return false
            end
            local fo = io.open(st.dst, 'wb')
            if not fo then fi:close()
                C.job = nil
                S.status(tr('apply_fail', 'write error: ' .. tostring(st.dst)), 'err')
                return false
            end
            local ok = true
            while true do
                local d = fi:read(1048576)
                if not d or #d == 0 then break end
                if not fo:write(d) then ok = false break end
            end
            fi:close()
            fo:flush()
            fo:close()
            if not ok then
                C.job = nil
                S.status(tr('apply_fail', 'disk write failed'), 'err')
                return false
            end
            -- проверяем размер dst против src
            local real, want = U.size(st.dst), U.size(st.src)
            if not real or not want or real ~= want then
                C.job = nil
                S.status(tr('apply_fail', 'size mismatch'), 'err')
                return false
            end
        else
            -- Маленький файл: читаем в память как в 1.11
            local data = U.read(st.src)
            if not data then
                C.job = nil
                S.status(tr('apply_fail', 'read error'), 'err')
                return false
            end
            chunks[#chunks + 1] = { st = st, data = data }
        end
    end

    -- Пишем маленькие файлы (если есть) и вызываем onDone
    for _, c in ipairs(chunks) do
        if not U.write(c.st.dst, c.data) then
            C.job = nil
            S.status(tr('apply_fail', 'write error'), 'err')
            return false
        end
    end

    -- Всё записалось — сразу завершаем
    C.job = nil
    if X.hideProgress then X.hideProgress() end
    if spec.onDone then U.safe(spec.onDone, 'jobDone', true) end
    return true
end

function C.jobTick() return false end

function C.finishStep() return false end

function C.jobTick()
    local j = C.job
    if not j then return false end
    if j.cancel then return C.jobFinish(false, tr('cancelled')) end
    local budget, files = 4 * 1048576, 0
    while budget > 0 and files < 40 do
        if not j.cur then
            j.i = j.i + 1
            local st = j.spec.steps[j.i]
            if not st then return C.jobFinish(true) end
            local fi = io.open(st.src, 'rb')
            if not fi then return C.jobFinish(false, 'read error: ' .. tostring(st.src)) end
            local target = st.atomic and (st.dst .. '.ctmp') or st.dst
            local fo = io.open(target, 'wb')
            if not fo then fi:close() return C.jobFinish(false, 'write error: ' .. tostring(st.dst)) end
            j.cur = { st = st, fi = fi, fo = fo, target = target, n = 0 }
        end
        local cur = j.cur
        local data = cur.fi:read(1048576)
        if not data or #data == 0 then
            cur.fi:close(); cur.fo:close()
            j.cur = nil
            local ok, err = C.finishStep(cur)
            files = files + 1
            if not ok then return C.jobFinish(false, err) end
        else
            if not cur.fo:write(data) then return C.jobFinish(false, 'disk write failed') end
            cur.n = cur.n + #data; j.done = j.done + #data; budget = budget - #data
        end
    end
    if X.updateProgress then X.updateProgress(j.done / j.total) end
    return true
end

-- ========================================
-- ОПЕРАЦИИ С ПАКАМИ
-- ========================================
function C.ensureBackups(silent)
    local steps = {}
    for e = 1, 2 do
        local g = P.GAME[e]
        if not U.exists(g.bak) and U.exists(g.dst) then steps[#steps + 1] = { src = g.dst, dst = g.bak, atomic = true } end
    end
    if #steps == 0 or C.job then return end
    C.jobStart({ title = 'Backup', steps = steps, silent = true, onDone = function(ok, msg)
        if ok then U.log('backup created') else U.log('backup failed: ' .. tostring(msg), 'E') end
        if not ok then S.status('Backup: ' .. tostring(msg), 'err') end
    end })
end

function C.markApplied(pack)
    local e = 'e' .. pack.engine
    local prev = S.cfg.sel[e]
    if prev and prev ~= pack.folder then
        local h = { prev }
        for _, f in ipairs(S.cfg.history) do if f ~= prev and f ~= pack.folder and #h < 8 then h[#h + 1] = f end end
        S.cfg.history = h
    end
    S.cfg.sel[e] = pack.folder
    S.cfg.selected, S.cfg.selected_name, S.cfg.selected_folder, S.cfg.engine = pack.index, pack.name, pack.folder, pack.engine
end

function C.applyPack(pack, silent)
    if C.job then S.status(tr('busy'), 'warn') return end
    if not pack.valid then S.status(pack.name .. ': ' .. tr('bad_zip'), 'err') return end
    local g = P.GAME[pack.engine]
    if U.exists(g.dst) and not U.exists(g.bak) then S.status(tr('need_backup'), 'warn'); C.ensureBackups() return end
    C.jobStart({ title = tr('applying', pack.name), silent = silent, steps = { { src = pack.zip, dst = g.dst, atomic = true } },
        onDone = function(ok, msg)
            if ok then
                C.markApplied(pack); C.saveConfig(); C.checkDrift()
                SDK.emit('pack_applied', pack.folder, pack.name)
                S.status(tr('applied', pack.name), 'ok')
            else S.status(tr('apply_fail', tostring(msg)), 'err') end
            if X.rerender then X.rerender() end
        end })
end

function C.undoPack()
    for _, f in ipairs(S.cfg.history) do
        local p = C.findPack(f)
        if p then C.applyPack(p) return end
    end
    S.status(tr('nothing_undo'), 'warn')
end

function C.reapplyDrift()
    local steps, packs = {}, {}
    for e, f in pairs(S.drift) do
        local p = C.findPack(f)
        if p and p.valid then steps[#steps + 1] = { src = p.zip, dst = P.GAME[e].dst, atomic = true }; packs[#packs + 1] = p end
    end
    if #steps == 0 then return end
    C.jobStart({ title = tr('applying', '...'), steps = steps, silent = not S.menuOpen, onDone = function(ok, msg)
        if ok then
            for _, p in ipairs(packs) do C.markApplied(p) end
            C.saveConfig(); C.checkDrift(); S.status(tr('applied', packs[1].name), 'ok')
        else S.status(tr('apply_fail', tostring(msg)), 'err') end
        if X.rerender then X.rerender() end
    end })
end

function C.resetVanilla()
    local steps = {}
    for e = 1, 2 do
        local g = P.GAME[e]
        if U.exists(g.bak) then steps[#steps + 1] = { src = g.bak, dst = g.dst, atomic = true } end
    end
    if #steps == 0 then S.status(tr('reset_fail'), 'err') return end
    C.jobStart({ title = tr('resetting'), steps = steps, onDone = function(ok, msg)
        if ok then
            S.cfg.sel = {}; S.cfg.selected, S.cfg.selected_name, S.cfg.selected_folder, S.cfg.engine = nil, nil, nil, nil
            C.saveConfig(); C.checkDrift(); S.status(tr('reset_ok'), 'ok')
        else S.status(tr('apply_fail', tostring(msg)), 'err') end
        if X.rerender then X.rerender() end
    end })
end

function C.verifyAll()
    local ok, bad = 0, 0
    for _, p in ipairs(S.packs) do
        p.valid = C.zipValid(p.zip)
        if p.valid then ok = ok + 1 else bad = bad + 1 end
    end
    S.status(tr('verify_res', ok, bad), bad > 0 and 'warn' or 'ok')
end

function C.copyZips()
    local steps = {}
    for e = 1, 2 do
        local g = P.GAME[e]
        if U.exists(g.dst) then steps[#steps + 1] = { src = g.dst, dst = P.BASE .. 'common_copy_v' .. e .. '.zip', atomic = true } end
    end
    if #steps == 0 then S.status(tr('copy_fail', 'no game zip'), 'err') return end
    C.jobStart({ title = tr('copying'), steps = steps, onDone = function(ok, msg)
        if ok then S.status(tr('copy_ok', #steps .. ' file(s)'), 'ok') else S.status(tr('copy_fail', tostring(msg)), 'err') end
    end })
end

function C.dumpRes()
    local steps = {}
    local function walk(src, dst)
        U.mkdir(dst)
        for _, name in ipairs(U.listdir(src)) do
            local sp, dp = src .. '/' .. name, dst .. '/' .. name
            local a = U.attr(sp)
            if a then
                if a.mode == 'directory' then walk(sp, dp)
                elseif a.mode == 'file' then steps[#steps + 1] = { src = sp, dst = dp, size = a.size or 0 } end
            end
        end
    end
    U.mkdir(P.DUMP_DST)
    walk(P.DUMP_SRC, P.DUMP_DST:gsub('/$', ''))
    if #steps == 0 then S.status(tr('copy_fail', 'nothing to copy'), 'err') return end
    C.jobStart({ title = tr('dumping'), steps = steps, onDone = function(ok, msg)
        if ok then S.status(tr('dump_ok', #steps), 'ok') else S.status(tr('copy_fail', tostring(msg)), 'err') end
    end })
end

function C.cleanTemp()
    local n, bytes = 0, 0
    local list = { P.TEMP_ZIP, P.BASE .. 'common_copy.zip', P.BASE .. 'common_copy_v1.zip', P.BASE .. 'common_copy_v2.zip' }
    for _, e in ipairs(U.listdir(P.BASE)) do if e:match('%.ctmp$') then list[#list + 1] = P.BASE .. e end end
    for e = 1, 2 do
        local d = P.GAME[e].dir
        for _, f in ipairs(U.listdir(d)) do if f:match('%.ctmp$') then list[#list + 1] = d .. f end end
    end
    for _, path in ipairs(list) do
        local s = U.size(path)
        if s and os.remove(path) then n = n + 1; bytes = bytes + s end
    end
    S.status(tr('clean_ok', n, U.fsize(bytes)), 'ok')
end

function C.storageLines()
    local lines, total = {}, 0
    for _, p in ipairs(S.packs) do total = total + p.size end
    lines[#lines + 1] = tr('st_line_packs', #S.packs, U.fsize(total))
    for e = 1, 2 do
        local g = P.GAME[e]
        local b, d = U.size(g.bak), U.size(g.dst)
        lines[#lines + 1] = tr('st_line_bak', e, b and U.fsize(b) or tr('st_missing'))
        lines[#lines + 1] = tr('st_line_game', e, d and U.fsize(d) or tr('st_missing'))
    end
    return lines
end

function C.diagReport()
    local t = {}
    local function add(s) t[#t + 1] = s end
    add('CeriumCore ' .. P.VER .. ' build ' .. P.BUILD)
    add('screen: ' .. tostring(X.W) .. 'x' .. tostring(X.H) .. '  frameMode=' .. tostring(X.caps.frame) .. '  fps=' .. tostring(X.caps.fps) .. '  timer=' .. tostring(hb.started))
    add('lang=' .. tostring(S.cfg.lang) .. ' theme=' .. tostring(S.cfg.theme) .. ' scale=' .. tostring(S.cfg.scale) .. ' safe=' .. tostring(S.cfg.safe_mode))
    add('active: ' .. tostring(C.selectedName()))
    add('packs=' .. #S.packs .. ' plugins=' .. #S.scripts .. ' enabled=' .. #S.activeList)
    for _, s in ipairs(S.scripts) do
        local st = S.plug[s.folder]
        add('  plugin ' .. s.folder .. ' on=' .. tostring(C.isPluginOn(s.folder)) .. ' st=' .. tostring(st and st.status) .. (st and st.err and (' err=' .. st.err) or ''))
    end
    for _, l in ipairs(C.storageLines()) do add(l) end
    for e, f in pairs(S.drift) do add('DRIFT engine ' .. e .. ': ' .. f) end
    for _, e in ipairs(U.errors) do add('ERR ' .. e) end
    return table.concat(t, '\n')
end

-- ========================================
-- ПРОФИЛИ
-- ========================================
function C.saveProfile()
    if #S.cfg.profiles >= P.MAX_PROFILES then S.status(tr('prof_max'), 'warn') return end
    S.cfg.profile_seq = (tonumber(S.cfg.profile_seq) or 0) + 1
    local plugins = {}
    for _, f in ipairs(S.activeList) do plugins[#plugins + 1] = f end
    local prof = { name = 'Profile ' .. S.cfg.profile_seq, ts = os.time(), sel = { e1 = S.cfg.sel.e1, e2 = S.cfg.sel.e2 }, plugins = plugins }
    S.cfg.profiles[#S.cfg.profiles + 1] = prof
    C.saveConfig()
    S.status(tr('prof_saved', prof.name), 'ok')
end
function C.deleteProfile(i)
    table.remove(S.cfg.profiles, i); C.saveConfig(); S.status(tr('prof_del'), 'ok')
end
function C.loadProfile(prof)
    if C.job then S.status(tr('busy'), 'warn') return end
    -- плагины
    local list = {}
    for _, f in ipairs(prof.plugins or {}) do
        for _, s in ipairs(S.scripts) do if s.folder == f then list[#list + 1] = f break end end
    end
    for _, f in ipairs(list) do
        if not C.isPluginOn(f) then S.plug[f] = { status = 'pending' } end
    end
    S.activeList = list; C.saveActive()
    -- паки
    local steps, packs = {}, {}
    for e = 1, 2 do
        local f = prof.sel and prof.sel['e' .. e]
        local p = f and C.findPack(f)
        if p and p.valid and S.cfg.sel['e' .. e] ~= f then
            steps[#steps + 1] = { src = p.zip, dst = P.GAME[p.engine].dst, atomic = true }; packs[#packs + 1] = p
        end
    end
    if #steps == 0 then S.status(tr('prof_loaded', prof.name), 'ok') if X.rerender then X.rerender() end return end
    C.jobStart({ title = tr('applying', prof.name), steps = steps, onDone = function(ok, msg)
        if ok then
            for _, p in ipairs(packs) do C.markApplied(p) end
            C.saveConfig(); C.checkDrift(); S.status(tr('prof_loaded', prof.name), 'ok')
        else S.status(tr('apply_fail', tostring(msg)), 'err') end
        if X.rerender then X.rerender() end
    end })
end

-- ========================================
-- ПЛАГИНЫ + SDK
-- ========================================
function SDK.emit(ev, ...)
    local list = SDK.handlers and SDK.handlers[ev]
    if not list then return end
    for _, fn in ipairs(list) do U.safe(fn, 'sdk:' .. ev, ...) end
end
SDK.handlers, SDK.tools = {}, {}
SDK.version, SDK.build = P.VER_NUM, P.BUILD
function SDK.log(...)
    local t = {}
    for i = 1, select('#', ...) do t[#t + 1] = tostring((select(i, ...))) end
    U.log('[' .. tostring(SDK.current or 'plugin') .. '] ' .. table.concat(t, ' '))
end
function SDK.toast(msg, kind) C.toast(tostring(msg), kind) end
function SDK.on(ev, fn)
    if type(fn) ~= 'function' then return end
    SDK.handlers[ev] = SDK.handlers[ev] or {}
    table.insert(SDK.handlers[ev], fn)
end
function SDK.after(ticks, fn) return later(ticks, fn) end
function SDK.activePack() return C.selectedName() end
function SDK.registerTool(def)
    if type(def) ~= 'table' or type(def.run) ~= 'function' then return false end
    def.owner = SDK.current
    SDK.tools[#SDK.tools + 1] = def
    return true
end
function SDK.config(name)
    name = name or SDK.current or 'shared'
    local dir = P.SCR .. name .. '/'
    local path = dir .. 'config.json'
    local store = { data = {} }
    local c = U.read(path)
    if c then
        local ok, d = pcall(cjson.decode, c)
        if ok and type(d) == 'table' then store.data = d end
    end
    function store.get(k, def) local v = store.data[k]; if v == nil then return def end return v end
    function store.set(k, v) store.data[k] = v end
    function store.save() U.mkdir(dir); return U.write(path, cjson.encode(store.data)) end
    return store
end

function C.runPlugin(folder)
    local s
    for _, x in ipairs(S.scripts) do if x.folder == folder then s = x break end end
    if not s then return false end
    local code = U.read(s.path)
    local loader = rawget(_G, 'loadstring') or rawget(_G, 'load')
    local fn, err
    if code and loader then fn, err = loader(code, '=' .. folder) else err = 'cannot read script' end
    if not fn then
        S.plug[folder] = { status = 'error', err = tostring(err):match('^[^\n]*') }
        U.log('plugin load error [' .. folder .. ']: ' .. tostring(err), 'E')
        return false
    end
    SDK.current = folder
    local ok, res = xpcall(fn, U.tb)
    SDK.current = nil
    if ok then
        S.plug[folder] = { status = 'ok' }
        U.log('plugin started: ' .. folder)
        return true
    end
    S.plug[folder] = { status = 'error', err = (tostring(res):match('^[^\n]*') or '?') }
    U.log('plugin runtime error [' .. folder .. ']: ' .. tostring(res), 'E')
    return false
end

function C.setPlugin(folder, on)
    local list, found = {}, false
    for _, v in ipairs(S.activeList) do
        if v == folder then found = true; if on then list[#list + 1] = v end else list[#list + 1] = v end
    end
    if on and not found then list[#list + 1] = folder end
    S.activeList = list
    C.saveActive()
    S.plug[folder] = on and { status = 'pending' } or { status = 'off' }
    SDK.emit('plugin_toggled', folder, on)
end

function C.bootPlugins()
    for _, f in ipairs(S.activeList) do
        if S.cfg.safe_mode then S.plug[f] = { status = 'safe' } else C.runPlugin(f) end
    end
end
function C.pluginStatus(folder)
    local st = S.plug[folder]
    if st then return st.status, st.err end
    return C.isPluginOn(folder) and 'pending' or 'off'
end

-- ========================================
-- UI ТУЛКИТ
-- ========================================
if not UI or not Enum or not Enum.WidgetType then U.log('UI is not available, CeriumCore stopped', 'E') return end
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
do
    local ss = GUIManager.Instance():getScreenSize()
    X.W, X.H = ss.x, ss.y
end
local W, H = X.W, X.H
X.caps = { frame = false, fps = false }
X.groups = { frame = {}, nav = {}, content = {}, status = {}, overlay = {}, launcher = {}, hud = {} }
X.instant = false
X.delay = 0
X.rawN = 0

-- проверка: умеет ли Frame рисовать сплошной цвет (иначе рисуем картинками, как в 1.11)
do
    local ok, w = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Frame) end)
    if ok and w then
        local ok1 = pcall(function() w:setBackgroundColor({ 0.25, 0.5, 0.75, 1 }) end)
        local ok2, got = pcall(function() return w:getBackgroundColor() end)
        X.caps.frame = (ok1 and ok2 and got ~= nil) and true or false
    end
    local okF, fps = pcall(function() return Root.Instance():getFPS() end)
    X.caps.fps = (okF and type(fps) == 'number') and true or false
    U.log('caps: frame=' .. tostring(X.caps.frame) .. ' fps=' .. tostring(X.caps.fps) .. ' screen=' .. tostring(W) .. 'x' .. tostring(H))
end

function X.computeFonts()
    local sc = ({ 0.88, 1.0, 1.18 })[S.cfg.scale] or 1.0
    local b = max(12, floor(H * 0.025 * sc + 0.5))
    X.FS = { base = b, small = max(10, floor(b * 0.8)), tiny = max(9, floor(b * 0.7)), h2 = floor(b * 1.25), h1 = floor(b * 1.7), big = floor(b * 2.2) }
end
function X.computeLayout()
    local PW, PH = floor(W * 0.92), floor(H * 0.90)
    local L = { px = floor((W - PW) / 2), py = floor((H - PH) / 2), pw = PW, ph = PH }
    L.pad = floor(PH * 0.022)
    L.sbw = floor(PW * 0.19)
    L.cx = L.px + L.sbw + L.pad
    L.cw = PW - L.sbw - L.pad * 2
    L.hh = floor(PH * 0.13)
    L.fh = floor(PH * 0.085)
    L.cy = L.py + L.hh
    L.ch = PH - L.hh - L.fh
    L.gap = floor(PH * 0.02)
    X.LY = L
end

local function mix(a, b, k) return { a[1] * (1 - k) + b[1] * k, a[2] * (1 - k) + b[2] * k, a[3] * (1 - k) + b[3] * k } end
function X.role(role)
    local acc = S.theme().rgb
    local bg = mix({ 0.035, 0.055, 0.085 }, acc, 0.05)
    local R = {
        dim    = { c = { 0, 0, 0 }, a = 0.55, img = P.IMG_PANEL, ia = 0.55 },
        panel  = { c = bg, a = 0.97, img = P.IMG_PANEL, ia = 0.9 },
        side   = { c = mix(bg, { 0, 0, 0 }, 0.35), a = 0.98, img = P.IMG_PANEL, ia = 0.7 },
        card   = { c = mix(bg, { 1, 1, 1 }, 0.07), a = 0.95, img = P.IMG_ROW, ia = 0.30 },
        cardon = { c = mix(bg, acc, 0.22), a = 0.97, img = P.IMG_ROW, ia = 0.55 },
        modal  = { c = mix(bg, { 1, 1, 1 }, 0.04), a = 0.99, img = P.IMG_PANEL, ia = 0.98 },
        acc    = { c = acc, a = 1, img = P.IMG_BTN, ia = 1 },
        ok     = { c = { 0.29, 0.87, 0.50 }, a = 1, img = P.IMG_BTN, ia = 1 },
        warn   = { c = { 0.98, 0.75, 0.14 }, a = 1, img = P.IMG_BTN, ia = 1 },
        err    = { c = { 0.98, 0.44, 0.52 }, a = 1, img = P.IMG_BTN, ia = 1 },
        track  = { c = { 1, 1, 1 }, a = 0.14, img = P.IMG_ROW, ia = 0.25 },
        hudbg  = { c = { 0, 0, 0 }, a = 0.55, img = P.IMG_PANEL, ia = 0.5 },
        thumb  = { c = acc, a = 1, img = P.IMG_ROW, ia = 0.6 },
    }
    return R[role] or R.card
end

-- --- узлы: {el=, a=целевая альфа, dead=} (в сами виджеты поля писать нельзя) ---
local function px2(el, x, y, w, h)
    pcall(function() el:setPosition(UDim2.new(x / W, 0, y / H, 0)) end)
    pcall(function() el:setSize(UDim2.new(w / W, 0, h / H, 0)) end)
end
local function setAlpha(n, a) pcall(function() n.el:setAlpha(a) end) end

local anims, animOn = {}, false
local function animStep()
    local keep = {}
    for _, an in ipairs(anims) do
        if not an.n.dead then
            an.t = an.t + 1
            local p = (an.t - an.d) / an.dur
            if p >= 1 then setAlpha(an.n, an.n.a)
            else
                if p > 0 then setAlpha(an.n, an.n.a * (p * (2 - p))) end
                keep[#keep + 1] = an
            end
        end
    end
    anims = keep
    if #anims == 0 then animOn = false return false end
    return true
end
local function appear(n)
    if X.instant or not S.cfg.anim or not S.ensureHB() then setAlpha(n, n.a) return end
    setAlpha(n, 0)
    anims[#anims + 1] = { n = n, d = X.delay, dur = 6, t = 0 }
    if not animOn then animOn = true; S.addTicker(animStep) end
end

local function register(grp, el, a, passive)
    local n = { el = el, a = a or 1 }
    X.groups[grp][#X.groups[grp] + 1] = n
    UI.root:addChild(el)
    if passive then
        pcall(function() el:setMousePassThroughEnabled(true) end)
        pcall(function() el:setTouchThrough(true) end)
    end
    appear(n)
    return n
end

function X.clear(grp)
    for _, n in ipairs(X.groups[grp]) do
        n.dead = true
        pcall(function() n.el:setVisible(false) end)
        pcall(function() winMgr:destroyWindow(n.el) end)
    end
    X.groups[grp] = {}
end

local function tint(el, c, a)
    local function h(v) return sfmt('%02X', floor(U.clamp(v, 0, 1) * 255 + 0.5)) end
    local s = h(a or 1) .. h(c[1]) .. h(c[2]) .. h(c[3])
    pcall(function() el:setProperty("ImageColours", "tl:" .. s .. " tr:" .. s .. " bl:" .. s .. " br:" .. s) end)
end

-- прямоугольник. role: см. X.role; passive=true -> не ловит нажатия
function X.rect(grp, x, y, w, h, role, o)
    o = o or {}
    local st = X.role(role)
    local c = o.rgb or st.c
    local n
    if X.caps.frame then
        local ok, el = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Frame) end)
        if not ok or not el then return nil end
        pcall(function() el:setBackgroundColor({ c[1], c[2], c[3], 1 }) end)
        pcall(function() el:setProperty("BackgroundEnabled", true) end)
        px2(el, x, y, w, h)
        n = register(grp, el, o.a or st.a, o.passive)
        n.frame = true
    else
        X.rawN = X.rawN + 1
        local ok, el = pcall(function() return winMgr:createWindow("Engine/StaticImage", "cerium-" .. X.rawN .. "-" .. winMgr:generateUniqueWindowName()) end)
        if not ok or not el then return nil end
        pcall(function() el:setProperty("FrameEnabled", false) end)
        pcall(function() el:setImage(st.img) end)
        pcall(function() el:setDestroyedByParent(false) end)
        if o.rgb or role == 'acc' or role == 'ok' or role == 'warn' or role == 'err' then tint(el, c, 1) end
        pcall(function() el:setArea2({ 0, x }, { 0, y }, { 0, w }, { 0, h }) end)
        pcall(function() el:setVisible(true) end)
        n = register(grp, el, o.a or st.ia, o.passive)
    end
    n.geom = { x, y, w, h }
    return n
end
function X.setGeom(n, x, y, w, h)
    if not n then return end
    n.geom = { x, y, w, h }
    if n.frame then px2(n.el, x, y, w, h)
    else pcall(function() n.el:setArea2({ 0, x }, { 0, y }, { 0, w }, { 0, h }) end) end
end
function X.setRectColor(n, c)
    if not n then return end
    if n.frame then pcall(function() n.el:setBackgroundColor({ c[1], c[2], c[3], 1 }) end)
    else tint(n.el, c, 1) end
end

local function setAlign(el, align, valign)
    local hf, vf = Enum.TextHorizontalFormat, Enum.TextVerticalFormat
    if hf then
        local v = (align == 'c' and hf.Center) or (align == 'r' and hf.Right) or hf.Left
        if v then pcall(function() el:setTextHorizontalFormat(v) end) end
    end
    if vf then
        local v = (valign == 'm' and (vf.Center or vf.Middle)) or vf.Top
        if v then pcall(function() el:setTextVerticalFormat(v) end) end
    end
    local hn = (align == 'c' and 'CentreAligned') or (align == 'r' and 'RightAligned') or 'LeftAligned'
    pcall(function() el:setProperty("HorzFormatting", hn) end)
    pcall(function() el:setProperty("VertFormatting", valign == 'm' and 'CentreAligned' or 'TopAligned') end)
end

-- текст. o: size, color(hex), align l/c/r, valign t/m
function X.text(grp, str, x, y, w, h, o)
    o = o or {}
    local ok, el = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Text) end)
    if not ok or not el then return nil end
    local s = U.esc(str)
    if o.raw then s = tostring(str) end
    if o.color then s = U.col(o.color, s) end
    pcall(function() el:setText(s) end)
    px2(el, x, y, w, h)
    pcall(function() el:setTextSize(o.size or X.FS.base) end)
    pcall(function() el:setWordWrapped(false) end)
    setAlign(el, o.align or 'l', o.valign or 't')
    return register(grp, el, 1, true)
end
function X.setText(n, str, color)
    if not n then return end
    local s = U.esc(str)
    if color then s = U.col(color, s) end
    pcall(function() n.el:setText(s) end)
end

-- кнопка. o: style(primary|chip|danger|ghost), on(bool для chip), size, color
function X.btn(grp, label, x, y, w, h, onClick, o)
    o = o or {}
    local ok, el = pcall(function() return UI:CreateGUIWidget(Enum.WidgetType.Button) end)
    if not ok or not el then return nil end
    local style = o.style or 'primary'
    local color = o.color
    if not color then
        if style == 'chip' then color = o.on and S.accent() or S.C_DIM
        elseif style == 'danger' then color = S.C_ERR
        elseif style == 'ghost' then color = S.C_DIM end
    end
    local txt = o.raw and tostring(label) or U.esc(label)
    if color then txt = U.col(color, txt) end
    pcall(function() el:setText(txt) end)
    px2(el, x, y, w, h)
    for _, k in ipairs({ "NormalImage", "PushedImage", "HoverImage" }) do pcall(function() el:setProperty(k, P.IMG_BTN) end) end
    pcall(function() el:setTextSize(o.size or X.FS.base) end)
    local last = -100
    if onClick then
        el.onMouseClick = function()
            if hb.tick - last < 3 and hb.started then return end
            last = hb.tick
            U.safe(onClick, 'btn:' .. tostring(label))
        end
    end
    local a = 1
    if style == 'chip' and not o.on then a = 0.7 elseif style == 'ghost' then a = 0.8 end
    local n = register(grp, el, a, false)
    if o.disabled then pcall(function() el:setEnabled(false) end) end
    return n
end

-- ========================================
-- СТАТУС-СТРОКА, МОДАЛКИ, ПРОГРЕСС
-- ========================================
function X.drawStatus()
    X.clear('status')
    local m = S.statusMsg
    if not m or not S.menuOpen then return end
    local L = X.LY
    local c = (m.kind == 'err' and S.C_ERR) or (m.kind == 'warn' and S.C_WARN) or (m.kind == 'ok' and S.C_OK) or S.C_TXT
    local saveInst = X.instant; X.instant = true
    X.text('status', U.fit(m.text, L.cw * 0.52, X.FS.small), L.cx, L.py + L.ph - L.fh + L.fh * 0.28, L.cw * 0.54, L.fh * 0.5, { size = X.FS.small, color = c })
    X.instant = saveInst
end

function X.closeModal() X.clear('overlay'); S.modal = false; X.prog = nil end

-- buttons: { {text=, fn=, style=} ... }
function X.modal(title, lines, buttons)
    X.clear('overlay')
    S.modal = true
    local mw, mh = floor(W * 0.46), floor(H * 0.46)
    local mx, my = floor((W - mw) / 2), floor((H - mh) / 2)
    X.rect('overlay', 0, 0, W, H, 'dim')
    X.rect('overlay', mx, my, mw, mh, 'modal')
    X.rect('overlay', mx, my, mw, max(3, floor(mh * 0.012)), 'acc', { passive = true })
    local pad = floor(mh * 0.07)
    X.text('overlay', title, mx + pad, my + pad, mw - pad * 2, mh * 0.14, { size = X.FS.h2, color = S.accent() })
    local body = {}
    for _, l in ipairs(lines or {}) do
        for _, w in ipairs(U.wrap(l, mw - pad * 2, X.FS.base, 4)) do body[#body + 1] = w end
    end
    if #body > 0 then X.text('overlay', table.concat(body, '\n'), mx + pad, my + pad + mh * 0.18, mw - pad * 2, mh * 0.4, { size = X.FS.base, color = S.C_TXT, raw = false }) end
    local n = #buttons
    local bw = floor((mw - pad * 2 - (n - 1) * pad * 0.5) / n)
    local bh = floor(mh * 0.17)
    for i, b in ipairs(buttons) do
        X.btn('overlay', b.text, mx + pad + (i - 1) * (bw + pad * 0.5), my + mh - pad - bh, bw, bh, function()
            X.closeModal()
            if b.fn then b.fn() end
        end, { style = b.style or 'primary' })
    end
end
function X.confirm(title, body, onYes)
    X.modal(title, { body }, { { text = tr('yes'), fn = onYes, style = 'danger' }, { text = tr('no'), style = 'ghost' } })
end

function X.showProgress(title)
    X.clear('overlay')
    S.modal = true
    local mw, mh = floor(W * 0.42), floor(H * 0.30)
    local mx, my = floor((W - mw) / 2), floor((H - mh) / 2)
    X.rect('overlay', 0, 0, W, H, 'dim')
    X.rect('overlay', mx, my, mw, mh, 'modal')
    X.rect('overlay', mx, my, mw, max(3, floor(mh * 0.02)), 'acc', { passive = true })
    local pad = floor(mh * 0.1)
    X.text('overlay', U.fit(title, mw - pad * 2, X.FS.h2), mx + pad, my + pad, mw - pad * 2, mh * 0.2, { size = X.FS.h2, color = S.accent() })
    local bx, by, bw, bh = mx + pad, my + floor(mh * 0.42), mw - pad * 2, max(8, floor(mh * 0.1))
    X.rect('overlay', bx, by, bw, bh, 'track', { passive = true })
    local fill = X.rect('overlay', bx, by, 1, bh, 'acc', { passive = true })
    local pct = X.text('overlay', '0%', bx, by + bh + 4, bw, mh * 0.15, { size = X.FS.small, color = S.C_DIM, align = 'c' })
    X.btn('overlay', tr('cancel'), mx + mw - pad - floor(mw * 0.3), my + mh - pad - floor(mh * 0.2), floor(mw * 0.3), floor(mh * 0.2), function()
        if C.job then C.job.cancel = true end
    end, { style = 'ghost', size = X.FS.small })
    X.prog = { fill = fill, pct = pct, bx = bx, by = by, bw = bw, bh = bh, last = -1 }
end
function X.updateProgress(f)
    local p = X.prog
    if not p then return end
    f = U.clamp(f, 0, 1)
    local pc = floor(f * 100)
    if pc == p.last then return end
    p.last = pc
    X.setGeom(p.fill, p.bx, p.by, max(1, floor(p.bw * f)), p.bh)
    X.setText(p.pct, pc .. '%', S.C_DIM)
end
function X.hideProgress() if X.prog then X.closeModal() end end

-- ========================================
-- КАРКАС: рамка, навигация, шапка, пагинация
-- ========================================
X.TABS = { 'packs', 'plugins', 'profiles', 'tools', 'log', 'settings' }

function X.buildFrame()
    local L, F = X.LY, X.FS
    X.rect('frame', 0, 0, W, H, 'dim')
    X.rect('frame', L.px, L.py, L.pw, L.ph, 'panel')
    X.rect('frame', L.px, L.py, L.sbw, L.ph, 'side')
    X.rect('frame', L.px + L.sbw, L.py, max(2, floor(L.pw * 0.002)), L.ph, 'acc', { passive = true, a = 0.5 })
    X.text('frame', U.grad('CERIUM', S.theme().acc, S.theme().acc2), L.px + L.sbw * 0.1, L.py + L.ph * 0.025, L.sbw * 0.9, F.big * 1.4, { size = F.big, raw = true })
    X.text('frame', P.VER .. '  "Nova"', L.px + L.sbw * 0.1, L.py + L.ph * 0.025 + F.big * 1.35, L.sbw * 0.9, F.small * 1.5, { size = F.small, color = S.C_DIM })
    local cb = floor(L.hh * 0.5)
    X.btn('frame', 'X', L.px + L.pw - L.pad - cb, L.py + floor(L.hh * 0.15), cb, cb, function() X.closeMenu() end, { style = 'danger' })
end

function X.buildNav()
    local L, F = X.LY, X.FS
    local top = L.py + floor(L.ph * 0.2)
    local ih, ig = floor(L.ph * 0.092), floor(L.ph * 0.012)
    local bx, bw = L.px + floor(L.sbw * 0.08), floor(L.sbw * 0.84)
    for i, key in ipairs(X.TABS) do
        local y = top + (i - 1) * (ih + ig)
        local on = (S.tab == key)
        if on then X.rect('nav', L.px, y, max(4, floor(L.sbw * 0.025)), ih, 'acc', { passive = true }) end
        X.btn('nav', tr('nav_' .. key), bx, y, bw, ih, function()
            if S.tab ~= key then S.tab = key; X.renderTab() end
        end, { style = 'chip', on = on, size = F.base })
    end
    -- нижний блок
    local by = L.py + floor(L.ph * 0.80)
    local an = C.selectedName() or tr('side_none')
    X.text('nav', tr('side_active'), bx, by, bw, F.small * 1.4, { size = F.small, color = S.C_DIM })
    X.text('nav', U.fit(an, bw, F.small), bx, by + F.small * 1.4, bw, F.small * 1.5, { size = F.small, color = C.hasDrift() and S.C_WARN or S.accent() })
    X.text('nav', tr('side_plugins', #S.activeList), bx, by + F.small * 2.9, bw, F.small * 1.5, { size = F.small, color = S.C_DIM })
    X.btn('nav', tr('sidebar_link'), bx, L.py + L.ph - floor(L.ph * 0.075), bw, floor(L.ph * 0.055), function()
        C.copyText('https://' .. P.VFORGE); S.status(tr('link_copied'), 'ok')
    end, { style = 'ghost', size = F.small })
end

function X.header(title, sub)
    local L, F = X.LY, X.FS
    X.text('content', title, L.cx, L.py + L.hh * 0.1, L.cw * 0.5, F.h1 * 1.3, { size = F.h1, color = S.accent() })
    if sub then X.text('content', U.fit(sub, L.cw * 0.5, F.small), L.cx, L.py + L.hh * 0.1 + F.h1 * 1.25, L.cw * 0.5, F.small * 1.5, { size = F.small, color = S.C_DIM }) end
end
-- правые кнопки шапки: список {text, fn, on}; рисуются справа налево до кнопки закрытия
function X.headerButtons(list)
    local L, F = X.LY, X.FS
    local right = L.px + L.pw - L.pad - floor(L.hh * 0.5) - L.pad
    local bh = floor(L.hh * 0.42)
    local y = L.py + floor(L.hh * 0.5)
    for i = #list, 1, -1 do
        local b = list[i]
        local bw = floor(L.cw * (b.w or 0.15))
        X.btn('content', b.text, right - bw, y, bw, bh, b.fn, { style = 'chip', on = b.on, size = F.small })
        right = right - bw - floor(L.pad * 0.5)
    end
end

function X.pager(pages, tabKey)
    if pages <= 1 then return end
    local L, F = X.LY, X.FS
    local fy = L.py + L.ph - L.fh
    local bh, bw = floor(L.fh * 0.72), floor(L.fh * 1.1)
    local rx = L.cx + L.cw
    local pg = S.page[tabKey]
    X.btn('content', '>', rx - bw, fy + floor(L.fh * 0.12), bw, bh, function()
        if S.page[tabKey] < pages then S.page[tabKey] = S.page[tabKey] + 1; X.renderTab(true) end
    end, { style = 'chip', on = pg < pages })
    X.text('content', tr('page', pg, pages), rx - bw - floor(L.cw * 0.12), fy + floor(L.fh * 0.25), floor(L.cw * 0.11), F.base * 1.4, { size = F.base, color = S.C_TXT, align = 'c' })
    X.btn('content', '<', rx - bw * 2 - floor(L.cw * 0.12), fy + floor(L.fh * 0.12), bw, bh, function()
        if S.page[tabKey] > 1 then S.page[tabKey] = S.page[tabKey] - 1; X.renderTab(true) end
    end, { style = 'chip', on = pg > 1 })
end

function X.empty(t1, t2)
    local L, F = X.LY, X.FS
    X.text('content', t1, L.cx, L.cy + L.ch * 0.35, L.cw, F.h2 * 1.5, { size = F.h2, color = S.C_DIM, align = 'c' })
    if t2 then
        local lines = U.wrap(t2, L.cw * 0.7, F.small, 3)
        X.text('content', table.concat(lines, '\n'), L.cx + L.cw * 0.15, L.cy + L.ch * 0.35 + F.h2 * 1.8, L.cw * 0.7, F.small * 4.5, { size = F.small, color = S.C_DIM, align = 'c' })
    end
end

-- ========================================
-- ЭКРАН: ПАКИ
-- ========================================
local SORTS = { 'az', 'za', 'new', 'size', 'fav' }
local FILTERS = { 'all', 'fav', 'v1', 'v2' }
local function cycle(list, cur)
    for i, v in ipairs(list) do if v == cur then return list[i % #list + 1] end end
    return list[1]
end

-- превью из preview.png (если файл есть и валиден)
function X.previewImage(p)
    if p.img ~= nil then return p.img or nil end
    p.img = false
    if not p.preview or not C.pngValid(p.preview) then return nil end
    local ok = pcall(function()
        local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
        local name = 'cerium_prev_' .. p.folder
        for _, grp in ipairs({ '', '_textures_', 'gameres', 'asset' }) do
            if imgMgr:isDefined(name) then break end
            pcall(function() imgMgr:addFromImageFile(name, p.preview, grp) end)
        end
        if imgMgr:isDefined(name) then p.img = name end
    end)
    return p.img or nil
end

function SCR.packCard(p, x, y, w, h)
    local F = X.FS
    local active = C.activeFor(p)
    X.rect('content', x, y, w, h, active and 'cardon' or 'card')
    X.rect('content', x, y, max(4, floor(w * 0.012)), h, active and 'ok' or 'acc', { passive = true, a = active and 1 or 0.55 })
    local ip = floor(h * 0.1)
    local th = h - ip * 2 - floor(h * 0.3)
    local tx, ty = x + ip + floor(w * 0.012), y + ip
    local hue = U.hash(p.folder)
    local base = S.theme().rgb
    local rgb = { 0.25 + ((hue % 97) / 97) * 0.5, 0.25 + (((hue / 97) % 89) / 89) * 0.5, 0.35 + (((hue / 8633) % 83) / 83) * 0.45 }
    X.rect('content', tx, ty, th, th, 'thumb', { rgb = mix(rgb, base, 0.25), passive = true })
    local img = S.cfg.previews ~= false and X.previewImage(p)
    if img then
        X.rawN = X.rawN + 1
        local ok, el = pcall(function() return winMgr:createWindow("Engine/StaticImage", "cerium-pv-" .. X.rawN .. "-" .. winMgr:generateUniqueWindowName()) end)
        if ok and el then
            pcall(function() el:setProperty("FrameEnabled", false) end)
            pcall(function() el:setImage(img) end)
            pcall(function() el:setArea2({ 0, tx }, { 0, ty }, { 0, th }, { 0, th }) end)
            pcall(function() el:setVisible(true) end)
            register('content', el, 1, true)
        end
    else
        X.text('content', U.initials(p.name), tx, ty + floor(th * 0.3), th, F.h1 * 1.3, { size = F.h1, color = 'FFFFFFFF', align = 'c' })
    end
    local nx = tx + th + ip
    local nw = x + w - nx - ip
    X.text('content', U.fit(p.name, nw, F.base), nx, ty, nw, F.base * 1.4, { size = F.base, color = active and S.C_OK or S.C_TXT })
    local meta = 'v' .. p.version .. '  -  ' .. tr('engine_tag', p.engine) .. '  -  ' .. U.fsize(p.size)
    if p.author ~= '' then meta = meta .. '  -  ' .. p.author end
    X.text('content', U.fit(meta, nw, F.small), nx, ty + F.base * 1.45, nw, F.small * 1.4, { size = F.small, color = p.valid and S.accent() or S.C_ERR })
    local descY = ty + F.base * 1.45 + F.small * 1.45
    if not p.valid then
        X.text('content', tr('bad_zip'), nx, descY, nw, F.small * 1.4, { size = F.small, color = S.C_ERR })
    elseif p.description ~= '' then
        local lines = U.wrap(p.description, nw, F.small, 2)
        X.text('content', table.concat(lines, '\n'), nx, descY, nw, F.small * 3, { size = F.small, color = S.C_DIM })
    end
    local bh = floor(h * 0.26)
    local by = y + h - ip - bh
    local bx = x + ip + floor(w * 0.012)
    local avail = w - ip * 2 - floor(w * 0.012)
    local favw = floor(avail * 0.28)
    X.btn('content', active and tr('active') or tr('apply'), bx, by, avail - favw - floor(ip * 0.5), bh, function()
        C.applyPack(p)
    end, { style = 'primary', disabled = active or not p.valid, size = F.base, color = active and S.C_OK or nil })
    local fav = C.isFav(p.folder)
    X.btn('content', tr('fav'), bx + avail - favw, by, favw, bh, function()
        S.cfg.favorites[p.folder] = (not fav) or nil
        C.saveConfig(); X.renderTab(true, true)
    end, { style = 'chip', on = fav, color = fav and S.C_WARN or S.C_DIM, size = F.small })
end

function SCR.packs()
    local L, F = X.LY, X.FS
    local list = C.viewPacks()
    local pages = max(1, ceil(#list / P.PER_PACKS))
    S.page.packs = U.clamp(S.page.packs, 1, pages)
    local sub = tr('packs_sub', #S.packs, C.selectedName() or tr('side_none'))
    X.header(tr('nav_packs'), sub)
    X.headerButtons({
        { text = tr('undo'), w = 0.15, fn = function() C.undoPack() end },
        { text = tr('filter', tr('flt_' .. S.cfg.filter)), w = 0.16, on = S.cfg.filter ~= 'all', fn = function()
            S.cfg.filter = cycle(FILTERS, S.cfg.filter); S.page.packs = 1; C.saveConfig(); X.renderTab(true) end },
        { text = tr('sort', tr('sort_' .. S.cfg.sort)), w = 0.16, fn = function()
            S.cfg.sort = cycle(SORTS, S.cfg.sort); C.saveConfig(); X.renderTab(true) end },
    })
    if C.hasDrift() then
        local e, f = next(S.drift)
        local pk = C.findPack(f)
        local bw = floor(L.cw * 0.2)
        X.text('content', U.fit(tr('drift_warn', pk and pk.name or f), L.cw - bw - L.gap, F.small), L.cx, L.cy - F.small * 1.9, L.cw - bw - L.gap, F.small * 1.5, { size = F.small, color = S.C_WARN })
        X.btn('content', tr('reapply'), L.cx + L.cw - bw, L.cy - F.small * 2.4, bw, floor(L.hh * 0.38), function() C.reapplyDrift() end, { style = 'chip', on = true, color = S.C_WARN, size = F.small })
    end
    if #list == 0 then X.empty(tr('packs_none'), tr('packs_none2')) return end
    local gap = L.gap
    local cw, ch = floor((L.cw - gap) / 2), floor((L.ch - gap * 2) / 3)
    for i = 1, P.PER_PACKS do
        local p = list[(S.page.packs - 1) * P.PER_PACKS + i]
        if not p then break end
        X.delay = i
        SCR.packCard(p, L.cx + ((i - 1) % 2) * (cw + gap), L.cy + floor((i - 1) / 2) * (ch + gap), cw, ch)
    end
    X.delay = 0
    X.pager(pages, 'packs')
end

-- ========================================
-- ЭКРАН: ПЛАГИНЫ
-- ========================================
function SCR.plugins()
    local L, F = X.LY, X.FS
    local list = S.scripts
    local pages = max(1, ceil(#list / P.PER_PLUGINS))
    S.page.plugins = U.clamp(S.page.plugins, 1, pages)
    X.header(tr('nav_plugins'), tr('plug_sub', #list, #S.activeList))
    X.headerButtons({
        { text = tr('safe', S.cfg.safe_mode and tr('on') or tr('off')), w = 0.22, on = S.cfg.safe_mode, fn = function()
            S.cfg.safe_mode = not S.cfg.safe_mode; C.saveConfig()
            S.status(S.cfg.safe_mode and tr('safe_on_t') or tr('safe_off_t'), 'warn'); X.renderTab(true, true) end },
        { text = tr('refresh'), w = 0.14, fn = function() C.rescan(); S.status(tr('rescanned', #S.packs, #S.scripts), 'ok'); X.renderTab(true) end },
    })
    if #list == 0 then X.empty(tr('plug_none'), tr('plug_none2')) return end
    local gap = floor(L.gap * 0.8)
    local rh = floor((L.ch - gap * (P.PER_PLUGINS - 1)) / P.PER_PLUGINS)
    for i = 1, P.PER_PLUGINS do
        local s = list[(S.page.plugins - 1) * P.PER_PLUGINS + i]
        if not s then break end
        X.delay = i
        local y = L.cy + (i - 1) * (rh + gap)
        local on = C.isPluginOn(s.folder)
        local st, err = C.pluginStatus(s.folder)
        local sc = (st == 'ok' and S.C_OK) or (st == 'error' and S.C_ERR) or ((st == 'pending' or st == 'safe') and S.C_WARN) or S.C_DIM
        X.rect('content', L.cx, y, L.cw, rh, on and 'cardon' or 'card')
        X.rect('content', L.cx, y, max(5, floor(L.cw * 0.008)), rh, (st == 'ok' and 'ok') or (st == 'error' and 'err') or ((st == 'pending' or st == 'safe') and 'warn') or 'acc', { passive = true, a = on and 1 or 0.35 })
        local ip = floor(rh * 0.12)
        local tx = L.cx + ip + floor(L.cw * 0.01)
        local tw = floor(L.cw * 0.6)
        X.text('content', U.fit(s.name .. '  v' .. s.version, tw, F.base), tx, y + ip, tw, F.base * 1.4, { size = F.base, color = on and S.C_TXT or S.C_DIM })
        X.text('content', tr('st_' .. (st == 'safe' and 'safe' or st)), tx + tw, y + ip, floor(L.cw * 0.2), F.small * 1.4, { size = F.small, color = sc, align = 'r' })
        local meta = (s.author ~= '' and ('by ' .. s.author .. '  -  ') or '') .. s.folder
        X.text('content', U.fit(meta, tw, F.small), tx, y + ip + F.base * 1.4, tw, F.small * 1.4, { size = F.small, color = S.accent() })
        local line = (err and st == 'error') and err or s.description
        if line and line ~= '' then
            X.text('content', U.fit(line, tw + floor(L.cw * 0.2), F.small), tx, y + ip + F.base * 1.4 + F.small * 1.4, tw + floor(L.cw * 0.2), F.small * 1.4, { size = F.small, color = (st == 'error') and S.C_ERR or S.C_DIM })
        end
        local bh = floor(rh * 0.5)
        local by = y + floor((rh - bh) / 2)
        local rw = floor(L.cw * 0.13)
        X.btn('content', tr('run'), L.cx + L.cw - ip - rw, by, rw, bh, function()
            if C.runPlugin(s.folder) then S.status(tr('plug_run_ok', s.name), 'ok') else S.status(tr('plug_run_err', s.name), 'err') end
            X.renderTab(true, true)
        end, { style = 'chip', on = true, size = F.small })
        X.btn('content', on and tr('on') or tr('off'), L.cx + L.cw - ip * 2 - rw * 2, by, rw, bh, function()
            C.setPlugin(s.folder, not on)
            S.status(on and tr('plug_disabled', s.name) or tr('plug_enabled', s.name), on and 'info' or 'ok')
            X.renderTab(true, true)
        end, { style = 'chip', on = on, color = on and S.C_OK or S.C_DIM, size = F.small })
    end
    X.delay = 0
    X.pager(pages, 'plugins')
end

-- ========================================
-- ЭКРАН: ПРОФИЛИ
-- ========================================
function SCR.profiles()
    local L, F = X.LY, X.FS
    local profs = S.cfg.profiles
    X.header(tr('nav_profiles'), tr('prof_sub', #profs, P.MAX_PROFILES))
    local gap = L.gap
    local cw, ch = floor((L.cw - gap) / 2), floor((L.ch - gap * 2) / 3)
    local items = { 'new' }
    for i = 1, #profs do items[#items + 1] = i end
    for i, it in ipairs(items) do
        if i > P.PER_PROFILES + 1 then break end
        local x, y = L.cx + ((i - 1) % 2) * (cw + gap), L.cy + floor((i - 1) / 2) * (ch + gap)
        X.delay = i
        local ip = floor(ch * 0.1)
        if it == 'new' then
            X.rect('content', x, y, cw, ch, 'card')
            X.rect('content', x, y, max(4, floor(cw * 0.012)), ch, 'acc', { passive = true })
            X.text('content', tr('prof_new'), x + ip * 1.5, y + ip, cw - ip * 3, F.base * 1.4, { size = F.base, color = S.accent() })
            X.text('content', tr('prof_new_d'), x + ip * 1.5, y + ip + F.base * 1.5, cw - ip * 3, F.small * 1.4, { size = F.small, color = S.C_DIM })
            X.text('content', U.fit(tr('prof_pack', C.selectedName() or tr('side_none')), cw - ip * 3, F.small), x + ip * 1.5, y + ip + F.base * 1.5 + F.small * 1.6, cw - ip * 3, F.small * 1.4, { size = F.small, color = S.C_TXT })
            X.text('content', tr('prof_plug', #S.activeList), x + ip * 1.5, y + ip + F.base * 1.5 + F.small * 3.2, cw - ip * 3, F.small * 1.4, { size = F.small, color = S.C_TXT })
            X.btn('content', tr('save'), x + ip * 1.5, y + ch - ip - floor(ch * 0.26), cw - ip * 3, floor(ch * 0.26), function()
                C.saveProfile(); X.renderTab(true, true) end, { style = 'primary', size = F.base })
        else
            local pr = profs[it]
            X.rect('content', x, y, cw, ch, 'card')
            X.rect('content', x, y, max(4, floor(cw * 0.012)), ch, 'acc', { passive = true, a = 0.55 })
            X.text('content', U.fit(pr.name, cw - ip * 3, F.base), x + ip * 1.5, y + ip, cw - ip * 3, F.base * 1.4, { size = F.base, color = S.C_TXT })
            local names = {}
            for e = 1, 2 do
                local f = pr.sel and pr.sel['e' .. e]
                if f then local p = C.findPack(f); names[#names + 1] = p and p.name or f end
            end
            X.text('content', U.fit(tr('prof_pack', #names > 0 and table.concat(names, ' + ') or tr('side_none')), cw - ip * 3, F.small), x + ip * 1.5, y + ip + F.base * 1.5, cw - ip * 3, F.small * 1.4, { size = F.small, color = S.accent() })
            X.text('content', tr('prof_plug', #(pr.plugins or {})) .. '  -  ' .. U.shortdate(pr.ts), x + ip * 1.5, y + ip + F.base * 1.5 + F.small * 1.6, cw - ip * 3, F.small * 1.4, { size = F.small, color = S.C_DIM })
            local bh = floor(ch * 0.26)
            local bw = floor((cw - ip * 3 - ip * 0.5) * 0.68)
            X.btn('content', tr('load'), x + ip * 1.5, y + ch - ip - bh, bw, bh, function() C.loadProfile(pr) end, { style = 'primary', size = F.base })
            X.btn('content', tr('delete'), x + ip * 1.5 + bw + ip * 0.5, y + ch - ip - bh, cw - ip * 3 - bw - ip * 0.5, bh, function()
                X.confirm(tr('delete') .. '?', pr.name, function() C.deleteProfile(it); X.renderTab(true, true) end)
            end, { style = 'danger', size = F.small })
        end
    end
    X.delay = 0
end

-- ========================================
-- ЭКРАН: ИНСТРУМЕНТЫ
-- ========================================
function SCR.toolList()
    local t = {
        { title = tr('t_reset'), desc = tr('t_reset_d'), danger = true, fn = function()
            X.confirm(tr('reset_title'), tr('reset_body'), function() C.resetVanilla() end) end },
        { title = tr('t_rescan'), desc = tr('t_rescan_d'), fn = function() C.rescan(); S.status(tr('rescanned', #S.packs, #S.scripts), 'ok'); X.renderTab(true, true) end },
        { title = tr('t_verify'), desc = tr('t_verify_d'), fn = function() C.verifyAll() end },
        { title = tr('t_copy'), desc = tr('t_copy_d'), fn = function() C.copyZips() end },
        { title = tr('t_dump'), desc = tr('t_dump_d'), fn = function() X.confirm(tr('t_dump'), tr('dump_conf'), function() C.dumpRes() end) end },
        { title = tr('t_store'), desc = tr('t_store_d'), fn = function() X.modal(tr('store_title'), C.storageLines(), { { text = tr('ok') } }) end },
        { title = tr('t_diag'), desc = tr('t_diag_d'), fn = function() C.copyText(C.diagReport()); S.status(tr('diag_ok'), 'ok') end },
        { title = tr('t_clean'), desc = tr('t_clean_d'), fn = function() C.cleanTemp() end },
    }
    for _, d in ipairs(SDK.tools) do
        t[#t + 1] = { title = tostring(d.name or d.owner or 'Plugin'), desc = tostring(d.desc or ''), plugin = true, fn = function()
            local ok, err = U.safe(d.run, 'tool:' .. tostring(d.name))
            if not ok then S.status('Tool error', 'err') end
        end }
    end
    return t
end

function SCR.tools()
    local L, F = X.LY, X.FS
    local tools = SCR.toolList()
    local pages = max(1, ceil(#tools / P.PER_TOOLS))
    S.page.tools = U.clamp(S.page.tools, 1, pages)
    X.header(tr('nav_tools'), tr('tools_sub'))
    local gap = L.gap
    local cw, ch = floor((L.cw - gap * 2) / 3), floor((L.ch - gap * 2) / 3)
    for i = 1, P.PER_TOOLS do
        local d = tools[(S.page.tools - 1) * P.PER_TOOLS + i]
        if not d then break end
        X.delay = i
        local x, y = L.cx + ((i - 1) % 3) * (cw + gap), L.cy + floor((i - 1) / 3) * (ch + gap)
        local ip = floor(ch * 0.1)
        X.rect('content', x, y, cw, ch, 'card')
        X.rect('content', x, y, cw, max(3, floor(ch * 0.025)), d.danger and 'err' or (d.plugin and 'ok' or 'acc'), { passive = true, a = 0.8 })
        X.text('content', U.fit(d.title, cw - ip * 2, F.base), x + ip, y + ip, cw - ip * 2, F.base * 1.4, { size = F.base, color = d.danger and S.C_ERR or S.accent() })
        local lines = U.wrap(d.desc, cw - ip * 2, F.small, 3)
        X.text('content', table.concat(lines, '\n'), x + ip, y + ip + F.base * 1.5, cw - ip * 2, F.small * 4.2, { size = F.small, color = S.C_DIM })
        local bh = floor(ch * 0.25)
        X.btn('content', tr('run'), x + ip, y + ch - ip - bh, cw - ip * 2, bh, d.fn, { style = d.danger and 'danger' or 'primary', size = F.small })
    end
    X.delay = 0
    X.pager(pages, 'tools')
end

-- ========================================
-- ЭКРАН: ЛОГ
-- ========================================
function SCR.log()
    local L, F = X.LY, X.FS
    X.header(tr('nav_log'), tr('log_sub'))
    X.headerButtons({
        { text = tr('refresh'), w = 0.14, fn = function() X.renderTab(true, true) end },
        { text = tr('copy'), w = 0.12, fn = function()
            local c = U.tail(P.LOG, 6000); C.copyText(c or ''); S.status(tr('log_copied'), 'ok') end },
        { text = tr('clear'), w = 0.13, fn = function()
            X.confirm(tr('log_conf'), '', function() U.write(P.LOG, ''); S.status(tr('log_cleared'), 'ok'); X.renderTab(true, true) end) end },
    })
    X.rect('content', L.cx, L.cy, L.cw, L.ch, 'card')
    local fs = F.small
    local lh = fs * 1.35
    local maxLines = max(4, floor((L.ch * 0.94) / lh))
    local raw = U.tail(P.LOG, 24000) or ''
    local all = {}
    for line in raw:gmatch('[^\r\n]+') do all[#all + 1] = line end
    local out = {}
    for i = max(1, #all - maxLines + 1), #all do
        local line = all[i]
        local c = line:find('%[E%]') and S.C_ERR or (line:find('%[W%]') and S.C_WARN or S.C_DIM)
        out[#out + 1] = U.col(c, U.esc(U.fit(line, L.cw * 0.96, fs)))
    end
    if #out == 0 then out[1] = U.col(S.C_DIM, tr('log_empty')) end
    X.text('content', table.concat(out, '\n'), L.cx + L.cw * 0.02, L.cy + L.ch * 0.03, L.cw * 0.96, L.ch * 0.94, { size = fs, raw = true })
end

-- ========================================
-- ЭКРАН: НАСТРОЙКИ
-- ========================================
function SCR.settings()
    local L, F = X.LY, X.FS
    X.header(tr('nav_settings'), tr('set_sub'))
    local gap = L.gap
    local colw = floor((L.cw - gap) / 2)
    local rowh = floor(L.ch * 0.15)
    local function row(col, idx, label, options, current, onPick)
        local x = L.cx + col * (colw + gap)
        local y = L.cy + (idx - 1) * (rowh + floor(gap * 0.5))
        X.delay = idx
        X.text('content', label, x, y, colw, F.small * 1.4, { size = F.small, color = S.C_DIM })
        local n = #options
        local bw = floor((colw - (n - 1) * 4) / n)
        for i, o in ipairs(options) do
            X.btn('content', o.text, x + (i - 1) * (bw + 4), y + F.small * 1.5, bw, floor(rowh - F.small * 1.7), function() onPick(o.value) end,
                { style = 'chip', on = (o.value == current), color = o.color, size = F.small })
        end
    end
    local function rerenderAll() X.rerender() end
    local lang = S.cfg.lang
    row(0, 1, tr('set_lang'), { { text = 'RU', value = 'ru' }, { text = 'EN', value = 'en' } }, lang, function(v) S.cfg.lang = v; C.saveConfig(); rerenderAll() end)
    local th = {}
    for i, t in ipairs(S.THEMES) do th[#th + 1] = { text = t[lang], value = i, color = t.acc } end
    row(0, 2, tr('set_theme'), th, S.cfg.theme, function(v) S.cfg.theme = v; C.saveConfig(); rerenderAll(); X.refreshLauncher() end)
    row(0, 3, tr('set_scale'), { { text = tr('scale1'), value = 1 }, { text = tr('scale2'), value = 2 }, { text = tr('scale3'), value = 3 } }, S.cfg.scale, function(v)
        S.cfg.scale = v; C.saveConfig(); X.computeFonts(); rerenderAll() end)
    row(0, 4, tr('set_anim'), { { text = tr('on'), value = true }, { text = tr('off'), value = false } }, S.cfg.anim and true or false, function(v) S.cfg.anim = v; C.saveConfig(); X.renderTab(true, true) end)
    row(1, 1, tr('set_corner'), { { text = tr('corner1'), value = 1 }, { text = tr('corner2'), value = 2 }, { text = tr('corner3'), value = 3 }, { text = tr('corner4'), value = 4 } }, S.cfg.corner, function(v)
        S.cfg.corner = v; C.saveConfig(); X.buildLauncher(); X.setHud(S.cfg.hud); X.renderTab(true, true) end)
    row(1, 2, tr('set_hud'), { { text = tr('on'), value = true }, { text = tr('off'), value = false } }, S.cfg.hud and true or false, function(v)
        S.cfg.hud = v; C.saveConfig(); X.setHud(v); X.renderTab(true, true) end)
    row(1, 3, tr('set_safe'), { { text = tr('on'), value = true }, { text = tr('off'), value = false } }, S.cfg.safe_mode and true or false, function(v)
        S.cfg.safe_mode = v; C.saveConfig(); X.renderTab(true, true) end)
    row(1, 4, tr('set_autofix'), { { text = tr('on'), value = true }, { text = tr('off'), value = false } }, S.cfg.autofix and true or false, function(v)
        S.cfg.autofix = v; C.saveConfig(); X.renderTab(true, true) end)
    -- авторы
    local y = L.cy + 4 * (rowh + floor(gap * 0.5)) + floor(gap * 0.3)
    X.delay = 5
    X.text('content', U.col('FFFFFFFF', tr('cr_by')) .. U.col(S.C_OK, P.AUTHOR) .. U.col('FFFFFFFF', '   VForge: ') .. U.col(S.accent(), P.VFORGE), L.cx, y, L.cw, F.base * 1.4, { size = F.base, raw = true })
    local bw = floor((L.cw - gap * 2) / 3)
    local by, bh = y + F.base * 1.6, floor(L.ch * 0.1)
    X.btn('content', tr('cr_copy_site'), L.cx, by, bw, bh, function() C.copyText('https://' .. P.VFORGE); S.status(tr('link_copied'), 'ok') end, { style = 'ghost', size = F.small })
    X.btn('content', tr('cr_copy_tg'), L.cx + bw + gap, by, bw, bh, function() C.copyText('https://' .. P.TG); S.status(tr('link_copied'), 'ok') end, { style = 'ghost', size = F.small })
    X.btn('content', tr('cr_copy_yt'), L.cx + (bw + gap) * 2, by, bw, bh, function() C.copyText('https://' .. P.YT); S.status(tr('link_copied'), 'ok') end, { style = 'ghost', size = F.small })
    X.delay = 0
end

-- ========================================
-- ОТРИСОВКА / ОТКРЫТИЕ / ЗАКРЫТИЕ
-- ========================================
function X.renderTab(keepFrame, instant)
    X.clear('nav'); X.clear('content')
    local save = X.instant
    X.instant = instant and true or false
    X.buildNav()
    U.safe(SCR[S.tab], 'screen:' .. tostring(S.tab))
    X.instant = save
end
function X.render()
    X.clear('frame'); X.clear('nav'); X.clear('content'); X.clear('status')
    X.computeFonts(); X.computeLayout()
    X.buildFrame()
    X.renderTab()
    X.drawStatus()
end
function X.rerender()
    if not S.menuOpen then return end
    if S.modal then X.clear('overlay'); S.modal = false; X.prog = nil end
    X.render()
end
function X.openMenu()
    if S.menuOpen then X.closeMenu() return end
    S.menuOpen = true
    S.ensureHB()
    C.rescan()
    for k in pairs(S.page) do S.page[k] = 1 end
    for _, n in ipairs(X.groups.launcher) do pcall(function() n.el:setVisible(false) end) end
    SDK.emit('menu_open')
    X.render()
end
function X.closeMenu()
    if C.job then C.job.cancel = true end
    for _, g in ipairs({ 'frame', 'nav', 'content', 'status', 'overlay' }) do X.clear(g) end
    S.menuOpen, S.modal, S.statusMsg, X.prog = false, false, nil, nil
    for _, n in ipairs(X.groups.launcher) do pcall(function() n.el:setVisible(true) end) end
    SDK.emit('menu_close')
end

-- ========================================
-- ЛАУНЧЕР
-- ========================================
function X.buildLauncher()
    X.clear('launcher')
    X.computeFonts()
    local bw, bh = floor(W * 0.11), floor(H * 0.058)
    local m = floor(W * 0.01)
    local c = S.cfg.corner
    local x = (c == 1 or c == 3) and m or (W - bw - m)
    local y = (c == 1 or c == 2) and floor(H * 0.02) or (H - bh - floor(H * 0.02))
    X.lx, X.ly, X.lw, X.lh = x, y, bw, bh
    local label = U.grad('CERIUM', S.theme().acc, S.theme().acc2)
    if C.hasDrift() then label = U.col(S.C_WARN, 'CERIUM !') end
    local save = X.instant; X.instant = true
    local n = X.btn('launcher', label, x, y, bw, bh, function() X.openMenu() end, { style = 'primary', raw = true, size = X.FS.small + 1 })
    if n and S.menuOpen then pcall(function() n.el:setVisible(false) end) end
    X.instant = save
end
function X.refreshLauncher() if X.buildLauncher and not S.dead then X.buildLauncher() end end

-- ========================================
-- FPS HUD
-- ========================================
X.hud = nil
local function readFps()
    local ok, v = pcall(function() return Root.Instance():getFPS() end)
    if ok and type(v) == 'number' then return v end
    ok, v = pcall(function() return CGame.Instance():getCurFps() end)
    if ok and type(v) == 'number' then return v end
    return nil
end
function X.setHud(on)
    X.clear('hud'); X.hud = nil
    if not on then return end
    X.computeFonts()
    local bw, bh = floor(W * 0.15), floor(H * 0.1)
    local c = S.cfg.corner
    local x = (c == 1 or c == 3) and floor(W * 0.01) or (W - bw - floor(W * 0.01))
    local ly = X.ly or floor(H * 0.02)
    local y = (c == 1 or c == 2) and (ly + floor(H * 0.07)) or (ly - bh - floor(H * 0.01))
    local save = X.instant; X.instant = true
    X.rect('hud', x, y, bw, bh, 'hudbg', { passive = true })
    local txt = X.text('hud', '...', x + 4, y + 2, bw - 8, X.FS.small * 1.5, { size = X.FS.small, color = S.C_TXT })
    local N = 24
    local bars = {}
    local barW = floor((bw - 8) / N)
    for i = 1, N do bars[i] = X.rect('hud', x + 4 + (i - 1) * barW, y + bh - 3, max(2, barW - 1), 2, 'ok', { passive = true }) end
    X.instant = save
    X.hud = { hist = {}, txt = txt, bars = bars, x = x, y = y, bw = bw, bh = bh, barW = barW, N = N, nextAt = 0 }
    if not S.addTicker(X.hudStep) then X.hud = nil end
end
function X.hudStep()
    local h = X.hud
    if not h then return false end
    if hb.tick < h.nextAt then return true end
    h.nextAt = hb.tick + 10
    local f = readFps()
    if not f then X.setText(h.txt, tr('hud_na'), S.C_DIM) return true end
    h.hist[#h.hist + 1] = f
    if #h.hist > h.N then table.remove(h.hist, 1) end
    local sum, mn = 0, 9999
    for _, v in ipairs(h.hist) do sum = sum + v; mn = min(mn, v) end
    local c = f >= 50 and S.C_OK or (f >= 30 and S.C_WARN or S.C_ERR)
    X.setText(h.txt, tr('hud_fps', floor(f + 0.5)) .. '  ' .. tr('hud_avg', floor(sum / #h.hist + 0.5)) .. '  ' .. tr('hud_min', floor(mn + 0.5)), c)
    local maxH = h.bh - X.FS.small * 1.8
    local off = h.N - #h.hist
    for i, v in ipairs(h.hist) do
        local bh = max(2, floor(U.clamp(v / 60, 0.03, 1) * maxH))
        local b = h.bars[off + i]
        X.setGeom(b, h.x + 4 + (off + i - 1) * h.barW, h.y + h.bh - 3 - bh, max(2, h.barW - 1), bh)
        X.setRectColor(b, v >= 50 and { 0.29, 0.87, 0.5 } or (v >= 30 and { 0.98, 0.75, 0.14 } or { 0.98, 0.44, 0.52 }))
    end
    return true
end

-- ========================================
-- ЗАГРУЗКА
-- ========================================
U.mkdir(P.LOGS); U.mkdir(P.TEX); U.mkdir(P.SCR)
do   -- ротация лога
    local sz = U.size(P.LOG)
    if sz and sz > P.LOG_MAX then
        local c = U.tail(P.LOG, 60000)
        if c then U.write(P.LOG, c:gsub('^[^\n]*\n', '')) end
    end
end
U.log('=== CeriumCore ' .. P.VER .. ' (build ' .. P.BUILD .. ') started ===')

C.loadConfig()
C.loadActive()
rawset(_G, 'Cerium', SDK)
X.computeFonts(); X.computeLayout()
C.rescan()

-- [FIX] Раньше здесь шли C.ensureBackups(), C.bootPlugins(), X.buildLauncher(),
-- X.setHud(), later(60, driftBoot) прямо в главном теле. В логе они вызывали
-- "attempt to call a boolean value" из-за того, что World.Timer ещё не готов.
-- Теперь ждём его готовности и только потом работаем.
local bootAttempts = 0
local function boot()
    if S.dead then return end
    bootAttempts = bootAttempts + 1
    if bootAttempts > 600 then
        U.log('boot: World.Timer never became available, giving up', 'E')
        return
    end
    if not ensureHB() then
        pcall(function()
            World.Timer(1, function() if not S.dead then boot() end return false end)
        end)
        return
    end
    -- World.Timer готов — можно запускать всё остальное
    U.safe(function() C.ensureBackups() end, 'boot:backups')
    U.safe(function() C.bootPlugins() end, 'boot:plugins')
    U.safe(function() X.buildLauncher() end, 'boot:launcher')
    if S.cfg.hud then U.safe(function() X.setHud(true) end, 'boot:hud') end
    local function driftBoot()
        C.checkDrift()
        if C.hasDrift() then
            if S.cfg.autofix then
                C.reapplyDrift()
            else
                local _, f = next(S.drift)
                local pk = f and C.findPack(f)
                C.toast(tr('drift_warn', pk and pk.name or '?'), 'warn')
            end
        end
    end
    if not later(60, driftBoot) then driftBoot() end
end
boot()

rawset(_G, "__CERIUM_CORE__", { version = P.VER_NUM, destroy = function()
    S.dead = true
    for g in pairs(X.groups) do X.clear(g) end
end })