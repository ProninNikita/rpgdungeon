# TODO

## Direction

The project should grow as a compact dungeon roguelite where battles stay automatic and the player's agency comes from preparation, route choice, equipment, risk, and rewards.

## High Priority

- [x] Extract shared combat resolution from `battle.gd` and `check_combat_balance.gd`.
  - [x] Create a `CombatResolver` or equivalent script that owns damage, evasion, armor pierce, regeneration, Resolve, and Vampirism rules.
  - [x] Make the battle scene use the shared resolver for live combat.
  - [x] Make the combat balance check use the same resolver instead of duplicating combat rules.
- [x] Continue splitting `GameState` into clearer runtime responsibilities.
  - [x] Move run-specific data and actions into a `RunState` style module.
  - [x] Move character definitions out of `GameState`.
  - [x] Move enemy definitions out of `GameState`.
  - [x] Keep `GameState` focused on orchestration and compatibility with the autoload.
- [x] Add a real run ending.
  - [x] Add a victory/result screen after clearing the final floor.
  - [x] Show basic run stats: character, path, gold, defeated enemies, equipped items.
  - [x] Decide whether successful runs should delete the save, archive the result, or return to menu.

## Run Depth

- [x] Add placeholder artifact and shop rooms to every generated floor.
  - [x] Generate one golden artifact room per floor.
  - [x] Generate one brown shop room per floor.
  - [x] Mark both rooms visually without adding artifacts, items, or consumables yet.
- [ ] Add more meaningful room events between fights.
  - [ ] Add an altar event with a risk/reward choice.
  - [ ] Add a merchant or upgrade event.
  - [ ] Add a cursed chest or sacrifice event.
  - [ ] Ensure events are represented in generated level data and saves.
- [ ] Make route choice more interesting.
  - [ ] Give normal and elite paths different reward pools.
  - [ ] Add elite-specific modifiers or hazards.
  - [ ] Show route consequences before the player commits.
- [ ] Add floor modifiers.
  - [ ] Create at least three modifiers, such as enemy attack up, extra loot, no fountain, or stronger elites.
  - [ ] Display the current modifier in the dungeon HUD.
  - [ ] Include modifiers in save data and full-run checks.

## Character And Builds

- [ ] Expand playable characters.
  - [ ] Add at least one new character with a distinct automatic-combat passive.
  - [ ] Make character select show stats and passive details clearly.
  - [ ] Add balance coverage for the new character.
- [ ] Expand item design beyond flat stat bonuses.
  - [ ] Add item effects that change combat behavior, such as lifesteal, thorns, first-hit shield, execute, or regeneration.
  - [ ] Add rarity or tier labels to item definitions.
  - [ ] Make reward messages show item rarity/effect text.
- [ ] Decide on meta-progression.
  - [ ] Keep death as permanent run deletion for now, or add persistent unlocks.
  - [ ] If adding meta-progression, create a separate profile save that is not deleted on run death.

## Data And Content Structure

- [ ] Move scalable definitions to data assets.
  - [ ] Choose Godot `Resource` files or JSON for characters, enemies, items, events, and floor modifiers.
  - [ ] Add loaders/validators for these definitions.
  - [ ] Keep save data storing stable ids, not copied definition blobs where possible.
- [ ] Normalize text ownership.
  - [ ] Remove remaining fallback English strings.
  - [ ] Centralize repeated UI labels if localization will continue growing.
  - [ ] Keep player-facing text consistently Russian.

## UI And UX

- [ ] Improve the battle screen from log-only feedback to readable automatic combat presentation.
  - [ ] Add simple player/enemy visual positions or portraits.
  - [ ] Highlight trait triggers, passive triggers, and rewards.
  - [ ] Add a speed-up or skip-after-result option without adding manual combat actions.
- [ ] Improve dungeon map readability.
  - [ ] Replace letter markers with small icons or clearer tiles.
  - [ ] Differentiate enemies, fountain, chest, normal exit, and elite exit visually.
  - [ ] Show a small legend or tooltip only where it helps.
- [ ] Make key screens more responsive.
  - [ ] Reduce fixed `offset_*` layouts in battle, inventory, and main level HUD.
  - [ ] Check 1024x768 and a smaller window size.
  - [ ] Ensure long Russian strings fit in buttons and slot descriptions.
- [ ] Improve inventory usability.
  - [ ] Show item details before discard/equip when item effects become more complex.
  - [ ] Add clear feedback when inventory is full.
  - [ ] Consider sorting or grouping items by slot/type.

## Visual And Feel

- [ ] Establish a simple visual direction.
  - [ ] Pick a small palette for dungeon, UI, enemies, rewards, and danger states.
  - [ ] Replace plain rectangles gradually with sprites, icons, or styled tiles.
  - [ ] Keep the style readable before making it decorative.
- [ ] Add lightweight game feel.
  - [ ] Add hit/heal/reward animations or flashes.
  - [ ] Add short transition feedback between dungeon and battle.
  - [ ] Add audio hooks later, after the visual loop feels stable.

## Verification

- [ ] Keep all current automated checks passing after each structural change.
  - [ ] `Godot --headless --path /Users/likit/Rpg --quit`
  - [ ] `check_dungeon_generation.gd`
  - [ ] `check_combat_balance.gd`
  - [ ] `check_scene_loads.gd`
  - [ ] `check_full_run_flow.gd`
- [ ] Expand automated checks as systems grow.
  - [ ] Add checks for new event generation.
  - [ ] Add checks for item effects once combat uses a shared resolver.
  - [x] Add checks for victory/result flow.
  - [ ] Add save migration checks whenever `SAVE_VERSION` changes.
- [ ] Keep `MANUAL_TEST_CHECKLIST.md` updated for visual passes.
