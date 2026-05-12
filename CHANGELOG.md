# Changelog

All notable changes to this project will be documented in this file.

The project uses semantic versioning while it is in prototype stage:
- `0.x.0` for new gameplay systems or visible feature groups.
- `0.x.y` for fixes and small improvements.

## [Unreleased]

### Added
- Added the base character's Resolve passive, which heals once per battle at low HP.
- Added higher-tier weapon, armor, and accessory items to enemy loot and floor chests.
- Added a once-per-floor healing fountain room interaction.
- Added explicit save slot overwrite controls when starting a new game with full save slots.
- Added scene-load and full-run verification checks, plus a manual full-run checklist.
- Added `RPG_SAVE_DIR` support for isolated save-file verification runs.
- Added a shared `CombatResolver` for live battles and combat balance simulation.
- Added character, enemy, and run-state helper modules to reduce `GameState` responsibility.
- Added a result screen for successful final-floor clears with run summary stats.
- Added placeholder artifact and shop rooms to every generated floor.

### Changed
- New games now require a free save slot and show a clear message when all slots are occupied.
- Player defeat now ends the active run by removing its save slot.
- Successful completed runs now show a result summary and remove the active run save.
- Localized battle, map, inventory, and save slot UI text to Russian.
- Centralized scene paths, reward result keys, and enemy encounter naming for cleaner project structure.

## [0.1.2] - 2026-05-07

### Added
- Reworked dungeon generation to create connected rooms and corridors.
- Added a character inventory window with equipment, 16 inventory slots, and a passive abilities tab.
- Added character stats and passive ability display to the inventory window.
- Added generated enemy battle stats and connected combat to the current dungeon enemy.
- Added a death screen with new game and main menu choices after defeat.
- Added a high-damage Skeleton enemy to dungeon generation for death flow testing.
- Added saved inventory and equipment data with test item drops and equipping.
- Added an inventory item action menu for equipping or discarding items.
- Added equipment stat bonuses for weapon and armor items.
- Added balanced enemy types with evasion, armor piercing, and regeneration traits.
- Added three-floor dungeon progression with post-clear chests and branching exits.
- Added gold rewards and loot tables for enemies and floor chests.
- Added map HUD, reward messages, enemy trait summaries, item bonus text, and richer save slot descriptions.

## [0.1.1] - 2026-05-05

### Added
- Added a main menu with New Game, Load, and Exit actions.
- Added a character selection screen with the base character.
- Added a load menu with three save slots and delete actions.
- Added basic save slot creation and loading through `GameState`.
- Added procedural level generation with random walls and multiple enemies.
- Added saved level data so generated rooms can be restored from save slots.
- Added the Vampire playable character with a Vampirism passive.

## [0.1.0] - 2026-05-05

### Added
- Created the initial Godot RPG project.
- Added a main dungeon room scene with a 16x16 grid.
- Added grid-based player movement.
- Added an enemy scene and encounter detection.
- Added an automatic battle scene.
- Added persistent runtime game state through `GameState`.
- Added defeated enemy tracking so enemies disappear after victory.
- Added a local Git repository and connected it to GitHub.

### Fixed
- Fixed enemy positioning by syncing scene position with grid position.
- Fixed battle scene loading by correcting invalid color syntax in `battle.tscn`.
- Added a collision shape to the enemy scene.
