# Save States (melonDS)

## Gameplay Progression

| Name | Description |
|------|-------------|
| `bedroom_fresh_start_claude` | Fresh save wipe. Player CLAUDE (boy), rival Barry. Overworld control in Twinleaf bedroom, pre-starter. Pre-staged for QA session of Renegade MCP tools. |
| `twinleaf_outside_house_post_mom` | Just stepped outside of player's house in Twinleaf Town. Mom dialogue done (Running Shoes + Bicycle received). Still pre-starter. `view_map`/`map_name` still blocked by BUG-001 at this point. |
| `twinleaf_outside_barry_house_post_mom_items` | Outside Barry's house after receiving Running Shoes + Bicycle from Mom. Pre-starter, pre-Thud scene. Used for testing the town traversal. |
| `twinleaf_west_past_guitarist` | Walked west past the Guitarist NPC at (102, 868). Pre-starter. Used for testing whether the Guitarist trigger fires based on LoS vs script state. |
| `twinleaf_barry_triggered_post_thud` | The "Thud!!" scene has played (Barry burst out of his house and ran back inside). Still pre-starter. `map_name`/`view_map` all working. |
| `twinleaf_barry_talked_upstairs` | Met Barry upstairs in his bedroom (Palmer's house, map 413). Barry said "I'll be waiting on the road!" Story flag for Route 201 advanced. Ready to cross the Guitarist gate. |
| `rival_battle_1_chimchar_critical` | Mid-rival-1 battle with Chimchar at 3/19 HP vs Piplup at 9/21. Useful for testing battle_turn edge cases (blackout flow, faint handling). |
| `twinleaf_post_rival_loss_chimchar` | Post-blackout state — back in Twinleaf house after losing rival battle. Chimchar Lv5 healed. Mom has given "go see Prof. Rowan" dialogue. Ready to retry Route 201. |
| `lake_verity_cyrus_cutscene_done` | Lake Verity, Cyrus cutscene complete (flowing time / expanding space speech + legendary Pokémon "Kyauuun" cry). Barry next to player at (46, 53). Ready to walk back to Sandgem Town. |
| `sandgem_town_pokeballs_bought` | Sandgem Town overworld. Pokédex + Poké Radar received from Rowan/Dawn. Bag: Poké Ball×15, Premier Ball×1, Potion×5, Antidote×3, Repel×10, Bicycle, Poké Radar. ¥410 remaining. Ready to head to Twinleaf or Route 202. |
| `twinleaf_mom_visited_eevee_obtained` | Player's house in Twinleaf. Mom visited (story gate cleared for Route 202). Received Journal + Parcel (deliver to Barry). Received Eevee Lv5 (Bold, Run Away, Def IV 31) from window Poké Ball. Party: Chimchar Lv5 + Eevee Lv5. |
| `jubilife_city_arrival` | Jubilife City overworld on arrival from Route 202. Before Looker encounter or any Jubilife events. |
| `jubilife_city_town_map_obtained` | Jubilife City, Pokétch obtained. Barry delivered Parcel + Town Map in Trainer's School (map 29). Chimchar Lv13, Eevee Lv5. Ready to head to Route 203. |
| `route202_ready_chimchar_lv10` | Route 202 grass. Chimchar Lv10 as lead, used for BUG-004 reproduction and general Route 202 grinding. |
| `jubilife_healed_3mon_pre_barry2` | Jubilife City Pokemon Center. Party healed: Chimchar Lv13, Eevee Lv5, Shinx Lv5. Before second Barry rival battle on Route 203. |
| `route202_shinx_lv13_pre_barry3` | Route 202 grass (181,804). Party: Shinx Lv13 (Spark/Bite/Howl/Quick Attack), Eevee Lv5, Chimchar Lv13. Before third Barry rival battle. |
| `route203_barry2_defeated` | Route 203 just after beating Barry (rival battle 2). Party: Shinx Lv14, Eevee Lv6, Chimchar Lv13 (fainted). Exp. Share obtained from Barry. Ready for Oreburgh Gate / Oreburgh City. |
| `route203_trainers_defeated_monferno` | Route 203, just after defeating all mandatory double battle trainers (Youngster Michael / Lass / Youngster Dallas + Youngster Sebastian). Chimchar evolved to Monferno Lv14, learned Mach Punch (forgot Scratch). Party: Shinx Lv15 (39/39), Monferno Lv14 (35/42), Eevee Lv6 (healthy). Good reproduction state for BUG-007 (walk north from here to trigger Lass Kaitlin + Lass Madeline double battle). |
| `oreburgh_city_arrival` | Oreburgh City on first arrival, immediately after exiting Oreburgh Gate. Oval Stone obtained from arriving NPC. Party not yet healed. |
| `oreburgh_city_healed` | Oreburgh City, party fully healed at Pokemon Center. Shinx Lv15 / Monferno Lv15 / Eevee Lv11. HM06 Rock Smash in bag (from Hiker in Oreburgh Gate). Ready to challenge Roark's Gym. |

## Bug Reproduction

| Name | Bug ID | Description |
|------|--------|-------------|
| `bug_view_map_mystery_zone_pre_starter` | BUG-001 | Player in Twinleaf bedroom post-Barry-dialogue, pre-starter. `view_map`/`map_name`/`navigate` all return invalid data (x=0xFFFFFFFF, "Mystery Zone"). |
| `bug_buy_item_potion_bought_antidote` | BUG-003 | Sandgem Town, post-Poke Ball purchase. Calling `buy_item("Potion", 5)` here bought Antidote×3 instead; bag shows Antidote×3, no Potions. Second call to `buy_item("Potion", 5)` from same state worked correctly. |
| `monferno_lv15_route202` | BUG-005 | Route 202. Monferno Lv15 post-evolution — map detection broken (Pal Park / Mystery Zone). **Do not use directly.** Load `jubilife_city_town_map_obtained` + `reload_tools` first for partial recovery. |
| `monferno_lv15_route202_v2` | BUG-005 | Same as above; second capture of the broken post-evolution state. Same caveats apply. |
