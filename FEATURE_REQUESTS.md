# Feature Requests

QoL improvements identified during QA playthrough. Ordered by impact.

---

### FR-001: In-battle item use (`use_battle_item`)
- **Priority**: High
- **Context**: Roark's Onix (Lv15, Rock Head, Muscle Band) hits Monferno for ~43 with SE Bulldoze. Mach Punch (priority) does ~24 per hit, needs 2 hits to KO. The winning line is: Mach Punch → survive Bulldoze → Potion → survive Bulldoze → Mach Punch. This is a completely standard Pokemon strategy but there's no tool to use items from the bag during battle.
- **Proposed**: `use_battle_item(item_name, party_slot=-1)` — navigates BAG → selects pocket → selects item → uses on target (if applicable). Returns to action prompt. Works on the player's turn instead of selecting a move. Party_slot only needed for healing items.
- **Impact**: Without this, gym leader fights that require any healing are basically impossible unless you can OHKO everything. That gets harder as the game progresses.

### FR-002: `interact_with` should re-path after fled encounters
- **Priority**: Low
- **Context**: In Oreburgh Mine, `interact_with(object_index=5, flee_encounters=True)` fled a wild Geodude but then stopped without completing the interaction. Had to `navigate_to` the item manually, then `interact_with` once adjacent.
- **Proposed**: After fleeing an encounter, `interact_with` should re-BFS from current position to the target (like `navigate_to` does with its re-path logic) instead of stopping.
- **Impact**: Minor annoyance — easy workaround exists (navigate_to + interact_with separately).

### FR-003: `auto_grind` cross-map auto-heal
- **Priority**: Medium
- **Context**: Grinding Monferno Lv21→23 in Oreburgh Gate (cave, map 258) required healing at Oreburgh City PC (map 45). The auto-heal loop (`heal_x/heal_y/grind_x/grind_y`) only works within the same map, so PP depletion stopped the grind and I had to manually navigate out of the cave, heal, navigate back in, and restart. This cycle happened twice for 2 levels of grinding.
- **Proposed**: Support cross-map heal coordinates. When `heal_x/heal_y` are on a different map than the grind area, auto_grind would navigate through warps/doors to reach the town, heal, then navigate back. The warp data from `view_map` already provides the exit coordinates needed.
- **Impact**: Eliminates the most tedious part of cave grinding. Without this, every PP depletion or faint in a cave requires 4+ manual navigation steps to heal and return.

### FR-004: Deep snow / special terrain navigation
- **Priority**: Low
- **Context**: Route 205 has deep snow tiles (behavior `???`) near a Pokeball item. `navigate_to` and `interact_with` repeatedly reported the item as "reachable, 3 steps" but then returned `stopped_early` / `blocked_at` without moving. Manual `navigate(directions)` also failed. The item was inaccessible through tools despite being walkable in-game. Deep snow likely requires holding the D-pad longer per tile (like mud in later gens).
- **Proposed**: `navigate` and `navigate_to` should recognize deep snow tiles (and similar slow-walk terrain) and hold directional input for extra frames per step, similar to how cave encounters use `cave=true` for non-grass.
- **Impact**: Minor — only affects a few areas with deep snow tiles. Easy workaround: skip the item.

### FR-005: Partner double battle support (Eterna Forest / tag battles)
- **Priority**: Medium
- **Context**: Eterna Forest has Cheryl as a partner — all wild encounters are double battles with her Chansey as ally. The `battle_turn` tool handles player-side doubles (already tested), but partner AI battles may have different flow (partner acts automatically). When Cheryl joins, `seek_encounter` and `auto_grind` need to handle the partner's turn without player input. Currently untested whether `battle_turn` correctly handles the case where only 1 of 2 allied Pokemon is player-controlled.
- **Proposed**: Verify/fix `battle_turn` for partner double battles. The tool should recognize when the partner acts automatically and not wait for a second player action.
- **Impact**: Eterna Forest is a required area with ~10 trainer battles as doubles with Cheryl. If partner doubles don't work, the entire forest must be navigated manually.

### FR-006: `battle_turn` accuracy-drop awareness
- **Priority**: Low
- **Context**: In the Floaroma Meadow double battle, Croagunk spammed Mud-Slap dropping Monferno to -2 accuracy. Flame Wheel then missed 4 consecutive turns against a Lv15 Ledyba, nearly losing the fight. The type effectiveness guardrail warns about NVE moves, but there's no warning when accuracy drops make a move unreliable.
- **Proposed**: When the active Pokemon has accuracy stages <= -2, `battle_turn` could note "Warning: accuracy at -2 (60% hit rate)" in the response so the caller can decide whether to switch or use a never-miss move instead.
- **Impact**: Nice-to-have situational awareness. The caller can already read stages from battle_state, but a proactive nudge prevents wasted turns.
