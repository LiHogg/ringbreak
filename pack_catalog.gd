extends RefCounted

const PACKS = {
 "spark": {"name":"ИСКРА","price":10,"cards":1,"coins_min":0,"coins_max":0,"slot_chance":0.02,"tier":0,"color":"#70e9d0","rule":"Одна случайная карта"},
 "arcana": {"name":"АРКАН","price":30,"cards":4,"coins_min":60,"coins_max":120,"slot_chance":0.05,"tier":1,"color":"#b69aff","rule":"Первые две карты — разные способности"},
 "crown": {"name":"КОРОНА","price":75,"cards":10,"coins_min":250,"coins_max":450,"slot_chance":0.10,"tier":2,"color":"#ffd184","rule":"Одна новая способность, пока есть закрытые"}
}

static func purchase(g, id: String) -> Dictionary:
 if not PACKS.has(id) or not g.mode in ["menu","pack_shop"] or not g.profile.pending_pack.is_empty(): return {}
 var pack = PACKS[id]
 if int(g.profile.diamonds) < int(pack.price): return {}
 var before: Dictionary = g.profile.duplicate(true)
 var rewards: Array = []
 var coins = randi_range(pack.coins_min,pack.coins_max)
 var ids: Array = g.ABILITIES.keys()
 var unopened: Array = ids.filter(func(key):return not key in g.profile.owned)
 var first = ""
 g.profile.diamonds -= pack.price
 g.profile.coins += coins
 if coins > 0: rewards.append({"kind":"coins","amount":coins})
 for i in int(pack.cards):
  var card: String
  if id == "crown" and i == 0 and not unopened.is_empty(): card = unopened.pick_random()
  elif id == "arcana" and i == 1: card = ids.filter(func(key):return key != first).pick_random()
  else: card = ids.pick_random()
  if i == 0: first = card
  var duplicate: bool = g.receive_card(card)
  rewards.append({"kind":"card","id":card,"duplicate":duplicate})
 g.profile.pity += 1
 if int(g.profile.slots) < 8 and (int(g.profile.pity) >= 50 or randf() < float(pack.slot_chance)):
  g.profile.slots += 1
  g.profile.pity = 0
  rewards.append({"kind":"slot","amount":1})
 var receipt = {"pack":id,"rewards":rewards,"price":pack.price}
 g.profile.pending_pack = receipt.duplicate(true)
 # Commit once before any animation. Reopening a receipt never grants again.
 if not g.save_progress():
  g.profile = before
  return {}
 return receipt
