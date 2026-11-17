extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
 if value: checks += 1
 else:
  failures += 1
  push_error("FAIL: "+message)
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 check(g.ring_health(0,1) == 32,"first stage entry remains a moderate 32 HP")
 check(is_equal_approx(g.ring_health(47,1),1054.25),"last ring of stage one has substantially more health")
 check(g.ring_health(83,10) > 16000,"late-stage outer layers resist upgraded damage")
 var previous = 0.0
 for stage in [1,2,7,10,25]:
  g.profile.stage = stage
  g.profile.selected_stage = stage
  g.start_run()
  check(g.rings[0].max_hp > previous,"stage difficulty increases entry health")
  previous = g.rings[0].max_hp
  var last_hp = 0.0
  for ring in g.rings:
   check(ring.hp == ring.max_hp and ring.hp > last_hp and is_finite(ring.hp),"rings start full and increase outward")
   last_hp = ring.hp
  g.update_hud()
  check(g.labels.hp.text == "ПРОЧНОСТЬ  %d / %d" % [ceili(g.rings[0].hp),ceili(g.rings[0].max_hp)],"HUD consistently rounds current and maximum health")
 g.choose_card({"id":"bounce","kind":"new"})
 var count = g.rings.size()
 g.rings[0].hp = 1e12
 g.break_ring(true)
 check(g.rings.size() == count-1 and g.destroyed == 1,"gap destruction still ignores health")
 print("RING_HEALTH_OK: " if failures == 0 else "RING_HEALTH_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
