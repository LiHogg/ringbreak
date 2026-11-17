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
 # Replaying stages keeps the highest unlock and survives save/load.
 g.profile.stage = 5
 g.select_stage(2)
 check(g.current_stage() == 2 and g.profile.stage == 5, "select earlier stage without losing unlocks")
 g.start_run()
 check(g.run_stage == 2 and g.total_rings == 54, "replay uses selected stage difficulty and length")
 g.choose_card({"id":"bounce","kind":"new"})
 g.finish_run(true)
 check(g.profile.stage == 5 and g.current_stage() == 2, "winning replay does not unlock extra stages")
 g.load_progress()
 check(g.current_stage() == 2 and g.profile.stage == 5, "selected and unlocked stages persist")
 g.select_stage(99)
 check(g.current_stage() == 5, "locked stage selection is clamped")
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.finish_run(true)
 check(g.profile.stage == 6 and g.current_stage() == 6, "winning frontier unlocks the next stage")
 check(g.stage_color(1) != g.stage_color(2) and g.stage_color(2) != g.stage_color(3), "adjacent stages have distinct colors")
 g.profile.stage = 1
 g.profile.selected_stage = 0
 g.start_run()
 for id in g.PROC_CHANCES:
  if id != "recoil": g.choose_card({"id":id,"kind":"new"})
 g.build.bounce.recoil = 1
 for id in g.PROC_CHANCES:
  var successes = 0
  seed(123)
  for i in 2000:
   if g.triggers(id): successes += 1
  check(absf(successes/2000.0-g.PROC_CHANCES[id]) < 0.05,"ability proc rate matches chance: " + id)
 g.build.bounce.chance = 2
 g.build.bounce.recoil_chance = 3
 check(is_equal_approx(g.proc_chance("bounce"),0.22),"bounce chance upgrade applies")
 check(is_equal_approx(g.proc_chance("recoil"),0.35),"recoil chance is independent")
 var expansions = 0
 var golden_rewards = 0
 g.crit = 0
 g.build = {"bounce":g.build.bounce,"fortune":g.build.fortune}
 g.rings[0].hp = 1e12
 for i in 1000:
  g.bounce_left = 3
  for r in g.rings: r.r = r.start_r
  g.hit_ring(g.rings[0])
  if g.rings[0].r > g.rings[0].start_r: expansions += 1
  if g.coin_reward(100) > 100: golden_rewards += 1
 check(expansions > 200 and expansions < 500,"recoil sometimes expands and sometimes misses during empowered bounce")
 check(golden_rewards > 150 and golden_rewards < 350,"fortune is probabilistic rather than passive")
 check(g.particles.size() <= 120,"particle budget stays bounded under rapid hits")
 g.build.bounce.recoil = 0
 check(not g.triggers("recoil"),"recoil requires its upgrade")
 g.profile.coins = 0
 g.profile.diamonds = 30
 g.profile.stage = 1
 g.profile.selected_stage = 0
 # Free flight follows a parabola and is independent of step partitioning.
 g.start_run()
 check(g.total_rings == 48, "first stage has 48 rings")
 g.profile.stage = 2
 check(g.stage_ring_count() == 54, "next stage adds six rings")
 g.profile.stage = 100
 check(g.stage_ring_count() == 84, "stage length has an upper bound")
 g.profile.stage = 1
 check(is_equal_approx(g.BASE_SHRINK, 1.8), "base shrink increased to 1.8")
 g.choose_card({"id":"speed", "kind":"stat"})
 g.rings[0].r = 1000.0
 g.ball = g.CENTER
 g.velocity = Vector2(100, -100)
 g.move_ball(0.5)
 check(g.ball.is_equal_approx(g.CENTER + Vector2(50, 15)), "gravity curves long free flight downwards")
 check(g.velocity.is_equal_approx(Vector2(100, 160)), "free flight preserves horizontal momentum and accelerates down")
 var flight_end = g.ball
 g.ball = g.CENTER
 g.velocity = Vector2(100, -100)
 for i in 60: g.move_ball(1.0 / 120)
 check(g.ball.distance_to(flight_end) < 0.01, "gravity is stable across time steps")
 # Exercise actual contacts: status effects sometimes activate and sometimes miss.
 g.start_run()
 for id in ["fire", "frost", "slow"]: g.choose_card({"id": id, "kind": "new"})
 var effect_ring = g.rings[0]
 effect_ring.hp = 10000000.0
 effect_ring.max_hp = effect_ring.hp
 var activated = {"burn": 0, "freeze": 0, "slow": 0}
 seed(7251)
 for i in 1000:
  for key in activated: effect_ring[key] = 0.0
  g.hit_ring(effect_ring)
  for key in activated:
   if effect_ring[key] > 0: activated[key] += 1
 for key in activated:
  check(activated[key] > 80 and activated[key] < 400, "status is probabilistic: " + key)
 g.rings = [effect_ring]
 effect_ring.r = 1000.0
 effect_ring.burn = 0.0
 effect_ring.freeze = 0.0
 effect_ring.slow = 0.2
 g.ball = g.CENTER
 g.velocity = Vector2.ZERO
 g.mode = "cards"
 g._physics_process(0.1)
 check(is_equal_approx(effect_ring.slow, 0.2), "card choice pauses status duration")
 g.mode = "play"
 g._physics_process(0.1)
 g._physics_process(0.1)
 check(is_zero_approx(effect_ring.slow), "temporary slow expires")
 var angle_before = effect_ring.angle
 g._physics_process(0.1)
 check(absf(effect_ring.angle - angle_before - effect_ring.omega * 0.1) < 0.0001, "rotation returns to normal after slow")
 g.start_run()
 g.choose_card({"id":"speed", "kind":"stat"})
 check(not g.triggers("fire"), "unselected ability cannot activate")
 g.profile.coins = 500
 g.start_run()
 check(g.offered.size() == 4, "four starting cards")
 g.choose_card({"id":"bounce", "kind":"new"})
 for i in 80:
  g.offer_cards()
  check(g.offered.size() == 4, "four choices")
  check(g.offered.any(func(c): return c.kind == "upgrade" and c.id == "bounce"), "guaranteed useful upgrade")
 var ring = g.rings[0].duplicate()
 ring.gaps = 1
 ring.angle = 0
 check(g.in_gap(ring, 0, 0.1), "gap center passes")
 check(not g.in_gap(ring, PI, 0.1), "solid arc blocks")
 check(not g.in_gap(ring, PI * 0.2 - 0.05, 0.1), "ball must fit through gap")
 ring.gaps = 2
 check(g.in_gap(ring, PI, 0.1), "opposite gap")
 ring.gaps = 0
 check(not g.in_gap(ring, 0), "solid ring")
 g.start_run()
 g.choose_card({"id":"bounce", "kind":"new"})
 var r = g.rings[0]
 r.hp = 100000
 r.max_hp = 100000
 for i in 1000:
  g.move_ball(1.0 / 120)
  check(g.ball.distance_to(g.CENTER) + g.BALL_R <= r.r - 3.9, "no tunneling through solid ring")
 g.earned = 200
 g.finish_run(false)
 check(g.profile.coins == 580, "loss preserves bank plus 40 percent")
 g.finish_run(false)
 check(g.profile.coins == 580, "result paid once")
 g.start_run()
 check(g.build.is_empty() and g.battle_lvl == 1 and g.earned == 0, "retry resets build and run earnings")
 g.choose_card({"id":"bounce", "kind":"new"})
 g.break_ring(true)
 check(g.battle_lvl == 2 and g.needed == 2, "first ring grants level")
 g.choose_card(g.offered[0])
 g.break_ring(false)
 check(g.battle_lvl == 2, "next level requires two more rings")
 g.break_ring(false)
 check(g.battle_lvl == 3 and g.needed == 4, "third total ring grants next level")
 g.profile.diamonds = 10
 g.profile.pity = 49
 g.profile.slots = 3
 g.show_menu()
 g.open_pack()
 check(g.profile.slots == 4 and g.profile.pity == 0 and g.profile.diamonds == 0, "slot guarantee at 50 packs")
 g.save_progress()
 g.profile.slots = 3
 g.load_progress()
 check(g.profile.slots == 4, "save reload")
 print("CHECKS_OK: " if failures == 0 else "CHECKS_FAILED: ", checks," failures=",failures)
 quit(1 if failures > 0 else 0)
