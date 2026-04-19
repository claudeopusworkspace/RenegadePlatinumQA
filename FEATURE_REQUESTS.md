# Feature Requests & QoL Improvements

Ideas for improving the Renegade MCP tooling, surfaced during QA playthroughs. These are not bugs — existing tools work. But they could work *better*, more ergonomically, or cover gaps that currently require manual `press_buttons` / `tap_touch_screen` workarounds.

## Template

```
### FR-XXX: [Short description]
- **Area**: [navigation / battle / menu / dialogue / inventory / pc / other]
- **Priority**: [high / medium / low]
- **Context**: [what I was trying to do]
- **Current friction**: [what's awkward / missing / unclear]
- **Proposal**: [the improvement, ideally concrete]
- **Notes**: [alternatives, edge cases, prior art]
```

---

### FR-006: `view_map` legend does not document the walkable-floor character; easy to misread sparse-land rooms as "fully blocked" — **DONE (2026-04-19)**

Resolved in `renegade_mcp/map_state.py::render_map`. Cave-floor (behavior `0x08`) now renders as `·` (middle dot) instead of a bare space, and both `_=ground` and `·=cave_floor` are tracked in `behaviors_seen` so they appear in the `Key:` legend whenever the map contains them. Void tiles (val==0, outside map) keep `.` so the three are visually distinct. Tests: `TestFr006FloorLegend` in `tests/test_map_tools.py` (5 cases).

- **Area**: navigation / developer experience
- **Priority**: medium — I wasted a session's Route-216 attempt because of this.
- **Context**: Session 11, Mt. Coronet R0113 (map 219, reached via stairs from R0112). The ASCII map was dense with `≈` (sea) in the center and `#` (walls) on the right; a narrow vertical strip of space characters `" "` flanked the sea on the west. The legend only said `≈=sea`, with no entry for the walkable floor character. Visually this read as "mostly water, walled in" and I backed out looking for another path. Per Woj, R0113 is actually the correct direction — the land strip is traversable and leads to higher Mt. Coronet floors.
- **Current friction**:
  - Walkable cave floor renders as a literal space, same char as "void outside the map" — the two look identical.
  - The legend omits spaces entirely, so there's no hint that " " is meaningful terrain.
  - When a room has a dense sea + sparse land mix, the eye lumps land into the visual "background" and reads the water as the dominant feature.
  - Cross-referencing the objects list does help (I had a Pokeball at `(2, 60) reachable: true` which was the hint I missed), but when skimming a large map you don't always catch it.
- **Proposal**: Pick any of these (or combine):
  1. Change walkable cave/dungeon floor from `" "` to a clearly-visible char like `·` (middle dot) or `.` (already used for some floors). Keep void / outside-map unchanged as `" "` so the distinction is visually obvious.
  2. Always include walkable-floor entries in the legend when they appear — e.g. `·=floor` or `.=walkable` so a quick reader knows blank-ish areas inside walls are navigable.
  3. When a room is majority-water, add an info line above the map like `# walkable land tiles: 47  sea tiles: 183` so the caller knows there's a non-trivial land path even if it doesn't dominate visually.
- **Notes**: Not a bug — the data is all there, and `navigate_to` / reachability correctly treat the floor as walkable. Pure rendering clarity. One minor related issue: the current legend in R0112 also lists unlabeled entries like `?=0x83 ?=0x85 ?=0xe1 ?=0xe5` inside buildings — those tile-behavior codes not in the symbol table might benefit from the same "add a name" treatment.

---

### FR-003: Consider merging `use_battle_item` into `battle_turn` as a fourth action type — **DONE (2026-04-17)**

Resolved: `battle_turn(use_item="Potion", party_slot=0, target=N)` delegates to `use_battle_item` at ACTION prompt and returns the unified shape. Standalone tool kept for back-compat. See `renegade_mcp/turn.py` + `TestFr003BattleTurnUseItemDelegation`.

- **Area**: battle
- **Priority**: medium (pure discoverability / UX — existing `use_battle_item` tool already covers the capability, just easy to miss)
- **Context**: Mid-Roark gym fight, Monferno at 21 HP + Spe-1 after Geodude's Bulldoze, Onix incoming. Needed to Potion Monferno mid-fight. I walked right past `use_battle_item` in the tool list and reached for `battle_turn`, which has no `use_item` parameter, and fell back to ~10 manual taps through the in-battle BAG UI to do what one call to `use_battle_item("Potion", party_slot=0)` would have done.
- **Current friction**: Every other "take an action this turn" path is a parameter on `battle_turn` — `move_index`, `switch_to`, `run`, `forget_move`. Items being a separate top-level tool breaks that pattern and makes them easy to forget when you're deep in a battle loop looking at battle_turn's docstring.
- **Proposal**: Fold `use_battle_item` into `battle_turn` as a mutually-exclusive fourth action:
  ```python
  battle_turn(use_item="Potion", party_slot=0)              # Potion on active
  battle_turn(use_item="Full Heal", party_slot=2)           # Full Heal on bench
  battle_turn(use_item="X Attack")                          # Self-targeted stat booster
  battle_turn(use_item="Poke Doll")                         # Escape item, no target
  ```
  Internally just delegates to the existing `use_battle_item` implementation. Preserve `use_battle_item` as a standalone tool for backward compat if desired. Return the unified `battle_turn` response shape (battle log, final_state, updated battle_state).
