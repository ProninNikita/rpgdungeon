# Changelog

All notable changes to this project will be documented in this file.

The project uses semantic versioning while it is in prototype stage:
- `0.x.0` for new gameplay systems or visible feature groups.
- `0.x.y` for fixes and small improvements.

## [Unreleased]

### Changed
- Reworked the character inventory into compact item slots with type colors, stronger-item borders, separate equipment cards, split base/equipment stat text, and a selected item detail panel with direct actions.
- Replaced long battle HP bars with compact left/right character plates and reduced battle log/status visual weight.
- Added a subtle left-side map vignette behind the HUD so empty map space reads as intentional darkness rather than unused screen.
- Extended visual review captures with empty inventory, full inventory, selected item detail, and battle hit-frame states.
- Restyled the shell UI with a shared dark fantasy menu style, an atmospheric main menu backdrop, character cards, save cards, and confirmation dialogs for deleting or overwriting saves.
- Added `capture_shell_review.gd` to save repeatable main-menu, character-select, load-menu, and save confirmation states.
- Restyled the result screen as a dark fantasy victory scene with a framed run summary, equipment cards, hero artwork, and warm victory lighting.
- Strengthened the main-menu title treatment with a short Russian subtitle and accent line so the first screen reads less like a placeholder.
- Extended shell review captures with selected character cards, vampire overwrite confirmation, and normal/elite victory states with empty and full equipment.
- Reworked the playable vampire sheet from the large hero art style with pale skin, crimson armor, a dark cape silhouette, and a red attack arc.
- Added a vampire battle visual-review case and updated victory portraits so vampire clears show the vampire instead of the base hero.
- Added hero backlight and floor shadow treatment to the main menu so the character reads as part of the scene instead of a separate sticker.
- Pixel asset loading now falls back to the source PNG when an imported texture cache is stale after an asset size change.
- Rebuilt battle arenas with procedural pixel wall/floor textures, stronger horizon lighting, deeper columns, foreground vignette, and clearer fighter grounding.
- Differentiated crypt, moss, and ember battle arenas with runes/cracks, roots/puddles, and lava glow details instead of color-only variants.
- Extended visual review captures with a moss slime battle case and fixed battle capture setup so forced enemy variants keep the correct name, stats, and traits.
- Made shell review captures wait for the rendered frame before saving so UI screenshots no longer intermittently capture a black viewport.
- Expanded visual review coverage to refresh captures from a clean directory and include all enemy battle sprites across crypt, moss, and ember arenas, plus player-attack and enemy-attack frames.
- Added the death screen to shell review captures so full-path visual review covers both win and loss endings.
- Restyled the death screen with the shared dark fantasy shell UI, a framed defeat summary, fallen-character artwork, and muted red defeat lighting.
- Improved dungeon map readability with softer background props and stronger presence glows/shadows under the player, enemies, and important interactable objects.
- Added generated pixel item icons to inventory slots, equipment cards, and the selected item detail panel, and changed the full inventory grid to three columns for cleaner spacing.
- Extended visual review captures with a dense map-object case and additional death-screen states for the base hero and vampire.
- Renamed and repackaged the main menu title treatment as `Тени подземелья`, with a cover-like arch silhouette, warmer title lighting, torch glows, and foreground fog.
- Tuned battle arenas to sit closer to the dungeon maps by darkening foregrounds, adding map-like floor edge shadows, and reducing biome accent intensity.
- Rechecked the shell UI captures as one visual system across main menu, character select, load/delete/overwrite dialogs, defeat, and victory screens.
- Prototyped smoother grid movement on the dungeon map with short tweened steps, sprite bobbing, shadow/glow feedback, directional facing, and wall bump response.
- Extended visual review captures with dungeon map movement and wall-bump frames for animation/art-direction review.
- Added 4-frame PNG map actor sheets for the base hero and vampire across crypt, moss, and ember variants, with idle, two walk poses, and a bump pose plus a runtime fallback if a sheet is missing.
- Added visible step phases during grid movement and a stronger squash/shadow bump response on blocked movement.
- Added a distinct vampire map variant with a red cape silhouette so vampire runs no longer reuse the base hero map silhouette.
- Improved map threat readability with enemy-specific threat anchors and stronger presence glows that stay weaker than interactive object highlights.
- Muted special-room accent floor tiles, floor details, and background props so decorative map art reads less like clickable content.
- Calmed dungeon floor rendering with quieter corridor tiles, larger room-floor texture patches, rarer special-room accents, and fewer background floor details.
- Extended visual review captures with vampire map, enemy-in-dark-room, interactives-vs-decor, accent-tile, four-direction movement, and vampire movement review states.
- Visual review capture now validates that the capture directory is clean before rendering and that required map/movement screenshots are created.

