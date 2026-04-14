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

### BUG-001: view_map / map_name / navigate report invalid player position & map in Twinleaf bedroom (pre-starter)
- **Status**: FIXED (verified 2026-04-13). Reloaded `bug_view_map_mystery_zone_pre_starter`: `map_name()` -> `{"map_id":415,"name":"Twinleaf Town","x":4,"y":10}`, `view_map()` returns a valid bedroom map with stairs warp, `read_party()` returns `count=0` (no junk slots), and `navigate_to(8,4)` cleanly took the player upstairs through the warp to map 414. Both halves of the bug (false-positive save-block scan + pre-starter party junk) are resolved.
- **Tools**: `view_map`, `map_name`, `navigate`, `navigate_to` (all Renegade map/nav tools)
- **Severity**: blocking (for pre-starter QA)
- **Save state**: `bug_view_map_mystery_zone_pre_starter` (also reproducible from `bedroom_fresh_start_claude` after advancing intro dialogue)
- **Calls**:
  - `view_map()` -> `{"error":"Could not resolve terrain","map":"","player":{},"objects":[]}`
  - `map_name()` -> `{"map_id":0,"name":"Mystery Zone","display":"Mystery Zone (EVERYWHERE)","x":4294967295,"y":4}`
  - `navigate(directions="d1")` -> blocked at `{x:4294967295,y:4}` step 0
- **Expected**: Valid Twinleaf bedroom map, real player coordinates, navigable one tile south.
- **Actual**: Player X reported as `4294967295` (0xFFFFFFFF, uninitialized sentinel). Map resolves as `Mystery Zone` / `EVERYWHERE`. `view_map` fails entirely with "Could not resolve terrain". `navigate` refuses to step.
- **Reproduction steps** (from `bedroom_fresh_start_claude`):
  1. Load state, `advance_frames(count=300)` to warm up rendering.
  2. `read_dialogue()` to auto-advance Barry's intro conversation.
  3. `advance_frames(count=180)` with a `press_buttons(["b"])` in between for Barry's cutscene to release control.
  4. Call `map_name()` / `view_map()` / `navigate(directions="d1")`.
- **Verification**: Manual `press_buttons(["down"], frames=32)` DOES move the player one tile (visible in screenshot), confirming the game itself has control and the player position memory should be valid. `reload_tools()` does not fix it.
- **Workaround**: Advance past starter pickup (Lake Verity) before testing map/nav tools. Post-starter QA states like `jubilife_city_arrival`, `oreburgh_city_pre_roark_lv21`, `eterna_city_arrival` all resolve `view_map` / `map_name` correctly — confirmed on 2026-04-12.
- **Notes**: Party also shows 5 "partial / stale" slots (Chikorita in slot 1, ??? in 2-5). Pre-starter party should be count=0, not count=5 with junk. Likely the same root cause: uninitialized memory region being read without a validity check.
- **Persistence correction**: The bug does NOT persist past the starter. Earlier BUG_LOG note claimed `twinleaf_outside_house_post_mom` was broken even with Running Shoes + Bicycle — but that save state is actually still **pre-starter** (opening the menu with X does nothing, confirming party count == 0). In Platinum, Mom gives Running Shoes before the player receives their starter at Lake Verity. The "bicycle received" annotation in that save-state filename appears to be inaccurate.

**Root cause (diagnosed 2026-04-12, not caused by recent commit cbae5ed):**

`renegade_mcp/addresses.py::detect_shift` validates a candidate heap delta by reading three canaries near the save block:
1. `ENCRYPTED_PARTY_COUNT` as u32 in `[1..6]`
2. `SAVE_BLOCK_BASE + 0x82` bit-popcount in `[0..8]` (badges)
3. `SPECIES_ARRAY_BASE` as u16 in `[1..649]`

