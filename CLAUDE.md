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
- **Badges**: **2 (Coal, Forest)**.
- **Money**: **~$12,906** (8,786 entry + 640 Alexandra + 152 Zach + 528 Sean + 960 Forest-Badge Grunt + 1,840 double grunts — recompute on load).
- **Location**: **T.G. Eterna Bldg (map 72)** at (19, 8) mid-raid arc, mid-floor ground level, party beat up. Best resume point: **`session15_end_post_double_grunts_eterna_hq`** (BUT needs heal + status cure). Cleaner alternative: `session14_end_post_gardenia_healed` (pristine, pre-arc) if restarting from scratch is preferred.
- **Party** (post-double-grunt, battered):
  1. **Monferno** Lv33 (Quirky, Blaze) — Low Kick (20/20) / **Flamethrower (1/15 — critical, needs PP Up or PC)** / Fake Out (9/10) / Rock Smash (14/15). 23/99 HP. **⚠ Paralysis.** Leveled Lv32 → Lv33 this session (Golbat KO).
  2. **Vaporeon** Lv21 (Serious, Water Absorb) holding Exp. Share — **Water Pulse / Quick Attack / Bite / Aurora Beam (NEW — learned at Lv19, replaced Covet)**. 20/91 HP. **⚠ Paralysis.** **Leveled Lv17 → Lv21 this session** via Exp. Share haul on Route 211 W and the HQ grunts. Aurora Beam gives her Ice coverage (2x vs Grass/Flying/Dragon/Ground).
  3. **Mothim** Lv29 (Naive, Swarm) — Protect (10/10) / Gust (34/35) / Bug Buzz (9/10) / Hidden Power (15/15). 52/85 HP. **⚠ Toxic (badly poisoned).** Switched in vs Nidoran♀ Poison-Fang + toxic tick.
  4. **Shinx** Lv6 — still unused bait.
- **Key Items**: Bicycle, Poké Radar, Journal, Vs. Recorder, Town Map, Pokétch (all apps), Fashion Case, HM06 Rock Smash (on Monferno), HM01 Cut, **Coal Badge, Forest Badge**, Works Key.
- **Bag** (post-double-grunts, pre-heal):
  - Medicine: Super Potion x9 (untouched this session — Monferno only fainted vs Roserade in s14), Antidote x5, Awakening x1, **Parlyz Heal x0 — BUY NEXT SESSION** (both active mons paralyzed). Need ~3+ for safe HQ clear.
  - Items: Repel x7, **Fire Stone (NEW — Route 211 East drop at (433, 535))**, Silk Scarf, Oval Stone, Expert Belt, Miracle Seed, Magnet, Honey x10, Destiny Knot, Moon Stone, Soft Sand, Prism Scale, **Escape Rope (NEW — Mt. Coronet drop at (28, 43))**.
  - TMs & HMs: TM08/09/27/34/39/58/76/86 (x99 each), HM01, HM06, **TM12 Taunt (NEW — R211W (368, 535))**, **TM69 Rock Polish (NEW — Mt. Coronet (2, 31))**, **TM73 Thunder Wave (NEW — T.G. Eterna Bldg L1 map 73 at (3, 12))**.
  - Balls: Poké Ball x21.
