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
 g.profile.coins = 500
 g.profile.power = 0
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 check(g.round_energy == 0,"attempt starts with zero energy")
 g.rings[0].hp = 1000000
 g.hit_ring(g.rings[0])
 check(g.round_energy == 1,"contact gives one energy")
 g.ring_age = 0
 g.break_ring(false)
 check(g.round_energy == 19,"ring and fast clear grant energy")
 var offer = g.offered.duplicate(true)
 check(not g.buy_energy_upgrade("damage") and g.round_energy == 19 and g.offered == offer,"card choice prevents hidden purchases")
 g.choose_card({"id":"bounce","kind":"upgrade","branch":"force"})
 var damage = g.damage
 check(g.buy_energy_upgrade("damage"),"damage can be purchased without a level-up")
 check(g.round_energy == 1 and is_equal_approx(g.damage,damage+2),"damage purchase spends energy and adds a flat two damage")
 check(g.energy_upgrade_cost("damage") == 30 and g.energy_upgrade_cost("energy") == 15,"prices increase independently")
 damage = g.damage
 check(not g.buy_energy_upgrade("damage") and g.round_energy == 1 and g.damage == damage,"insufficient energy has no effect")
 check(not g.buy_energy_upgrade("unknown"),"unknown upgrade is rejected")
 g.round_energy = 200
 check(g.buy_energy_upgrade("energy") and g.round_energy == 185 and is_equal_approx(g.energy_gain,1.02),"income purchase uses energy")
 check(g.buy_energy_upgrade("energy") and g.round_energy == 160 and is_equal_approx(g.energy_gain,1.06),"second production upgrade adds four points")
 check(g.coin_reward(100) == 100,"energy production does not change coin payout")
 check(g.profile.coins == 500,"energy upgrades never charge permanent coins")
 g.pause_game()
 var ball = g.ball
 check(g.buy_energy_upgrade("energy") and g.mode == "pause" and g.ball == ball,"purchase from pause stays paused")
 g.show_build()
 var energy = g.round_energy
 check(not g.buy_energy_upgrade("damage") and g.round_energy == energy,"build inspection cannot trigger hidden purchases")
 g.close_build()
 g.earned = 200
 g.finish_run(false)
 check(g.round_energy == 0 and g.profile.coins == 580,"loss burns energy and still pays 40 percent of coins")
 check(not g.buy_energy_upgrade("damage"),"result screen cannot buy upgrades")
 g.start_run()
 check(g.round_energy == 0 and g.energy_upgrades.damage == 0 and g.energy_upgrades.energy == 0,"new attempt resets purchases and energy")
 check(is_equal_approx(g.damage,10) and is_equal_approx(g.energy_gain,1),"temporary damage and energy production reset")
 check(not g.profile.has("round_energy") and not g.profile.has("energy_upgrades"),"energy is absent from permanent profile")
 g.choose_card({"id":"bounce","kind":"new"})
 for i in 100:
  g.offer_cards()
  check(g.offered.size() == 4 and not g.offered.any(func(c):return c.kind=="stat" and c.id in ["damage","income"]),"four-card offer excludes paid base stats")
 for multiplier in [1.0,10.0]:
  g.start_run()
  g.choose_card({"id":"bounce","kind":"new"})
  g.income = multiplier
  g.rings[0].hp = 1000000
  g.hit_ring(g.rings[0])
  g.ring_age = 0
  g.break_ring(true)
  check(g.round_energy == 23,"income does not amplify hit/ring/gap energy")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.energy_gain = 1.25
 for i in 4: g.gain_energy(1)
 check(g.round_energy == 5 and is_zero_approx(g.energy_remainder),"fractional hit energy accumulates without rounding away the bonus")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.energy_gain = 1.25
 g.rings[0].hp = 1000000
 g.hit_ring(g.rings[0])
 g.ring_age = 0
 g.break_ring(true)
 check(g.round_energy == 28 and is_equal_approx(g.energy_remainder,0.75),"production multiplier boosts hits, rings, speed and gap energy")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.round_energy = 99
 g.earned = 100
 var bank = g.profile.coins
 g.finish_run(true)
 check(g.round_energy == 0 and g.profile.coins == bank+100,"victory burns energy without converting it to coins")
 check(is_zero_approx(g.energy_remainder),"fractional energy also expires")
 print("ENERGY_OK: " if failures == 0 else "ENERGY_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
