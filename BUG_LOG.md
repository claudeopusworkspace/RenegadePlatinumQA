# Bug Log

Bugs discovered during QA playthrough. Each entry includes reproduction steps and a save state.

**Session convention**: Bugs surfaced in a prior QA run are fixed by the dev team between runs. At the start of each session, re-verify old entries and mark them `**FIXED (verified YYYY-MM-DD session N)**` rather than deleting — the audit trail matters. Newly observed instances of a "same class" issue get a fresh BUG-N entry; don't resurrect old IDs.

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

### BUG-014: `battle_turn(use_item=...)` / `use_battle_item` party_slot targets wrong Pokemon after a switch (session 12, 2026-04-19) — **FIXED (verified 2026-04-19 session 12 dev)**

Re-ran the Route 216 Blake repro: `load_state(qa_session12_route216_entry)` → `interact_with(Blake)` → `battle_turn(switch_to=1)` → `use_battle_item("Super Potion", party_slot=1)`. Post-fix, the tool reports `target: "Vaporeon", role: "active", old_hp: 44, new_hp: 30` — Super Potion correctly applied to the on-field Vaporeon (the 44→30 tail is the enemy's Charge Beam + hail landing after the heal animation, not a misroute). Pre-switch calls (`party_slot=0` vs active Monferno) still resolve correctly — the identity partyOrder case is unchanged.

Root cause: `use_battle_item` tapped `PARTY_TOUCH_XY[party_slot]` directly, treating `party_slot` as a UI position into the battle party grid. After a mid-battle switch the Gen 4 engine updates `BattleContext.partyOrder[0]` (the UI→persistent-slot map) without physically reordering the party block — so persistent slot 1 (Vaporeon) moves to UI position 0, and the tool's direct tap hit UI position 1 (now Monferno).

Fix in `renegade_mcp/use_battle_item.py`: read `PARTY_ORDER_ADDR` and translate the caller's persistent `party_slot` to the current UI position via `_persistent_to_ui_pos()` before tapping. HP verification splits on active vs bench — active reads live HP from the BattleMon struct (verifiable diff); bench relies on the UI tap + "HP unverifiable" message, since the party block isn't updated in real time for switched-out mons (see BUG-015). The response now carries a `role` field (`"active"`/`"bench"`) so callers can disambiguate.

6 regression tests added in `TestQaBug014UseItemPartySlotAfterSwitch` (3 unit + 3 integration — post-switch heal, identity-map sanity, persistent→UI translation edge cases).

**Original entry retained below for reference.**

Using a healing item mid-battle with `party_slot=<active battler's slot>` skips the active battler and routes the heal to a bench Pokemon that happens to be at that party index. The tool's reply is also misleading — says "Slot N (bench — HP unverifiable)" for what the caller intended as the active slot.

- **Tool**: `battle_turn(use_item=..., party_slot=...)` (and the equivalent `use_battle_item`).
- **Severity**: major — can waste a turn and a consumable on the wrong target; in a trainer fight on Route 216 this let Vaporeon get KO'd while a Super Potion intended for it was silently applied to the benched Monferno.
- **Save state**: `session12_route216_entry` (before the trainer fight). To repro: walk west to Ace Trainer Blake at (355, 402), engage, let Monferno get put to sleep / low HP, switch to Vaporeon (party_slot 1), take a hit, then `battle_turn(use_item="Super Potion", party_slot=1)`.
- **Call**: `battle_turn(use_item="Super Potion", party_slot=1)` while Vaporeon is active (post-switch).
- **Expected**: Super Potion heals active Vaporeon (party slot 1).
- **Actual**: Tool responded `"target":"Slot 1","party_slot":1,"final_state":"WAIT_FOR_ACTION","formatted":"Used Super Potion on Slot 1 (bench — HP unverifiable). State: WAIT_FOR_ACTION."`. Post-turn `read_battle` showed Vaporeon still at 35/76 HP (unchanged); Monferno (the ACTUAL bench mon at the time) later switched in at 52/88 HP, up from 2/88 — the Super Potion healed Monferno, not Vaporeon. Item count decremented, turn was consumed.
- **Related**: `switch_to` is aware of the post-switch party-slot swap (errors with "switch_to=0 is your active battler (Vaporeon)" once Vaporeon has been switched in and is, per read_party, at slot 1 pre-battle). The `use_item` path seems to use a DIFFERENT slot convention than `switch_to`. They should agree, and the "bench — HP unverifiable" message should not fire when the caller's party_slot equals the active battler's party_slot.
- **Workaround**: For active-battler heals, trial-and-error the party_slot; or exit battle and use `use_medicine` (which works correctly in the overworld).
- **Notes**: See also BUG-015 below — `read_party` during battle returns stale pre-switch slot positions, which compounds confusion about what "party_slot=1" even means mid-battle.

---

### BUG-015: `read_party` during battle returns stale/pre-switch party order (session 12, 2026-04-19) — **FIXED (verified 2026-04-19 session 12 dev)**

Re-verified against `qa_session12_route216_entry` → Blake battle → `battle_turn(switch_to=1)`. Post-fix `read_party` entries now carry `battle_ui_slot` (position in the battle party grid, read from `BattleContext.partyOrder[0]`) and `battle_role` (`"active"` / `"bench"`), and the active battler's `hp`/`max_hp`/`status_conditions` are refreshed from the live BattleMon struct. Persistent `slot` stays unchanged so callers keyed off stable identifiers still work. Verified in-battle: Vaporeon → `slot:1, battle_ui_slot:0, battle_role:"active"`; Monferno → `slot:0, battle_ui_slot:1, battle_role:"bench"`; HP for Vaporeon matches `read_battle` live value. `formatted` shows `"[UI 0 · active]"` tags per entry.

Clarification on the QA "physical swap" hypothesis: the Gen 4 engine does *not* reorder encrypted party blocks on switch — it updates `partyOrder[4][6]` (a `[battler_index][ui_position] → persistent_slot` indirection table at `0x022C5B60`). `switch_to` / use_item targeting by UI position worked for unrelated reasons; the real signal is the partyOrder array, which this fix surfaces.

Fix in `renegade_mcp/party.py`: `_read_battle_context()` snapshots `partyOrder` + live BattleMon data whenever battleEndFlag is zero. `read_party` then enriches each slot with `battle_ui_slot`/`battle_role`, and overrides the active battler's HP/status with the BattleMon value. No change when out of battle. 4 tests added in `TestQaBug015ReadPartyBattleEnrichment` (overworld = no enrichment, post-switch UI/role tags, live HP matches BattleMon, formatted output).

**Original entry retained below for reference.**

During a battle where a Pokemon has been switched out and a new one switched in, the Gen 4 engine physically swaps the two Pokemon's positions in the party block. `read_party` does not reflect this mid-battle — it keeps returning the pre-battle order until the battle ends.

- **Tool**: `read_party`.
- **Severity**: minor/major — on its own just confusing, but it compounds BUG-014: the caller uses `read_party` to figure out which party slot Vaporeon occupies, plugs that into `use_item(party_slot=...)`, and ends up healing the wrong mon.
- **Save state**: `session12_route216_entry` (same as BUG-014).
- **Call**: After switching from Monferno (lead) to Vaporeon in battle, call `read_party()` without ending the battle.
- **Expected**: `read_party` returns current party order — Vaporeon at slot 0, Monferno at slot 1 (matching the post-switch swap the Gen 4 engine performs and that `switch_to`'s logic agrees with).
- **Actual**: `read_party` still shows `slot 0 = Monferno`, `slot 1 = Vaporeon` (pre-battle order). Also HP in `read_party` output is the pre-battle HP, not the current battle HP (Monferno shows 88/88 even while Monferno is at 2/88 in battle). The "pre-battle HP" half is a documented Gen 4 convention (party block isn't updated mid-battle) but the slot-order mismatch is specifically misleading — especially when combined with BUG-014.
- **Workaround**: For mid-battle identification, prefer the `battle_state.party` array returned by `battle_turn` after a faint/switch event; it reports the post-swap order.
- **Notes**: Verified cross-check — `FAINT_FORCED` response after Vaporeon fainted returned `"party":[{"slot":0,"name":"Vaporeon"},{"slot":1,"name":"Monferno"},...]` while `read_party` same moment would still show slot 0 = Monferno / slot 1 = Vaporeon. So the emulator DOES have the swapped order in RAM — `read_party` is reading the wrong struct during battle.

---

### BUG-016: Level-up / stat-gain dialogue emits malformed text tokens mid-battle (session 12, 2026-04-19) — **FIXED (verified 2026-04-19 session 12 dev)**

Root-caused via ROM scan: the two leak patterns come from the level-up summary UI labels, not a new text-substitution class.

* `"Mothim@\nLv. 23"` — ROM file 368 index 944: `{NAME}{COLOR_ON}@{COLOR_OFF}\nLv. {LEVEL}` — party-panel summary label with a literal `@` glyph (renders as a sprite icon in-game). The decoder strips the `{0xFF00,...}` color VAR blocks around it, leaving the bare `@`.
* `"Sp. Def"` — ROM file 368 index 947: a standalone stat-name VAR (`{0x010D,...}`) that drives the "stat rose by N!" summary graphic. Only the stat name leaks into the scan region.

Both are party-panel rendering artifacts scraped from the battle text scan buffer alongside the real narration. They never carried actual story text — the real "grew to Lv. N!" and "<stat> rose!" lines are separate scan entries (from template indices 3 and 750–755 respectively), which still render cleanly.

Fix in `renegade_mcp/battle_tracker.py`: new `_is_level_summary_artifact()` filter matches the `<name>[@*]?\nLv. <num>` shape (name ≤10 chars — Gen 4 nickname max — so real narration like "Monferno grew to\nLv. 30!" is not caught) plus a list of standalone stat-name tokens (HP / Atk / Def / SpA / SpD / Spe / Attack / Defense / Speed / Sp. Atk / Sp. Def / Sp. Attack / Sp. Defense / accuracy / evasion). Applied alongside BUG-011's `_is_orphan_name_text` in both `BattleTracker.poll` and `turn._wait_for_action_prompt`.

7 regression tests added in `TestQaBug011OrphanNameFilter.test_bug016_*` (covers @-marker label, *-marker label, no-marker label, every standalone stat name, real narration negative cases, empty-text edge case).

**Original entry retained below for reference.**

When Mothim leveled from 22 → 23 mid-battle after a Natu wild fight on Route 211, `read_dialogue`'s conversation array contained a garbled line: `"Mothim@\nLv. 23"`. This looks like an unresolved text substitution — expected shape is something like `"Mothim reached\nLv. 23!"` or the classic Gen 4 `"{MON_NAME} is\ntrying to learn\n{MOVE_NAME}."`. Separately, during the Togetic fight earlier in the session, Monferno leveled from 29 → 30 and the battle log emitted a standalone line `"Sp. Def"` (no value, no "rose by X"), followed by the next game event — so the stat-gain numbers appear to be dropped entirely in one of the two level-up paths.

- **Tool**: `read_dialogue` (auto-advance mode) during battle level-up; `battle_turn` surfaces the same text via its log.
- **Severity**: cosmetic/minor — doesn't block gameplay, but if another tool or a human reader relies on these lines (analytics, regression tests, etc.) it will mis-parse.
- **Save state**: `session12_route216_post_blake` is the earliest checkpoint with a party that will level mid-battle; grinding vs Route 211 wild mons there will re-trigger. The exact "Sp. Def" bare-line variant triggered when Monferno KO'd Togetic with Flamethrower and immediately leveled during the exp-gain rollup.
- **Call**: Any `battle_turn(move_index=...)` that finishes a battle with XP that crosses a level boundary.
- **Expected**: Full formatted level-up string with stat names AND values (e.g. `"Sp. Def\nrose by 2!"`) OR a correctly substituted `"Mothim reached Lv. 23!"`.
- **Actual**: `"Mothim@\nLv. 23"` (Natu fight level-up) / `"Sp. Def"` (Togetic fight level-up) — partial/garbled output.
- **Related**: Feels like the same class as **BUG-007** ({ITEM} substitution elision on the Exp. Share receive dialogue) — maybe the dialogue-advance engine is over-aggressively filtering out token-only lines or stopping mid-substitution. Worth cross-checking with the BUG-007 fix.
- **Notes**: Not every level-up produces the bug — Monferno's 29→30 from Metang kill on the return trip through Mt Coronet (cave `Monferno grew to Lv. 30!`) parsed cleanly.

---

### BUG-013: BUG-012 symptoms return on the FIRST `load_state` after `init_emulator` + `load_rom` (session 11, 2026-04-18) — **FIXED (verified 2026-04-19 session 12)**

**Session 12 re-verification**: Applied the session-11 cold-start workaround as a precaution (`load_state("post_starter_twinleaf_eevee")` → 300f → `load_state("mt_coronet_west_entrance_from_route211")` → 300f). First post-workaround `read_party` / `read_trainer_status` / `map_name` all returned correct values (Monferno Lv29, Vaporeon Lv17, Mothim Lv21, Shinx Lv6; $16,092; Mt. Coronet D05R0112 at 2,41). No Mystery Zone / $36M symptoms. Stayed stable across many `load_state` calls, trainer battles, map transitions (Mt. Coronet R0112 ↔ R0113 ↔ R0111 ↔ Route 216 ↔ Route 211 ↔ Eterna City). Fix holding. Can drop the pre-load warmup dance next session.


Root cause: BUG-012's fix made `name_length × 10` dominate delta scoring, which works when the decoy is a *longer* name (Monferno, 8 chars) than the real player name. In QA's save the player name is "WOJ" (3 chars), and a ROM text-buffer in main RAM contains the string "Destiny Knot". The 4-char substring `"Knot"` scored 40+2=42 at delta=-0x100, beating the real `"WOJ"` at delta=-0x20 with score 30+3=33. The secondary canaries at the decoy were wildly out of range (party_count=36,299,880 and money=$36,302,676 — the reported "always $36,302,676" fingerprint), but the scoring treated them as missed bonuses, not disqualifications.

Fix in `renegade_mcp/addresses.py`: structural gate `_save_block_structural_ok()` disqualifies any candidate where `party_count ∉ [0, 6]` OR `money > 999,999` (Platinum's hard invariants). Applied to both `_detect_save_block_delta` (during the scan) and `revalidate` (so a cached decoy delta can't stay stuck). 4 regression tests added in `TestQaBug013ShortPlayerNameDecoy` (test_detect_shift.py), covering cold-start, mid-session, the unit-level gate, and revalidate. Full detect_shift suite (18 tests) passes; pre-starter, BUG-012 name-length cap, and cross-save-switch tests unaffected.

**Original entry retained below for reference.**

Fresh QA session startup triggers the identical memory-read desync that BUG-012 was supposed to fix. Symptoms match BUG-012 exactly — `map_name`→Mystery Zone, `read_party` slot 0 = Combusken species 256 + slots 1-5 "???", `read_trainer_status` money = $36,302,676 / badges=0 / on_bicycle=true, `read_bag` returns empty pockets with nonsense total, `view_map` → "Could not resolve terrain". Every renegade RAM read is pointing at the wrong heap offset. BUG-012's fix to `addresses._name_length_at` / `revalidate` must have been bypassed by the cold-ROM-init code path.

- **Tool**: `map_name`, `view_map`, `read_party`, `read_trainer_status`, `read_bag` (every renegade memory-read tool tested; likely universal).
- **Severity**: **blocking on cold start**, but has a clean in-session workaround (see below).
- **Save state**: `bug_012_regression_post_load_eterna_cycle_shop_session11` (captured immediately after `load_state("eterna_cycle_shop_entered")` on fresh init, desync already present). Also `bug_012_regression_session11_after_mapexit` (after exiting the Cycle Shop back to Eterna City — desync persists across the map transition).
- **Call** (exact cold-start repro):
  ```
  init_emulator()
  load_rom("/workspace/RenegadePlatinumQA/RenegadePlatinum.nds", "qa-run-3-session-11")
  load_state("eterna_cycle_shop_entered")
  advance_frames(150)
  map_name()             # Mystery Zone (0,0)
  read_party()           # Combusken slot 0, ??? slots 1-5
  read_trainer_status()  # $36,302,676 / 0 badges / bicycle ON
  read_bag("Key Items")  # empty list, formatted header says "79 items" though
  view_map()             # {"error":"Could not resolve terrain"}
  ```
- **Expected**: On `eterna_cycle_shop_entered` → map_id=71 (Cycle Shop), $15,484, 1 badge (Coal), on_bicycle=false, party = Monferno/Vaporeon/Mothim/Shinx.
- **Actual**: All reads produce the EXACT BUG-012 signature garbage values (money always $36,302,676, slot-0 species always 256). On-screen rendering is correct — top screen shows the Cycle Shop interior with the player next to the owner, the game is playable. Desync does NOT clear from: waiting 600+ frames, walking one tile in any direction, or a full door-warp map transition from Cycle Shop → Eterna City.
- **Workaround (reliable, but requires settling frames between loads)**: **load any other fully-initialized save state, advance frames, then load the target state, advance frames again**. Exact sequence that works: `load_state("qa_base_bedroom")` → `advance_frames(120)` → `load_state("eterna_cycle_shop_entered")` → `advance_frames(120)`. After that, all renegade reads return correct values. Back-to-back loads with NO `advance_frames` between them **do not** fix the desync (retested in session 11 — the second `load_state` still produced Mystery Zone / $36M). So the workaround is specifically "let the intermediate state run for 1-2 seconds of emulated time before switching to the target state" — the revalidate pass needs a valid initialized heap to detect the correct signature offset, and a freshly-loaded state with no advancement apparently doesn't expose that yet.
- **Notes**:
  - Exact same garbage fingerprint as original BUG-012 (money `$36,302,676` = `0x229DEB4`, species 256 = Combusken) — so the BUG-012 fix to `_name_length_at` / `revalidate` is not being invoked on the cold-start path, or is being invoked before heap state is valid and its own "no valid name signature" probe locks onto a zero/ghost region.
  - One read showed slot 4's nature flip from "Lonely" to "Modest" between calls while every other field stayed identical — data IS coming from somewhere, just the wrong pointer. Not a pure zero read.
  - After the two-load workaround, the session is stable — follow-up `read_party` / `read_trainer_status` / `view_map` / `map_name` all match in-game state exactly.
  - This is arguably a different bug from BUG-012 (different trigger: ROM cold-start vs. mid-session reload) but the same symptom class. Filing as BUG-013 per session convention rather than re-opening BUG-012.
  - **Addendum (same session, later)**: Desync can also trigger *during gameplay* with no `load_state` call in between. After completing the HM01 Cut Cynthia cutscene, entering+exiting two Eterna buildings, and talking to the Gym Guide via `interact_with`, a subsequent `navigate_to(305, 520)` returned `"Could not read map state (chunk resolution failed)"` and all reads flipped to garbage. Repro state: `bug_013_mid_session_desync_post_gym_guide`. The `qa_base_bedroom` + target double-load workaround *failed* on this instance — reads stayed garbage even with 120 frames between loads. What *did* recover was loading `post_starter_twinleaf_eevee` (a very different save, well past name-entry, early party state) → advance 300 frames → load target state → advance 300 frames. So the workaround is: use a save with a *fully-initialized post-starter party block* and give ample settling frames, not just any pre-starter state. `reload_tools()` alone did not recover.

---

### BUG-012: All renegade memory-read tools return stale/wrong values after `load_state` (blocking) — **FIXED (verified 2026-04-18 session 10)**

Re-ran the QA repro sequence (load `eterna_forest_entered_south` → `read_trainer_status` + `map_name` + `read_party`) against the fixed code: money $11,468, badges 1 (Coal), map Eterna Forest (203), party = Monferno/Vaporeon/Burmy/Shinx — all correct. Cross-save switch (Playtest ↔ Wayne's E4 save) also verified — `revalidate()` self-heals the stale delta across saves with different heap layouts.

Root cause: `addresses._name_length_at()` accepted runs of 8+ consecutive valid Gen4 name chars "as a 7-char name" via a max-length fallback. The party block's encrypted region contains 8-character Pokémon species names (Monferno, Vaporeon, Bronzong…) at offsets that coincide with the scan's `+0x68` canary for certain deltas. With `name_len * 10` dominating the scoring, an 8-char nickname (score 83) would outrank the real 1–7 char player name (score 33) and lock `detect_shift` onto a bogus delta. Every subsequent `addr()` lookup returned garbage — manifesting as Mystery Zone / $36M money / Combusken species.

Fix in `renegade_mcp/addresses.py`:
1. `_name_length_at`: strictly require the 0xFFFF terminator within positions 0..7. 8 consecutive name chars now returns 0 (rejected as not a player name).
2. `revalidate`: replaced the 1-char fast-path with full `_name_length_at` validation, so stale deltas pointing at random name-shaped bytes can't mask stale state.

4 regression tests added in `TestQaBug012NameLengthCap` / `TestQaBug012RevalidateCrossSaveSwitch` (`tests/test_detect_shift.py`). Full suite passes.

**Original entry retained below for reference.**

Session 10 (2026-04-18) first observation — but the session-9 notes flagged a brief post-load desync of `view_map`/`map_name` as a candidate. This session the symptom is present on *every* `load_state` attempted (three different states, including ones never touched before this session), persistent across `reset_emulator` + `reload_tools`, and affects every memory-read tool in the `renegade` namespace. Cannot safely navigate, read party, or trigger `navigate_to`/`interact_with` until fixed.

- **Tool**: `map_name`, `view_map`, `read_trainer_status`, `read_party` (likely all renegade memory reads; others not yet tested because navigation is blocked).
- **Severity**: **blocking** — QA run cannot continue without map data, party data, or trainer status.
- **Save state**: `bug_012_memory_desync_post_cycle_shop_load` (captured after loading `eterna_cycle_shop_entered` and pressing down once; desync is already present). Also reproduces from any `load_state` call in a fresh MCP session — tested with `eterna_cycle_shop_entered`, `eterna_city_arrived_post_forest`, and `qa_base_bedroom`.
- **Call** (fresh MCP / Claude session startup sequence):
  ```
  init_emulator()
  load_rom("/workspace/RenegadePlatinumQA/RenegadePlatinum.nds", "x")
  load_state("eterna_cycle_shop_entered")
  advance_frames(300)   # let the game settle and render
  map_name()            # returns Mystery Zone (map_id=0)
  read_trainer_status() # returns money=36,302,676, badges=0, on_bicycle=true
  read_party()          # returns 6 slots, slot 0="Combusken" species 256, slots 1-5="???", all hp=0, flagged as "[stale data] (moves/IVs/EVs unavailable — encrypted data stale)"
  view_map()            # returns {"error":"Could not resolve terrain", ...}
  ```
- **Expected**: Post-load reads should report the actual state. For the `eterna_cycle_shop_entered` save: map_id=71 (Eterna Cycle Shop), money=$15,484, badges=1, on_bicycle=false, party = Monferno/Vaporeon/Mothim/Shinx.
- **Actual**: All reads return the exact same garbage values regardless of which state is loaded. Specifically, `money` is **always** `36,302,676` (= `0x229DEB4` — looks like it could be an address pointer bleed-through) and `slot 0 species` is **always** `256` (Combusken). `on_bicycle` varies (true from some states, false from others) — so that one field might be reading the right location.
- **Workaround**: None found. Tried: `advance_frames(60/120/180/300/600/1800)`, `reload_tools()`, `reset_emulator()` + `load_rom()` + `load_state()` (same bug), loading an older unrelated save state (same garbage values), opening the X menu (same garbage). The game itself is rendering correctly — top screen shows the right map, the X menu opens with "WOJ" as the trainer name, door warps trigger normally.
- **Notes**:
  - **Critical clue from pre-save-file error** (reset_emulator + advance 1800 frames, no state loaded, game at Pokémon-logo splash): `read_trainer_status` raises `Could not detect save-block heap shift. Scanned deltas -0x200..+0x200 (step 4) for player-name signature at SAVE_BLOCK_BASE + 0x68 but found no valid Gen4-encoded name. Has the game finished name entry?` → confirms the renegade tools use a **signature-based heap-shift resolver** keyed on the Gen4-encoded player name at `SAVE_BLOCK_BASE + 0x68`. The fact that reads **succeed but return consistent wrong values** after `load_state` suggests the scan is finding *a* match but the wrong match — e.g. locking onto a ghost/old save block still resident in RAM at a different offset, or matching on a secondary buffer rather than the active one.
  - `$36,302,676` decoded as hex = `0x229DEB4`. Not obviously a real DS RAM address (DS main RAM is 0x02000000–0x023FFFFF), but `0x0229DEB4` would fit inside main RAM — possible read from a pointer field rather than the money field.
  - `Species 256` is Combusken; Combusken is the first Pokemon of species-id-order pool 256+ (3rd-gen). Reading from `species_id_0 = 256` from a fresh/zeroed party-extension block would happen if the encryption context hasn't been restored. Slot 0 having `species=256` across **all three loaded states** (including `qa_base_bedroom` which predates catching any non-starter) is a dead giveaway that no real party data is being read.
  - Load-state visual restoration takes a noticeable time (~300 frames) but the MCP reads never converge on correct values within any wait I tested (up to 1800 frames).
  - Session 9's ending-notes mentioned a brief `view_map` / `map_name` desync after loading `eterna_forest_entered_south` that cleared "after my first interaction with the world." That precursor did NOT clear in this session's reproductions — walking one tile, opening/closing X menu, triggering a door warp all failed to fix it. Either the session-9 self-heal was coincidental or something about this session's bug is worse.
  - Hypothesis for the dev team: the save-block heap-shift resolver needs to either (a) re-scan after every `load_state` (not once per MCP server startup), (b) verify its match by cross-checking money / badge / location against some sanity bound, or (c) pick the match whose surrounding memory layout is self-consistent rather than the first match.

---

### BUG-011: Orphan Pokémon-name / trainer-class lines appear in `battle_turn` log around level-up & battle-end macros — **FIXED (verified 2026-04-17 session 10)**

Re-ran `seek_encounter` from `forest_exit_route205_north_post_cheryl` and the Cheryl battle from `eterna_forest_entered_south`. The orphan `"Slowpoke"` before `"A wild Slowpoke appeared!"` is gone; the orphan `"Water Pulse"` / `"Drifloon"` entries that used to sandwich the level-up and faint macros no longer appear. Fix in `battle_tracker._is_orphan_name_text()`: filter AUTO_ADVANCE log entries with no newline, no terminal punctuation, and ≤24 chars — covers every bare species/move/trainer-class name observed in session 9 without touching real narration. Applied in both `BattleTracker.poll` and `turn._wait_for_action_prompt`. 6 tests in `TestQaBug011OrphanNameFilter` (5 unit + 1 integration via `seek_encounter`).

**Original entry retained below for reference.**

Session 9 (2026-04-17) newly observed across multiple battles this session. Short single-token lines — a Pokémon species name or trainer class — appear as their own entries in the `log` array, sandwiched between normal battle macro lines. The line has no verb/punctuation; it's just the name. Parses as `{"text":"Makuhita","stop":"AUTO_ADVANCE"}` (or "Monferno", "Drowzee", "Slowpoke", "Bug Catcher", "Buneary"). Occurs consistently after level-up messages and after some defeat/faint messages.

- **Tool**: `battle_turn` (`log` output), also leaks into the `encounter.battle_log` returned by `interact_with`/`navigate_to` on trigger.
- **Severity**: minor (cosmetic) — doesn't break callers that iterate the log and skip unknown entries, but a naive formatter will render a nonsensical standalone word mid-battle.
- **Save state**: Reproducible from multiple session-9 states:
  - `eterna_forest_entered_south` → `interact_with(x=28, y=83)` to start Cheryl solo battle → after the Makuhita KO, a "Makuhita" orphan line appears bracketing the Lv28 level-up message and Burmy's Lv19 level-up message.
  - `forest_exit_route205_north_post_cheryl` → trigger any wild encounter in Route 205 N grass → the encounter's first log entry is often just the species name (e.g. "Slowpoke") *before* the real "A wild Slowpoke appeared!" line.
- **Call**: Any `battle_turn(...)` that ends a Pokémon / ends the battle / level-ups a party member. Examples from session 9:
  - Cheryl battle: log contains `"Monferno grew to / Lv. 28!"` → orphan `"Makuhita"` → `"Burmy grew to / Lv. 19!"` → orphan `"Makuhita"`.
  - Bug Catcher Jack+Lass Briana double battle end: log contains `"Don't ignore bug Pokémon! / That really bugs me!"` → orphan `"Bug Catcher"` → `"WOJ got $528 / for winning!"`.
  - Psychic Elijah Drowzee KO: log contains `"Vaporeon grew to / Lv. 17!"` → orphan `"Drowzee"` → `"Psychic Elijah is / about to send in Baltoy."`.
  - Every wild-encounter open this session ("Slowpoke", "Buneary") prefixes the real "A wild X appeared!" with an orphan X.
- **Expected**: `log` should contain only complete message-box lines. The Pokémon name standalone is an artifact of how the game splits message text into `[name][action]` pairs for the battle text engine — the parser should combine the name with its following macro, not emit it as its own entry.
- **Actual**: Orphan name emitted as a separate `{"text": "...", "stop": "AUTO_ADVANCE"}` entry.
- **Workaround**: Filter log entries whose text exactly matches a species name or trainer class (no newline, no punctuation). Not a correctness issue.
- **Notes**: Distinct from BUG-009 (hex-code prefix leak). This one is a structural line-split issue — the text itself is correct, it's just chunked wrong. Probably fixable by looking for short single-word entries and concatenating with the next entry before emitting.

---

### BUG-010: `read_party` reports garbled `max_hp` (37988) for slot 3 Shinx; other fields and slots correct (TRANSIENT — clears after first battle transition) — **FIXED (verified 2026-04-17 session 10)**

Re-ran `read_party` on a fresh load of `eterna_forest_entered_south`. Shinx slot 3 now returns `hp: 21, max_hp: 21` matching the in-game party menu; Monferno/Vaporeon/Burmy unaffected. Root cause was a **mixed encryption state** in the party extension bytes — after a PC round-trip the first 8 bytes (status/level/cur_hp) and the next 2 bytes (max_hp) end up in opposite encryption states, so neither "fully decrypted" nor "fully encrypted" reads pass `_ext_sane`. Fix in `party._resolve_party_extension`: when both sources fail full-record sanity, compose field-by-field by picking each of `level`/`cur_hp`/`max_hp`/`status` from whichever source reads sane for that field. 3 tests in `TestQaBug010MaxHpMixedStateRecovery` (unit mix-state reconstruction + integration fresh-load + sanity check for other slots).

**Original entry retained below for reference.**

Session 9 (2026-04-17) newly observed on loading `eterna_forest_entered_south`. Only the slot-3 Pokémon (Shinx Lv6, PC-withdrawn earlier in the playthrough) is affected; slots 0–2 report sensible values. In-game party menu displays Shinx correctly at **HP 21/21**, so the underlying save data is fine — this is a read-side issue in `read_party` computing max_hp for this one slot.

**Post-finding**: Garbled value **self-heals after the first battle transition** of the session. After Cheryl's solo test-battle ended and Cheryl's auto-heal cutscene ran, a fresh `read_party` returned Shinx as `21/21` correctly and stayed correct for the rest of the session across many battles. So the trigger is specifically: *freshly-loaded savestate + slot N contains a previously-PC-round-tripped mon*. Likely explanation: `read_party`'s max_hp path on load reads from a different memory region (or expects a decryption context) that gets populated/refreshed during the first script context the game enters (battle intro, menu open with stat recompute, etc.). Not game-breaking — the behaviour just confuses tools that rely on `max_hp` from a freshly-loaded state before any UI/battle happens.

- **Tool**: `read_party`
- **Severity**: minor (cosmetic, misleading — a heal/grind automator that respects max_hp would treat this mon as "nearly-fainted" forever)
- **Save state**: `bug_shinx_max_hp_garbled_read_party` (loaded from `eterna_forest_entered_south`; player at (29,86) map 203 facing up in Eterna Forest, overworld idle, no dialogue/battle active). Also reproduces directly from the underlying state `eterna_forest_entered_south`.
- **Call**: `read_party()` — no parameters. Reproducible across multiple invocations and after `advance_frames(60)`, so not a transient mid-frame artifact.
- **Expected**: Slot 3 entry `{"name":"Shinx","level":6,"hp":21,"max_hp":21,...}` — matching the in-game party menu screenshot (HP 21/21, full HP bar).
- **Actual**: Slot 3 entry shows `"hp":21,"max_hp":37988`, and the `formatted` pretty-print shows `HP 21/37988 [░░░░░░░░░░░░░░░░░░░░]` (a 20-segment empty bar because the ratio is tiny). All other fields for Shinx look correct (species 403, Lv6, IVs 9/21/0/4/24/5, Timid, Guts, etc.).
- **Workaround**: None needed for gameplay — I simply don't use Shinx. A caller that relied on `max_hp` for decisions (e.g. auto-heal thresholds) would need to clamp or re-compute.
- **Notes**: 37988 = `0x9464`. Suspicious that only slot 3 is wrong: slot 3 is the one Pokémon that was **deposited and withdrawn** from Box 1 this playthrough (see session 3/4 PC exercises). Possible cause: `read_party` using a stale/wrong pointer or decryption context for slots whose encryption state was last toggled by PC ops. Worth checking whether `read_party` re-runs after another party slot is modified (e.g. after battle damage or item use on slot 0) clear the garbled slot-3 field — haven't tested yet. Also worth trying a PC deposit→withdraw cycle on another party member to see if the corruption follows the "last-touched-by-PC" slot or is specific to Shinx's PID/blocks layout.

---

### BUG-009: Hex text-format codes (`[01E0][01E1]`) leak in trainer-name prefix lines during battle — **FIXED (verified 2026-04-17 session 10)**

Re-ran the Cheryl battle from `eterna_forest_entered_south`. Turn-2 log now renders `"Pokémon Trainer Cheryl used one Super Potion!"` and `"Pokémon Trainer Cheryl is about to send in Wailmer."` with the ligature resolved — no `[01E0]` / `[01E1]` leaks. Confirmed via ROM search (file 619): `[0x01E0][0x01E1]` is the 2-tile "Pokémon" sprite ligature used to prefix trainer classes "Pokémon Trainer", "Pokémon Breeder", "Pokémon Ranger". Fix: added 2 CHAR_MAP entries in `renegade_mcp/text_encoding.py` — `0x01E0 → "Pokémon"` and `0x01E1 → ""`, so the pair decodes as one word and the space that follows in the ROM string renders naturally. 4 tests in `TestQaBug009PokemonLigatureLeak` (3 unit + 1 integration driving the Cheryl battle).

**Original entry retained below for reference.**

Session 8 (2026-04-17) newly observed — BUG-008's `[0113]`/`[0114]`/`[0115]`/`[01C2]` family is genuinely fixed (4 clean item pickups this session: Destiny Knot on Route 205 N at (204,603), Repel at (204,603), Super Potion at (219,608), Antidote at Eterna Forest (15,81) — all parse clean `"WOJ put the X in the ITEMS/MEDICINE Pocket."`). But a distinct new code family surfaces in trainer-class-prefixed battle text against Cheryl in Eterna Forest.

- **Tool**: `battle_turn` (trainer-class prefix lines in `log` output) and also leaks into trainer dialogue rendered via `interact_with`'s battle transition
- **Severity**: minor (cosmetic)
- **Save state**: `bug008_cheryl_trainer_01e0_01e1_codes` — captured mid-Cheryl battle right after Drifloon Super Potion line; codes already surfaced in the log. For a deterministic from-scratch repro, load `eterna_forest_entered_south` and `interact_with(object_index=1)` (Cheryl at (28,83)) — her battle-start sequence will emit multiple lines.
- **Call**: Any `battle_turn(...)` against Cheryl. Lines affected:
  - `"[01E0][01E1] Trainer Cheryl / used one Super Potion!"`
  - `"[01E0][01E1] Trainer Cheryl is / about to send in Wailmer."`
  - `"[01E0][01E1] Trainer Cheryl sent / out Wailmer!"`
  - `"Player defeated / [01E0][01E1] Trainer Cheryl!"`
- **Expected**: Trainer-class prefix should render as the class label (vanilla Platinum prints e.g. `"Crasher Wake"` or `"Pok\xe9mon Trainer Cheryl"` — probably `"Pokémon Trainer Cheryl"` here given Cheryl is the partnered trainer in canonical Platinum).
- **Actual**: The two-code prefix leaks through as bracketed hex. Text that should say `"Pokémon Trainer Cheryl"` (or similar class prefix) instead becomes `"[01E0][01E1] Trainer Cheryl"`.
- **Workaround**: Strip the leading `[01E0][01E1] ` when parsing trainer names out of log lines. The trainer's base name (`Cheryl`) and all post-battle dialogue (Cheryl's chat lines when she joins as partner: "Ah, marvelous!", "WOJ decided to go with Cheryl!", "Cheryl: I'll keep your Pokémon in perfect health.") all parse cleanly — only the `is about to send in` / `sent out` / `used one X` / `Player defeated` formatted lines carry the prefix leak.
- **Notes**: Same general family as BUG-008's fix — ROM text format codes (`[01xx]` range) slipping through the encoding layer — but different specific codes (`01E0` / `01E1`) and a different text context (trainer battle macros rather than item-pickup macros). The BUG-008 fix added entries for `0x0113`-`0x011A` (pocket sprite glyphs); this bug's `0x01E0`/`0x01E1` pair is likely the two glyphs for the Pokémon-sprite + word-joiner that render "Pokémon" as its ligatured icon in trainer class text. Could be a one-line CHAR_MAP addition. Not observed on the earlier Galactic Grunt / Mars battles this session — possibly specific to *partnered* trainers (Cheryl, Dawn), or specific to trainers whose class label includes the Pokémon sprite. Worth checking other partnered trainers (Riley on Iron Island, Mira in Wayward Cave, etc.) as the game progresses.

---

### BUG-008: Hex text-format codes (`[01D2]`, `[0114]`) leak in Team Galactic post-battle cutscene dialogue — **FIXED (verified 2026-04-17 session 8)**

Re-ran the Galactic-grunts double battle from `jubilife_galactic_grunts_double_battle_start`; post-battle `post_battle_dialogue` now returns "90% of all Pokémon are somehow tied to evolution!" and "WOJ put the Fashion Case in the KEY ITEMS Pocket." with no hex-code leaks. Fix added 10 entries to `renegade_mcp/text_encoding.py::CHAR_MAP`: `0x01C2`=`&`, `0x01D2`=`%` (alt-font variants), and `0x0113`–`0x011A` mapped to empty string (the 8 pocket-icon sprite glyphs enumerated from ROM file 396). 5 tests added to `TestQaBug008HexFormatCodeLeak`. **Session 8 re-verified on 4 fresh item pickups** (Destiny Knot, Repel, Super Potion, Antidote) — all parse clean. Fix holds.

**Original entry retained below for reference.**

- **Tool**: `navigate_to` (trigger via entering Jubilife cutscene tile) → `battle_turn` `post_battle_dialogue` surface, and to a lesser extent mid-cutscene `read_dialogue`-style output from the same pipeline. Same code path as BUG-005 (marked FIXED this session for the `[VAR]…` family) but a different hex-code family is still slipping through.
- **Severity**: minor (cosmetic)
- **Save state**: `jubilife_galactic_grunts_double_battle_start` (pre-first-turn of the Team Galactic double battle, Dawn-as-partner vs. Stunky Lv13 + Glameow Lv13). Ending sequence is deterministic after finishing the battle — final Silcoon KO triggers the Rowan / Dawn / Jubilife-TV reward cutscene. Post-cutscene state also saved as `post_galactic_grunts_jubilife_fashion_case`.
- **Call**: After the battle ends (any winning sequence works; I used `battle_turn(move_index=1, target=0)` on Silcoon), the returned `post_battle_dialogue` list contains leaked hex codes.
- **Expected**: Human-readable lines, e.g.
  ```
  "…90% of all Pokémon are somehow tied to evolution!"
  "WOJ put the Fashion Case in the KEY ITEMS Pocket."
  ```
- **Actual**: Two distinct hex-format codes surface as bracketed literals mid-line:
  - `"According to his research, 90[01D2] of all / Pokémon are somehow tied to evolution!"` — `[01D2]` is the `%` symbol substitution (same family as BUG-005's `[01A8]` for ¥).
  - `"WOJ put the Fashion Case / in the [0114]KEY ITEMS Pocket."` — `[0114]` looks like a color-open formatting code (blue-tint for item category / pocket name) that should have been stripped rather than surfaced.
- **Workaround**: Ignore the noise — the game displays these correctly on-screen; only the text returned to the caller is affected. Cross-reference with `read_bag` to confirm item names/pockets if disambiguation matters.
- **Notes**: Distinct from BUG-007 (the Roark-reward token-elision bug, where `{ITEM}`/`{POCKET}` are silently replaced with empty strings). This bug is the opposite failure mode — the stripper doesn't run at all on these specific codes and the raw `[XXXX]` hex leaks through. BUG-005 covered `[VAR][…]` *and* listed `[25BD]`, `[01A8]`, `[FFFE]` as examples of the same family — those were generically marked FIXED this session based on the "What will Chimchar do?" smoke test, but it looks like the fix only covered the `[VAR]…` escape prefix form, not the bare-hex-in-brackets form. Likely worth re-running the whole BUG-005 example list against this new code path (Galactic cutscene dialogue) rather than just the battle prompt. Also: the raw text also shows `;1: / ;2: / …` for Rowan's numbered list — the `;` prefix is probably a bullet-point control char that should render as `●` or be stripped; very low priority, but part of the same cleanup class.
- **Additional repros collected same session** (all from `interact_with` on a Pokeball item pickup — no save state needed, deterministic from any item pickup):
  - Expert Belt from Ravaged Path Pokeball at (11,36): `"WOJ put the Expert Belt / in the [0113]ITEMS Pocket."`
  - TM39 Rock Tomb from Ravaged Path Pokeball at (6,36): `"WOJ put the TM39 / in the [0115]TMs [01C2] HMs Pocket."`
  - Fashion Case (original Galactic-battle repro): `"in the [0114]KEY ITEMS Pocket."`
  The per-pocket format codes observed so far: `[0113]` = ITEMS, `[0114]` = KEY ITEMS, `[0115]` = TMs & HMs (with `[01C2]` for the literal `&` between "TMs" and "HMs"). Strong hint that the entire color-open/close + ampersand family of codes is bypassing the stripper. The `%` sign (`[01D2]`) from the Galactic cutscene fits the same class — all are in the `[01xx]` / `[0Bxx]`-ish range of low-hex format codes.
- **Additional repros 2026-04-17 session 7** (confirms the same leaks remain across a fresh play session):
  - TM08 Bulk Up from Route 205 N Pokeball at (213,640): `"WOJ put the TM08 / in the [0115]TMs [01C2] HMs Pocket."`
  - Magnet from Valley Windworks Pokeball at (246,660): `"WOJ put the Magnet / in the [0113]ITEMS Pocket."`
  - TM34 Shock Wave from Valley Windworks Pokeball at (229,653): `"WOJ put the TM34 / in the [0115]TMs [01C2] HMs Pocket."`
  - TM09 Bullet Seed from Route 204 N Pokeball at (162,682): `"WOJ put the TM09 / in the [0115]TMs [01C2] HMs Pocket."`
  - Works Key + Honey reward from Floaroma Meadow grunts (`meadow_cleared_works_key_obtained` save): `"WOJ put the Works Key / in the [0114]KEY ITEMS Pocket."` and `"WOJ put the Honey / in the [0113]ITEMS Pocket."`
  All five repros 100% reproduce the same `[0113]` / `[0114]` / `[0115]` / `[01C2]` codes — this is a deterministic leak on *every* item-acquired cutscene text, not a one-off.

---

### BUG-007: Post-battle reward dialogue drops `{ITEM}` / `{POCKET}` / `{ARTICLE}` variable tokens entirely

**Investigation 2026-04-17 session 8 — root cause identified, fix deferred.** Searched ROM message files for the Roark reward templates: file 213 index 25 is `"Obtained the {0x0108,0x0000,0x0000}!"` and file 56 index 4 is `"That {0x0108,0x0000,0x0000} contains the move {0x0106,0x0001,0x0000}."`. Cross-referenced against the Galactic-grunts cutscene (same battle_turn code path, same text decoder, same session) where `WOJ` and `Fashion Case` DO resolve correctly — those templates use `{0x0108,0x0001,0x0000}` (arg-0 = `0x0001`) vs Roark's `{0x0108,0x0000,0x0000}` (arg-0 = `0x0000`). Working theory: Gen 4 VAR blocks' arg-0 selects which internal memory slot the game's `TextPrinter` substitutes from; the Roark script doesn't populate slot 0, so the VAR block reaches our text buffer un-substituted and `_consume_var_block` (from the BUG-005 fix) correctly strips it → empty. Fix would need either (a) a per-var-id substitution layer that reads game state and fills in the tokens, or (b) reading the text buffer at a later point in the pipeline after the game's own substitution pass completes. Option (b) needs more investigation — probably looking at multiple text buffers in memory (pre-substitution vs post-substitution) and picking the right one. Deferred because this is cosmetic (minor severity) and option (a) risks regressions in the many places VAR stripping already works.

- **Tool**: `battle_turn` (post-battle dialogue auto-advance surfacing via `post_battle_dialogue`)
- **Severity**: minor (cosmetic, but harder to detect than BUG-005 was — instead of emitting visible `[VAR]…` placeholders, the tokens are silently replaced with empty strings, so the text reads almost correctly and it's easy to miss)
- **Save state**: `oreburgh_gym_pre_roark_lv20_monferno` (pre-Roark; non-deterministic to hit exactly — must actually win the gym battle to trigger the TM76/Coal Badge reward ceremony). Also captured just-after state `post_roark_coal_badge_monferno_lv22` (dialogue already dismissed — use the pre-state if trying to re-trigger).
- **Call**: Final `battle_turn(move_index=0)` against Roark's Bonsly; on KO the tool auto-advances the post-battle reward cutscene and returns `post_battle_dialogue` containing the leaked lines.
- **Expected**: Token-substituted output like
  ```
  "Obtained the TM76!"
  "WOJ put the TM76 in the TMs & HMs Pocket."
  "That TM contains the move Stealth Rock."
  ```
- **Actual**: Tokens elided to empty strings — look closely at the whitespace:
  ```
  "Obtained the !"
  " put the \nin the  Pocket.\n---"
  "That  contains\nthe move Stealth Rock.\n---"
  ```
  Three distinct tokens are dropped: the player name (`WOJ`), the item name (`TM76`), the pocket name (`TMs & HMs`), and the item-article/category (`TM`).
- **Workaround**: Cross-reference the actual received item via `read_bag` after the battle (confirmed `TM76` appeared in the TMs & HMs pocket with qty 99). The ceremony completes correctly in-game — only the returned dialogue text is corrupted.
- **Notes**: BUG-005 was verified fixed this session — `read_dialogue(advance=False, region="battle")` from `fr001_repro_growlithe_battle_prompt` now returns a clean `"What will Chimchar do?"`. So this is a new class of token leak, not a regression. The prior BUG-005 manifested as raw `[VAR][XXXX]` escape sequences leaking through; this one manifests as the substitution pass *running* but resolving the tokens to empty strings. Likely a narrow regression or a dialogue code path (the "obtain+store item" event script) whose token resolver isn't wired up. Also worth checking other item-reward events (Oval Stone, Silk Scarf, Exp. Share cutscenes) for the same class of issue.

---

### BUG-006: `buy_item` leaves player stuck in shop UI on "How many?" prompt — **FIXED (verified 2026-04-16 session 5)**

Re-ran `buy_item(item_name="Potion", quantity=1)` from `jubilife_mart_after_buy_5potions`. Tool now drives all the way back to overworld — post-call screenshot shows player in mart with Pokétch visible on bottom screen, no lingering shop UI. Money ¥1,948 → ¥1,648 correctly recorded.

- **Tool**: `buy_item`
- **Severity**: major (leaves game in a non-overworld state; subsequent tools misread the context)
- **Save state**: `jubilife_mart_after_buy_5potions` (player inside Jubilife Mart at (3,7), money ¥1,948, 0 badges, party and bag are whatever they were mid-QA — irrelevant to the bug)
- **Call**: `buy_item(item_name="Potion", quantity=1)`
- **Expected**: After the purchase, the tool should drive inputs all the way back to full overworld control (same criteria other tools use for "completed") — through the quantity confirmation, the "Is there anything else? (BUY/SELL/SEE YA!)" main menu, and the cashier's "Please come again!" line.
- **Actual**: Purchase succeeded — tool returned `success: true, item: "Potion", money_before: 1948, money_after: 1648, money_spent: 300`. **But the game is still inside the shop UI on the "Potion? Certainly. How many would you like?" quantity prompt** (screenshot captured: shop inventory list on top screen, quantity/dialogue box with "Potion? Certainly. / How many would you..." visible). Player has no overworld control.
- **Workaround**: Manually press B several times to back out: quantity prompt → item list → main menu (BUY/SELL/SEE YA!) → "Please come again!" → overworld. Be careful on the 3-option main menu — down+A lands in the SELL bag view instead of SEE YA!, adding more backtrack.
- **Notes**: The tool stops one state too early — it already knows the expected post-purchase states and just needs to keep driving inputs until the cashier's closing line resolves. Related side-effect: `read_dialogue(advance=True)` called in this lingering state presses A, which re-opens the shop quantity select instead of advancing to overworld — the dialogue tool doesn't recognize it's inside a shop menu rather than a plain dialogue box. Originally filed as FR-002; reclassified as a bug after live-verified repro on 2026-04-16 from the dedicated save state.

---

### BUG-005: ROM text-variable placeholders leak through `read_dialogue` / `battle_turn` output — **FIXED (verified 2026-04-16 session 5)**

Re-ran `read_dialogue(advance=False, region="battle")` from `fr001_repro_growlithe_battle_prompt`. Output is now clean: `text: "What will Chimchar do?"` with no `[VAR]…` tail. See BUG-007 for a *narrower* new class of token leak observed this session on post-battle reward dialogue.

**Original entry retained below for reference.**

- **Tool**: `read_dialogue`, `battle_turn` (any tool surfacing in-game text)
- **Severity**: minor (cosmetic — output is noisy and occasionally confusing to grep)
- **Save state**: `fr001_repro_growlithe_battle_prompt` (mid-battle vs wild Growlithe Lv6 on Route 202, action prompt up, Chimchar Lv13 at 25/38 HP — deterministic one-call repro)
- **Call**: `read_dialogue(advance=False, region="battle")` — returns `text: "What will Chimchar do?[VAR][0200][0001][0000]"` in a single call. Alternatively, `seek_encounter()` from `route202_chimchar_lv13` surfaces the same class of codes in the encounter `battle_log`.
- **Expected**: In-game text returned to callers should be human-readable — names substituted from game state, currency symbols and line-break codes normalized, and unknown format/control codes stripped with a warning rather than surfaced raw.
- **Actual**: Multiple ROM control-code families leak through verbatim. Examples observed in live play:
  - `[VAR][0200][0001][0000]` / `[FFFE][0200][0001][0000]` — appear wrapping the "What will Chimchar do?" battle prompt and level-up lines. Same escape-byte category is labeled `[VAR]` by `read_dialogue` but `[FFFE]` by `battle_turn`/`seek_encounter` log formatting — probably two code paths stringifying the same raw bytes differently.
  - `[25BD]` — page-break marker that should become a newline; leaks inline (e.g. `"Intimidate cuts Chimchar's[25BD]Attack!"` in the battle log for the Growlithe encounter).
  - `[VAR][0103][0002][0000][0000]` — player/rival name placeholder. **Inconsistent**: resolves in some lines (Mom cutscene) but not others (Barry's bedroom) during the intro.
  - `[VAR][FF00][0001][0001]Running Shoes[VAR][FF00][0001][0000]` — item name wrapped in color/format codes.
  - `[01A8]10 million` / `[01A8]500` — currency symbol (P-with-stroke) not rendered.
  - `[FFFE][0202][0001][0003]...[FFFE][0202][0001][0002]` — control codes seen in BUG-001's `formatted` output (the stripped "Gotcha! Shinx was caught!" line). Same bug class.
- **Workaround**: Ignore noise, read around the placeholders.
- **Notes**: Originally filed as FR-001; reclassified as a bug after live-verified repro on 2026-04-16. The *inconsistent* `[VAR][0103]` resolution (works in Mom cutscene, fails in Barry's bedroom) is the most interesting lead — suggests a pre-rendering pass that runs for some dialogue paths but not others, which could be repurposed to normalize all paths. Tied to BUG-001: the `throw_ball` formatter strips text wrapped by `[FFFE]...` codes, which is one specific fallout of this leak.

---

### BUG-004: `battle_turn` stalls on target-pick sub-menu in doubles after partner Pokémon faints — **FIXED (assumed fixed per Woj 2026-04-16; no doubles battle encountered this session to re-verify live)**

**Original entry retained below for reference.**

- **Tool**: `battle_turn`
- **Severity**: major (can't take any action, blocks the fight unless worked around with raw button taps)
- **Save state**: `bug_battle_turn_stuck_after_double_ko_doubles` (mid-Route 203 doubles vs Lass tag team: Monferno 28/54 solo, Azurill 20/29 solo enemy after Shinx and Sunkern both fainted on the same turn; action prompt showing and target-pick sub-menu open on bottom screen with only Azurill highlighted)
- **Call**: `battle_turn(move_index=0, target=0)` and `battle_turn(move_index=0)` — both returned `final_state: "ACTION"` with log only showing "What will Monferno do? / Azurill / What will Monferno do?" and **no damage dealt / battle state unchanged**.
- **Expected**: Submit Scratch against the surviving Azurill and resolve the turn (either taps Azurill automatically since it's the only valid target, or uses the explicit `target=0` to pick it).
- **Actual**: Tool completes without error and with a "WAIT_FOR_ACTION"-like response, but the game is actually sitting on the **target-pick sub-menu** (bottom screen shows the 4-target grid with only Azurill lit up — screenshot saved alongside the state). No move is ever selected and the enemy also doesn't move. Repeating the call does nothing. The new `final_state: "ACTION"` value (not in the documented state list) was also returned on the prior turn when the partner Shinx fainted from Mega Drain simultaneously with Sunkern's burn KO, suggesting the tool enters this degraded state specifically when a double battle "collapses" to 1v1 mid-turn.
- **Workaround**: Manually `tap_touch_screen` the Azurill target tile to dismiss the sub-menu, then `battle_turn(move_index=N)` resumes normal behavior.
- **Notes**: Two related quirks seen on the same turn sequence: (1) `final_state: "ACTION"` appears to be a truncated/misnamed variant of `WAIT_FOR_ACTION`; (2) Azurill's Bubble produced the "Monferno's Speed fell!" message **twice** after a single Bubble use (also seen earlier in the same battle), even though `stages.Spe` only shows `-1` — probably a cosmetic dup, but noted here for context.

---

### BUG-003: `auto_grind` cancels Chimchar→Monferno evolution and leaves dialogue hanging — **FIXED (assumed fixed per Woj 2026-04-16; no Chimchar-stage auto_grind this session to re-verify live — stone evolution path exercised instead)**

**Original entry retained below for reference.**

- **Tool**: `auto_grind`
- **Severity**: major (misses an evolution, and the residual dialogue jams subsequent tool calls)
- **Save state**: `bug_auto_grind_evolution_stop_lingering_dialogue` (captures the stuck "Huh? Chimchar stopped evolving!" dialogue on the top screen; player on Route 202 grass at (163,805); Chimchar is Lv14 with Flame Wheel already learned, i.e. move-learn flow *did* complete before the evolution step went wrong)
- **Call sequence**:
  1. `auto_grind(move_index=2, backup_move=0, target_level=15, auto_heal=True)` from (163,806). After 7 wild battles returned `stop_reason: "move_learn"` — Chimchar wants to learn Flame Wheel.
  2. `auto_grind(move_index=2, backup_move=0, target_level=15, auto_heal=True, forget_move=1)` to replace Leer → returned `stop_reason: "seek_failed"` / `stop_detail: "seek_encounter returned 'blocked'"` with 0 battles fought.
- **Expected**: After the move-learn resolution, Chimchar should (a) learn Flame Wheel, (b) run through the Chimchar→Monferno evolution cutscene (auto-advanced by the tool per CLAUDE.md: *"Evolution is handled — after level-up + move-learn resolution, battle_turn detects 'is evolving' text and handles it automatically. Works in both battle_turn and auto_grind flows."*), and (c) continue grinding toward Lv15.
- **Actual**: Flame Wheel was learned, but the evolution sequence was **canceled** (the "Huh? Chimchar stopped evolving!" dialogue is on screen and `read_party` reports Chimchar still species 390 at Lv14). The second `auto_grind` call saw the lingering dialogue and bailed with `seek_failed`. Manual recovery required pressing B, then A, then ~120 frames to clear the overlay and return to overworld.
- **Workaround**: Manually dismiss the "stopped evolving" dialogue with `press_buttons(["b"])` + `press_buttons(["a"])`, then re-call `auto_grind`. Evolution is missed entirely — Chimchar will try again on next level-up per vanilla rules.
- **Notes**: The advertised auto-evolution handler looks like it pressed B (or otherwise declined) instead of letting the evolution finish. Combined cost: (1) a missed/delayed evolution, and (2) a zombie dialogue that breaks the next tool call. Might be specific to the mid-battle/post-level-up evolution path — worth checking whether the issue is an overzealous B-mash in the move-learn confirmation sequence that bleeds into the evolution prompt.

---

### BUG-002: `auto_grind` auto-heal stops on wild-battle FAINT_SWITCH prompt — **FIXED (assumed fixed per Woj 2026-04-16; no auto_grind auto-heal cycle exercised this session to re-verify live)**

**Original entry retained below for reference.**

- **Tool**: `auto_grind`
- **Severity**: major (breaks the auto-heal loop)
- **Save state**: `bug_auto_grind_faint_switch_stuck` (captures the stuck state: wild Rattata on field, "Choose a Pokémon" switch prompt on bottom screen, Shinx fainted with 3 other party members alive)
- **Call**: `auto_grind(move_index=0, target_level=11, auto_heal=True)` with Shinx Lv5 (11/19 HP) as slot 0 on Route 202. Other party members full HP.
- **Expected**: When slot 0 faints in a wild encounter, auto-heal should either (a) flee the battle and navigate to the nearest PC, or (b) switch to another party member and continue grinding. The tool advertises "when heal_x/heal_y/grind_x/grind_y are set … auto-heals on faint or PP depletion" and `auto_heal=True` should do the equivalent.
- **Actual**: Stopped immediately after the first Rattata battle with `stop_reason: "heal_failed"` and `stop_detail: "Failed to exit battle after faint. State: WAIT_FOR_ACTION"`. `heal_trips: 1` — so the tool tried to heal but gave up. Game is still in the battle at the **FAINT_SWITCH** prompt (bottom screen shows "Choose a Pokémon." with Shinx marked FNT). The reported state `WAIT_FOR_ACTION` doesn't match what's actually on screen — looks like the tool polled once and timed out instead of recognizing FAINT_SWITCH.
- **Workaround**: Manually call `battle_turn(switch_to=N)` to send another Pokemon, or `battle_turn(run=True)` to flee, then `heal_party` from overworld.
- **Notes**: Misidentification of the prompt state is probably the root cause — if the tool expected a regular action prompt after faint instead of a FAINT_SWITCH, the subsequent flee/switch logic never fires. Seems specific to **wild battles** where the player can flee, since the earlier Barry trainer-battle faint sequence returned the correct `FAINT_FORCED`/`BATTLE_ENDED` flow.

---

### BUG-001: `throw_ball` formatted output reports `State: TIMEOUT` after successful catch — **FIXED (assumed fixed per Woj 2026-04-16; no catch attempts this session to re-verify live)**

**Original entry retained below for reference.**

- **Tool**: `throw_ball`
- **Severity**: minor (cosmetic)
- **Save state**: `bug_throw_ball_state_mismatch` (state is *after* the bug; the successful catch is already reflected in party slot 3)
- **Call**: `throw_ball()` against a Lv5 Shinx at 11/19 HP after Burmy's Tackle — 5th ball, caught successfully.
- **Expected**: `formatted` string should end with `State: CAUGHT` to match the JSON field `final_state: "CAUGHT"`.
- **Actual**: JSON correctly reports `"final_state":"CAUGHT"` and Shinx is in party slot 3 with full data, *but* the `formatted` human-readable log ends with `State: TIMEOUT`. The two are contradictory. Also in the same `formatted` string, the "Gotcha! Shinx was caught!" line is rendered as a blank entry — the raw log had `[FFFE][0202][0001][0003]Gotcha!\nShinx was caught![FFFE][0202][0001][0002]\n` and the formatter appears to strip the entire line when leading/trailing control codes wrap the text.
- **Workaround**: Trust the JSON `final_state` field; ignore the `State: …` tail of `formatted`. Also confirmed via `read_party` that the catch succeeded.
- **Notes**: Two issues in one output: (1) final-state label inconsistency in the formatted summary, (2) missing "Gotcha!" line because of `[FFFE]…` control-code wrapping. Both are cosmetic — the catch worked.

---
