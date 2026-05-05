# Changelog

All notable changes to this project will be documented in this file.

The project uses semantic versioning while it is in prototype stage:
- `0.x.0` for new gameplay systems or visible feature groups.
- `0.x.y` for fixes and small improvements.

## [Unreleased]

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