**Before the first starter is received, the player has 0 Pokemon. Every real-save canary is 0, so the scanner can't find the save block.** Instead it locks onto the first random noise in the scan range that happens to look like (pc=6, badges=0, species=152). In the reproduction, that false-positive delta is `-0x60`; applying it to `PLAYER_POS_BASE` lands in uninitialized memory and returns `(map=0, x=1, y=116)` / `(x=0xFFFFFFFF, y=4)` in various runs.

Additionally, scanning for the player's Gen4-encoded name ("CLAUDE" = `0x12d 0x136 0x12b 0x13f 0x12e 0x12f`) reveals the **real** save block is at delta `-0x5C` (name at `SAVE_BLOCK_BASE + 0x68`), **not** `-0x60`. Even at the correct save-block delta, `PLAYER_POS_BASE + delta` gives `map=411, x=116, y=886` — not Twinleaf Town. A narrow scan of `PLAYER_POS_BASE ± 0x200` finds the true player-position struct at delta `-0x34` (map=414=Twinleaf, x=6, y=10). So there's a **second latent issue**: `SAVE_BLOCK_BASE` and `PLAYER_POS_BASE` live in separate heap allocations that can shift by different amounts. They coincidentally share a delta in post-starter states we've tested, but not always.

**Not related to cbae5ed (battle scan narrowing).** That commit only changed `BATTLE_SCAN_START` / `BATTLE_SCAN_SIZE`, which are unrelated to `map_name` / `view_map`. The bug is latent and surfaces only in pre-starter states; QA is the first context that hit it because Playtest sessions always start from post-starter states.

**Fix approach (deferred — non-trivial):**
1. Replace or supplement the `party_count ∈ [1..6]` canary with a **player-name signature** at `SAVE_BLOCK_BASE + 0x68` (u16 chars in Gen4 letter range `0x012b..0x015e`). This works with party=0.
2. **Detect a separate delta for `PLAYER_POS_BASE`** (and the other FieldOverworldState addresses like `CYCLING_GEAR_ADDR`): narrow search around its baseline for a struct whose `+0`=map_id (0 or 1..600), `+8`=x (0..128), `+12`=y (0..128).
3. Split `_DESMUME` address table into multiple heap groups (save-block, field-state, battle, text-printer) each with its own detected delta; update `addr(name)` to look up the right one.

None of the tools that work in post-starter states need to change; this is purely hardening `detect_shift` so pre-starter QA isn't blocked.


### BUG-004: `battle_turn` returns `MOVE_BLOCKED` when the opponent's move is blocked (not ours)
- **Tool**: `battle_turn`
- **Severity**: minor (incorrect state returned, but caller can detect it from the log)
- **Save state**: `route202_ready_chimchar_lv10` (load and battle a Youngster to recreate the scenario; easier to repro by reaching the Growlithe trainer on Route 202)
- **Call**: `battle_turn(move_index=3)` (Taunt), when the enemy tried to use a status move that was blocked by Taunt
- **Expected**: `WAIT_FOR_ACTION` — Chimchar's Taunt executed successfully and a turn was consumed; opponent's Howl was blocked as a result.
- **Actual**: Returned `MOVE_BLOCKED`, implying our move was rejected. In reality:
  1. Chimchar successfully used Taunt (PP 20 → 19, confirmed by move list)
  2. The battle log shows `"The foe's Growlithe fell for the taunt!"` and `"The foe's Growlithe can't use Howl after the taunt!"`
  3. The turn WAS consumed (Taunt PP decremented), contradicting the `MOVE_BLOCKED` contract ("no turn consumed")
  4. Battle continued normally on next call
- **Hypothesis**: The tool detects `MOVE_BLOCKED` by scanning for "can't use [move]!" text, but doesn't distinguish between this text appearing for the **opponent**'s blocked move vs our own move being blocked. Taunt causes the opponent's status moves to be blocked, producing the same "can't use" message pattern.
- **Workaround**: If `MOVE_BLOCKED` is returned but the log contains "fell for the taunt!" or "The foe's [Pokemon] can't use [move]!", treat it as `WAIT_FOR_ACTION` and continue normally.

---

