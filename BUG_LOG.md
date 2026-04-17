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

### BUG-006: `buy_item` leaves player stuck in shop UI on "How many?" prompt

- **Tool**: `buy_item`
- **Severity**: major (leaves game in a non-overworld state; subsequent tools misread the context)
- **Save state**: `jubilife_mart_after_buy_5potions` (player inside Jubilife Mart at (3,7), money ¥1,948, 0 badges, party and bag are whatever they were mid-QA — irrelevant to the bug)
- **Call**: `buy_item(item_name="Potion", quantity=1)`
- **Expected**: After the purchase, the tool should drive inputs all the way back to full overworld control (same criteria other tools use for "completed") — through the quantity confirmation, the "Is there anything else? (BUY/SELL/SEE YA!)" main menu, and the cashier's "Please come again!" line.
- **Actual**: Purchase succeeded — tool returned `success: true, item: "Potion", money_before: 1948, money_after: 1648, money_spent: 300`. **But the game is still inside the shop UI on the "Potion? Certainly. How many would you like?" quantity prompt** (screenshot captured: shop inventory list on top screen, quantity/dialogue box with "Potion? Certainly. / How many would you..." visible). Player has no overworld control.
- **Workaround**: Manually press B several times to back out: quantity prompt → item list → main menu (BUY/SELL/SEE YA!) → "Please come again!" → overworld. Be careful on the 3-option main menu — down+A lands in the SELL bag view instead of SEE YA!, adding more backtrack.
- **Notes**: The tool stops one state too early — it already knows the expected post-purchase states and just needs to keep driving inputs until the cashier's closing line resolves. Related side-effect: `read_dialogue(advance=True)` called in this lingering state presses A, which re-opens the shop quantity select instead of advancing to overworld — the dialogue tool doesn't recognize it's inside a shop menu rather than a plain dialogue box. Originally filed as FR-002; reclassified as a bug after live-verified repro on 2026-04-16 from the dedicated save state.

---

### BUG-005: ROM text-variable placeholders leak through `read_dialogue` / `battle_turn` output

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

### BUG-004: `battle_turn` stalls on target-pick sub-menu in doubles after partner Pokémon faints

