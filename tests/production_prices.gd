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
 g.profile.power = 0
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 check(g.energy_production == 100 and g.energy_gain == 1,"production starts at 100 points = normal gain")
 var known = {1:102,2:106,3:112,6:157,9:247,10:574,20:2498,30:7346,40:18042,49:19977,50:101085,60:518800}
 var factors = {0:1,9:1,10:2,19:2,20:4,30:8,40:16,49:16,50:80,59:80,60:400}
 for level in factors:
  check(g.upgrade_price_multiplier(level) == factors[level],"cumulative price factor at "+str(level))
 g.round_energy = 1000000000
 for level in range(1,61):
  var preview = g.next_energy_production()
  check(g.buy_energy_upgrade("energy"),"production purchase "+str(level))
  check(is_equal_approx(g.energy_production,preview) and is_equal_approx(g.energy_gain,g.energy_production/100),"production preview and gain agree")
  if known.has(level): check(is_equal_approx(g.energy_production,known[level]),"known production total at "+str(level))
  if factors.has(level):
   check(g.energy_upgrade_cost("damage") == 18*factors[level],"production milestone also raises damage price")
   check(g.energy_upgrade_cost("energy") == (15+level*10)*factors[level],"production price includes milestone factor")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.round_energy = 1000000000
 for i in 10: g.buy_energy_upgrade("damage")
 check(g.energy_upgrade_cost("damage") == 276 and g.energy_upgrade_cost("energy") == 15,"damage tenth doubles its price only")
 for i in 10: g.buy_energy_upgrade("energy")
 check(g.energy_upgrade_cost("damage") == 552 and g.energy_upgrade_cost("energy") == 230,"two independent milestone factors combine correctly")
 g.round_energy = 551
 var damage = g.damage
 check(not g.buy_energy_upgrade("damage") and g.round_energy == 551 and g.damage == damage,"post-milestone unaffordable purchase cannot debit")
 g.start_run()
 check(g.energy_production == 100 and g.energy_upgrade_cost("damage") == 18 and g.energy_upgrade_cost("energy") == 15,"new attempt resets production and price factors")
 print("PRODUCTION_PRICES_OK: " if failures == 0 else "PRODUCTION_PRICES_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
