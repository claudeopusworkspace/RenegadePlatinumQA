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

### FR-003: In-battle BAG item use is not covered by `battle_turn`

- **Area**: battle
- **Priority**: high
- **Context**: Mid-Roark gym fight, Monferno at 21 HP + Spe-1 after Geodude's Bulldoze, Onix incoming. Needed to heal Monferno with a Potion to survive Onix's next Bulldoze while Burmy (sacrifice) ate the hit on the switch turn. Standard battle tactic, but the only path was the in-battle BAG UI.
- **Current friction**: `battle_turn` only supports `move_index`, `switch_to`, `run`, `forget_move`, `target`, `force`. No `use_item` action. Had to drive the BAG menu by hand: `tap (50,165)` → `tap (64,55)` HP/PP Restore → `tap (50,25)` Potion → `tap (95,178)` USE → *party-pick screen*. Party-pick coordinates (50,85) worked once but taps were unreliable on subsequent screens (see FR-006); fell back to D-pad. Whole flow was ~10 tool calls plus screenshots for a single action the game considers one turn.
- **Proposal**: Extend `battle_turn` with a `use_item` action:
  ```python
  battle_turn(use_item="Potion", target_slot=0)              # Potion on active Monferno
  battle_turn(use_item="Super Potion", target_slot=2)         # Super Potion on Burmy in bench
  battle_turn(use_item="Full Heal")                           # target defaults to active
  battle_turn(use_item="X Attack")                            # Battle Items pocket (self-target)
  ```
  Resolve the pocket from the item name (Medicine / Battle Items / Poké Balls / Berries are the four usable in-battle pockets). Return the same post-turn shape as the move/switch path: opponent's reactive turn, battle log, updated `battle_state`.
- **Notes**: Trainer-side item use was observed this session (Roark used Super Potion on Nosepass and a Potion on Bonsly) — those were handled correctly by `battle_turn` as the trainer's "turn" and my move still executed. So the machinery for parsing in-battle item use exists — the gap is just on the player side.

---

### FR-004: No helper for evolution-stone use; `use_item` is Medicine-pocket only

- **Area**: inventory / menu
- **Priority**: medium
- **Context**: After defeating Roark, used the Water Stone from his Rock Smash boulder quiz to evolve Eevee → Vaporeon.
- **Current friction**: `use_item("Water Stone", 1)` returns `'Water Stone' not found in Medicine pocket. Available: ['Potion']` — the tool is hard-scoped to the Medicine pocket. Evolution stones live in the Items pocket. Had to drive the whole pause-menu + Bag + Items pocket flow manually: `X` → A (Bag) → tap Items pocket (27,51) → D-pad down x4 (Water Stone) → A (options) → A (USE) → D-pad right (Eevee) → A (evolve). That's ~12 inputs for a single-call workflow.
- **Proposal**: Either (a) generalize `use_item` to search across the Items pocket as a fallback when the item isn't in Medicine (simplest; covers stones, Exp. Share toggles, etc.), or (b) add a dedicated `evolve_with_stone(party_slot, stone_name)` that validates compatibility from ROM data (e.g. "Fire Stone on Vulpix/Growlithe/Eevee") before executing.
- **Notes**: Related to `teach_tm`, which already does ROM-validated pre-checks for move compatibility — an equivalent `evolve_with_stone` that checks the species' stone-evolution table would fit the same pattern. Edge cases: Eevee has multiple stone evolutions, so the validator just needs to confirm "this stone + this species → any valid evolution" and let the game handle the rest.

---

### FR-005: `battle_turn(switch_to=0)` rejected when a non-slot-0 Pokémon is actually active

- **Area**: battle
- **Priority**: medium (a workaround exists — the manual party-selection UI — but the error message is actively misleading)
- **Context**: Mid-Roark fight, Burmy active after a voluntary switch (from Monferno), Burmy fainted to Onix's Bulldoze → `FAINT_FORCED`. Wanted to bring Monferno (party slot 0) back in.
- **Current friction**: `battle_turn(switch_to=0)` returned `"switch_to=0 is the active battler. Use 1-5 to switch to a different Pokemon."` — but Monferno (party slot 0) was *not* active; Burmy was. The tool seems to treat party slot 0 as the active battler unconditionally, which only holds when the party-slot-0 Pokémon happens to still be the one on the field. The docstring says "Slot 0 is the active battler" — consistent with the code, but it makes `switch_to` partly unusable whenever the active battler isn't at party slot 0.
- **Proposal**: Interpret `switch_to` as the **party slot** (0-5) at all times, and reject the call only when the target slot *currently is* the active battler (resolved dynamically). The error message in that case should name what's active: `"Slot 0 (Monferno) is already the active battler"` instead of the current generic phrasing. The earlier call `battle_turn(switch_to=2)` already used party-slot semantics successfully — aligning the faint-forced path with the same semantics would remove the inconsistency.
- **Notes**: Repro path from `roark_switch_prompt_onix_incoming`: `battle_turn(switch_to=2)` to bring Burmy in → let Onix KO Burmy with Bulldoze → at the forced-switch prompt, call `battle_turn(switch_to=0)` — rejected. Workaround was D-pad navigation through the party-select screen and tapping SHIFT.

---

### FR-006: Party-selection screen touch coordinates are unreliable

- **Area**: menu
- **Priority**: low
- **Context**: Two separate party-selection contexts this session: (1) the FAINT_FORCED "Choose a Pokémon" screen after Burmy fainted, (2) the "Use on which Pokémon?" target screen after pressing USE on Water Stone.
- **Current friction**: Taps that should have landed on the party cards didn't register at multiple estimated coordinates — `(50, 85)`, `(50, 110)`, `(80, 120)` for Monferno (bottom-left card), and `(185, 25)` for Eevee (top-right card) — all silently ignored, no cursor change, no activation. Switching to D-pad (`right`/`down` + `a`) worked immediately every time.
- **Proposal**: Document the tested-good tap coordinates for the 2x2 party-pick grid in CLAUDE.md (similar to the existing "Bag Pocket Tabs" table), or add a `select_party_member(party_slot)` helper that handles the D-pad/tap details. Short-term, updating the CLAUDE.md coordinates reference with a note "D-pad is more reliable than tap on party-pick screens" would save future sessions from the same trial-and-error.
- **Notes**: The Bag pocket-tabs coordinates (CLAUDE.md) *do* work reliably — so there's a mismatch in calibration specifically for the party-pick screen. Could be the sprite hitboxes vs. the card outlines, or the card rows drawn at different Y offsets than expected.

---

*Previously filed FR-001 and FR-002 were reclassified as BUG-005 and BUG-006 during the 2026-04-16 triage and have since been verified FIXED (see BUG_LOG.md).*
