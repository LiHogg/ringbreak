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
 check(is_equal_approx(g.damage,10),"base damage is ten")
 var values = {1:12,2:16,3:22,4:32,5:47,6:67,9:157,10:394,20:2138,30:6626,40:16602,49:18537,50:93885,60:482800}
 g.round_energy = 1000000
 var bank = g.profile.coins
 for level in range(1,61):
  var before = g.damage
  var expected_preview = g.next_damage_value()
  check(g.buy_energy_upgrade("damage"),"damage level can be purchased: "+str(level))
  check(is_equal_approx(g.damage,expected_preview),"preview matches actual damage: "+str(level))
  check(g.damage > before and g.energy_upgrades.damage == level,"damage progression is increasing and counts purchases")
  if values.has(level): check(is_equal_approx(g.damage,float(values[level])),"known total at level "+str(level))
  if level == 9: check(g.damage_button_title().contains("×2"),"next tenth milestone shown on button")
  if level == 49: check(g.damage_button_title().contains("×5"),"next fiftieth milestone shown on button")
 check(g.profile.coins == bank,"damage purchases do not charge coins")
 check(not g.buy_energy_upgrade("income"),"old coin-income upgrade no longer exists")
 g.start_run()
 check(g.damage == 10 and g.energy_upgrades.damage == 0,"new attempt resets damage levels")
 g.profile.power = 3
 g.start_run()
 check(is_equal_approx(g.damage,13),"permanent base damage bonus remains")
 print("DAMAGE_PROGRESSION_OK: " if failures == 0 else "DAMAGE_PROGRESSION_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
