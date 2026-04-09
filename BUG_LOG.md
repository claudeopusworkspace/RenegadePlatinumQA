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