## [0.1.4] - 2026-05-14

### Changed
- Replaced goblin, skeleton, bat, and slime battle sprites with larger AI-generated sheets that match the base hero's dark fantasy pixel-art style.
- Updated dungeon enemy map icons from the new monster art and protected external monster assets from deterministic regeneration.
- Increased large enemy battle sprite scaling so the new sheets read clearly beside the hero.
- Enemy combat sprites now explicitly keep their left-facing orientation and lunge toward the hero during attacks.
- Redrew crypt, ember, and moss dungeon floor, wall, artifact-room, and shop-room tiles from a darker AI-generated stone atlas that better matches the new character art.
- Protected the new dungeon environment tiles from deterministic asset regeneration.
- Dungeon rooms now choose environment tile variants by floor path: normal floors alternate crypt/moss, while elite floors use ember.
- Added floor and wall tile variants plus sparse floor details to break up repeated map patterns.
- Dungeon walls now render only around walkable tiles, leaving the space behind rooms as dark void instead of repeated wall texture.
- Removed the visible grid overlay from dungeon rooms and reduced repeated special-room rune tiles.
- Added inner floor-edge shadows so rooms read as shaped spaces instead of flat tile carpets.
- Replaced colored map marker backplates with small world-object sprites for chests, fountains, exits, shops, artifacts, and used rooms.
- Enemy name labels now appear only when the player is close instead of always floating over the dungeon map.
- Added floor edge and corner overlays plus directional wall tiles so dungeon rooms have clearer silhouettes.
- Added non-blocking environment props for crypt, ember, and moss floors with placement rules that avoid gameplay objects.
- Added varied room decoration density and rare room scene props such as altars, rubble piles, and ruined corners.
- Added a dungeon lighting overlay with variant-specific darkness, a soft player light, vignette, and local lights for important map objects.
- Replaced the old symbol legend with contextual inspection text and a pulsing world highlight for nearby interactive objects.
- Added a short world-space flash response when using chests, fountains, exits, and special rooms.
- Added subtle variant-specific map atmosphere particles and ember light flicker.
- Reframed the dungeon camera and replaced the exposed gray viewport with a dark full-scene backdrop.
- Replaced the blue interaction selection square with a softer fantasy-style bracket highlight.
- Added object-specific interaction bursts for chests, fountains, exits, shops, and artifact rooms.
- Added grounding shadows and slightly stronger map scale for player and enemy sprites so they read better on dark floors.
- Added a procedural battle arena backdrop with floor tiles, distant silhouettes, and grounding light under fighters, tinted by map variant.
- Restyled battle HP bars with muted fills, segment ticks, and no embedded percentage text.
- Reduced map HUD visual weight with shorter labels and a more compact framed layout.
- Tightened inventory tabs, buttons, and slot typography so the inventory reads closer to the map UI style.
- Added deterministic wall break-up marks and reduced sparse floor detail density after the camera framing pass.
- Added `capture_visual_review.gd` to save repeatable map and battle screenshots for design review.
- Extended visual review captures with a full-inventory, fully-equipped character screen state.
- Restyled the map HUD, message panel, choice panel, and choice buttons with a darker framed fantasy UI treatment.
- Restyled nearby enemy name labels with compact placement and dark outlines so they no longer feel like debug overlays.
- Extended the darker framed UI style to the battle screen, HP bars, speed button, inventory window, tabs, item slots, and action menu.
- Added a visual map smoke check that validates crypt, moss, ember, normal, and elite map states with the new lighting and interaction layers.
- Protected generated map variant assets by prefix so future procedural asset runs do not overwrite external floor, wall, object, prop, or scene art.
- Bumped project and save data version to `0.1.4`.

