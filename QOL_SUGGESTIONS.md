# QoL Suggestions (Renegade MCP tools)

Small usability/ergonomics ideas collected during QA playthroughs. Not bugs — the tools work — but friction points where a smart default or extra hint would save the caller a round-trip.

---

## `navigate_to` — distinguish blocking vs ambient encounter dialogue

**Observed:** In Twinleaf Town, the Guitarist at (108, 869) fires an ambient "Hiya, CLAUDE. Barry was looking for you..." line whenever the player walks into their proximity zone. `navigate_to` correctly stops + returns `encounter.dialogue.status="completed"` — but if I call `navigate_to` again, the NPC's LoS re-fires the *same line* on the very first step, producing a loop. Manual `press_buttons(["up"])` bypasses it fine because the game only blocks the one input frame; it's the navigate loop that gets stuck.

**Suggestion:** when an encounter ends with `status="completed"` (no yes/no, no battle), optionally auto-retry the remainder of the path once. Or return a hint like `encounter.blocking=false` when the dialogue is pure flavor so the caller knows it's safe to keep moving. A user-controllable `pass_through_ambient=True` flag would also work.

---

## `read_dialogue` — recognize timed cutscene text (see BUG-002)

Separate from the bug itself: even once the `no_dialogue` mis-classification is fixed, it would be great if `read_dialogue(advance=true)` could *wait* for timed cutscene lines instead of bailing with `frames_elapsed=0`. A bounded `max_cutscene_wait_frames` (e.g. 600) would cover most Pokemon cutscenes and keep the tool behavior predictable.

---

## `interact_with` — patrol-movement timeout ergonomics

**Observed:** At Lake Verity, the Briefcase object had `type_14` patrol movement and `interact_with(object_index=13)` returned a 15-second timeout:
```
"note":"Briefcase has patrol movement (type_14) and could not be intercepted within 15 seconds. Try navigating to their patrol area and waiting manually."
```
The briefcase is stationary in practice — the "patrol" is just a movement *type* flag, not actual motion. Same thing happened with Barry immediately after the Cyrus scene (`type_48`).

**Suggestions:**
1. Extend the intercept logic to try a direct A-press if the target hasn't moved in ~2 seconds (it probably won't).
2. Or: expose the patrol type in the error so the caller can decide (stationary NPCs with patrol flag set are common for scripted-scene actors).
3. Or: auto-fallback to coordinate-mode `interact_with(x, y)` when the object-index mode times out on a non-moving target.

---

## `battle_turn` — damage/KO preview alongside type-effectiveness

**Observed:** During rival-1 (Chimchar Lv5 w/ Atk−1 vs Piplup Lv5, 9 HP), I had to hand-compute: "Scratch hits for 2 under Atk−1, Ember hits for ~3 under NVE+STAB, neither one-shots, Piplup's Pound KOs me next turn." The type-matchup warning told me Ember was NVE, but didn't help me compare to Scratch's effectively-neutered output.

**Suggestion:** include `expected_damage_min/max` (or KO chance) per eligible move in `read_battle` / the `battle_state` payload. Renegade already knows stats, stages, STAB, types, ability — the damage formula is right there. Even a rough `hp_percent_min/max` would let callers make the right call without recomputing the Gen 4 formula.

---

## `view_map` — consistent NPC labels in the grid

**Observed:** In Twinleaf Town, the Guitarist (obj index 3) appears as `C` in the grid render because "C" is the display-type symbol assigned by the renderer, not the first letter of the name. Similarly the Arrow Signpost rendered as `G` in a different frame. Both showed up correctly in `objects[]`, but I spent time trying to reconcile grid symbols with names.

**Suggestion:** either (a) render NPCs/objects with a digit matching their `objects[]` index so the map is directly cross-referenceable, or (b) put the mapping (`G=Arrow Signpost, C=Guitarist, ...`) in the Key line at the bottom of the map — same format as the existing terrain legend.

---

## Starter-briefcase scene — contradictory input scheme hint

**Observed:** Prior-session memory says "Rowan's pokeball intro requires a touch-screen tap on the pokeball — A/B don't work." This session, the briefcase-open UI only responded to **D-pad + A** (touch did nothing). Different scene, or different moment within the scene?

**Suggestion:** this is more a memory/documentation issue than a tool bug, but if `interact_with` on the Briefcase could return a hint like `ui_mode="dpad_select"` when it transitions into the starter-choice screen, the caller wouldn't have to guess. A general "what input does this current UI accept?" probe would help a lot of the one-off scripted UIs.

---

*Add more entries as they come up during subsequent QA sessions.*
