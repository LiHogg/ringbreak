extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
 if value: checks += 1
 else:
  failures += 1
  push_error("FAIL: "+message)
func keys(g) -> Array:
 var result = g.offered.map(func(c):return g.card_key(c))
 result.sort()
 return result
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.start_run()
 check(not g.reroll_cards() and not g.reroll_used,"four unlocked starters have no alternative and do not spend reroll")
 check(not g.take_all_cards() and not g.take_all_used and g.build.is_empty(),"insufficient slots do not consume take-all")
 g.profile.owned = g.ABILITIES.keys()
 g.profile.slots = 8
 g.start_run()
 var previous = keys(g)
 check(g.reroll_cards() and keys(g) != previous and g.offered.size() == 4,"reroll changes the set of four")
 var rerolled = g.offered.duplicate(true)
 check(not g.reroll_cards() and g.offered == rerolled,"reroll is limited to once")
 g.show_build()
 g.close_build()
 check(g.reroll_used and not g.take_all_used and g.offered == rerolled,"inspection preserves counters and offer")
 check(g.take_all_cards() and g.mode == "play" and g.build.size() == 4,"take-all applies four new abilities and resumes")
 for card in rerolled: check(g.build.has(card.id),"each new card was applied")
 g.offer_cards()
 var snapshot = g.build.duplicate(true)
 check(not g.take_all_cards() and g.build == snapshot,"take-all stays consumed on later levels")
 check(not g.reroll_cards(),"reroll stays consumed on later levels")
 g.start_run()
 check(not g.reroll_used and not g.take_all_used,"new attempt resets both independent uses")
 g.choose_card({"id":"bounce","kind":"new"})
 g.profile.slots = 1
 g.offer_cards()
 check(g.reroll_cards() and g.offered.any(func(c):return c.kind == "upgrade" and c.id == "bounce"),"reroll preserves useful-upgrade guarantee")
 var selected = g.offered.duplicate(true)
 check(g.take_all_cards() and g.build.size() == 1,"all upgrades fit without using additional ability slots")
 for card in selected:
  if card.kind == "upgrade": check(g.build[card.id][card.branch] == 1,"each offered improvement applied once")
  elif card.kind == "stat": check(g.stat_upgrades.get(card.id,0) == 1,"each stat applied once")
 check(not g.take_all_cards() and not g.reroll_cards(),"buttons cannot execute while playing")
 print("CARD_ACTIONS_OK: " if failures == 0 else "CARD_ACTIONS_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
