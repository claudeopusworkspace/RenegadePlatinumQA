# Bug Log

Bugs discovered during QA playthrough. Each entry includes reproduction steps and a save state.

## Template

```
### BUG-XXX: [Short description]
- **Tool**: [tool name]
- **Severity**: [blocking / major / minor / cosmetic]
- **Save state**: `[state name]`
- **Call**: `tool_name(param1=value1, param2=value2)`
- **Expected**: [what should have happened]
- **Actual**: [what actually happened]
- **Workaround**: [how you got past it, if applicable]
- **Notes**: [any additional context]
```

---

### BUG-001: auto_grind seek_failed — ended up in player's house
- **Tool**: `auto_grind`
- **Severity**: major
- **Save state**: `bug_autogrind_seekfailed_in_house` (post-bug state; use `twinleaf_party2_pre_journey` to reproduce from pre-journey)
- **Call**: `auto_grind(move_index=2, target_level=10, forget_move=1, heal_x=177, heal_y=842, grind_x=180, grind_y=826)`
- **Expected**: auto_grind should continue seeking encounters on Route 202 (map 343) near grind position (180, 826), healing at Sandgem PC when needed
- **Actual**: After 2 encounters (Shinx, Rattata), returned `seek_failed` with `stop_detail="seek_encounter returned '' instead of 'encounter'"`. Player ended up in Twinleaf Town player's house (map 414) instead of Route 202. heal_trips=0, so no heal cycle was attempted. Eevee was at full HP (25/25), so no blackout occurred. Something during the 3rd seek_encounter iteration warped the player to their house.
- **Workaround**: Continue from current position, navigate back to Route 202 manually, grind without auto-heal or in shorter iterations.
- **Notes**: This was the second consecutive auto_grind call (first stopped for move_learn, second resumed with forget_move=1). The forget_move flow worked correctly. The unexpected teleport home may be related to a game event trigger or a navigation issue during seek_encounter's grass-pacing logic crossing a map boundary/warp.

