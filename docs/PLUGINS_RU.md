# 🧩 Разработка плагинов для CeriumCore

Начиная с версии **1.12.1 "Nova"**, в ядро встроен полноценный SDK для создания плагинов. Плагины пишутся на Lua с использованием API 2 Engine и имеют доступ к глобальному объекту `Cerium`.

## 📁 Структура плагина
Каждый плагин — это отдельная папка в `cerium-scripts/`:
```
cerium-scripts/
└── my_super_plugin/
    ├── script.lua       (основной код)
    ├── manifest.json    (опционально: имя, автор, версия)
    └── config.json      (создается автоматически, если использовать Cerium.config)
```

Пример `manifest.json`:
```json
{
  "name": "Auto Farm",
  "version": "1.0",
  "author": "YourName",
  "description": "Автоматическая добыча ресурсов"
}
```

## 🛠 Базовый API CeriumCore (SDK)

Внутри `script.lua` вам доступен объект `Cerium` (глобальная переменная).

### События
```lua
-- Подписаться на событие
Cerium.on("pack_applied", function(folder, name)
    Cerium.log("Был применен пак: " .. name)
    Cerium.toast("Пак " .. name .. " успешно установлен!")
end)
```

**Доступные события:**
- `pack_applied` (folder, name) — применен текстур-пак.
- `menu_open` — открыто меню ядра.
- `menu_close` — закрыто меню ядра.
- `plugin_toggled` (folder, is_on) — плагин включен/выключен.

### Утилиты
- `Cerium.log(msg)` — записать сообщение в общий лог `cerium.log`.
- `Cerium.toast(msg, kind)` — показать всплывающее уведомление (`kind`: `"ok"`, `"err"`, `"warn"`).
- `Cerium.after(ticks, function)` — выполнить функцию через N тиков (1 тик = ~1 кадр).
- `Cerium.activePack()` — получить имя текущего активного пака.

### Свои кнопки в меню (Tools)
Вы можете добавить свою кнопку во вкладку **TOOLS**:
```lua
Cerium.registerTool({
    name = "Мой инструмент",
    desc = "Делает что-то полезное",
    run = function()
        Cerium.toast("Инструмент сработал!")
    end
})
```

### Сохранение настроек
Вместо того чтобы писать свои файлы, используйте встроенный конфиг:
```lua
local cfg = Cerium.config("my_super_plugin")
local speed = cfg.get("speed", 10) -- получить (по умолчанию 10)

cfg.set("speed", 20) -- изменить
cfg.save()           -- сохранить в config.json
```

## ⚠️ Важно
- Плагины запускаются в **Safe Mode**, если в настройках ядра включена эта опция.
- Ошибки в плагинах не крашат игру: ядро перехватывает их и пишет в лог со статусом `ERROR`.
- Не используйте бесконечные циклы `while true do end` без `Cerium.after` — это повесит игру.
