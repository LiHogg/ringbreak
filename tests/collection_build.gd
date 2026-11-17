extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
 if not value:
  push_error("FAIL: " + message)
  failures += 1
  return
 checks += 1
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 var legacy = g.profile.duplicate(true)
 legacy.erase("copies")
 legacy.ranks = {"bounce":3}
 var f = FileAccess.open(g.SAVE,FileAccess.WRITE)
 f.store_string(JSON.stringify(legacy))
 f.close()
 g.load_progress()
 check(g.profile.ranks.bounce == 3 and g.profile.copies.is_empty(),"legacy ranks preserved without minting copies")
 g.receive_card("bounce")
 check(g.profile.copies.bounce == 1 and g.profile.ranks.bounce == 3,"duplicate is banked rather than auto-upgrading")
 g.profile.copies.bounce = 3
 check(not g.upgrade_card("bounce") and g.profile.copies.bounce == 3,"insufficient copies cannot upgrade")
 g.profile.copies.bounce = 4
 check(g.upgrade_card("bounce"),"rank can be upgraded manually")
 check(g.profile.copies.bounce == 0 and g.profile.ranks.bounce == 4,"upgrade spends exact required copies")
 check(is_equal_approx(g.rank_bonus("bounce"),1.2),"permanent rank affects gameplay strength")
 check(not g.upgrade_card("bounce"),"repeat click cannot spend missing copies")
 g.profile.owned.erase("pressure")
 g.profile.copies.pressure = 99
 check(not g.upgrade_card("pressure"),"locked card cannot be upgraded")
 check(not g.receive_card("pressure") and g.profile.copies.pressure == 99,"first unlock is separate from duplicate")
 g.save_progress()
 g.profile.ranks.bounce = 0
 g.profile.copies.pressure = 0
 g.load_progress()
 check(g.profile.ranks.bounce == 4 and g.profile.copies.pressure == 99,"copies and ranks survive save/load")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.choose_card({"id":"bounce","kind":"upgrade","branch":"force"})
 g.choose_card({"id":"bounce","kind":"upgrade","branch":"force"})
 g.choose_card({"id":"bounce","kind":"upgrade","branch":"chance"})
 g.round_energy = 18
 g.buy_energy_upgrade("damage")
 check(g.stat_upgrade_count() == 1 and g.chosen_upgrades("bounce").contains("×2"),"viewer tracks chosen ability and stat upgrades")
 check(g.ability_summary("bounce").contains("17%"),"viewer shows effective upgraded chance")
 var run_build = g.build.duplicate(true)
 var pos = g.ball
 var radius = g.rings[0].r
 g.show_build()
 g._physics_process(1.0)
 check(g.mode == "build" and g.ball == pos and is_equal_approx(radius,g.rings[0].r),"build inspection pauses movement and shrink")
 check(not g.upgrade_card("bounce"),"permanent upgrades unavailable during a run")
 g.close_build()
 check(g.mode == "play" and g.build == run_build,"closing viewer resumes same build")
 g.pause_game()
 g.show_build()
 g.close_build()
 check(g.mode == "pause","inspection from pause returns to pause")
 g.offer_cards()
 var offer = g.offered.duplicate(true)
 g.show_build()
 g.close_build()
 check(g.mode == "cards" and g.offered == offer,"inspection preserves exact offered cards")
 g.start_run()
 check(g.build.is_empty() and g.stat_upgrades.is_empty(),"new attempt resets temporary improvements")
 check(g.profile.ranks.bounce == 4 and g.profile.copies.pressure == 99,"new attempt keeps permanent progress")
 check(g.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE,"overlay root does not intercept HUD buttons")
 print("COLLECTION_BUILD_OK: " if failures == 0 else "COLLECTION_BUILD_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