- **Story flags** (new this session in bold):
  - All priors still valid.
  - **Defeated Aroma Lady Jenna** (gym Breeder #1 at (20, 17)): Weepinbell/Ivysaur/Gloom Lv23 all 2x SE'd. **view_map labels her "Pokemon Breeder F" but in-battle class is "Aroma Lady"** — minor display-vs-class mismatch (cosmetic, same class as earlier non-filed notes). +$736.
  - **Defeated Aroma Lady Angela** (gym Breeder #2 at (2, 7)): Roselia/Bayleef/Skiploom Lv23. Burned the last 2 Flamethrower PP on Roselia+Bayleef, then had to cheese Skiploom (no attacking moves, just Leech Seed + Cotton Spore + Worry Seed + Sleep Powder) with a slow Rock Smash grind from Monferno.
  - **Defeated Gardenia** (Leader, map 67): 6-mon team **Bellossom Lv25 → Roserade Lv26 → Tangela Lv25 → Cherrim Lv25 → Breloom Lv25 → Grotle Lv25**. Bellossom had Wide Lens + Stun Spore (paralyzed Monferno T1 — that's what ultimately let Roserade Sludge-crit Monferno to 0 next fight). Roserade had Sitrus Berry + Technician + Extrasensory (which hits Monferno Fire/Fighting for 2x!) + Dazzling Gleam — **Fighting-type answer is very thin now that Roserade has Psychic + Fairy coverage**. Cherrim had Focus Sash + Sunny Day setup. Breloom Lv25 (Grass/Fighting) dies 4x to Gust but also has Thunder Punch 2x on Mothim Flying — very close call. Grotle pure Grass (not dual-type in RP), Leftovers + Protect, OHKO by Bug Buzz once Protect broke. Mothim grew **Lv26 → Lv29** on the Gardenia XP haul.
  - **TM86 confirmed = Grass Knot** in RP (per Gardenia's post-battle dialogue). My session-13 note that called this "TM86 Dazzling Gleam" was wrong — TM85 is Dazzling Gleam, TM86 still = Grass Knot. CLAUDE.md section "TM Changes and Gym Leader Rewards" was correct all along.
  - **Eterna Gym floral clock**: confirmed the dialogue flavor — **the clock hand rotates on each trainer defeat**, unlocking the next trainer's arm. Gym Guide's "You can go to Pokemon Center during your challenge" works — the south-exit warp (11, 27) stays reachable once you step off the clock back onto the L1 floor.
  - **BUG-017 discovered** — `navigate_to`/`interact_with` teleport the player to the east clock arm at (15, 13) every time when trying to path *across* the clock tiles, regardless of start position or destination. Manual `press_buttons` is the only way to move between arms/hub once you're on `2`/`3`/`/`/`\` tiles. Details in BUG_LOG.md. 
  - **BUG-018 discovered** — mid-battle MOVE_LEARN response's `learning_pokemon` and `current_moves` fields report the party-slot-0 Pokemon (Monferno, fainted) instead of the actually-leveling Pokemon (Mothim at party slot 2). Triggered via Mothim 28 → 29 on Grotle KO. Looks related to the BUG-014/015 persistent-slot vs UI-slot family; the MOVE_LEARN path likely wasn't updated when `battle_ui_slot` / `battle_role` were added.
  - **`heal_party` auto-navigates perfectly** from Eterna City (map 65) → PC (map 69) → nurse dialogue → heal → same flow used to leave the gym for a mid-challenge restock. `buy_item("Super Potion", 8)` **also** auto-navigates from the overworld into the mart, to the correct cashier, and executes — great tool coverage moment.
- **Next session start**:
  1. Load **`session15_end_post_double_grunts_eterna_hq`** (battered, mid-raid in T.G. Eterna Bldg). Or `session15_post_grunt_ledian_ariados` for a cleaner mid-session resume (one fight earlier, party at similar HP but before the Toxic-spikes/paralysis mess).
  2. **Immediately retreat south** from the HQ: south warp at (11, 15) → Eterna City map 65 → `heal_party()` to auto-nav the PC (healed in session 14 from same position, so `heal_party` is battle-tested). Cure Paralysis + Toxic + HP.
  3. **Restock at Eterna Mart**: buy **Parlyz Heal x5+** (crucial — 2 paralysis per double-battle has been common) and more Super Potions (currently 9, should be fine). `buy_item` on the overworld auto-navs now (exercised session 14).
  4. **Return to T.G. Eterna Bldg (305, 519)** and take the **OTHER stair — (20, 6)**, NOT (14, 6). Looker (disguised as a "Grunt F" object at (18, 8)) hinted 2 stairs = 1 trap. Session 15 took the left one (14, 6) → map 73 dead-end loop (4 stairs all same map, the only way up was going back). **Prediction: (20, 6) is the correct stair** — but verify before committing.
  5. **Goal of the raid arc**: find the manager of the Cycle Shop (dialogue said he's "at the Team Galactic building and hasn't returned"). Once he's freed, he returns to the Cycle Shop, and talking to him opens **Route 206 Cycling Road** — the actual path to Hearthome. (Session 15 confirmed the south-of-Eterna warp at (315, 548) goes to a residential building chain, NOT Cycling Road.)
  6. **Actual Eterna → Hearthome path** (revised from session 14's wrong guess): **Route 206 Cycling Road south** → Route 207 → Route 208 → Hearthome. Route 211 East is **blocked** until post-game (Collector at (445, 526) demands SlowpokeTail "for $1,000,000" — permanent hard gate).
  7. **Consider routing order**: the Grunt at (305, 520) who blocks Galactic HQ entrance respawned after Forest Badge and dropped the post-Jupiter flag — he's a new story trigger and is now defeated (Ledian Lv24 + Ariados Lv24 team). Similar respawns likely on the 2nd floor.
  8. **Vaporeon leveling update**: Exp. Share got her to Lv21 in one session from Lv17 — Aurora Beam Ice coverage is now useful. Keep Exp. Share on Vaporeon.
  9. **Monferno Flamethrower PP = 1/15** — critical for the HQ raid. Either PC-heal restores PP (yes, heal_party refills PP too) or use Rock Smash as chip until Flamethrower restored. Post-heal should be fine.
  10. **Fighting-type weakness note** still applies — Roserade-style Psychic/Fairy coverage wrecks Monferno at Lv32+. Rely on Vaporeon Aurora Beam + Mothim Bug Buzz for bulk of damage.
- **Open QA bugs after this session**:
  - **BUG-019 NEW** — Double-battle logs duplicate "fainted" and "gained N Exp. Points" lines (cosmetic). Repro: `session15_galactic_bldg_pre_stairs` → right-stair double-grunt fight.
  - **BUG-020 NEW** — `view_map` `object.name` reports sprite class, not battle class. Route 211 W "Ace Trainer F" trainer_id 76 is actually a Bird Keeper in battle. Cosmetic but affects matchup planning. Repro: `session15_route211_west_entry`.
  - **BUG-021 NEW** — `view_map` shows non-battleable flavor NPCs as `trainer=true defeated=true` on FIRST entry to a never-visited map (Route 211 W "Hiker" trainer_id 326, only gives flavor dialogue). Repro: `session15_route211_west_entry`.
  - **BUG-017 (Eterna Gym clock)** and **BUG-018 (MOVE_LEARN wrong-mon)** still FIXED — no repros this session. MOVE_LEARN on Vaporeon Lv18→19 Aurora Beam correctly reported `learning_pokemon: {slot: 1, name: "Vaporeon"}`, and all Eterna Gym nav this session (entering/exiting the building) worked.
  - **BUG-013, BUG-014, BUG-015, BUG-016** still holding FIXED — heavy mid-battle switching during double grunts, level-ups in double battle, cold-start load all fine.
  - **BUG-007, BUG-009** still open, untriggered this session.
  - **Stale party read in `battle_turn` response's `party` field** (minor, not filed) — during Ninja Boy Zach fight, after Vaporeon leveled Lv17→Lv18, subsequent battle_turn responses still showed `party: [{slot:1, name:"Vaporeon", level:17}]` for the rest of the double-enemy chain. Full `read_party` post-battle showed correct Lv18. Same family as BUG-018 (stale battle-context Pokemon slot data). Not filed — BUG-018 is the canonical ticket for this class.
  - **MOVE_LEARN `learning_pokemon.level` off-by-one** (minor, not filed) — at Vaporeon Lv18 → Lv19 learn-Aurora-Beam prompt, `learning_pokemon.level` returned **18** (pre-level-up value), but the in-game text said "Vaporeon grew to Lv. 19!" immediately before. Cosmetic — not worth a bug ticket unless it repros more broadly.
  - **Collector gate on Route 211 East (by design, not a bug)** — NPC at (445, 526) demands SlowpokeTail for $1,000,000; rejects any decline and hard-blocks east passage toward Celestic. No map signage warns about this. Consider FR for a dialogue hint or map note.
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
- **Session 14 highlights**:
  - **Forest Badge obtained.** Gardenia cleared in a single gym trip (one Eterna-PC restock mid-run).
  - **BUG-017 discovered** — Eterna Gym floral-clock tiles break `navigate_to` pathing; player teleports to (15, 13) east arm regardless of target. Manual `press_buttons` workaround.
  - **BUG-018 discovered** — MOVE_LEARN wrong-pokemon bug at Mothim 28→29 (reported Monferno as the learning mon).
  - **Mothim is now the team carry**: Bug Buzz 90 BP Special STAB upgraded from Bug Bite at Lv26. 2x SE on pure Grass, 4x SE Gust on Grass/Fighting Breloom. Lv29 by end of run.
  - **Monferno sustained a KO** vs Roserade crit — first gym leader loss in this QA run. Not a whiteout since Mothim was the MVP clean-up.
  - **`heal_party` + `buy_item` overworld auto-nav chain** worked perfectly for mid-challenge restock (Eterna Gym → PC → Mart → back). Good dogfooding.
- **Session 15 highlights**:
  - **Exp. Share moved Mothim → Vaporeon** as planned (`take_item(2)` + `give_item("Exp. Share", 1)`) — Vaporeon went **Lv17 → Lv21** this session on Exp. Share alone. Learned **Aurora Beam at Lv19** (forgot Covet). Big power-up.
  - **Wrong-route detour exposed**: session 14's "Route 211 East → Hearthome" plan was incorrect. Route 211 East is hard-gated by the Collector at (445, 526) demanding SlowpokeTail — permanent block until post-game. Actual Eterna → Hearthome path is **Cycling Road (Route 206) south**, which is itself gated until the Cycle Shop manager returns. Session 14's note "bike shop is open (already triggered)" was wrong too — the shop employee confirmed the manager is still missing at the Galactic Bldg.
  - **NEW story arc discovered: post-Forest-Badge Grunt at (305, 520) Eterna** — triggered a Ledian Lv24 + Ariados Lv24 fight, then his post-battle dialogue ("I must inform Commander Jupiter...") opened the T.G. Eterna Bldg door. **Implies a 2nd raid of the Galactic HQ is required to free the Cycle Shop manager and unlock Route 206.** This was not mentioned in CLAUDE.md's story guide.
  - **Entered T.G. Eterna Bldg raid** — ground floor has Looker in disguise (as "Grunt F" at (18, 8)) hinting "2 stairs, 1 is a trap". Took left stair (14, 6) → map 73 floor 2 L1 with 4 warps all labeled "T.G. Eterna Bldg" — dead-end loop (Pokeball pickup only, TM73 Thunder Wave). Next session try the right stair (20, 6).
  - **Right-stair floor is the real one**: had a Grunt×2 double battle at (19, 8) — Koffing + Ekans → Nidoran♂ + Nidoran♀ → Stunky + Glameow. Burned through our party's status bars (both active mons paralyzed + Mothim badly poisoned). Great dogfood for double-battle mechanics but **left the party heavily battered**. BUG-019 discovered (duplicated fainted/Exp lines in double-battle logs).
  - **Items gained this session**: TM12 Taunt (R211W), TM69 Rock Polish (MtCoronet), Escape Rope (MtCoronet), Fire Stone (R211E), TM73 Thunder Wave (T.G. Bldg F2).
  - **BUG-019, BUG-020, BUG-021 filed** — all cosmetic/minor, all view_map/log display issues, none blocking progress.
  - **BUG-017, BUG-018 untriggered this session** and still FIXED.
  - **Ended mid-raid** — session 16 starts with a retreat-to-heal, restock (Parlyz Heal especially), and re-entry via the CORRECT (20, 6) stair to continue the HQ.

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
