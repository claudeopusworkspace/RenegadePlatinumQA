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
- **Money**: **$15,484** (verified via `read_trainer_status`).
- **Location**: **Eterna City Cycle Shop interior** (map 71) at (7,11). Just entered through the south door from Eterna City map 65. Haven't talked to the Bike Shop owner yet. Cleanest resume point: **`eterna_cycle_shop_entered`** (just inside, ready to interact with owner). Alternative: **`eterna_city_arrived_post_forest`** (just arrived at Eterna from Route 205 forest exit, at (297,525) map 65, no actions taken yet). Backup: **`forest_exit_route205_north_post_cheryl`** (just exited Eterna Forest at (259,524) map 349, Cheryl gone).
- **Party** (all full HP, Cheryl auto-healed repeatedly in forest):
  1. **Monferno** Lv29 (Quirky, Blaze) — Low Kick (20/20) / Flamethrower (15/15) / Fake Out (10/10) / Rock Smash (15/15). 88/88 HP.
  2. **Vaporeon** Lv17 (Serious, Water Absorb) — Water Pulse / Quick Attack / Bite / Covet. 76/76 HP. **(+1 level from Psychic Elijah Drowzee/Baltoy fight.)**
  3. **Mothim** Lv21 (Naive, **Swarm**, formerly Burmy Shed Skin) **holding Exp. Share** — Protect / **Gust** (replaced Tackle at Lv20) / Bug Bite / Hidden Power (Rock type per IV math). 64/64 HP. **Evolved from male Burmy at Lv20.**
  4. **Shinx** Lv6 (Timid, Guts) — Tackle / Leer / Howl / Quick Attack. 21/21 HP. (Still parked; per feedback memory, don't detour to PC just to deposit.)
- **Key Items**: Bicycle, Poké Radar, Journal, Vs. Recorder, Town Map, Pokétch (all apps), Fashion Case, HM06 Rock Smash (on Monferno), Coal Badge, Works Key. No new key items.
- **Bag** — new this session:
  - Medicine: **+1 Antidote** (Eterna Forest (15,81)), **+1 Parlyz Heal** (Eterna Forest (41,59)).
  - TMs & HMs: **+TM27 (×99, Cheryl's gift at forest exit — RP policy: 99-count, unsellable, $0).**
  - Items: unchanged.
  - Repels: **-1 Repel** (used on Route 205 N this session, now 9).
- **Story flags** (new this session in bold):
  - All priors still valid.
  - **Defeated Cheryl solo test-trainer cleanly** (no mid-battle save needed). Strategy: Flamethrower Drifloon OHKO → Low Kick crit Wailmer OHKO → Flamethrower crit Makuhita OHKO (Monferno Lv27→28) → Low Kick Chansey SE OHKO. Cheryl joined as partner.
  - **Cleared Eterna Forest (map 203) entirely**: Bug Catcher Jack + Lass Briana double trainer (Surskit Lv16/Paras Lv16/Venonat Lv16 + Buneary Lv17/Marill Lv17/Slakoth Lv15). Then two *solo* Psychic trainer battles (Cheryl-less despite her being partner — note that separate trainers trigger singles, not every forest fight is a double): Psychic Lindsey (Slowpoke Lv17 / Natu Lv17 / Exeggcute Lv17) and Psychic Elijah (Spoink Lv17 / Drowzee Lv17 / Baltoy Lv17). Plus 2 wild doubles (Paras+Buneary, Slakoth+Buneary).
  - **Burmy → Mothim at Lv20** during the double battle. Taught Gust, replaced Tackle.
  - **Received TM27 from Cheryl** at forest exit (86,36) Eterna Forest. Her farewell cutscene: "Oh! There's the exit!" / "Thank you so much!" / gift / "I'm sure we'll meet again somewhere!".
  - **Arrived in Eterna City (map 65)** via Route 205 (map 349) → Eterna City warp at (296-297, 525).
  - **Entered Cycle Shop (map 71)** via door at (310, 539). Haven't talked to the Bike Shop owner yet.
- **Next session start**:
  1. Load **`eterna_cycle_shop_entered`** (inside Cycle Shop, one step in from the south door).
  2. Find & talk to the Bike Shop owner to re-open **Route 206** (RP gate). Then exit shop back to Eterna City.
  3. **Grab HM01 Cut from Cynthia** — she's somewhere in Eterna City near Eterna's east side (vanilla: Cynthia's Grandma's house, check for her there).
  4. **Heal at Eterna PC** and stock Potions. Team is fine post-Cheryl but we'll need to top up PP for Gardenia.
  5. **Pick up Porygon Lv22** from the Galactic Building (map 65 warp at (305,519) "T.G. Eterna Bldg") — but that requires defeating Jupiter first. Defer until Gardenia done.
  6. **Challenge Gardenia (Gym 2, Grass-type)** — reward TM86 Grass Knot. Her signature is Roserade in RP. Monferno Flamethrower will cook her. Watch for Dustox (Grass-free Bug/Poison) and Gloom variants.
  7. Consider PC-dumping Shinx *if* we naturally visit a PC anyway. No detour.
  8. Optional: grab Chatot "Macaw" in-game trade at Eterna (give Snorunt, get Chatot, Modest, Sharp Beak) — but we have no Snorunt so skip unless we catch one later.
- **Open QA bugs after this session**:
  - **BUG-007** still open (post-battle token elision on Roark-class reward dialogue). Not re-triggered this session.
  - **BUG-008 FIXED (verified again)** — 2 more clean item pickups this session (Antidote, Parlyz Heal). Fix holds strong.
  - **BUG-009** still open (`[01E0][01E1] Trainer Cheryl` prefix leak). **Confirmed class-specific** this session — Psychic Lindsey, Psychic Elijah, Bug Catcher Jack, Lass Briana all parse CLEAN ("Psychic Lindsey is about to send in Natu.", "Player defeated Psychic Elijah!", etc.). Only Cheryl's lines leak the `[01E0][01E1]` prefix, suggesting the code family is specific to the "Pokémon Trainer" class label rendering (not all trainer classes).
  - **BUG-010 NEW (this session)** — `read_party` garbled `max_hp` for PC-round-tripped slot 3 (Shinx) on fresh savestate load. **Transient** — clears after first battle transition. See BUG_LOG.md.
  - **BUG-011 NEW (this session)** — orphan Pokémon-name / trainer-class lines appear in `battle_turn` log entries around level-up and battle-end text sequences. Cosmetic but systematic. See BUG_LOG.md.
  - **Possible BUG-004 echo** (carried forward from session 7, still unverified).
- **FR docket**: FR-003, FR-004, FR-005 still open. No new FRs filed this session. FR-005 (doubles target clarity) continues to work cleanly.
- **Session 9 highlights**:
  - **Mothim** is now a legitimate party member post-Lv20-evo. Swarm + Gust STAB + HP Rock coverage. Still slot 3 for EXP Share though.
  - **view_map / map_name became desync'd** briefly after loading `eterna_forest_entered_south` — returned "Oreburgh Gate (0,0)" for several calls before correctly showing Eterna Forest. Cleared up after my first interaction with the world (walking on a warp + map transition). Didn't file a bug yet — one-off, needs more reproductions to characterise.
  - Cheryl's **partner auto-heal** also fires after battles where she did *not* participate (e.g. the two Psychic singles). Very generous.
  - **Wild doubles with Cheryl** were fun and fast — Chansey's Hyper Voice hits both enemies in doubles (spread move).
  - Chained fleeing + Repel worked cleanly on Route 205 N wild encounters.

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
