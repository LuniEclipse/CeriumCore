# Changelog · История версий

## v1.12.1 "Nova" — Pre-release
- Полностью новый интерфейс: 6 вкладок (PACKS / PLUGINS / PROFILES / TOOLS / LOG / SETTINGS)
- SDK для плагинов: `Cerium.on`, `Cerium.registerTool`, `Cerium.config`, `Cerium.after`
- Профили (до 6), избранное, сортировка/фильтр паков, UNDO
- Drift-детект и autofix после обновления игры
- Независимые паки на 1-м и 2-м движке
- RU/EN, 5 тем, масштаб S/M/L, 4 угла лаунчера, FPS-оверлей
- Инструменты: reset, rescan, verify ZIP, copy game ZIP, dump resources, storage info, diagnostics, clean temp
- Исправлено: пагинация по вкладкам, UTF-8 обрезка текста, OOM на больших файлах, падение boot при отсутствии World.Timer, `.ctmp`/`os.rename` → прямая запись, опечатка `app_resources_dumpmax`

## v1.11 — Release
- Поддержка 2 движка (V1 + V2), отдельные бэкапы
- Плагин-система (`plugins_config.json`, `plugins.lua`)
- Градиентный текст, окно CREDITS, Link VForge
- COPY ZIP, DUMP RES, RESET (V1+V2)

## v1.10 — Debug
- Описания паков в UI (лимит 50 символов)
- Заготовка режима SCRIPTS
- COPY ZIP, DUMP RES

## v1.8 — Release
- Бэкап оригинала, RESET, индикатор ACTIVE
- Фон-панель, анимации появления, тосты
- Исправлена пагинация

## v1.510 — Legacy
- Первая стабильная версия: смена текстур, сканирование папки, APPLY