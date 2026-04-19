# Pokemon Renegade Platinum QA

You are performing a **QA playthrough** of Pokemon Renegade Platinum using the melonDS MCP tooling. Your primary mission is to play through the game from the start and **document any tool bugs you encounter** along the way.

## QA Mission

**Play the game. Document bugs. Don't fix them.**

- Play normally using the available tools (navigation, battle, inventory, etc.)
- When a tool misbehaves, **immediately save a state and log the bug** in BUG_LOG.md
- Do not edit tool code, analyze memory, write tests, or investigate root causes
- Focus on coverage: exercise as many tools and workflows as possible
- Progress through the story at a reasonable pace - don't rush past areas, but don't over-grind either
- The bug reports you write here will be triaged and fixed in the main RenegadePlatinumPlaytest project

### Bug Reporting Protocol

When you encounter a bug:

1. **Save a state for reproduction** — the save must capture the game state *before* the faulty tool call, so the bug can be reproduced by loading the state and re-running the same call.
   - If the bug is **reproducible from the current state** (e.g., a read tool returning wrong data, a navigate call that always fails from this position), use **`save_state`** with a descriptive name (e.g., `bug_navigate_to_stuck_route203`).
   - If the bug involved a tool that **changed game state** and can't be re-triggered from the current position (e.g., a navigation that moved you partway, a battle turn that advanced the fight), use **`save_checkpoint`** to capture a previous point in time before the tool was called. Name it descriptively.
2. **Add an entry to BUG_LOG.md** with:
   - The tool that failed
   - What you were trying to do
   - What actually happened (include the error/unexpected output)
   - The save state/checkpoint name for reproduction
   - Exact tool call and parameters that triggered it
3. **Work around it** and keep playing - don't get stuck on any single issue
4. If a bug is blocking progress entirely, note it and find an alternative path

### What Counts as a Bug

- Tool returns an error when it shouldn't
- Tool succeeds but produces wrong results (wrong position, wrong items, wrong battle state)
- Tool hangs or times out unexpectedly
- Navigation pathfinding fails on walkable terrain
- Battle automation gets stuck or makes wrong inputs
- UI navigation (menus, bags, PC) ends up in wrong state
- Dialogue advancement misses text or gets stuck
- Any inconsistency between what a read tool reports and what's on screen

### What Is NOT a Bug

