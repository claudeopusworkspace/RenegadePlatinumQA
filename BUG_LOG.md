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

