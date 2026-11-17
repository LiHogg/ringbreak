extends RefCounted
const Catalog = preload("res://pack_catalog.gd")
const PackArt = preload("res://pack_art.gd")
const SpellArt = preload("res://spell_art.gd")

static func art(g, pack: Dictionary, pos: Vector2, dimensions: Vector2):
 var node = PackArt.new()
 node.tier = pack.tier
 node.ink = Color(pack.color)
 node.position = pos
 node.size = dimensions
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 g.panel.add_child(node)
 return node

static func shop(g):
 if not g.profile.pending_pack.is_empty():
  receipt(g)
  return
 g.mode = "pack_shop"
 g.clear_ui(g.panel)
 g.backdrop()
 g.text_at(g.panel,"ХРАНИЛИЩЕ АРКАНОВ",Vector2(28,43),25,Color("ffd184"),355)
 var odds = g.button(g.panel,"ШАНСЫ",Rect2(398,39,114,40),g.show_pack_odds)
 odds.add_theme_font_size_override("font_size",13)
 g.text_at(g.panel,"◇ %d алмазов  ·  %d монет" % [g.profile.diamonds,g.profile.coins],Vector2(28,98),18,Color("b9cbdd"))
 var i = 0
 for id in Catalog.PACKS:
  var pack = Catalog.PACKS[id]
  var key: String = id
  var y = 148+i*208
  var box = Panel.new()
  box.position = Vector2(28,y)
  box.size = Vector2(484,194)
  box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var style = StyleBoxFlat.new()
  style.bg_color = Color("0e172a").lerp(Color(pack.color),0.07)
  style.set_border_width_all(1)
  style.border_color = Color(pack.color,0.5)
  style.set_corner_radius_all(15)
  box.add_theme_stylebox_override("panel",style)
  g.panel.add_child(box)
  art(g,pack,Vector2(35,y+8),Vector2(142,177))
  g.text_at(g.panel,pack.name,Vector2(194,y+14),24,Color(pack.color),290)
  var coins = "" if pack.coins_max == 0 else " + %d–%d монет" % [pack.coins_min,pack.coins_max]
  g.text_at(g.panel,"Карт: %d%s" % [pack.cards,coins],Vector2(194,y+53),15,Color("e2e8f0"),290,true)
  var rule = g.text_at(g.panel,pack.rule,Vector2(194,y+84),12,Color("98acc4"),285,true)
  rule.size = Vector2(285,44)
  var buy = g.button(g.panel,"ОТКРЫТЬ · %d ◇" % pack.price,Rect2(194,y+137,290,42),func():g.buy_pack(key),Color(pack.color).darkened(0.64))
  buy.add_theme_font_size_override("font_size",16)
  buy.disabled = int(g.profile.diamonds) < int(pack.price)
  i += 1
 var guarantee = "Все 8 слотов открыты. Пакеты продолжают выдавать карты." if int(g.profile.slots) >= 8 else "Бонусный слот: 2%% / 5%% / 10%%.\nОбщая гарантия через %d пак. без слота." % maxi(1,50-int(g.profile.pity))
 var note = g.text_at(g.panel,guarantee,Vector2(28,784),13,Color("98acc4"),484,true)
 note.size = Vector2(484,52)
 g.button(g.panel,"←  ГЛАВНОЕ МЕНЮ",Rect2(28,851,484,60),g.show_menu)

static func odds(g):
 g.mode = "pack_odds"
 g.clear_ui(g.panel)
 g.backdrop()
 g.text_at(g.panel,"СОСТАВ И ШАНСЫ",Vector2(28,44),28,Color("ffd184"))
 g.text_at(g.panel,"Награды определяются один раз при покупке",Vector2(28,98),14,Color("98acc4"))
 var content = g.scroll_content()
 for id in Catalog.PACKS:
  var pack = Catalog.PACKS[id]
  var selection = "Каждая из 8 способностей — 12.5%."
  if id == "arcana": selection = "Первая карта: 1 из 8 (12.5%). Вторая: 1 из остальных 7 (≈14.29%). Ещё две — по 1 из 8."
  if id == "crown": selection = "Первая карта: равный шанс среди закрытых способностей. Если всё открыто — 1 из 8. Остальные 9 — по 1 из 8 (12.5%)."
  var bonus = "Бонусный слот отключён: лимит 8 достигнут." if int(g.profile.slots)>=8 else "Шанс +1 слота: %d%%, отдельно от карт." % roundi(pack.slot_chance*100)
  var coins = "Монет в этом пакете нет." if pack.coins_max == 0 else "Монеты: %d–%d, равновероятное целое число." % [pack.coins_min,pack.coins_max]
  g.info_block(content,"%s · %d ◇ · %d КАРТ" % [pack.name,pack.price,pack.cards],pack.rule+".\n"+selection+"\n"+coins+"\n"+bonus,Color(pack.color))
 g.info_block(content,"ПОВТОРЫ И ГАРАНТИЯ","Уже открытая карта даёт 1 копию для ручной прокачки.\nЛюбой пакет добавляет 1 к общей гарантии слота. На 50-м без слота он гарантирован; выпадение сбрасывает счётчик. Максимум 8 слотов.\nАнимация не влияет на результат. Все награды сохраняются до начала раскрытия.",Color("ffd184"))
 g.button(g.panel,"←  К ПАКЕТАМ",Rect2(28,851,484,60),g.show_pack_shop)

