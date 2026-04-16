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

### FR-002: `buy_item` should fully exit the shop UI

- **Area**: menu / inventory
- **Priority**: medium
- **Context**: Called `buy_item("Potion", quantity=1)` from Sandgem Town overworld. Purchase succeeded — Potion landed in Medicine pocket, money went ¥3500 → ¥3200 — and `navigated_to_mart: true`, `success: true` were returned.
- **Current friction**: After the tool returns, the game is still inside the shop UI on the "Potion? How many would you like?" quantity prompt for a repeat purchase. Had to manually press B/A several times to back out of: quantity prompt → item list → "Is there anything else? (BUY/SELL/SEE YA!)" main menu → final goodbye text. Along the way a stray A press re-opened the SELL bag view, compounding the backtrack.
- **Proposal**: After the purchase confirmation, `buy_item` should continue driving inputs until the cashier's "Please come again!" line resolves and the player has full overworld control again (same criteria other tools use for "completed"). The tool already knows the expected states post-purchase; it just stops one state too early.
- **Notes**: This was *specifically* painful because the shop's 3-option main menu (BUY/SELL/SEE YA!) is not a standard Yes/No — down+A landed me in the SELL bag view when I was trying to exit. A user who isn't familiar with the Platinum shop layout would have a bad time unraveling this. Also filing as a possible related issue: `read_dialogue(advance=true)` called in this lingering state seems to press A, which re-opened the shop — so the dialogue tool doesn't realize it's inside a shop menu rather than a dialogue.

---

### FR-001: Resolve ROM text-variable placeholders in dialogue output

- **Area**: dialogue
- **Priority**: medium
- **Context**: Reading dialogue via `read_dialogue` and `battle_turn`'s `post_battle_dialogue` during the intro sequence and first rival battle.
- **Current friction**: Many ROM string variables leak through raw in the returned `conversation` / `text` fields. Examples observed in the first ~20 minutes of play:
  - `[VAR][0103][0002][0000][0000]` — appeared as Barry's and WOJ's names in some lines but not others (inconsistent; same var worked fine in the Mom cutscene but not in Barry's bedroom)
  - `[VAR][FF00][0001][0001]Running Shoes[VAR][FF00][0001][0000]` — the item name is there but wrapped in color/format codes that clutter the reading
  - `[01A8]10 million` / `[01A8]500` — currency symbol (P with stroke) not rendered
  - `[25BD]` — line-break / page-break marker leaking inline instead of becoming a newline
  - `[FFFE][0200][0001][0000]` / `[FFFE][0202][0001][0005][FFFE][0202][0001][0002]` — internal control codes appearing inside `"What will Chimchar do?"` and level-up lines
- **Proposal**: Post-process dialogue text to (1) resolve player / rival / item / species names from game state, (2) substitute known symbol codes (`[01A8]` → `$` or `¥`), (3) strip or normalize format/control codes (`[FFFE]...`, `[VAR][FF00]...` color wrappers, `[25BD]` page breaks). Could be a best-effort pass where unknown codes are stripped with a warning rather than surfaced raw.
- **Notes**: Minor stuff that doesn't break the tool, but it makes the conversation output noisy and occasionally confusing when you're trying to grep for literal dialogue content. The fact that the *same* variable resolves in one line but not another is the most interesting part — might point to a pre-rendering step that runs for some dialogue paths but not others.

---