### Fixed
- Fixed the goblin attack frame so its slash points toward the left-side hero instead of away from the fight.
- Fixed the skeleton battle sheet and map icon direction so the enemy faces the left-side hero.
- Fixed the bat hurt frame so it no longer turns away while taking damage.

## [0.1.3] - 2026-05-13

### Added
- Added deterministic pixel-art asset generation for map tiles, markers, map actors, and 64x64 combat spritesheets, plus support for a larger external base hero battle spritesheet.
- Added an AI-generated source sheet for the base hero battle art and preserved it as an external asset outside deterministic redraws.
- Added three dungeon tile palette variants: crypt, ember, and moss.
- Added 3-frame battle sprites for hero, vampire, goblin, skeleton, bat, and slime with idle, attack, and hurt frames.
- Added centralized texture loading for generated pixel assets with an import-friendly path and runtime PNG fallback.
- Added artifact reward choices and multi-item shop stock through map choice panels.
- Added path modifier data, HUD labels, and pre-transition consequence confirmation.
- Added a `RunFlowService` helper for new-run, floor transition, defeat, and completion flow.
- Added battle effect callouts and a speed toggle for automatic combat.
- Added save migration support for `0.1.3` special-room options and path modifiers.
- Added working artifact and shop room interactions with item rewards, gold prices, and used-room state.
- Added deterministic dungeon generation support through optional seed overrides for reproducible checks.
- Added `check_inventory_flow.gd` to verify add, equip, unequip, discard, and full-inventory behavior.
- Added an `InventoryService` helper for inventory and equipment mutations.
- Added a battle status label that shows whose turn is currently resolving.
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
- Redrew generated pixel assets with richer character silhouettes, equipment details, hit-frame slashes, and more textured dungeon tiles.
- Increased the game viewport to 1600x900 and set canvas textures to nearest filtering for crisp pixel art.
- Reworked the base hero battle art into a larger leather-armored swordsman style with visible face, hair, armor plates, and a wider attack arc.
- Replaced the deterministic base hero combat art with an AI-generated transparent sprite sheet derived from the supplied style references.
- Dungeon rooms now render pixel tiles and icon markers over the existing generated layout.
- Player and dungeon enemies now use 32x32 pixel sprites on the map.
- Battle scenes now display enlarged pixel sprites and briefly switch frames during attacks and hits.
- Bumped project and save data version to `0.1.3`.
- Map overlays, battle UI, and the inventory window now adjust their layout from the current viewport size.
- Map markers and the legend now use clearer symbols for artifact, fountain, chest, normal exit, and elite exit.
- Elite dungeon paths now use a more dangerous enemy type rotation and improved reward sources.
- Dungeon generation now reserves rooms for start, exits, chests, and fountains before assigning special rooms.
- Used special rooms now render with a muted map marker color.
- Updated `TODO.md` to reflect the current implementation status and passing verification checks.
- New games now require a free save slot and show a clear message when all slots are occupied.
- Player defeat now ends the active run by removing its save slot.
- Successful completed runs now show a result summary and remove the active run save.
- Localized battle, map, inventory, and save slot UI text to Russian.
- Centralized scene paths, reward result keys, and enemy encounter naming for cleaner project structure.

### Fixed
- Fixed the AI-generated base hero spritesheet so the attack sword no longer clips at the frame edge and the hurt frame no longer includes neighboring-frame weapon fragments.
- Fixed dungeon generation cases where exits or chests could overlap shop/artifact rooms.
- Fixed rare dungeon generation cases that produced too few rooms for guaranteed special-room placement.
- Fixed equipment slots staying unclickable after equipping an item, preventing unequip through the UI.

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