- Losing a battle (that's gameplay)
- Game difficulty (that's Renegade Platinum)
- Needing to grind (normal)
- A tool correctly reporting an error (e.g., "not in battle" when you're not in battle)
- One-off manual tasks that no Renegade tool covers (see below)

### Manual / One-Off Tasks

Some game moments — especially early game — involve unique UIs or story sequences that the Renegade tools don't cover (e.g., the professor's intro dialogue, naming your rival, choosing your starter). These are **not bugs or missing features**. They're one-off situations. Use the base melonDS MCP tools (`press_buttons`, `tap_touch_screen`, `advance_frames`, `get_screenshot`, etc.) to get past them manually and move on.

## Getting Started

1. Call `init_emulator` to initialize melonDS.
2. Call `load_rom` with path `/workspace/RenegadePlatinumQA/RenegadePlatinum.nds`.
3. No save states exist yet - you're starting from scratch. Advance through the intro (~8000 frames) to reach the title screen.
4. Save states frequently as you progress. Log them in SAVE_STATES.md.

## Renegade Platinum Story Guide

Renegade Platinum (Drayano's v1.3.0 hack of Pokémon Platinum) relocates NPCs, moves items, adds new story gates, and changes evolutions/types/moves. Use this section as a cheat sheet so you're not blindly wandering when the in-game dialogue doesn't point clearly to the next step. Full source docs were reviewed from `/tmp/Documentation/` (not committed).

### Critical Story Gates (can otherwise trap you)

- **After Eterna Galactic HQ events**: Route 206 is blocked until you talk to the **Bike Shop owner in Eterna City**. Do this before trying to head south.
- **Before Canalave City**: the guard blocks you until you **visit Pal Park** and talk to all the NPCs there to obtain the **Tea** key item. Pal Park is reached via Route 221 once you have Surf + Cut.
- **Valley Windworks door**: Works Key is obtained from Floaroma Meadow (gate at ~(162-163, 641) on Floaroma Town, NOT from Route 205).
- **Route 205 North Galactic Grunts**: permanent blockers until Dawn sends you to Eterna after Windworks/Mars.

### Gift Pokémon (all shiny-eligible; SR to reroll)

- **Twinleaf Town, Mom's house**: Eevee Lv5 (after Lucas/Dawn tells you to talk to Mom).
- **Sandgem Lab**: other two Sinnoh starters Lv5 from Rowan's briefcase (second interaction).
- **Jubilife City**:
  - Trainers' School Cowgirl: random baby-Pokémon Egg.
  - Pokémon Center interviewer: **Bulbasaur / Charmander / Squirtle** Lv5 (win the battle, one per visit).
- **Oreburgh City**:
  - Pokémon Center interviewer: **Treecko / Torchic / Mudkip** Lv10.
  - House near the mine: **Steven gives Beldum** Lv10.
- **Floaroma Town Pokémon Center**: interviewer gives **Chikorita / Cyndaquil / Totodile** Lv15.
- **Eterna City**:
  - Galactic Building (after Jupiter): **Porygon Lv22**.
  - Underground Man's house: **all 7 fossils** (Omanyte/Kabuto/Aerodactyl/Lileep/Anorith/Cranidos/Shieldon) → revive at Oreburgh Museum.
- **Pastoria City**: old lady in a house gives **Lapras Lv35**.

### New / Moved NPCs

- **Item Fanatic** — Floaroma Town (house right of PC): gives held items for specific party members. Pikachu→Light Ball, Farfetch'd→Stick, Cubone/Marowak→Thick Club, Chansey→Lucky Punch, Ditto→Quick+Metal Powder, Clamperl→Deep Sea Tooth+Scale.
- **Hidden Power Teller** — Jubilife Trainers' School (also still in Veilstone): tells HP type.
- **Move Deleter** — Oreburgh City (left of PC).
- **Move Relearner** — Pastoria City: **FREE**, no Heart Scales required.
- **Move Tutors** — Route 212 South house: all tutors (Route 212 + Snowpoint + Survival) combined, **FREE**, no Shards.
- **Rare Berry Seller** — Route 208 (Berry Master's neighbour): Liechi/Salac/etc. at $10,000 each.
- **Training NPCs** — Solaceon Day Care: Chansey/Blissey EXP battles (tiers unlock by badge progress) + Lv10 EV trainers (Low/Medium/High = 1/2/3 EV per battle). Farmer sells 15-of-each EV-reducing berry bundle for $5,000.
- **Evolution Item Seller** — Snowpoint City (top-left house): evo items not in Veilstone Dept Store or Game Corner, $10,000 each.

### In-Game Trades (traded mons **always obey**, no badge gate)

- **Oreburgh City** — give **Ponyta**, get **Spheal "Gaia"** (Quiet, Never-Melt Ice).
- **Floaroma Town** — give **Cherubi**, get **Skorupi "Spike"** (Jolly, Poison Barb).
- **Eterna City** — give **Snorunt**, get **Chatot "Macaw"** (Modest, Sharp Beak).
- **Route 226** — give **Magikarp**, get **Magikarp "Foppa"** (Adamant, 31×6 IVs, Starf Berry).

### Evolution Changes (most playthrough-relevant)

- **Eevee stone evolutions** are reassigned: Sun Stone→Espeon, Moon Stone→Umbreon, Leaf Stone→Leafeon, Ice Stone→Glaceon. Water/Fire/Thunder Stones still produce Vaporeon/Flareon/Jolteon. (Already exercised: our Eevee→Vaporeon via Water Stone.)
- **Trade evolutions are now level-based at Lv36**: Kadabra→Alakazam, Machoke→Machamp, Graveler→Golem, Haunter→Gengar.
- **New "use item like a stone" evolutions**: Onix+Metal Coat→Steelix, Scyther+Metal Coat→Scizor, Poliwhirl+King's Rock→Politoed, Slowpoke+King's Rock→Slowking, Seadra+Dragon Scale→Kingdra, Rhydon+Protector→Rhyperior, Electabuzz+Electirizer→Electivire, Magmar+Magmarizer→Magmortar, Porygon+Up-Grade→Porygon2, Porygon2+Dubious Disc→Porygon-Z, Feebas+Prism Scale→Milotic, Dusclops+Reaper Cloth→Dusknoir, Clamperl+Deep Sea Tooth→Huntail, Clamperl+Deep Sea Scale→Gorebyss.
- **Level tweaks**: Ponyta→Lv35 Rapidash, Aron→Lv24 / Lairon→Lv40 Aggron, Croagunk→Lv33, Snorunt→Lv32 Glalie, Stunky/Glameow/Shuppet/Duskull/Slugma/Baltoy→Lv32, Skorupi/Rhyhorn/Omanyte/Kabuto/Lileep/Anorith/Trapinch→Lv30, Spheal→Lv24/Sealeo→Lv40, Grimer→Lv35 Muk, Meditite/Slowpoke→Lv33, Wailmer→Lv36.
- **Happiness evos simplified** (time-of-day ignored): Budew→Roselia, Chingling→Chimecho, Riolu→Lucario.

### Type Changes (Complete version — the one patched here)

Fairy type is added; all canonical Fairies (Gen VI+) are Fairy here. Notable retypings to remember when planning battles:

- Charizard Fire/**Dragon** (not Flying)
- Ninetales Fire/**Fairy**; Meganium Grass/**Fairy**; Altaria Dragon/**Fairy**; Milotic Water/**Fairy**; Luvdisc Water/Fairy; Misdreavus/Mismagius Ghost/**Fairy**; Swablu **Fairy**/Flying; Uxie/Mesprit/Azelf Psychic/**Fairy**
- Sceptile Grass/**Dragon**; Ampharos Electric/**Dragon**
- Golduck Water/**Psychic**; Noctowl **Psychic**/Flying
- Farfetch'd **Fighting**/Flying; Lopunny Normal/**Fighting**; Electivire Electric/**Fighting**
- Luxray Electric/**Dark**; Feraligatr Water/**Dark**; Seviper Poison/**Dark**
- Flygon/Vibrava/Trapinch gain **Bug** type (Trapinch Bug/Ground; Vibrava/Flygon Bug/Dragon)
- Glalie Ice/**Rock**; Masquerain Bug/**Water**; Volbeat Bug/**Electric**; Illumise Bug/**Fairy**

### Move Changes Worth Knowing

- **Cut** is now **Grass-type**, 60 power, 100% acc, high-crit — actually decent!
- **Rock Climb** is now **Rock-type**, 80 power, 95% acc, 10 PP.
- **Rock Smash** 60 power (was 40). **Flame Wheel** 75 power (was 60). **Fly** 100 power.
- Numbers updated to USUM (Shadow Claw 80, Shadow Punch 80, Cross Poison 90, Aurora Beam 75, etc.).
- **Curse** is now Ghost-type. **Charm / Moonlight / Sweet Kiss** are now Fairy-type.
- **Replaced moves** (old → new): Barrage→Draining Kiss, Brine→Scald, Constrict→Icicle Crash, Horn Drill→Drill Run, Lunar Dance→Moonblast, Luster Purge→Dazzling Gleam, Mist Ball→Disarming Voice, Sand Tomb→Bulldoze, Submission→Play Rough, Twister→Hurricane, Volt Tackle→Wild Charge.

### TM Changes and Gym Leader Rewards

- **All TMs** are 99 count when picked up and are **unsellable** (price $0). **No TMs sold in PokéMarts.**
- **Moved/changed TMs** (old→new move): TM55 Scald, TM57 Wild Charge, TM62 Bug Buzz, TM83 Hyper Voice, TM85 Dazzling Gleam, TM88 Hurricane.
- **Gym leader reward TMs** (memorize before challenging):
  - Roark → **TM76 Stealth Rock**
  - Gardenia → **TM86 Grass Knot**
  - Maylene → **TM60 Drain Punch**
  - Fantina → **TM30 Shadow Ball**
  - Crasher Wake → **HM07 Waterfall** (now an HM reward)
  - Byron → **TM91 Flash Cannon**
  - Candice → **TM72 Avalanche** (also gives **HM08 Rock Climb**)
  - Volkner → **TM57 Wild Charge**
- **HM sources**: HM01 Cut (Cynthia, Eterna), HM02 Fly (Galactic Warehouse), HM03 Surf (Celestic), HM04 Strength (Riley, Iron Island), HM05 Defog (Solaceon Ruins), HM06 Rock Smash (Oreburgh Gate NPC), HM07 Waterfall (Wake), HM08 Rock Climb (Candice).

### Item Economy / Other

- **Ball prices slashed**: Poké Ball $50, Great Ball $150, Ultra Ball $300. Stock up liberally.
- **Exp. Share** is on Route 203 (we already picked it up). **Silk Scarf** Route 203; **Soothe Bell** Route 203.
- **New key items** unique to this hack: Blue Orb / Red Orb / Jade Orb (Steven in Oreburgh; unlock Kyogre/Groudon/Rayquaza post-game), **GS Ball** (Celestic → Celebi), **Silver Wing** and **Rainbow Wing** (Oak in Eterna → Lugia/Ho-Oh), **Mysterious Invitation** (Survival Area, Mewtwo event), **Tea** (Pal Park, required for Canalave gate).
- **Super Rod** is now in Snowpoint City (not Route 218).
- **Gift Pokémon come holding items**: Bulba/Chiko/Treecko→Miracle Seed, Char/Cynda/Torchic→Charcoal, Squirtle/Toto/Mudkip→Mystic Water.

### Legendary/Postgame (for awareness only — not part of main story)

- Most roamers and Regis are post-Distortion-World via Rowan.
- Articuno=Mt Coronet summit, Zapdos=Valley Windworks island (Surf), Moltres=Victory Road, Raikou=Route 208 (Rock Climb), Entei=Route 211 East, Suicune=Route 213, Mewtwo=Oreburgh Gate B1F with Odd Invitation.
- Plates/Arceus chain starts at the "Foreign Building" in Hearthome after becoming Champion.

## Save States

See [SAVE_STATES.md](SAVE_STATES.md) for the save state table (starts empty - build it as you go).

## Renegade MCP Tools

Game-specific tools live in the `renegade` MCP server (source: `renegade_mcp/`). Each tool's full schema + usage notes are surfaced via `ToolSearch` and at call time — **don't re-document them here**. Key ROM file indices you'll occasionally want: `0392`=items, `0412`=species, `0610`=abilities, `0647`=moves, `0433`=locations, `0646`=move descriptions.

## Navigation

**CRITICAL: Do not rely on screenshots for spatial reasoning in the overworld.** The isometric/overhead camera makes it very difficult to judge tile positions, room boundaries, and exits from pixel images. Use `view_map` — it returns terrain, player position, NPCs, and **warp destinations with coordinates**, all read live from the emulator. Warp (x,y) tuples can be passed directly to `navigate_to`. Screenshots are fine for dialogue, menus, and battle screens — just not overworld spatial reasoning. When stuck, ask Michael for visual help rather than brute-forcing positions.

## DS Screen Layout

- **Top screen** (256x192): Main game display.
- **Bottom screen** (256x192): Touch-enabled, used for menus, Pokemon selection, etc.
- Screenshots with `screen="both"` show both stacked vertically (256x384).

## Input Reference

**Buttons:** a, b, x, y, l, r, start, select, up, down, left, right

- **A**: Confirm / advance dialogue / interact. Use `press_buttons(["a"], frames=8)`.
- **B**: Cancel / advance dialogue. **Prefer B over A for advancing dialogue** - avoids re-triggering nearby NPCs.
- **X**: Open menu (overworld). **Use X, not Start** - Start does not open the menu in Platinum.
- **D-pad**: Move character / navigate menus.
- **Touch screen**: Tap targets on bottom screen. **Always use `get_screenshot(screen="bottom")`** for coordinate estimation.

### Bag Pocket Tabs (Bottom Screen, in-bag view)
Touch targets arranged in a circle around the Poketch ball:

| Pocket | Tap (x, y) |
|--------|-----------|
| Items | (27, 51) |
| Medicine | (35, 102) |
| Poke Balls | (59, 142) |
| TMs & HMs | (100, 165) |
| Berries | (156, 165) |
| Mail | (195, 142) |
| Battle Items | (220, 102) |
| Key Items | (228, 51) |

### Touch Screen Keyboard (Name Entry)
Letter grid coordinates (calibrated):
- Row 1 (A-J): y=99, x starts at 34, spacing 16px
- Row 2 (K-T): y=118
- Row 3 (U-Z): y=137
- Row 4 (0-9): y=172
- BACK button: x=188, y=74
- OK button: x=222, y=74

## Macros

Saved macros persist across sessions in `macros/`.

| Macro | Description |
|-------|-------------|
| `mash_a` | Press A 5 times (8-frame holds, 30-frame waits) for dialogue |
| `mash_b` | Press B 5 times (8-frame holds, 30-frame waits) - safer than A |
| `walk_up` / `walk_down` / `walk_left` / `walk_right` | Walk 2 tiles in the given direction |

## Game Progress

- **Character**: WOJ (boy), rival **Barry**
- **Badges**: 1 (**Coal**)
- **Money**: **~$11,000** (gained from Edward $640 + Garrett $1,320 + Laura + Caroline $352 this session; rough estimate, verify next session).
- **Location**: **Eterna Gym** (map 67) at elevation L1, (14, 23) facing up — mid-gym after defeating Lass Caroline. Gardenia + 2 Pokemon Breeder F trainers still pending. Best resume point: **`session13_end_gym_healed_post_lass`** (full HP, post-Lass, positioned inside gym ready to engage next trainer).
- **Party** (all fully healed via `use_medicine`):
  1. **Monferno** Lv31 (Quirky, Blaze) — Low Kick (11/20) / Flamethrower (**4/15 — LOW**) / Fake Out (8/10) / Rock Smash (15/15). 93/93 HP. **Leveled up this session** (Lv30 → Lv31 vs Scyther). Skipped learning **Feint** (priority +2 Normal, 30 BP) at Lv31. Spe 69, outspeeds Lv22 Scyther.
  2. **Vaporeon** Lv17 — 76/76 HP. Unchanged this session (only 1 wild Geodude KO for exp). Still painfully underleveled for gym.
  3. **Mothim** Lv25 holding Exp. Share — Protect (10/10) / Gust (35/35) / Bug Bite (14/20) / Hidden Power (15/15). 75/75 HP. **Leveled up TWICE this session** (Lv23 → Lv25 via Route 216 trainers + Lass Caroline). **Bug Bite is the MVP for Gardenia's grass team**.
  4. **Shinx** Lv6 — unchanged. Still bait.
- **Key Items**: Bicycle, Poké Radar, Journal, Vs. Recorder, Town Map, Pokétch (all apps), Fashion Case, HM06 Rock Smash (on Monferno), HM01 Cut, Coal Badge, Works Key.
- **Bag** (post Lass-fight heal):
  - Medicine: **Super Potion x1 (LOW — needs restock)**, Antidote x5, Awakening x1, Parlyz Heal x0 (used on Mothim vs Shroomish).
  - Items: **Repel x7**, Silk Scarf, Oval Stone, Expert Belt, Miracle Seed, Magnet, Honey x10, Destiny Knot, Moon Stone, Soft Sand, Prism Scale.
  - TMs & HMs: TM08/09/27/34/39/58/76 (x99 each), HM01, HM06.
  - Balls: Poké Ball x21.
- **Story flags** (new this session in bold):
  - All priors still valid.
  - **BUG-013 fix holds — no workaround needed at session start.** Loaded `session12_end_route211_stocked` cold, all reads clean immediately.
  - **Rematched and defeated Ace Trainer Laura (trainer 134) on Route 216** at (328, 405). Plan worked: Fake Out Togetic (flinched, ~16 dmg) → Flamethrower Togetic (did 36 dmg, Togetic put up Safeguard) → Flamethrower OHKO'd Togetic from 11 HP. Swellow came in; declined switch; took Wing Attack SE (63 dmg) and Monferno's Flamethrower OHKO'd Swellow. +cash.
  - **Defeated Skier Edward (trainer 137)** at (314, 404) — Snover/Swinub/Snorunt Lv20-ish. Easy Flamethrower/Low Kick. +$640.
  - **Defeated Ace Trainer Garrett (trainer 133, "Ace Trainer Snow M")** at (299, 394) — Mr. Mime Lv22 (Psychic/Fairy, Filter) → Scyther Lv22 (Bug/Flying, Technician, moves Agility/Wing Attack/Slash/Night Slash) → Nuzleaf Lv22 (Grass/Dark, Chlorophyll, Fake Out). **Key realization: Monferno Spe 66-69 outspeeds Lv22 Scyther** — Flamethrower OHKO'd (would've been KO'd if slower). +$1,320.
  - **Workers at (304, 385)/(305, 385) block further west on Route 216**: "We're very sorry, but this way is currently closed right now. The weather is too dangerous for anyone to continue forward." Confirms weather-gate mid-route.
  - **Gardenia found inside Snowbound Lodge (map 384) at (5, 3)** — lodge door at Route 216 (303, 398). Gardenia dialogue: "I'm Eterna City's Gym Leader! ... came here hoping to catch a SNOVER ... I'll go back to the Gym. I'll be waiting for you, Trainer!" — triggers her return to Eterna Gym.
  - **Returned to Eterna and entered gym (map 67 elevation L1)** via the gym door at Eterna (312, 563). Gardenia now spawned at gym coord (11, 3). Gym has 3 intermediate trainers: Lass (14, 22), Pokemon Breeder F (20, 17), Pokemon Breeder F (2, 7). Gym Guide at (9, 25) says "You can't challenge the Gym Leader until you beat all the Gym's Trainers."
  - **Defeated Lass Caroline** (first gym trainer): Lotad / Cacnea / Shroomish / Exeggcute all Lv22. Mothim Bug Bite SE OHKO'd all. +$352. Post-battle dialogue: "This gym's floral clock... You can walk on its hands. That's how you get to the next Trainer." — confirms the clock-tile-walking gym puzzle is active.
- **Next session start**:
  1. Load **`session13_end_gym_healed_post_lass`** (full HP, inside gym, post-Lass).
  2. **Primary objective: clear remaining 2 Breeders, then challenge Gardenia.** The gym uses floral clock hand tiles for navigation. Pokemon Breeder F (object 4) at (20, 17) is the next closest trainer.
  3. **Strategy vs Gardenia**: She's Grass-type. In RP her team is likely 4-6 mons (inflated vs vanilla). Monferno's Flamethrower + Mothim's Bug Bite (2x SE on pure Grass, 4x on Grass/Poison) are the key moves. **Watch Flamethrower PP — only 4 left.** May want to get to the Move Reminder at Pastoria (free) eventually, but for now rely on Bug Bite spam from Mothim.
  4. **Flamethrower PP is critical** (4 left). Consider healing party via `heal_party` auto-nav back to Eterna PC → Mart buy Super Potions (need at least 5-10) → return. The gym exit warp is at (11, 27).
  5. **Mart restock needed**: Super Potion down to 1. Need minimum 8-10 for gym + next route. Consider also buying Ether if available — no, Ethers are rare. Just play around PP.
  6. **Vaporeon is still Lv17 — useless against Gardenia's Grass team.** Leave in party for Exp. Share if possible, or switch Exp. Share to Vaporeon (currently on Mothim).
  7. **Gardenia's expected reward**: **TM86 Dazzling Gleam** (NOT Grass Knot — RP retyped TM86 per CLAUDE.md story gates section). Also Forest Badge.
- **Open QA bugs after this session**:
  - **BUG-014 NEW** — `battle_turn(use_item=..., party_slot=...)` / `use_battle_item` route heals to the wrong Pokemon after a mid-battle switch. Proved the Super Potion went to benched Monferno, not active Vaporeon, and the tool returned `"Slot N (bench — HP unverifiable)"` for what the caller intended as the active slot. Repro: `session12_route216_entry`. Details in BUG_LOG.md.
  - **BUG-015 NEW** — `read_party` during battle keeps pre-switch slot order (and pre-battle HP). Makes party_slot math for BUG-014 impossible to reason about without consulting the `battle_state.party` response from `battle_turn`. Repro: same as BUG-014.
  - **BUG-016 NEW** — Level-up / stat-gain text emits malformed lines (`"Mothim@\nLv. 23"`, `"Sp. Def"` alone) mid-battle on exp rollup. Cosmetic but possibly related to BUG-007 token-substitution class. Repro: grind from `session12_route216_post_blake` until the next party level-up triggers mid-battle.
  - **BUG-013 VERIFIED FIXED this session** — holds through heavy use (many `load_state`s, many battles, map transitions, exits/entries). Marker flipped in BUG_LOG.md.
  - **BUG-007** still open. Possibly related to new BUG-016 — same class of text-substitution issue.
  - **BUG-009** still open. No "Pokémon Trainer" class label fights this session (all trainers had specific class names).
  - **BUG-010, BUG-011, BUG-012** still FIXED.
  - **Arrow Signpost null dialogue (minor, not filed)**: `interact_with(object_index=<Arrow Signpost>)` on Route 211 West at (353, 531) returned `dialogue: null`, note `"Arrow Signpost did not produce any dialogue when interacted with."` — other Arrow Signposts DID produce dialogue earlier (Rt. 216 / Mt. Coronet marker). Possibly the sign-overlay-capture path missed this one. Worth a targeted repro later.
  - **map_name display inconsistency (still minor, not filed)**: Same as session 11 note.
  - **view_map legend unlabeled tile-behavior placeholders** — not filed, cosmetic.
- **FR docket**: FR-003, FR-004, FR-005, FR-006 still open. FR-006 (R0113 water-tile rendering ambiguity) got a real-world dogfood this session — the west land strip IS traversable, legend should probably distinguish "shallow/crossable" vs "deep-needs-surf" water tiles or mark floor tiles that are surrounded by sea more prominently.
- **Session 12 highlights**:
  - BUG-013 re-verified as fixed under heavy use (many state loads, many battles).
  - Reached **Route 216** via Mt. Coronet R0113 — confirmed the west land strip walk works, grabbed 3 evolution/held items along the way.
  - 1 trainer defeated on Route 216 (Blake), 1 failed (Laura) — planned retry route next session.
  - Discovered BUG-014 + BUG-015 + BUG-016 through actual play — the item-target bug nearly cost me a whiteout.
  - Mothim hit Lv23 and is starting to pull its weight; Vaporeon is falling behind badly.
- **Session 13 highlights**:
  - **Rematched Laura successfully** on Route 216 — plan from session 12 worked almost exactly. Monferno outspeed Swellow was the key surprise (Spe 66 > Scyther/Swellow Lv22-23).
  - **Beat Skier Edward + Ace Trainer Garrett** — cleared mid-Route 216. Monferno hit Lv31 (+Feint skipped).
  - **Discovered the Gardenia fetch-quest trigger is inside the Snowbound Lodge (map 384), not past the Workers.** Lodge is at Route 216 (303, 398). Gardenia at (5, 3) inside. After dialogue she teleports back to Eterna Gym.
  - **Workers at (304, 385)/(305, 385) are a permanent(?) weather gate** blocking further west progress on Route 216. Likely lifted by later story event.
  - **Re-entered Eterna Gym** — Gardenia now spawned inside at (11, 3). Lass Caroline (first gym trainer) defeated. 2 Breeders + Gardenia pending.
  - No new bugs discovered (BUG-007, BUG-009 still open but untriggered this session). BUG-013/014/015/016 untriggered — no mid-battle item uses needed, no new level-up text observed closely.

## Tips

- Save state frequently - this is a difficulty hack, expect challenges.
- **Use `read_battle` at the start of every battle** - Renegade Platinum changes abilities and movesets from vanilla.
- **`read_dialogue` auto-advances by default** - just call it after triggering dialogue and it handles everything. Only need manual intervention for Yes/No and multi-choice prompts.
- The `load_state` tool may occasionally hang - check `get_status` to verify.
- Addresses must be passed as decimal integers to MCP tools, not hex strings.
- **Touch screen taps default to `frames=8`** - changed from 1 to avoid missed inputs.
- **Wait 300 frames between UI navigation steps** - Pokemon ignores input during forced text delays.
- **Always check the bottom screen for Yes/No prompts** - battle/switch prompts use touch screen.
- **Pause menu remembers cursor position** - cursor index stored at `0x0229FA28`. The `use_item` tool reads this automatically.
- **Trainer battles may have multiple Pokemon** - handle "Will you switch?" prompt before next action.
- **Evolution is handled** - `battle_turn` and `auto_grind` detect "is evolving" text and handle it automatically.
- **Use free switches at SWITCH_PROMPT** - don't tunnel-vision on one Pokemon.
- **Never mash A/B in battle or prompts** - single presses only to avoid skipping past important states.

## QA Coverage Checklist

Track which tools/flows you've exercised. Update as you go.

- [x] Name entry (touch keyboard)
- [x] Starter selection
- [x] Wild battle (single)
- [x] Trainer battle (single) — Route 202 trainers + Barry
- [x] Double battle (tag / wild / trainer) — Lass tag team on Route 203 (mid-battle save `route203_mid_double_battle_cubone_psyduck`)
- [x] Catching Pokemon — Shinx caught on Route 202 (5 balls)
- [x] Evolution (level-up) — Chimchar→Monferno at Lv14 (**BUG-003**: auto_grind canceled the first attempt; succeeded after manual dialogue dismissal + one more level-up)
- [x] Evolution (stone) — Water Stone on Eevee → Vaporeon at Lv10 (manual bag use — no Renegade tool covers stone evolutions)
- [x] In-battle BAG use — Potion on Monferno (slot 0) mid-Roark fight to survive Onix Bulldoze, manual touch flow since `battle_turn` has no item action
- [x] Trainer item use (observed) — Roark used Super Potion on Nosepass, Potion on Bonsly — handled as trainer "turn" (Monferno still attacked normally)
- [x] Move learning (< 4 moves) — Eevee learned Quick Attack via auto_grind
- [x] Move learning (4 moves, forget) — Eevee Tail Whip → Quick Attack
- [x] Move learning (4 moves, skip) — Eevee skipped Sand Attack
- [x] Party reorder — `reorder_party` exercised twice
- [x] PC deposit — deposited Shinx to Box 1
- [x] PC withdraw — withdrew Shinx back to party
- [x] Heal at Pokemon Center — `heal_party` with auto-navigate
- [x] Buy items at PokeMart — bought 5 Potions (**BUG-006 repro: shop UI stuck**)
- [x] Use medicine (single) — `use_item`/`use_medicine` Potion on Chimchar
- [x] Use medicine (bulk) — `use_medicine` plan + confirm flow
- [x] Use field item (Repel) — `use_field_item`
- [x] Give held item — `give_item("Exp. Share", 1)` → Vaporeon, then again → Burmy after take-test
- [x] Take held item — `take_item(1)` pulled Exp. Share off Vaporeon cleanly
- [x] Teach TM/HM — `teach_tm("HM06", 0, forget_move=3)` taught Rock Smash to Monferno (forgot Taunt)
- [x] Navigate multi-room dungeon — Oreburgh Gate (2 rooms / 2 trainers)
- [x] Navigate elevation-aware map — Oreburgh Gate BDHC transitions + Oreburgh Mine (L0-L4) + Oreburgh Gym (L0-L3)
- [x] Navigate with flee_encounters — used via auto_grind internally
- [x] Auto grind (basic)
- [x] Auto grind (with auto-heal loop) — **new `auto_heal=True` cross-map mode** on Route 204 grass → Jubilife PC loop. 5 successful trips in one ~70-battle grind run. Coordinate-based variant untested, but new auto-detect mode supersedes it.
- [x] Auto grind (smart move selection) — `backup_move` used (Ember/Scratch, Covet/Bite)
- [x] Auto grind (target species) — Shinx search on Route 202
- [x] Gym battle (full team) — **Roark defeated** (6 Pokemon RP-extended team: Nosepass/Geodude/Onix/Larvitar/Cranidos/Bonsly)
- [x] Story cutscene advancement — Parcel delivery, Pokétch gift, Looker, Oval Stone gift, Roark's Water Stone quiz
- [x] Sign/signpost interaction — Arrow Signpost on Route 203 ("Rt. 203 / Jubilife City")
- [x] Buy item via overworld auto-nav — bought 4 Potions in Oreburgh from overworld (auto-navigated to mart)
- [x] Multi-choice prompt — Roark's stone quiz ("What stone?" → "Water Stone")
- [x] Double battle (trainer, story-scripted) — 2x Galactic Grunts in Floaroma Meadow (Zubat/Croagunk → Spinarak/Ledyba). Clean targeting via `target=0`/`target=1`.
- [ ] HM obstacle (Cut tree, Rock Smash)
