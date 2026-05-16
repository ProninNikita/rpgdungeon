# TODO

Актуальный список после проектного аудита 2026-05-15. Старые арт-review пункты перенесены в историю; этот файл теперь ведет ближайший ремонт gameplay, проверок, сейвов и UI.

## P0 - Gameplay Flow

- [x] Исправить финал забега: последний бой больше не должен сразу пропускать финальный сундук.
- [x] Оставить финальный сундук как последнюю награду перед экраном победы.
- [x] Обновить full-run проверку, чтобы она ловила порядок: финальный этаж зачищен -> сундук открыт -> result screen разрешен.
- [ ] Вручную пройти финальный этаж и убедиться, что сообщение после сундука читается до перехода на экран результата.

## P0 - Save Safety

- [x] Проверять результат записи сейва в `GameState.save_current_game()`.
- [x] Писать сейвы через временный файл и backup, чтобы снизить риск битого JSON при сбое записи.
- [x] Добавить отдельную regression-проверку поврежденного/частично записанного сейва.
- [ ] Продумать UX-сообщение, если сохранение не удалось.

## P0 - Reproducible Checks

- [x] Сделать золото сундука частью seeded dungeon generation.
- [x] Добавить проверку воспроизводимости dungeon generation для заданных seed.
- [x] Зафиксировать seed в combat balance check, с возможностью передать seed аргументом.
- [ ] Сделать enemy loot RNG воспроизводимым в отдельных balance/regression сценариях, если появятся flaky-проверки наград.

## P0 - Capture Review Tools

- [x] `capture_visual_review.gd`: не падать на null viewport image в headless и не завершаться кодом 0 после ошибки.
- [x] `capture_visual_review.gd`: валидировать battle и inventory PNG, а не только map/movement PNG.
- [x] `capture_shell_review.gd`: добавить список обязательных shell PNG.
- [x] `capture_shell_review.gd`: убрать зависание на ожидании render frame в headless.
- [x] Документировать, что capture-скрипты чистят PNG в целевой директории.

## P1 - UI Responsiveness

- [x] Убрать отрицательные позиции и слишком жесткие фиксированные ширины на узких viewport.
- [x] Проверить `main_menu`, `character_select`, `load_menu`, `inventory_ui`, `death_screen`, `result_screen` на 960x540 и 1280x720.
- [ ] Убрать или явно оформить placeholder-ноды в `.tscn`, которые сразу заменяются динамическими карточками.
- [x] Удалить или вернуть в UX неиспользуемое popup-меню действий инвентаря.

## P1 - Manual Gameplay Pass

- [ ] Начать новую игру за base hero.
- [ ] Начать новую игру за vampire.
- [ ] Проверить бой, победу, смерть и удаление активного save slot.
- [ ] Проверить normal и elite путь.
- [ ] Проверить финальный сундук и экран результата.
- [ ] Проверить inventory full cases: drop, chest reward, artifact room, shop purchase.

## P2 - Architecture Cleanup

- [ ] Разгрузить `GameState`: вынести chest/fountain/special-room rewards в отдельный service.
- [ ] Разделить `room.gd`: map generation/rendering, interactions, lighting/effects, HUD/choice panel.
- [ ] Разделить `battle.gd`: battle flow, arena rendering, combat UI.
- [ ] Постепенно заменить stringly typed dictionaries константами ключей или typed data helpers.
- [ ] Вынести контент special rooms/shop rewards из `DungeonGenerator` в data/config слой.

## Регресс-проверки

Перед завершением каждой заметной правки прогонять:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_scene_loads.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_dungeon_generation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_save_integrity.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_combat_balance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_inventory_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_full_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_visual_map_states.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/check_ui_responsiveness.gd
```

Capture review остается ручной визуальной проверкой: в headless окружении capture-скрипты должны быстро завершаться с ошибкой, если viewport image недоступен.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script scripts/capture_visual_review.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script scripts/capture_shell_review.gd
```
