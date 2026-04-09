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