### BUG-003: `buy_item` purchases wrong item and misreports quantity/cost
- **Tool**: `buy_item`
- **Severity**: major (purchases wrong item, caller gets false success)
- **Save state**: `bug_buy_item_potion_bought_antidote` (post-bug state: bag contains Antidote×3, no Potions)
- **Call**: `buy_item(item_name="Potion", quantity=5)` — called from Sandgem Town overworld immediately after a successful `buy_item("Poké Ball", 15)` purchase.
- **Expected**: Bag gains Potion×5; ¥1,500 spent; money 2210 → 710. Response fields internally consistent (`money_spent == total_cost`).
- **Actual**: Bag gained Antidote×3 (not Potions); ¥300 spent; money 2210 → 1910.  
  Response returned:
  ```json
  {"success":true,"item":"Potion","item_id":17,"quantity":5,
   "unit_price":300,"total_cost":1500,
   "money_before":2210,"money_after":1910,"money_spent":300}
  ```
  Internal inconsistency: `money_spent` (300) ≠ `total_cost` (1500). `money_after − money_before = −300`, which matches 3× Antidote (¥100 each), not 5× Potion (¥300 each). Bag confirms: Antidote×3 added, zero Potions.
- **Hypothesis**: After the Poké Ball purchase the shop cursor sits on position 0 (Poké Ball). The tool scrolled down by 2 to reach Antidote (position 2) instead of down by 1 to reach Potion (position 1). Quantity selection also seems off (bought 3, requested 5). The response then reports the *planned* item name/price/quantity rather than what was actually transacted, masking the error behind a `success: true`.
- **Workaround**: Verify bag contents with `read_bag` after every `buy_item` call; re-purchase if wrong item received.
- **Notes**: Poke Ball purchase preceding this call used the same `buy_item` code path and succeeded correctly (Poké Ball×15 + Premier Ball bonus both landed). The error seems to manifest specifically on the second buy call in the same mart session, where the cursor position calculation may be off.  
  **Reproduction attempt**: Immediately after this bug, called `buy_item("Potion", 5)` a second time from the same session. That call succeeded correctly (¥1,500 spent, Potion×5 in bag, `money_spent == total_cost`). So the bug fired on call #2 of the session (Potion after Poké Ball), but not on call #3 (Potion after failed Potion). Strongly suggests a cursor-offset error on the *first scroll from the Poké Ball position*, not a systematic problem.

---