### BUG-002: auto_grind seek_failed after evolution + sequential move learns
- **Tool**: `auto_grind`
- **Severity**: major
- **Save state**: N/A (recovered manually; can reproduce from `jubilife_shopped_pre_route203` by grinding Chimchar to Lv14 on Route 202)
- **Call sequence**:
  1. `auto_grind(move_index=2, target_level=15, heal_x=175, heal_y=790, grind_x=177, grind_y=806)` → stopped with `move_learn` for Flame Wheel (correct)
  2. `auto_grind(move_index=2, target_level=15, forget_move=2, ...)` → processed Flame Wheel, immediately stopped with `move_learn` for Mach Punch. `current_moves: null` (couldn't read moves). `battles_fought: 0`.
  3. `auto_grind(move_index=2, target_level=15, forget_move=0, ...)` → returned `seek_failed` with `stop_detail="seek_encounter returned 'blocked'"`. `battles_fought: 0`. Game stuck on "Monferno learned Mach Punch!" screen.
- **Expected**: `auto_grind` with `forget_move` should fully handle evolution + sequential move learns, dismissing all dialogue/screens before seeking the next encounter.
- **Actual**: After processing the second move learn (Mach Punch), the evolution result screen ("Monferno learned Mach Punch!") was not dismissed. The tool returned to seeking encounters while the screen was still showing, causing movement to be blocked. Required manual B press + frame advance to recover.
- **Workaround**: Manually press B and advance frames to dismiss the evolution/move-learn screen, then resume grinding.
- **Notes**: The evolution from Chimchar → Monferno happened during the same level-up that triggered Flame Wheel and Mach Punch learning. The first `forget_move` call (Flame Wheel) worked, but the second (Mach Punch) left residual UI on screen. The `current_moves: null` in step 2 also suggests the tool had trouble reading move data during the evolution transition.

### BUG-003: battle_turn fails to submit first Pokemon's action in double battles
- **Tool**: `battle_turn`
- **Severity**: major
- **Save state**: `route203_trainers_cleared` (walk east toward Lass trainers at (242, 754) and (246, 754) to trigger double battle)
- **Call**: `battle_turn(move_index=0)` for Abra (slot 0, only knows Teleport) in a double battle
- **Expected**: `battle_turn` should navigate FIGHT → select Teleport → confirm target → advance to partner Pokemon's action prompt, returning `WAIT_FOR_PARTNER_ACTION`.
- **Actual**: Tool returns `WAIT_FOR_PARTNER_ACTION` with `NO_TEXT` status, but the game is stuck on the Pokemon selection submenu (POKEMON screen) instead of having advanced to the partner's action prompt. The game shows "What will Abra do?" with the Abra target selection screen. Subsequent `battle_turn` calls for the partner also fail, returning the same stuck state. Requires manual button presses (B → B → A on Teleport → A on Abra target) to advance past Abra's action and reach Hoothoot's action prompt. The issue reproduces every turn — `battle_turn` cannot handle the first Pokemon's action in doubles.
- **Workaround**: Manually submit the first Pokemon's action with `press_buttons`, then use `battle_turn` for the second Pokemon's action starting from its action prompt. This is tedious but functional.
- **Notes**: May be specific to Abra (only has 1 move, Teleport, which is self-targeting). The double battle target selection UI for self-targeting moves requires pressing A on the user's own Pokemon, which the tool's UI navigation doesn't account for. The tool likely navigates to the POKEMON submenu instead of the FIGHT submenu, or doesn't handle the target selection step for self-targeting moves in doubles.

### BUG-004: read_party shows HP as -1 for fainted Pokemon
- **Tool**: `read_party`
- **Severity**: minor
- **Save state**: N/A (observable any time a Pokemon is fainted)
- **Call**: `read_party()` when one or more party members are fainted
- **Expected**: Fainted Pokemon should show `hp: 0` and ideally `status_conditions: ["fainted"]` or similar indicator.
- **Actual**: Fainted Pokemon show `hp: -1` and `status_conditions: []` (empty). The formatted output shows "HP ?/?". The -1 value is likely an unsigned/signed integer interpretation issue in the HP field reading.
- **Workaround**: Treat HP -1 as fainted. Check `hp < 0` or `hp == -1` to detect fainted state.
- **Notes**: Observed consistently across multiple blackouts and faints (Eevee after Barry fight, entire party after double battle blackout). The max_hp field reads correctly.

### BUG-005: battle_turn returns WAIT_FOR_ACTION instead of MOVE_BLOCKED after Disable
- **Tool**: `battle_turn`
- **Severity**: minor
- **Save state**: `eterna_forest_post_psychics` (post-battle; reproduce from pre-battle by fighting Psychic Elijah whose Drowzee uses Disable)
- **Call**: `battle_turn(move_index=0)` after Drowzee used Disable on Air Cutter
- **Expected**: Should return `MOVE_BLOCKED` state when a disabled move is attempted, per documentation.
- **Actual**: Returned `WAIT_FOR_ACTION` with log text "Noctowl's Air Cutter is disabled!" No turn consumed (correct behavior), but wrong state label.
- **Workaround**: None needed — behavior is correct, just the state label is wrong.
- **Notes**: The MOVE_BLOCKED state is documented for Torment, Disable, Encore, Taunt, and Choice item locks. Disable specifically returns WAIT_FOR_ACTION instead.

### BUG-006: Wrong move selected after Disable-blocked attempt
- **Tool**: `battle_turn`
- **Severity**: major
- **Save state**: `eterna_forest_post_psychics` (post-battle; reproduce from pre-battle by fighting Psychic Elijah)
- **Call**: `battle_turn(move_index=1, force=True)` immediately after a Disable-blocked Air Cutter attempt
- **Expected**: Should select move index 1 (Extrasensory) from the move menu.
- **Actual**: Selected move index 3 (Peck) instead. The battle log showed "Noctowl used Peck!" when Extrasensory was requested. The cursor position in the move selection UI was likely shifted after the failed Disable attempt, and the tool's move navigation didn't account for this.
- **Workaround**: After a Disable-blocked move, manually verify the correct move is selected, or switch Pokemon to reset UI state.
- **Notes**: Sequence was: (1) battle_turn(move_index=0) → Air Cutter disabled, returned WAIT_FOR_ACTION. (2) battle_turn(move_index=1, force=True) → Peck used instead of Extrasensory. The move menu cursor may have been left in an unexpected position after the disabled move rejection. The 2x2 move grid navigation likely assumed cursor was at top-left but it may have been elsewhere.