- **Notes**: Originally filed as "there's no in-battle BAG coverage" — that was wrong, `use_battle_item` exists and is well-scoped (healing items, stat boosters, escape items, rejects Poké Balls with a pointer to `throw_ball`). The FR survives only as a discoverability / ergonomics suggestion — `battle_turn` is the obvious entry point for "I'm at the action prompt, do X," and having item-use live under a parallel tool adds cognitive overhead.

---

### FR-004: No helper for evolution-stone use; `use_item` is Medicine-pocket only — **DONE (2026-04-17)**

Resolved: `use_item` now dispatches on the item's ROM `fieldUseFunc` and covers healing / berries / evo stones / Gracidea / TMs & HMs / Repel / Bicycle / Escape Rope / Honey. Single signature `use_item(item_name, party_slot=-1, forget_move=-1)`. See `renegade_mcp/use_item.py`.

- **Area**: inventory / menu
- **Priority**: medium
- **Context**: After defeating Roark, used the Water Stone from his Rock Smash boulder quiz to evolve Eevee → Vaporeon.
- **Current friction**: `use_item("Water Stone", 1)` returns `'Water Stone' not found in Medicine pocket. Available: ['Potion']` — the tool is hard-scoped to the Medicine pocket. Evolution stones live in the Items pocket. Had to drive the whole pause-menu + Bag + Items pocket flow manually: `X` → A (Bag) → tap Items pocket (27,51) → D-pad down x4 (Water Stone) → A (options) → A (USE) → D-pad right (Eevee) → A (evolve). That's ~12 inputs for a single-call workflow.
- **Proposal**: Either (a) generalize `use_item` to search across the Items pocket as a fallback when the item isn't in Medicine (simplest; covers stones, Exp. Share toggles, etc.), or (b) add a dedicated `evolve_with_stone(party_slot, stone_name)` that validates compatibility from ROM data (e.g. "Fire Stone on Vulpix/Growlithe/Eevee") before executing.
- **Notes**: Related to `teach_tm`, which already does ROM-validated pre-checks for move compatibility — an equivalent `evolve_with_stone` that checks the species' stone-evolution table would fit the same pattern. Edge cases: Eevee has multiple stone evolutions, so the validator just needs to confirm "this stone + this species → any valid evolution" and let the game handle the rest.

---

### FR-005: Make `battle_turn`'s "slot 0 is the active battler" error self-describing — **DONE (2026-04-17)**

Resolved: `_switch_to_zero_error(emu)` now reads battle slot 0 species and names it in the error across all three validation paths (ACTION / SWITCH_PROMPT / FAINT_FORCED). Server docstring also clarifies battle-slot vs party-slot numbering. See `renegade_mcp/turn.py` + `TestFr005SwitchToZeroErrorMessage`.

- **Area**: battle / developer experience
- **Priority**: low (pure signaling — the behavior is correct, the message just didn't land for me)
- **Context**: Mid-Roark fight, Burmy active after a voluntary switch (from Monferno), Burmy fainted to Onix's Bulldoze → `FAINT_FORCED`. Wanted to bring Monferno back in and called `battle_turn(switch_to=0)` based on `read_party`'s party slot numbering (Monferno=0).
- **Current friction**: The tool correctly rejected with `"switch_to=0 is the active battler. Use 1-5 to switch to a different Pokemon."` — but because the message doesn't say *who* is active, the obvious (and wrong) inference is "the tool thinks Monferno is still active, that's a bug." It took re-reading the docstring to understand that `switch_to` uses **battle-slot** numbering (active = 0, always) rather than the persistent **party-slot** numbering I had in my head from `read_party`. The data to correct myself was available — `read_battle` after the voluntary switch would have shown `slot 0 = Burmy` — I just didn't look at the right source.
- **Proposal**: Include the active battler's species in the error message so the user's mental model gets corrected by the error itself:
  ```
  Before:  "switch_to=0 is the active battler. Use 1-5 to switch to a different Pokemon."
  After:   "switch_to=0 is the active battler (Burmy Lv6). Use 1-5 to switch to a different Pokemon. Note: slot numbering tracks read_battle (active = 0), not read_party's persistent party order."
  ```
  Same fix fits the `switch_to` docstring — currently `"Slot 0 is the active battler"` is technically accurate but trivially easy to read past. A tweak like `"Slots match read_battle (active battler is always 0). Use 1-5 for bench; note this can diverge from read_party after a mid-battle switch."` gives the reader the whole picture up front.
- **Notes**: Withdrew the original proposal (reinterpret `switch_to` as party slot) — that would *change* working behavior to match my mistaken expectation, which is the wrong fix. The game internally swaps the active Pokemon into battle slot 0, and the tool follows that convention correctly. Pure signaling fix.

---

---

*Previously filed FR-001 and FR-002 were reclassified as BUG-005 and BUG-006 during the 2026-04-16 triage and have since been verified FIXED (see BUG_LOG.md).*

*FR-006 (party-selection touch coords unreliable) was withdrawn before commit — I only waited ~120 frames after each screen render, and Pokémon UI screens can sit through longer arrival animations before accepting input. Need to redo the calibration next session with (a) longer post-render waits (300+ frames), (b) a coordinate sweep across the card bounds, (c) a screenshot after each tap to see whether the cursor moved, before I can claim the coordinates themselves are off.*
