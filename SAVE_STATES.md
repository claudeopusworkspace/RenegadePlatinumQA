# Save States (melonDS)

## Gameplay Progression

| Name | Description |
|------|-------------|
| `qa_base_bedroom` | **Permanent QA base state.** Fresh start, character WOJ (boy), rival Barry. Post-intro and post-Barry-bedroom-cutscene. Player at (4,7) in Twinleaf Town bedroom (map 415) with full overworld control. Next step: exit via warp at (8,4) to Twinleaf Town. Load this instead of replaying the intro. |
| `post_starter_twinleaf_eevee` | Chimchar (Lv6) + Eevee (Lv5) in party. Post-Pokédex, post-rival battle, post-Twinleaf Journal/Parcel/Eevee cutscene. Player downstairs in own house (map 414 at (4,5)), facing down. Key Items: Bicycle, Poké Radar, Journal, Parcel. Also holding 2 Repels. Next step: exit south to Twinleaf, head north to Sandgem → Route 202 → Jubilife City to deliver Parcel to Barry. |
| `sandgem_after_mart` | Chimchar Lv8, Eevee Lv5, Burmy Lv5 (caught on Route 202). Healed at Sandgem PC, bought 1 Potion. Player at (3,7) inside Sandgem PokéMart (map 419). Money: ¥3200. Next step: exit PokéMart, head back north through Route 202 to Jubilife. |
| `jubilife_entered_looker_done` | Chimchar Lv11 (22/33 HP), Eevee Lv6 (3/21), Burmy Lv5 (**fainted 0/19** — heal needed). Defeated Lass Natalie, Youngster Tristan, Youngster Logan on Route 202. Just finished Looker cutscene, received Vs. Recorder. Player at Jubilife City (map 3) at (175,775) in front of Trainers' School. Next step: enter Trainers' School via warp at (168,776) to find Barry and deliver Parcel. **Heal first** — Burmy is fainted. |
| `jubilife_parcel_delivered` | Party fully healed (Chimchar Lv11, Eevee Lv6, Burmy Lv5). Parcel delivered to Barry, **Town Map** obtained (now in Key Items). Player inside Trainers' School (map 29) at (6,4) facing up, one tile south of Barry. Next step: exit south warp at (7,11) to Jubilife City, then head west / north to trigger Team Galactic TV-station cutscene and exit toward Oreburgh via Route 204. |
| `route202_chimchar_lv13` | Chimchar Lv13, Eevee Lv6, Burmy Lv5. Post-10-battle auto_grind on Route 202. Player at (163,806) in Route 202 grass. |
| `jubilife_pc_after_barry_blackout` | **After losing Barry 1st attempt.** All healed by blackout. Chimchar Lv13, Eevee Lv10 (post-grind), Burmy Lv5. Player at Jubilife PC (map 6, 8,6). |
| `jubilife_pre_barry_rematch_lv13` | Full-health checkpoint before Barry rematch. Chimchar Lv13 (38/38), Eevee Lv10 (33/33, has Quick Attack), Burmy Lv5. Player at Jubilife PC (map 6, 8,6). Bag: Poké Ball x26, Repel x10 (started at 10). No Potions. |
| `jubilife_shinx_caught_pre_grind` | **Post-Shinx catch, BUG-002 investigation save.** Party: Chimchar Lv13, Eevee Lv10, Burmy Lv5, Shinx Lv5 (Timid, Guts, IVs 9/21/0/4/24/5). Player at Jubilife PC (map 6). 21 Poké Balls. |
| `jubilife_mart_after_buy_5potions` | Post-buy 5 Potions ¥1500. Player inside Jubilife Mart (map 4) at (3,7). Money ¥1948. **FR-002 repro** — tool left player stuck in shop UI (had to manually B-spam out). |
| `jubilife_pre_barry_rematch_potions_repel` | **Best Barry-rematch starting state.** Full HP party, Shinx in party slot 3, bag has 5 Potions + 9 Repels + 21 Poké Balls, Repel active. Player at (180,778) Jubilife City. Next step: navigate to (196,757) to trigger Barry battle. Chimchar Ember-spam Starly (3x incl. Barry's Potion heal), then Eevee Covet-spam Piplup with own-Potion heal as needed. |
| `jubilife_barry_rematch_mid_battle` | Mid-battle snapshot: Barry rematch T1 exchange done. Chimchar 26/38 vs Starly 18/31. **Continue with Ember** or reload `jubilife_pre_barry_rematch_potions_repel` for clean retry. |

## Bug Reproduction States

| Name | Bug ID | Description |
|------|--------|-------------|
| `bug_throw_ball_state_mismatch` | BUG-001 | Post-catch state showing the cosmetic `State: TIMEOUT` vs `final_state: "CAUGHT"` inconsistency. Shinx already in party slot 3. |
| `bug_auto_grind_faint_switch_stuck` | BUG-002 | Auto-heal loop failure. Shinx fainted vs wild Rattata, game stuck at FAINT_SWITCH prompt, tool reported `heal_failed`. |