static func opening(g):
 g.mode = "pack_opening"
 g.clear_ui(g.panel)
 g.backdrop()
 var data: Dictionary = g.profile.pending_pack
 var pack: Dictionary = Catalog.PACKS[data.pack]
 g.text_at(g.panel,pack.name+" · РАСКРЫТИЕ",Vector2(28,47),27,Color(pack.color))
 if g.pack_reveal_index < 0:
  g.text_at(g.panel,"Печать хранит твою награду",Vector2(28,105),17,Color("b9cbdd"))
  var seal = art(g,pack,Vector2(100,220),Vector2(340,410))
  seal.pivot_offset = seal.size*0.5
  var pulse = seal.create_tween()
  pulse.tween_property(seal,"scale",Vector2.ONE*1.06,0.4).set_trans(Tween.TRANS_SINE)
  pulse.tween_property(seal,"scale",Vector2.ONE,0.4).set_trans(Tween.TRANS_SINE)
 else:
  var reward: Dictionary = data.rewards[g.pack_reveal_index]
  g.text_at(g.panel,"НАГРАДА %d / %d" % [g.pack_reveal_index+1,data.rewards.size()],Vector2(28,105),16,Color("b9cbdd"))
  var is_card: bool = reward.kind == "card"
  var ink = Color(g.ABILITIES[reward.id][2]) if is_card else Color("ffd184")
  var content = Panel.new()
  content.position = Vector2(96,208)
  content.size = Vector2(348,434)
  content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var style = StyleBoxFlat.new()
  style.bg_color = Color("111b30")
  style.set_corner_radius_all(18)
  style.set_border_width_all(2)
  style.border_color = ink
  style.shadow_size = 18
  style.shadow_color = Color(ink,0.15)
  content.add_theme_stylebox_override("panel",style)
  g.panel.add_child(content)
  var decoration = load("res://card_decoration.gd").new()
  decoration.ink = ink
  decoration.size = content.size
  decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
  content.add_child(decoration)
  var art_node = SpellArt.new()
  art_node.ability = reward.id if is_card else ("fortune" if reward.kind == "coins" else "pressure")
  art_node.ink = ink
  art_node.position = Vector2(10,56)
  art_node.size = Vector2(328,166)
  art_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
  content.add_child(art_node)
  var badge = ("ПОВТОР · +1 КОПИЯ" if reward["duplicate"] else "НОВАЯ СПОСОБНОСТЬ") if is_card else ("МОНЕТЫ" if reward.kind=="coins" else "РЕДКИЙ БОНУС")
  g.text_at(content,badge,Vector2(24,25),12,ink,300)
  var title = g.ABILITIES[reward.id][0] if is_card else ("+%d МОНЕТ" % reward.amount if reward.kind=="coins" else "+1 СЛОТ")
  var heading = g.text_at(content,title,Vector2(24,239),25,Color.WHITE,300,true)
  heading.size = Vector2(300,68)
  var explanation = ("Копия добавлена для прокачки карты." if reward["duplicate"] else "Теперь доступна в раздачах внутри этапа.") if is_card else ("Начислены в постоянный баланс." if reward.kind=="coins" else "Лимит сборки увеличен навсегда.")
  var description = g.text_at(content,explanation,Vector2(24,327),17,Color("bdcce0"),300,true)
  description.size = Vector2(300,76)
  content.pivot_offset = content.size*0.5
  content.scale = Vector2(0.04,0.94)
  content.modulate.a = 0
  var flip = content.create_tween().set_parallel(true)
  flip.tween_property(content,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  flip.tween_property(content,"modulate:a",1.0,0.15)
 g.text_at(g.panel,"Все награды уже сохранены",Vector2(28,746),15,Color("98acc4"))
 g.button(g.panel,"ПОКАЗАТЬ ВСЁ",Rect2(28,851,484,60),g.skip_pack_reveal)
 g.pack_tween = g.create_tween()
 g.pack_tween.tween_interval(0.85 if g.pack_reveal_index<0 else 0.95)
 g.pack_tween.tween_callback(g.advance_pack_reveal)

static func receipt(g):
 if is_instance_valid(g.pack_tween): g.pack_tween.kill()
 g.mode = "pack_results"
 g.clear_ui(g.panel)
 g.backdrop()
 var data: Dictionary = g.profile.pending_pack
 if data.is_empty():
  shop(g)
  return
 var pack = Catalog.PACKS[data.pack]
 g.text_at(g.panel,"ТВОИ НАГРАДЫ",Vector2(28,44),29,Color(pack.color))
 g.text_at(g.panel,pack.name+" · Уже добавлены в коллекцию и баланс",Vector2(28,98),14,Color("98acc4"))
 var content = g.scroll_content(150,663)
 var copies: Dictionary = {}
 var fresh: Array[String] = []
 for reward in data.rewards:
  if reward.kind == "coins": g.info_block(content,"+%d МОНЕТ" % reward.amount,"Постоянный баланс: %d" % g.profile.coins,Color("ffd184"))
  elif reward.kind == "slot": g.info_block(content,"РЕДКИЙ БОНУС · +1 СЛОТ","Теперь слотов: %d / 8" % g.profile.slots,Color("ffd184"))
  elif reward["duplicate"]: copies[reward.id] = int(copies.get(reward.id,0))+1
  else: fresh.append(reward.id)
 for id in fresh: g.info_block(content,"НОВАЯ · "+g.ABILITIES[id][0],g.ABILITIES[id][1],Color(g.ABILITIES[id][2]))
 for id in copies: g.info_block(content,g.ABILITIES[id][0],"+%d коп. из пакета. В запасе: %d.\nПотрать их в «Прокачке карт»." % [copies[id],int(g.profile.copies.get(id,0))],Color(g.ABILITIES[id][2]))
 g.button(g.panel,"К ПАКЕТАМ",Rect2(28,851,236,60),func():g.dismiss_pack(false))
 g.button(g.panel,"ПРОКАЧКА КАРТ",Rect2(276,851,236,60),func():g.dismiss_pack(true),Color("51412a"))
