extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
 if value: checks += 1
 else:
  failures += 1
  push_error("FAIL: "+message)
func ordered(g) -> bool:
 for i in range(1,g.rings.size()):
  var a = g.rings[i-1]
  var b = g.rings[i]
  if b.r-a.r < b.start_r-a.start_r-0.0001: return false
 return true
func simulate(g, frames: int) -> bool:
 for frame in frames:
  # Keep the ball away from contact to isolate compression/status geometry.
  g.ball = g.CENTER
  g.velocity = Vector2.ZERO
  g._physics_process(1.0/60)
  if not ordered(g): return false
 return true
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 for stage in [1,7]:
  g.profile.stage = stage
  g.profile.selected_stage = stage
  g.start_run()
  g.choose_card({"id":"frost","kind":"new"})
  var inner_radius = g.rings[0].r
  g.rings[0].freeze = 1000.0
  check(simulate(g,1800),"30s frozen inner shell blocks outer compression, stage "+str(stage))
  check(is_equal_approx(g.rings[0].r,inner_radius),"collision rule never shrinks the frozen inner shell")
  check(g.rings[-1].r <= 232.0001,"blocked compression stays in arena")
  g.start_run()
  g.choose_card({"id":"slow","kind":"new"})
  g.build.slow.duration = 8
  g.rings[0].slow = 1000.0
  check(simulate(g,900),"slow inner shell cannot be overtaken, stage "+str(stage))
  g.start_run()
  g.choose_card({"id":"frost","kind":"new"})
  var frozen_outer_radius = g.rings[5].r
  g.rings[5].freeze = 1000.0
  check(simulate(g,600),"frozen middle shell keeps order on both sides")
  check(is_equal_approx(g.rings[5].r,frozen_outer_radius),"unpressured frozen outer shell stays stationary")
  g.start_run()
  g.choose_card({"id":"bounce","kind":"new"})
  var expansion = g.expand_rings(1000.0)
  check(expansion > 0 and expansion <= 6.0001,"expansion is limited by outermost shell")
  check(ordered(g),"large expansion preserves all gaps")
  var last = g.rings[-1].r
  for i in 100: g.expand_rings(30)
  check(ordered(g) and is_equal_approx(last,g.rings[-1].r),"repeated expansion at cap cannot flatten the stack")
  g.start_run()
  g.choose_card({"id":"frost","kind":"new"})
  g.rings[0].freeze = 1000.0
  for i in 600:
   g.ball = g.CENTER
   g.velocity = Vector2.ZERO
   g._physics_process(1.0/60)
   if i % 30 == 0: g.expand_rings(4)
  check(ordered(g),"alternating freeze, compression and recoil preserves order")
  g.break_ring(false)
  check(ordered(g),"removing active shell preserves nesting of remaining shells")
  g.rings[1].r = g.rings[0].r-8
  var active = g.rings[0].r
  g.preserve_ring_order()
  check(ordered(g) and is_equal_approx(active,g.rings[0].r),"overlapping shell is repaired outward without changing active shell")
 print("RING_ORDER_OK: " if failures == 0 else "RING_ORDER_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
