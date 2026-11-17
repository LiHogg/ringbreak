# Разработка, запуск и проверка

## Требования и запуск

Проект расположен в корне репозитория. Откройте `project.godot` в **Godot 4.6.3**; дополнительный сервер или npm-пакеты не нужны.

Для Windows есть `scripts/run.ps1`, `scripts/check.ps1`. Они ищут движок в параметре `-Godot`, `GODOT_BIN`, локальном игнорируемом `.local/godot-path.txt` или PATH (`godot`, `godot4`). Для диагностики удобнее консольный EXE движка.

```powershell
$env:GODOT_BIN = 'C:\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
.\scripts\run.ps1
.\scripts\run.ps1 -Editor
.\scripts\check.ps1
```

Подготовленный запуск изолирует APPDATA внутри процесса и хранит игровой профиль в `.local/player-data`. Настройки Windows глобально не меняются. Запуск из обычного редактора без скрипта использует стандартный пользовательский каталог Godot. Ранее существовавший профиль переносится отдельно, в Git его добавлять не нужно.

## Тесты

`scripts/check.ps1` импортирует проект, затем запускает сценарии с отдельным APPDATA для каждого и симуляцию с ещё одним свежим профилем. Проверяется код возврата и сообщения `ERROR`/`SCRIPT ERROR`.

Сценарии: `check`, `card_layout`, `collection_build`, `hud_input`, `packs`, `ring_order`, `energy`, `damage_progression`, `production_prices`, `card_actions`, `ring_health`.

Эквивалентные команды Godot:

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/check.gd
godot --headless --path . --fixed-fps 120 -- --smoke-test
```

Не запускайте отдельные сценарии на единственном пользовательском профиле: они меняют сохранения. На Linux для изоляции задавайте отдельные `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`. На Windows используйте подготовленный скрипт. Для симуляции предусмотрен предел шагов; результатом может быть победа или поражение, а не гарантированная победа.

Проверка кадров: `tests/performance.gd` с отключённым VSync. Она сравнивает первые 360 кадров в фиксированном сценарии; цифры зависят от компьютера.

## Превью

`preview.gd` — служебный сценарий, не часть обычного запуска. Примеры:

```text
godot --path . --script res://preview.gd -- --cards
godot --path . --script res://preview.gd -- --arena
godot --path . --script res://preview.gd -- --packs
```

Изображения сохраняются в `outputs/screenshots/`. Другие режимы: `--build`, `--workshop`, `--upgrade`, `--stages`, `--energy`, `--damage50`, `--pack-opening`, `--pack-card`, `--pack-receipt`. Используйте отдельный тестовый профиль: некоторые режимы демонстрируют покупку и меняют тестовое сохранение.

## Android APK

Нужны Android export templates **4.6.3**, Java SDK и Android SDK по требованиям этой версии Godot. В настройках редактора укажите локальные Java SDK Path и Android SDK Path. В прошлой локальной сборке использовались OpenJDK 17, build-tools 35.0.1, платформа API 36 и стандартный экспорт без Gradle.

Пресет `Android` включён в `export_presets.cfg`, путь результата — `build/Ringbreak-0.1.10.apk` внутри проекта. Создайте `build/`, затем экспортируйте через редактор либо:

```text
godot --headless --path . --export-debug Android build/Ringbreak-0.1.10.apk
```

Ключ предыдущих локальных APK хранится отдельно и в Git не опубликован. Чтобы обновить уже установленную игру с её прогрессом, используйте прежний ключ. Новый ключ меняет подпись приложения. Для выпуска создайте отдельный релизный ключ и храните его вне исходников.

После сборки проверьте `zipalign -c -p 4` и `apksigner verify --verbose`, фактические SDK/архитектуры через `aapt dump badging`, затем установку и работу на телефоне. Успешный экспорт не заменяет проверку устройства.

## Файлы

| Файл | Назначение |
|---|---|
| `game.gd` | Состояние игры, ручная физика, радиусы, способности, UI, экономика, сохранения |
| `pack_catalog.gd` | Состав пакетов, выдача наград, транзакция и квитанция |
| `pack_screen.gd` | Витрина, шансы, раскрытие и итоги |
| `spell_art.gd` | Символы способностей |
| `pack_art.gd` | Оформление запечатанных пакетов |
| `card_decoration.gd`, `ui_backdrop.gd`, `arena_backdrop.gd` | Декор карт и фон |
| `main.tscn`, `project.godot` | Главная сцена и настройки |
| `font.ttf`, `FONT-LICENSE.txt` | DejaVu Sans и лицензия |
| `tests/` | Проверки и измерения |

## Что не коммитить

`.godot`, инструменты движка/SDK, `.local`, пользовательские сохранения, подписи, credentials, APK/PCK, архивы, логи и временные превью исключены `.gitignore`. В `docs/images/` находятся только специально выбранные иллюстрации интерфейса с демонстрационными данными.

Официальные ссылки: [Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/), [Android export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html).