- **Tool**: `battle_turn`
- **Severity**: major (can't take any action, blocks the fight unless worked around with raw button taps)
- **Save state**: `bug_battle_turn_stuck_after_double_ko_doubles` (mid-Route 203 doubles vs Lass tag team: Monferno 28/54 solo, Azurill 20/29 solo enemy after Shinx and Sunkern both fainted on the same turn; action prompt showing and target-pick sub-menu open on bottom screen with only Azurill highlighted)
- **Call**: `battle_turn(move_index=0, target=0)` and `battle_turn(move_index=0)` — both returned `final_state: "ACTION"` with log only showing "What will Monferno do? / Azurill / What will Monferno do?" and **no damage dealt / battle state unchanged**.
- **Expected**: Submit Scratch against the surviving Azurill and resolve the turn (either taps Azurill automatically since it's the only valid target, or uses the explicit `target=0` to pick it).
- **Actual**: Tool completes without error and with a "WAIT_FOR_ACTION"-like response, but the game is actually sitting on the **target-pick sub-menu** (bottom screen shows the 4-target grid with only Azurill lit up — screenshot saved alongside the state). No move is ever selected and the enemy also doesn't move. Repeating the call does nothing. The new `final_state: "ACTION"` value (not in the documented state list) was also returned on the prior turn when the partner Shinx fainted from Mega Drain simultaneously with Sunkern's burn KO, suggesting the tool enters this degraded state specifically when a double battle "collapses" to 1v1 mid-turn.
- **Workaround**: Manually `tap_touch_screen` the Azurill target tile to dismiss the sub-menu, then `battle_turn(move_index=N)` resumes normal behavior.
- **Notes**: Two related quirks seen on the same turn sequence: (1) `final_state: "ACTION"` appears to be a truncated/misnamed variant of `WAIT_FOR_ACTION`; (2) Azurill's Bubble produced the "Monferno's Speed fell!" message **twice** after a single Bubble use (also seen earlier in the same battle), even though `stages.Spe` only shows `-1` — probably a cosmetic dup, but noted here for context.

---

### BUG-003: `auto_grind` cancels Chimchar→Monferno evolution and leaves dialogue hanging

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

### BUG-002: `auto_grind` auto-heal stops on wild-battle FAINT_SWITCH prompt

- **Tool**: `auto_grind`
- **Severity**: major (breaks the auto-heal loop)
- **Save state**: `bug_auto_grind_faint_switch_stuck` (captures the stuck state: wild Rattata on field, "Choose a Pokémon" switch prompt on bottom screen, Shinx fainted with 3 other party members alive)
- **Call**: `auto_grind(move_index=0, target_level=11, auto_heal=True)` with Shinx Lv5 (11/19 HP) as slot 0 on Route 202. Other party members full HP.
- **Expected**: When slot 0 faints in a wild encounter, auto-heal should either (a) flee the battle and navigate to the nearest PC, or (b) switch to another party member and continue grinding. The tool advertises "when heal_x/heal_y/grind_x/grind_y are set … auto-heals on faint or PP depletion" and `auto_heal=True` should do the equivalent.
- **Actual**: Stopped immediately after the first Rattata battle with `stop_reason: "heal_failed"` and `stop_detail: "Failed to exit battle after faint. State: WAIT_FOR_ACTION"`. `heal_trips: 1` — so the tool tried to heal but gave up. Game is still in the battle at the **FAINT_SWITCH** prompt (bottom screen shows "Choose a Pokémon." with Shinx marked FNT). The reported state `WAIT_FOR_ACTION` doesn't match what's actually on screen — looks like the tool polled once and timed out instead of recognizing FAINT_SWITCH.
- **Workaround**: Manually call `battle_turn(switch_to=N)` to send another Pokemon, or `battle_turn(run=True)` to flee, then `heal_party` from overworld.
- **Notes**: Misidentification of the prompt state is probably the root cause — if the tool expected a regular action prompt after faint instead of a FAINT_SWITCH, the subsequent flee/switch logic never fires. Seems specific to **wild battles** where the player can flee, since the earlier Barry trainer-battle faint sequence returned the correct `FAINT_FORCED`/`BATTLE_ENDED` flow.

---

### BUG-001: `throw_ball` formatted output reports `State: TIMEOUT` after successful catch

- **Tool**: `throw_ball`
- **Severity**: minor (cosmetic)
- **Save state**: `bug_throw_ball_state_mismatch` (state is *after* the bug; the successful catch is already reflected in party slot 3)
- **Call**: `throw_ball()` against a Lv5 Shinx at 11/19 HP after Burmy's Tackle — 5th ball, caught successfully.
- **Expected**: `formatted` string should end with `State: CAUGHT` to match the JSON field `final_state: "CAUGHT"`.
- **Actual**: JSON correctly reports `"final_state":"CAUGHT"` and Shinx is in party slot 3 with full data, *but* the `formatted` human-readable log ends with `State: TIMEOUT`. The two are contradictory. Also in the same `formatted` string, the "Gotcha! Shinx was caught!" line is rendered as a blank entry — the raw log had `[FFFE][0202][0001][0003]Gotcha!\nShinx was caught![FFFE][0202][0001][0002]\n` and the formatter appears to strip the entire line when leading/trailing control codes wrap the text.
- **Workaround**: Trust the JSON `final_state` field; ignore the `State: …` tail of `formatted`. Also confirmed via `read_party` that the catch succeeded.
- **Notes**: Two issues in one output: (1) final-state label inconsistency in the formatted summary, (2) missing "Gotcha!" line because of `[FFFE]…` control-code wrapping. Both are cosmetic — the catch worked.

---