### BUG-002: `read_dialogue(advance=true)` reports `status="no_dialogue"` while text is clearly visible on screen
- **Tool**: `read_dialogue`
- **Severity**: minor (stalls scripted-cutscene automation)
- **Save state**: `lake_verity_cyrus_cutscene_done`
- **Call**: `read_dialogue(advance=true)` immediately after loading the state (any small `advance_frames` before is fine).
- **Expected**: Either advance past the "Kyauuun!" line (the cutscene eventually yields to Barry's "Did you hear that?!" dialogue ~300 frames later), or return `status="waiting"` / `"cutscene"` / similar so the caller knows to keep polling.
- **Actual**: Returns
  ```json
  {"region":"overworld","address":"0x022A717C",
   "text":"Kyauuun!\n---","lines":["Kyauuun!","---"],
   "slot_count":2,"status":"no_dialogue",
   "conversation":["Kyauuun!","---"],"frames_elapsed":0}
  ```
  — `slot_count=2`, non-empty `text`/`lines`/`conversation`, and the text IS on the top screen, yet `status="no_dialogue"` and `frames_elapsed=0` (it didn't try to advance). The "Kyauuun!" line is the Mesprit cry after Cyrus's Lake Verity speech; it's a timed cutscene line, not a msgBox the player can A-through.
- **Reproduction steps**:
  1. `load_state("lake_verity_cyrus_cutscene_done")`
  2. `advance_frames(count=30)` — lets rendering warm up.
  3. `read_dialogue(advance=true)` → see inconsistent output above.
  4. Screenshot confirms "Kyauuun!" is showing in the top-screen textbox.
  5. Manual workaround: `advance_frames(count=300)` idles through the timed line; afterward `read_dialogue(advance=true)` correctly picks up Barry's "Did you hear that?!" and runs normally.
- **Notes**: Suspect `read_dialogue` is keying off a msgBox/ScriptManager flag that isn't set for cutscene-timed text, but the text-printer region still holds the string. Either the tool's `no_dialogue` detection is incorrect here, or the "advance" path needs a timed-wait branch for cutscene lines.

---

### BUG-005: `auto_grind` cancels level-up evolution via B-spam; causes post-evolution map detection failure
- **Tool**: `auto_grind` (also `map_name`, `view_map`, `navigate`)
- **Severity**: major (`auto_grind` silently suppresses evolution; subsequent map tools become unreliable until `reload_tools`)
- **Save state**: `monferno_lv15_route202` (post-workaround state; Monferno Lv15 in Route 202 — **do not use**, map detection is broken in this state. Reload and call `reload_tools` first.)
- **Call**: `auto_grind(move_index=2, backup_move=0, target_level=16, auto_heal=True)` — Chimchar Lv13 → Lv14 on Route 202 grass
- **Expected**: Chimchar reaches Lv14, evolution animation plays, Chimchar evolves into Monferno, grind continues.
- **Actual** (two separate issues):
  1. **Evolution cancelled silently**: `auto_grind` pressed B repeatedly during post-battle dialogue (to clear level-up / move-learn messages). B during Gen 4's evolution animation cancels the evolution. `auto_grind` reported `stop_reason="move_learn"` for Flame Wheel but made no mention of suppressing evolution. After all battles, `read_party` confirmed `species_id=390` (Chimchar) at Lv14 — evolution had not occurred.
  2. **Map detection broken after manual evolution**: After stopping `auto_grind`, the pending evolution animation played on screen ("Chimchar is evolving!" visible in screenshot). Advancing through it manually (A, no B) completed the evolution — Monferno Lv15. But immediately after, `map_name` returned `map_id=253 "Pal Park" x=0 y=0`, `view_map` returned garbage map data, and `navigate`/`navigate_to` refused to move. The underlying cause is the heap delta (from BUG-001's `detect_shift`) shifted mid-session as the game processed the evolution, invalidating the cached delta.
- **Reproduction steps**:
  1. Load `jubilife_city_town_map_obtained` (Chimchar Lv13 in Jubilife Trainers' School).
  2. Navigate south to Route 202 grass (~y=806, x=181).
  3. `auto_grind(move_index=2, backup_move=0, target_level=16, auto_heal=True)`.
  4. After ~11 battles, grind stops (move_learn or blocked). `read_party` → species_id=390, Lv14.
  5. `get_screenshot` → "Chimchar is evolving!" is visible.
  6. Press A (no B) to complete evolution. `map_name` → "Pal Park (0,0)". Navigation broken.
  7. `reload_tools` → map detection recovers.
- **Workaround**:
  - For suppressed evolution: after `auto_grind` stops near an expected evolution level, always `get_screenshot` to check for a pending evolution animation. If visible, advance with A (not B) and let it complete.
  - For broken map detection: (1) load any known-good save state (e.g., `jubilife_city_town_map_obtained`), (2) call `reload_tools` to establish a working delta, (3) immediately load the broken state without calling `reload_tools` again. The cached delta partially carries over. **Note**: only `map_name` and party reads recover — `navigate_to`, `navigate`, `heal_party`, and `view_map` remain broken because they depend on chunk/terrain addresses at a different heap offset. Full recovery requires starting from a known-good state and not loading the broken state at all. The safest post-evolution workflow: after the animation completes, immediately call `reload_tools`; if that fails (Mystery Zone), fall back to the known-good load sequence above and accept that navigation won't work from the broken state.
- **Notes**: `battle_turn` documentation states evolution is handled automatically, but `auto_grind`'s B-spam during seek/advance appears to suppress it. Two distinct sub-bugs: (a) evolution not guarded in `auto_grind`'s button loop, and (b) `detect_shift` delta not refreshed after evolution changes heap layout. Sub-bug (b) overlaps with BUG-001 root cause (separate heap allocation groups for different address tables).

---

### BUG-007: `battle_turn` partner-slot ignores `move_index` in double battles — always executes cursor-position move; `target` also misdirected
- **Tool**: `battle_turn` (double battle, `WAIT_FOR_PARTNER_ACTION` state only)
- **Severity**: major (partner Pokemon is uncontrollable in double battles; fires a random move every turn)
- **Save state**: `route203_trainers_defeated_monferno` (post-battle, just entered Oreburgh Gate area with the same Lass pair; reload and navigate north on Route 203 to trigger Lass Kaitlin + Lass Madeline double battle)
- **Calls** (all within the same double battle, Monferno as partner):
  - `battle_turn(move_index=0, target=0)` → Monferno used **Taunt** (not Mach Punch)
  - `battle_turn(move_index=1, target=1)` → Monferno used **Taunt** (not Flame Wheel)
  - `battle_turn(move_index=2, target=0)` → Monferno used **Taunt** (not Ember)
  - `battle_turn(move_index=3, target=0)` → Monferno used **Taunt** (confirmed — index 3 IS Taunt, so this one was correct by accident)
- **Expected**: `battle_turn(move_index=N)` executes the move at slot N for the partner Pokemon, targeting the specified opponent.
- **Actual** (two sub-issues):
  1. **`move_index` ignored**: Regardless of the value passed (0, 1, 2, or 3), Monferno always used Taunt (slot 3). The move cursor in the partner's action phase appears to be stuck at its last position (slot 3) and the tool navigates incorrectly or not at all.
  2. **`target` misdirected**: When `target=0` (first enemy) was specified, Monferno's Taunt hit Eevee (ally), triggering "Eevee fell for the taunt!" This indicates the target parameter is also mis-applied for the partner action; the cursor may be referencing the ally slot instead of the enemy slot.
- **Confirmed working in single battle**: In the same session, `battle_turn(move_index=0)` on Monferno as the *lead* (WAIT_FOR_ACTION state) correctly used Mach Punch, and `battle_turn(move_index=1)` correctly used Flame Wheel. The bug is **specific to WAIT_FOR_PARTNER_ACTION**.
- **Workaround**: In double battles, the partner Pokemon's moves cannot be controlled via `battle_turn`. The partner will repeat whatever move its cursor currently sits on. Position the partner's cursor on a useful move before the battle starts (via the menu), or avoid double battles where the partner's move choice matters. Taunt PP depletion will eventually trigger a `MOVE_BLOCKED` or Struggle situation.
- **Notes**: Taunt had 20 PP at battle start and decremented each turn, confirming it was genuinely being executed (not a phantom report). The cursor was on slot 3 (Taunt) likely because Taunt was the last move Monferno selected in a prior battle (cursor memory persists between battles). The tool's partner-action code likely reads the cursor position for display but fails to navigate to the requested `move_index` before pressing A.

---

### BUG-008: `map_name` returns "Floaroma Meadow" for Oreburgh Gate (map_id=258)
- **Tool**: `map_name` (pure lookup; also affects `navigate_to` position reports and `view_map` header)
- **Severity**: minor (cosmetic / misleading; navigation and warps function correctly)
- **Save state**: `oreburgh_city_arrival` (player just exited Oreburgh Gate into Oreburgh City; load and walk back west through the gate to be inside map_id=258)
- **Call**: `map_name()` while inside Oreburgh Gate (map_id=258)
- **Expected**: Returns something like `"Oreburgh Gate"` or `"Route 203 Gate"`.
- **Actual**: Returns `{"map_id":258,"name":"Floaroma Meadow","display":"Floaroma Meadow","code":"R209M","room":""}`. Floaroma Meadow is an entirely different area of the game (northwest of Jubilife City).
- **Confirmation that map_id=258 IS Oreburgh Gate**: `view_map()` inside the map shows warps to `"Route 203"` (west exit) and `"Oreburgh City"` (east exit), consistent with Oreburgh Gate's position in the game world. NPC dialogue there includes "you need Oreburgh City's Gym Badge" for Rock Smash, further confirming the location.
- **Reproduction steps**:
  1. From `oreburgh_city_arrival`, navigate west through the gate warp on Oreburgh City's west edge.
  2. `map_name()` → `"Floaroma Meadow"`.
  3. `view_map()` → warps confirm Route 203 ↔ Oreburgh City.
- **Workaround**: Cross-reference warp destinations from `view_map` to determine actual location; do not rely on `map_name` for indoor gate/cave maps if the name seems implausible.
- **Notes**: The ROM location name table likely has a mismatch at map_id=258. Renegade Platinum modifies many maps; this may be a side-effect of map ID reassignment without updating the name lookup table. map_id=258 in the name table might genuinely be labeled "Floaroma Meadow" in the ROM data, while the actual Floaroma Meadow uses a different map ID in this hack.

---

### BUG-006: Double battle partner-faint softlock — POKEMON replacement menu loops indefinitely when no replacement is available
- **Tool**: `battle_turn` (double battle mode); also reproduced with raw `advance_frames`/`press_buttons` input
- **Severity**: blocking (battle cannot be completed; only recovery is loading a save state)
- **Save state**: `route203_barry2_defeated` (pre-battle state — walk east ~5 tiles to trigger Youngster Michael + Lass double battle on Route 203)
- **Call**: `battle_turn(move_index=0)` after partner Pokemon (Eevee) has fainted mid-battle with no eligible replacement (Chimchar also fainted before the double battle started)
- **Expected**: After the partner slot is vacated with no replacement, subsequent turns proceed 1v2: "What will Shinx do?" → select move → turn executes. POKEMON replacement menu should only appear once (at the moment of faint) and auto-dismiss when no replacement is available.
- **Actual** (two-phase failure):
  1. **`battle_turn` loop**: Tool returned `final_state: "ACTION"` repeatedly. The battle log showed "What will [Pokemon] do?" twice per call (one per double-battle slot), and the tool cycled without executing a turn. Manual input required.
  2. **Game-level softlock**: After switching to raw button inputs, every attempt to select a move (FIGHT → Spark/Bite/Howl/Quick Attack → press A) immediately transitions to the POKEMON replacement menu. Pressing CANCEL or B from that menu undoes the move selection and returns to the FIGHT submenu — no turn ever executes. Sustained A-hold for 600+ frames from the POKEMON screen also fails to advance. Enemy Shinx HP confirmed stuck at 5/30 across dozens of input attempts.
- **Reproduction steps**:
  1. Load `route203_barry2_defeated`. Party: Shinx Lv14 (lead), Eevee Lv6 (healthy), Chimchar Lv13 (fainted).
  2. Walk east ~5 tiles to trigger Youngster Michael + Lass double battle.
  3. Battle their team (Kricketot/Zubat/Rattata/Shinx). Let Eevee faint to enemy damage.
  4. At the POKEMON replacement prompt, press CANCEL (no replacement available; Chimchar fainted).
  5. Try `battle_turn(move_index=0)` — tool loops on ACTION state. Or use raw FIGHT → move → A: POKEMON menu reappears every time.
- **Workaround**: Load `route203_barry2_defeated` and navigate past Youngster+Lass (use `navigate_to` with `flee_encounters=True`), or maintain at least 2 living party members so a replacement is always available in doubles.
- **Notes**: The game appears to treat the POKEMON replacement prompt as a required gate even when 0 eligible replacements exist. CANCEL's behavior in this context cancels the pending move selection rather than committing "no partner" and executing the turn. This may be a Gen 4 engine edge case (normally the game skips this prompt if no replacements exist, but the exact trigger conditions differ here). The `battle_turn` tool sees two ACTION prompts per cycle (one per double-battle slot) and loops rather than detecting the stuck state.

