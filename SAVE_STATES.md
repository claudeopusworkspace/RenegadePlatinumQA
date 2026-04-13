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

## Bug Reproduction

| Name | Bug ID | Description |
|------|--------|-------------|
| `bug_view_map_mystery_zone_pre_starter` | BUG-001 | Player in Twinleaf bedroom post-Barry-dialogue, pre-starter. `view_map`/`map_name`/`navigate` all return invalid data (x=0xFFFFFFFF, "Mystery Zone"). |
