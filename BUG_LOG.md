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
