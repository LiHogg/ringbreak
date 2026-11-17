extends SceneTree
var checks = 0
var failures = 0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
 if not value:
  failures += 1
  push_error("FAIL: "+message)
 else: checks += 1
func normalized(value):
 return JSON.parse_string(JSON.stringify(value))
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 var catalog = load("res://pack_catalog.gd")
 var original: Dictionary = g.profile.duplicate(true)
 var denied = catalog.purchase(g,"unknown")
 check(denied.is_empty() and g.profile == original,"unknown pack has no side effects")
 g.profile.diamonds = 0
 original = g.profile.duplicate(true)
 check(catalog.purchase(g,"crown").is_empty() and g.profile == original,"insufficient funds cannot grant or charge")
 for id in catalog.PACKS:
  var pack = catalog.PACKS[id]
  g.profile.diamonds = 200
  g.profile.coins = 0
  g.profile.owned = ["bounce","fire","frost","slow"]
  g.profile.copies = {}
  g.profile.pending_pack = {}
  g.profile.slots = 3
  g.profile.pity = 49
  g.mode = "menu"
  var receipt = catalog.purchase(g,id)
  var cards: Array = receipt.rewards.filter(func(r):return r.kind == "card")
  check(cards.size() == int(pack.cards),"card count: "+id)
  check(g.profile.diamonds == 200-int(pack.price),"exact price: "+id)
  check(g.profile.coins >= int(pack.coins_min) and g.profile.coins <= int(pack.coins_max),"coin range: "+id)
  check(g.profile.slots == 4 and g.profile.pity == 0,"shared slot guarantee: "+id)
  if id == "arcana": check(cards[0].id != cards[1].id,"arcana starts with distinct abilities")
  if id == "crown": check(not cards[0]["duplicate"],"crown guarantees an unopened ability")
  var earned = g.profile.duplicate(true)
  check(catalog.purchase(g,id).is_empty() and g.profile == earned,"unacknowledged receipt prevents repurchase: "+id)
  g.profile.coins = -1
  g.load_progress()
  check(normalized(g.profile) == normalized(earned),"receipt and all grants survive reload: "+id)
  g.show_pack_shop()
  check(g.mode == "pack_results" and normalized(g.profile) == normalized(earned),"reopening shows receipt without granting again")
  g.dismiss_pack()
  check(g.profile.pending_pack.is_empty() and g.profile.coins == earned.coins,"receipt acknowledgement does not grant twice")
 # Every crown card becomes a copy once the collection is complete.
 g.profile.owned = g.ABILITIES.keys()
 g.profile.copies = {}
 g.profile.slots = 8
 g.profile.diamonds = 100
 g.profile.pending_pack = {}
 g.mode = "menu"
 var receipt = catalog.purchase(g,"crown")
 var copies = 0
 for n in g.profile.copies.values(): copies += int(n)
 check(copies == 10,"complete collection receives ten spendable copies")
 check(not receipt.rewards.any(func(r):return r.kind=="slot") and g.profile.slots == 8,"slot limit respected")
 var saved = normalized(g.profile)
 var restored = load("res://main.tscn").instantiate()
 root.add_child(restored)
 restored.set_physics_process(false)
 check(restored.mode == "pack_results" and normalized(restored.profile) == saved,"new game instance restores pending receipt without a second grant")
 restored.queue_free()
 g.pack_reveal_index = -1
 g.PackScreen.opening(g)
 g.skip_pack_reveal()
 var snapshot = g.profile.duplicate(true)
 g.advance_pack_reveal()
 g.skip_pack_reveal()
 check(g.profile == snapshot and g.mode == "pack_results","skip and late reveal cannot double-grant")
 g.dismiss_pack(true)
 check(g.mode == "menu" and g.profile.pending_pack.is_empty(),"receipt links to manual card upgrades")
 print("PACKS_OK: " if failures == 0 else "PACKS_FAILED: ",checks," failures=",failures)
 quit(1 if failures > 0 else 0)
