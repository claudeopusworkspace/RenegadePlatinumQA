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

Game-specific tools are provided by the `renegade` MCP server (defined in `renegade_mcp/`). These run alongside the generic `melonds` MCP server. All tools connect to the emulator via the bridge socket - if the emulator isn't initialized yet, they return a clear error.

| Tool | Purpose |
|------|---------|
| `read_party` | Party Pokemon: species, level, HP, moves, PP, nature, IVs, EVs, **shiny** flag. Three-tier encryption handling: flag-based, opposite-flag fallback, and mixed-state split-point recovery for mid-encrypt/decrypt frames. Shiny detection: `(TID ^ SID ^ PID_hi ^ PID_lo) < 128` (Renegade Platinum 1/512 rate). Works reliably in any game state. |
| `read_battle` | Live battle state: all battlers with stats, moves, ability, types, status, **shiny** flag (from BattleMon isShiny bit) |
| `read_bag(pocket="")` | Bag contents across all 7 pockets. Optional pocket filter. |
| `view_map(level=-1)` | **Player-centered viewport**: 32x32 ASCII map centered on the player, loading adjacent chunks as needed on overworld maps. Indoor/small maps use compact content-fitted rendering (no void padding). Header includes `origin:(x,y) WxH` - the global coordinate of the top-left grid corner and viewport dimensions. Convert any grid position to global coords: `global = origin + grid_pos`. Player dict includes `grid_x`/`grid_y` for the player's position in the grid. Warp coordinates can be passed directly to `navigate_to`. **Objects sorted by distance**: nearest objects/NPCs appear first in the list (Manhattan distance from player). **Trainer defeated status**: trainer NPCs show `[defeated]` in label, plus `trainer_id` and `defeated` fields (reads VarsFlags bitfield from save RAM). Works for regular trainers; gym leaders/rivals use separate story flags. **Elevation-aware**: on 3D maps, passable tiles show height level numbers (0-9), ramps show `\ /`, bridges show `n*`, directional blockers show `] [`, with an elevation summary listing all levels and the player's current height. Pass `level=N` to filter to a single elevation level (other tiles dimmed to `~`). Flat maps render unchanged. Uses BDHC data from ROM land_data files. |
| `map_name(map_id=-1)` | Location name lookup. Defaults to current map. |
| `navigate(directions, flee_encounters)` | Manual walk: "d2 l3 u1". Validates path before moving; auto-trims at door/stair/warp transitions. Returns `encounter` key if battle/dialogue detected. **`flee_encounters=True`**: auto-flees wild battles and resumes remaining directions. Trainer battles and cutscenes still halt. |
| `navigate_to(x, y, path_choice, flee_encounters)` | BFS pathfind to target tile. **Sign-aware**: reads sign positions from ROM zone_event data (gfx IDs 91-96) and blocks the activation tile (one south of each sign) in BFS to prevent auto-trigger dialogue. **Elevation-aware**: on 3D maps (gyms, caves, AND multi-chunk overworld routes with bridges/cliffs), uses hierarchical BFS - constrains search to current elevation level and brute-forces through ramp transitions when target is on a different level. Multi-chunk maps load BDHC per chunk with unified height->level mapping. Depth-capped (5 transitions) with 5-minute timeout. Enforces directional blocks (0x30/0x31). Falls through to 2D BFS for flat maps only. **Obstacle-aware**: runs dual BFS (clean vs obstacle path). When HM obstacles (Rock Smash rocks, Cut trees) shorten or enable a path, returns `obstacle_choice`/`obstacle_required` status without moving - call again with `path_choice="obstacle"` or `"clean"`. Strength boulders never auto-cleared. Handles all 14 warp tile types. Water/waterfall/rock climb terrain recognized but deferred. Returns `encounter` key if battle/dialogue detected. **`flee_encounters=True`**: auto-flees wild battles and re-BFS's from current position. Trainer battles (detected by pre-battle dialogue) and cutscenes halt for the caller. Returns `flee_log` with species/attempts. **Adjacent target**: when the target tile is occupied by an NPC/entity, stops one tile away and returns `adjacent_to_target: true` with target coordinates - no wasted repaths. **Failure diagnostics**: on "no path found," returns a 9x9 ASCII `diagram` centered on the target (`@`=player, `X`=target, `*`=nearest reachable, `#`=wall, `.`=passable, `N`=NPC, `~`=water) plus `nearest_reachable` with global coords and distance. |
| `interact_with(object_index, x, y, flee_encounters)` | Navigate to a map object/NPC by index OR static tile by (x,y) and interact. Handles adjacent tiles, counter NPCs, facing, and dialogue. **Auto-advances** through full multi-page dialogue (chains into `advance_dialogue`). Detects trainer-spotted interruptions and checks for battle transitions post-dialogue. **Sign overlay support**: signpost text (board messages that bypass msgBox) is captured via memory scan and dismissed automatically - returns `sign_overlay: true`. **`flee_encounters=True`**: auto-flees wild battles encountered during the walk to the target. |
| `seek_encounter(cave=false)` | Pace in grass until wild encounter. Returns at first action prompt with full battle state. `cave=true` for non-grass encounters. |
| `read_dialogue(advance=true)` | Auto-advance through dialogue, collect full conversation. Stops at Yes/No prompts and multi-choice prompts. `advance=false` for passive read. |
| `battle_turn(move_index, switch_to, run, force)` | Full automated turn: FIGHT + move, POKEMON + switch, or RUN to flee. **Type effectiveness guardrail**: checks move type vs target types before executing. Returns `EFFECTIVENESS_WARNING` if move is immune or NVE - call again with `force=True` to proceed. Returns battle log + state + trimmed battle summary (species, level, hp, types, status, stages, moves name+pp; enemy gets ability+item). |
| `throw_ball` | Throw a Poke Ball in wild battle: BAG + ball select + USE + catch result |
| `reorder_party(from_slot, to_slot)` | Swap two party Pokemon via pause menu (overworld only) |
| `decode_rom_message(file_index)` | Decode ROM message archive (species, moves, items, etc.) |
| `search_rom_messages(query)` | Search all 724 message files for text |
| `use_item(item_name, party_slot)` | Use a Medicine item on a party Pokemon from overworld. Reads bag cursor state to handle remembered positions. |
| `use_field_item(item_name)` | Use a no-target field item (Repel, Escape Rope, Honey, etc.) from the Items pocket. Pre-validates `fieldUseFunc` from ROM data - rejects hold-only items (Silk Scarf, etc.). Handles BAG_MESSAGE items (Repel/Flutes), Escape Rope (warp animation), and Honey. |
| `use_medicine(confirm, exclude_items, priority)` | Bulk heal party using Medicine pocket items. Dry-run by default - returns a plan showing which items will be used on which Pokemon. Call with `confirm=True` to execute. Uses lowest-tier potions first (saves better items for battle), prefers specific status cures over general ones (Antidote before Full Heal), uses Full Restore when a Pokemon needs both status cure + HP. Revives fainted Pokemon. Optional `exclude_items` list and `priority` slot order. |
| `take_item(party_slot)` | Remove held item from a party Pokemon via pause menu (overworld only) |
| `give_item(item_name, party_slot)` | Give a held item to a party Pokemon via pause menu (overworld only). Pokemon must not already hold an item. Reads bag cursor state to handle remembered positions. |
| `heal_party` | Heal at Pokemon Center. Works from inside a PC (direct) or city overworld (auto-navigates to PC via warp lookup). Returns encounter data if interrupted during navigation. |
| `open_pc` | Boot up the PC: finds 0x83 tile, navigates, interacts, advances to storage menu (DEPOSIT/WITHDRAW/MOVE/SEE YA!). |
| `deposit_pokemon(party_slots)` | Deposit party Pokemon into Box 1. Takes list of 0-indexed slots. Multi-deposit supported. Must call open_pc first. |
| `withdraw_pokemon(box_slots)` | Withdraw Pokemon from Box 1 to party. Takes list of 0-indexed box slots. Multi-withdraw supported. Must call open_pc first. |
| `read_box(box=1)` | Read all Pokemon in a PC box from RAM. No UI needed - works anytime. Returns species, moves, nature, IVs, EVs, held item, **shiny** flag. |
| `close_pc` | Exit the PC from storage menu and return to overworld. |
| `read_trainer_status` | Read money and badges from memory. No UI needed. |
| `read_shop` | Read PokeMart inventory for current city. Badge-gated common items + city specialty items with ROM prices. Pure lookup, no UI. |
| `buy_item(item_name, quantity)` | Buy from a standard PokeMart. Works from inside the mart (FS room) or city overworld (auto-navigates to mart via warp lookup). Finds correct cashier (common vs specialty), scrolls to item by ROM-calculated position, purchases, exits. Pre-checks money. Returns encounter data if interrupted during navigation. |
| `teach_tm(tm_name, party_slot, forget_move)` | Teach a TM/HM to a party Pokemon. Accepts TM label ("HM06", "TM76") or move name ("Rock Smash"). Pre-validates ROM compatibility (personal.narc bitmasks) and badge+move availability. Handles both <4 moves (auto-learn) and 4 moves (forget prompt) flows. Pass `forget_move` (0-3) when Pokemon knows 4 moves, or -1 to cancel. |
| `tm_compatibility(tm_name)` | Check which party Pokemon can learn a given TM/HM. Pure ROM data lookup - no emulator interaction. Returns ABLE/UNABLE/ALREADY KNOWS per party slot. |
| `type_matchup(attacking_type, defending_types, move_name)` | Type effectiveness check (like Pokemon Showdown's calc). Pass `attacking_type="Fire"` + `defending_types="Grass/Steel"`, or `move_name="Spark"` + `defending_types="Water/Flying"`. Returns multiplier + label. Gen 4 chart + Fairy type. |
| `move_info(move_name)` | Move stats lookup: type, power, accuracy, PP, class (Physical/Special/Status), priority. Pure ROM data, no emulator needed. Also: `read_party` and `read_battle` now show move details inline (e.g. `Bullet Seed [Grass - Physical - 25 pwr - 100% acc]`). |
| `auto_grind(move_index, cave, target_level, iterations, forget_move, target_species, backup_move, heal_x, heal_y, grind_x, grind_y, max_heal_trips, flee_ineffective)` | Automated encounter loop: seek encounters + fight (spam a move) or run. **Smart move selection**: swaps to `backup_move` when primary is NVE/immune; flees when both are ineffective (`flee_ineffective`). **Auto-heal loop**: when `heal_x/heal_y/grind_x/grind_y` are set, auto-heals at Pokemon Center on faint/PP depletion instead of stopping. See Auto Grind Workflow below. |

Key ROM file indices: 0392=items, 0412=species, 0610=abilities, 0647=moves, 0433=locations, 0646=move descriptions.

## Navigation

**CRITICAL: Do not rely on screenshots for spatial reasoning in the overworld.** The isometric/overhead camera makes it very difficult to judge tile positions, room boundaries, and exits from pixel images. Instead:

- **Use `view_map`** to get a full map with terrain, player, NPCs, and **warp destinations** - all read live from the emulator. The `warps` list shows every door/stair exit with its destination name and tile coordinates.
- **Use warp coordinates from `view_map` with `navigate_to`** to enter buildings - the (x, y) from a warp entry can be passed directly to `navigate_to` for seamless transitions.
- **Use `navigate` or `navigate_to`** to walk paths - they verify each step and stop on collision. `navigate` auto-trims paths at door/stair transitions. `navigate_to` auto-enters adjacent walk-into doors (0x69, 0x6E).
- **When stuck navigating, ask Michael for visual help** rather than brute-forcing positions.
- Screenshots are fine for reading dialogue, menus, and battle screens - just not for spatial navigation.
- **Position dicts** (start/final in navigate responses) include full map name info (`map_id`, `name`, `display`, `code`, `room`) instead of a bare map ID. No need to call `map_name` separately.

## Game State Tools

**Use these tools instead of navigating in-game menus** - faster, more reliable, no accidental inputs.

- **`read_party`** - full party data from RAM. Works in overworld + battle.
- **`read_bag`** - all 7 bag pockets. Pass `pocket="Key Items"` to filter.
- **`read_battle`** - live battle data for all active battlers. Returns empty if not in battle.
- **`map_name`** - location name from map ID. No args = current map.
- **`read_dialogue(advance=true)`** - auto-advances through overworld dialogue, collecting the full conversation. Stops at Yes/No prompts (returns `status: "yes_no_prompt"`), multi-choice prompts (`status: "multi_choice_prompt"`), or dialogue end (`status: "completed"`). Pass `advance=false` for passive read. Pass `region="battle"` with `advance=false` for battle text.
- **`read_shop`** - PokeMart inventory for current city. Detects city from map code prefix (works inside buildings).
- **`decode_rom_message(file_index)`** / **`search_rom_messages(query)`** - ROM data lookup (no emulator needed).

## Battle Workflow

### Automated (preferred)
1. **`read_battle`** - check enemy species, types, ability, stats, moves. Plan tactics. Returns all 4 battlers in double battles. Use **`type_matchup`** to check effectiveness before committing.
2. **`battle_turn(move_index=N)`** - use a move (0-3). **Checks type effectiveness first** - returns `EFFECTIVENESS_WARNING` if the move is immune or not very effective against the target. Call with `force=True` to proceed anyway (e.g., status moves, chip damage, or when no better option). Returns battle log + final state + updated battle state.
   - Or **`battle_turn(switch_to=N)`** - switch to party slot N (0-5) instead of attacking.
   - Or **`battle_turn(run=True)`** - attempt to flee a wild battle. Returns `BATTLE_ENDED` on success, `WAIT_FOR_ACTION` on failure (enemy gets a free turn).
   - In **double battles**, add `target=` to specify the target: `0`=first enemy (slot 1), `1`=second enemy (slot 3), `2`=self/ally. Default `-1` auto-targets first enemy.
   - Works on the very first turn of battle - no need to call twice.
3. Handle the returned state:
   - `EFFECTIVENESS_WARNING` - move is immune or not very effective. Review the warning, then either pick a different move/switch, or call `battle_turn(move_index=N, force=True)` to use it anyway. No game state has changed yet.
   - `WAIT_FOR_ACTION` - next turn, call `battle_turn` again. Battle state is included in the response.
   - `WAIT_FOR_PARTNER_ACTION` - double battle: first Pokemon's action submitted, call `battle_turn` again for second Pokemon.
   - `SWITCH_PROMPT` - trainer sending next Pokemon. Call `battle_turn(switch_to=N)` to swap, `battle_turn()` to keep battling, or `battle_turn(move_index=N)` to decline the switch and use that move in one call.
   - `FAINT_SWITCH` - your Pokemon fainted (wild battle). Call `battle_turn(switch_to=N)` to send replacement, or `battle_turn()` to flee.
   - `FAINT_FORCED` - your Pokemon fainted (trainer battle). Call `battle_turn(switch_to=N)` to send replacement (required).
   - `MOVE_BLOCKED` - move was rejected by Torment, Disable, Encore, Taunt, or Choice item lock. No turn consumed, still at action prompt (in move selection submenu). Pick a different move or switch.
   - `BATTLE_ENDED` - back in overworld. **Auto-advances post-battle dialogue** (trainer defeat text, story triggers) if present - returned as `post_battle_dialogue` list. **Handles full party wipe**: auto-advances through blackout sequence + Nurse Joy dialogue, returns with `blackout: true` and player free in Pokemon Center. No manual `read_dialogue` needed.
   - `MOVE_LEARN` - Pokemon wants to learn a new move. Response includes `move_to_learn` (the new move name, read directly from memory) and `current_moves` with slot indices. Call `battle_turn(forget_move=N)` to forget move N (0-3) and learn the new move, or `battle_turn(forget_move=-1)` to skip. Works in both trainer and wild battles.
   - `NO_ACTION_PROMPT` - action prompt never appeared (~30 sec timeout). Game may need manual input.
   - `TIMEOUT` - something unexpected. If actually in the overworld (not in battle), auto-checks for dialogue and upgrades to `BATTLE_ENDED`. Otherwise, screenshot + `read_battle` to diagnose.
   - `NO_TEXT` - something unexpected. Screenshot + `read_battle` to diagnose.

Note: `battle_turn` includes `read_battle` data in every response - no separate call needed.

## Auto Grind Workflow

`auto_grind` automates wild encounter loops. Stand in a grass/cave area.

When `move_index` is provided, fights each encounter by spamming that move (grind mode).
When `move_index` is omitted, runs from each encounter (seek mode).
When `target_species` is set, stops at the action prompt when that species appears.

### Basic call
```
auto_grind(move_index=0)                    # spam move slot 0, grind indefinitely
auto_grind(move_index=2, target_level=15)   # stop at Lv15
auto_grind(move_index=1, cave=true)         # cave encounters
auto_grind(move_index=0, iterations=5)      # stop after 5 encounters (scouting)
auto_grind(move_index=0, iterations=10, target_level=20)  # whichever comes first
auto_grind(target_species="Machop")         # run from everything until Machop appears
auto_grind(move_index=0, target_species="Larvitar")  # grind, but stop if Larvitar appears
auto_grind(move_index=3, backup_move=2)     # alternate moves when Tormented/Disabled
```

### Smart move selection
When `backup_move` is set, checks type effectiveness per encounter:
- Primary move effective (mult > 0.5) -> use primary as normal
- Primary NVE/immune, backup effective -> use backup for that battle
- Both NVE/immune + `flee_ineffective=True` -> flee, continue to next encounter
- Both NVE/immune + `flee_ineffective=False` -> fight with primary anyway (default)

### Auto-heal loop
When `heal_x/heal_y/grind_x/grind_y` are all provided, auto-heals on faint or PP depletion
instead of stopping. Navigates to town, heals at Pokemon Center, returns to grind area.

- `heal_x, heal_y`: Tile on the city/town map to navigate to before healing. `heal_party` auto-finds the PC.
- `grind_x, grind_y`: Tile to return to after healing. Must be reachable from the city map.
- `max_heal_trips`: Safety cap (default 10).

### Stop conditions (returned as `stop_reason`)
| Reason | Meaning | What to do |
|--------|---------|------------|
| `target_level` | Slot 0 reached the target level. | Done! |
| `shiny` | Wild shiny Pokemon encountered. At action prompt. | Catch it! |
| `target_species` | Found the target species. At action prompt. | Fight, catch, or flee. |
| `iterations` | Completed the requested number of encounters. | Review encounter log. |
| `fainted` | Slot 0 fainted (only when auto-heal is disabled). | Heal, then grind again or switch lead. |
| `pp_depleted` | Spam move has 0 PP (only when auto-heal is disabled). | Handle manually. |
| `move_learn` | Pokemon wants to learn a move but all 4 slots are full. | Call `auto_grind` again with `forget_move`. |
| `move_blocked` | Primary move blocked, no `backup_move` set. | Provide `backup_move` or handle manually. |
| `turn_limit` | Battle exceeded 10 turns without ending. | Likely tanky opponent. |
| `heal_failed` | Auto-heal navigation or healing failed. | Check position, navigate manually, retry. |
| `max_heal_trips` | Reached the safety cap on heal cycles. | Increase cap or investigate. |
| `seek_failed` | `seek_encounter` didn't find a battle. | Investigate manually. |
| `unexpected` | Unknown battle state. | Screenshot + `read_battle` to diagnose. |

### Continuing from move_learn
When stopped for `move_learn`, the response includes `move_to_learn` and `current_moves` (with slot indices). Resume with:
```
auto_grind(move_index=0, forget_move=2)     # forget move slot 2, learn the new move, keep grinding
auto_grind(move_index=0, forget_move=-1)    # skip learning, keep grinding
```
All other parameters (cave, target_level, iterations) should be re-supplied when resuming.

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

Saved macros persist across sessions in macros/.

| Macro | Description |
|-------|-------------|
| `mash_a` | Press A 5 times (8-frame holds, 30-frame waits) for dialogue |
| `mash_b` | Press B 5 times (8-frame holds, 30-frame waits) - safer than A |
| `walk_up` | Walk up 2 tiles (32-frame hold + 4-frame wait) |
| `walk_down` | Walk down 2 tiles |
| `walk_left` | Walk left 2 tiles |
| `walk_right` | Walk right 2 tiles |

## Game Progress

*Start from scratch. Update this section as you play.*

- **Character**: (to be named)
- **Badges**: 0
- **Location**: New game
- **Party**: (empty)

## Quick Reference: Common Workflows

### Entering a new area
1. `view_map` - see the map layout, NPCs, exits, and **warp destinations** with coordinates
2. `navigate_to(x, y)` - use warp coordinates from `view_map` to enter buildings directly

### Before/during battle
1. `read_battle` - enemy species, types, ability, stats, moves, HP
2. `battle_turn(move_index=0)` - use a move. Returns battle log + state + updated battle data.
3. Or `battle_turn(switch_to=1)` - switch Pokemon instead of attacking.

### Checking inventory/party (overworld)
1. `read_party` - full party with moves, PP, nature, IVs, EVs. Reliable in any game state.
2. `read_bag` - all items across all pockets

### Using items (overworld)
1. `use_item("Potion", 0)` - uses a single Medicine item on the specified party slot (0-indexed)
2. `use_medicine()` - **preferred for bulk healing**. Dry-run returns a plan, `confirm=True` executes.

### Reordering party (overworld)
1. `reorder_party(0, 2)` - swap slot 0 and slot 2. Navigates pause menu automatically.

## Tips

- Save state frequently - this is a difficulty hack, expect challenges.
- **Use `read_battle` at the start of every battle** - Renegade Platinum changes abilities and movesets from vanilla.
- **`read_dialogue` auto-advances by default** - just call it after triggering dialogue and it handles everything. Returns full conversation + status. Only need manual intervention for Yes/No prompts and multi-choice prompts.
- The `load_state` tool may occasionally hang - check `get_status` to verify.
- Addresses must be passed as decimal integers to MCP tools, not hex strings.
- **Touch screen taps default to `frames=8`** - changed from 1 to avoid missed inputs.
- **Wait 300 frames between UI navigation steps** - Pokemon ignores input during forced text delays.
- **Always check the bottom screen for Yes/No prompts** - battle/switch prompts use touch screen.
- **Pause menu remembers cursor position** - cursor index stored at `0x0229FA28`. The `use_item` tool reads this automatically; for manual menu navigation, read this address first.
- **Trainer battles may have multiple Pokemon** - handle "Will you switch?" prompt before next action.
- **Evolution is handled** - after level-up + move-learn resolution, `battle_turn` detects "is evolving" text and handles it automatically. Works in both `battle_turn` and `auto_grind` flows.
- **Use free switches at SWITCH_PROMPT** - don't tunnel-vision on one Pokemon, take advantage of free switch opportunities.
- **Never mash A/B in battle or prompts** - single presses only to avoid skipping past important states.

## QA Coverage Checklist

Track which tools/flows you've exercised. Update as you go.

- [ ] Name entry (touch keyboard)
- [ ] Starter selection
- [ ] Wild battle (single)
- [ ] Trainer battle (single)
- [ ] Double battle (tag / wild / trainer)
- [ ] Catching Pokemon
- [ ] Evolution (level-up)
- [ ] Move learning (< 4 moves)
- [ ] Move learning (4 moves, forget)
- [ ] Move learning (4 moves, skip)
- [ ] Party reorder
- [ ] PC deposit
- [ ] PC withdraw
- [ ] Heal at Pokemon Center
- [ ] Buy items at PokeMart
- [ ] Use medicine (single)
- [ ] Use medicine (bulk)
- [ ] Use field item (Repel, etc.)
- [ ] Give held item
- [ ] Take held item
- [ ] Teach TM/HM
- [ ] Navigate multi-room dungeon
- [ ] Navigate elevation-aware map
- [ ] Navigate with flee_encounters
- [ ] Auto grind (basic)
- [ ] Auto grind (with auto-heal loop)
- [ ] Auto grind (smart move selection)
- [ ] Auto grind (target species)
- [ ] Gym battle (full team)
- [ ] Story cutscene advancement
- [ ] Sign/signpost interaction
- [ ] HM obstacle (Cut tree, Rock Smash)
