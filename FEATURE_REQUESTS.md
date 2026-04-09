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
