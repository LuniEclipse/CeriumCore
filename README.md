![logo](https://i.ibb.co/FL52490W/330-20261118105806.png)
<div align="center">

# × CeriumCore ×

**Ядро для текстур-паков и Lua-плагинов в Blockman GO (5v5 Brawl)**
**Texture pack & Lua plugin core for Blockman GO (5v5 Brawl)**

[![Version](https://img.shields.io/badge/version-1.13%20Star-4DD8D8?style=flat-square)](https://vforge.pythonanywhere.com/pack/35)
[![Build](https://img.shields.io/badge/build-11212-blue?style=flat-square)]()
[![Lang](https://img.shields.io/badge/lang-RU%20%7C%20EN-green?style=flat-square)]()
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Emulator-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/license-Custom%20Terms-red?style=flat-square)](TERMS.md)

[Скачать](https://vforge.pythonanywhere.com/pack/35) · [Условия](TERMS.md) · [Changelog](CHANGELOG.md) · [Telegram](https://t.me/korobkageri) · [YouTube](https://youtube.com/@missgeraa)

</div>

---

## 🇷🇺 Русский

### Что это?

**CeriumCore** — ядро (скрипт внутри `g20368480.zip`), которое запускается в **5v5 Brawl** и позволяет:

- 🎨 Менять текстуры игры в 1-м движке через удобное меню
- 🧩 Подключать Lua-плагины (с собственным SDK)
- 🔁 Держать **разные паки на 1-м и 2-м движке** одновременно
- 💾 Сохранять **профили** «пак + набор плагинов»
- 🛠 Иметь под рукой инструменты: бэкап, сброс, дамп, диагностика, проверка ZIP
- 🌐 Переключать **RU/EN**, выбирать из **5 тем**, настраивать масштаб и угол лаунчера
- 📊 Смотреть **FPS-оверлей** прямо в игре

> ⚠️ Ядро работает **только в 5v5 Brawl**. На других играх — не запустится (но код можно перенести вручную).

### Быстрый старт

1. Скачай архив: **[vforge.pythonanywhere.com/pack/35](https://vforge.pythonanywhere.com/pack/35)**
2. Скопируй его по пути:
   ```
   /storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20368480/
   ```
3. Замени существующий `g20368480.zip` скачанным (кнопка «Перезаписать» / «Заменить»). Рекомендую **MT Manager**.
4. Зайди в **5v5 Brawl** — в углу появится кнопка **CERIUM**.

Подробная инструкция: [`docs/INSTALL_RU.md`](docs/INSTALL_RU.md)

### Установка текстур-пака

1. Скачай пак с VForge.
2. Распакуй в:
   ```
   .../g20368480/cerium-texture/
   ```
   Внутри созданной папки должны быть: `texturepack.zip`, `manifest.json`, опционально `preview.png`.
3. Зайди в 5v5 Brawl → **CERIUM** → вкладка **PACKS** → **APPLY**.
4. Подожди 3–10 секунд, выйди и зайди в игру.

### Установка плагина

1. Скачай плагин.
2. Распакуй в:
   ```
   .../g20368480/cerium-scripts/
   ```
   Внутри: `script.lua`, опционально `manifest.json`.
3. В меню → вкладка **PLUGINS** → **Пуск**.

### Что нового в 1.12.1 «Nova»?

- Полностью новый интерфейс с 6 вкладками: PACKS, PLUGINS, PROFILES, TOOLS, LOG, SETTINGS
- SDK для плагинов: `Cerium.on`, `Cerium.registerTool`, `Cerium.config` и др.
- Профили, избранное, сортировка/фильтр, drift-детект, autofix
- RU/EN, 5 тем, FPS-оверлей, 4 угла лаунчера
- Независимые паки на V1 и V2

Полный список: [`CHANGELOG.md`](CHANGELOG.md)

### FAQ

**Могут ли забанить?**
В Blockman GO нет проверки клиентских текстур. Ядро не детектится. Риск — только если пак содержит любые читы/админ-панели. Не показывай ничего важным лицам БГ.

**Почему не работают текстуры?**
Проверь: правильный путь, имя `g20368480.zip` (без `(1)`, `qwe` и т.п.), `texturepack.zip` внутри папки, зашёл именно в **5v5 Brawl**.

**Работает на iOS?**
Нет. Нет доступа к папке игры. Только Android и эмуляторы (BlueStacks, LDPlayer, NoxPlayer).

**Вирусы есть?**
В паках с VForge — нет, они проверяются. Но любой Lua-код потенциально может быть стиллером. Скачивай только с VForge.

Больше вопросов: [`docs/`](docs/) или пиши на `luniaryfoundstudio@gmail.com`.

### Поддержать проект

⭐ Поставь звезду репозиторию · 🔗 Поделись с друзьями · 🐞 Сообщай о багах · 💬 Поддержи авторов в комментариях на VForge

---

## 🇬🇧 English

### What is this?

**CeriumCore** is a core (a script inside `g20368480.zip`) that runs in **5v5 Brawl** and lets you:

- 🎨 Change game textures via a built-in menu
- 🧩 Load Lua plugins (with its own SDK)
- 🔁 Keep **different packs on engine 1 and engine 2** at the same time
- 💾 Save **profiles** "pack + plugin set"
- 🛠 Use tools: backup, reset, dump, diagnostics, ZIP check
- 🌐 Switch **RU/EN**, pick from **5 themes**, adjust scale and launcher corner
- 📊 See an **FPS overlay** right in-game

> ⚠️ Works **only in 5v5 Brawl**. Won't run in other games (but the code can be ported manually).

### Quick Start

1. Download: **[vforge.pythonanywhere.com/pack/35](https://vforge.pythonanywhere.com/pack/35)**
2. Copy it to:
   ```
   /storage/emulated/0/Android/data/com.sandboxol.blockymods/files/Download/SandboxOL/BlockManv2/map_temp/g20368480/
   ```
3. Replace the existing `g20368480.zip` (Overwrite / Replace). **MT Manager** recommended.
4. Open **5v5 Brawl** — a **CERIUM** button appears in the corner.

Full guide: [`docs/INSTALL_EN.md`](docs/INSTALL_EN.md)

### Installing a texture pack

1. Download a pack from VForge.
2. Extract to:
   ```
   .../g20368480/cerium-texture/
   ```
   The created folder should contain: `texturepack.zip`, `manifest.json`, optional `preview.png`
3. Open 5v5 Brawl → **CERIUM** → **PACKS** tab → **APPLY**.
4. Wait 3–10 seconds, exit and re-enter the game.

### Installing a plugin

1. Download a plugin.
2. Extract to:
   ```
   .../g20368480/cerium-scripts/
   ```
   Must contain: `script.lua`, optional `manifest.json`.
3. Menu → **PLUGINS** tab → **Run**.

### What's new in 1.12.1 "Nova"?

- Brand-new UI with 6 tabs: PACKS, PLUGINS, PROFILES, TOOLS, LOG, SETTINGS
- Plugin SDK: `Cerium.on`, `Cerium.registerTool`, `Cerium.config` and more
- Profiles, favorites, sort/filter, drift detection, autofix
- RU/EN, 5 themes, FPS overlay, 4 launcher corners
- Independent packs on V1 and V2

Full list: [`CHANGELOG.md`](CHANGELOG.md)

### FAQ

**Can I get banned?**
Blockman GO doesn't check client textures. The core is undetectable. Risk only if the pack contains cheats/admin panels. Don't show mods to moderators.

**Textures don't work?**
Check: correct path, file name `g20368480.zip` (no `(1)`, `qwe`, etc.), `texturepack.zip` inside the folder, and that you entered **5v5 Brawl**.

**Does it work on iOS?**
No. No access to the game folder. Android and emulators only (BlueStacks, LDPlayer, NoxPlayer).

**Any viruses?**
Packs from VForge — no, they're reviewed. But any Lua code can potentially be a stealer. Download only from VForge.

More: [`docs/`](docs/) or email `luniaryfoundstudio@gmail.com`.

### Support

⭐ Star the repo · 🔗 Share with friends · 🐞 Report bugs · 💬 Support authors on VForge

---

## 📜 License / Лицензия

Custom terms. See [`TERMS.md`](TERMS.md) / [`TERMS.md`](TERMS.md).

- Original author: **MissGera**
- Created with: **DeepSeek**, **Claude**, **Chat GPT**
- VForge: https://vforge.pythonanywhere.com
