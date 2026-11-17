extends SceneTree

func _initialize(): call_deferred("run")

func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.start_run()
 var cards: Array = []
 for id in g.ABILITIES:
  g.choose_card({"id": id,"kind": "new"})
  if id == "bounce": g.build.bounce.recoil = 1
  cards.append({"id":id,"kind":"new","title":g.ABILITIES[id][0],"desc":g.ABILITIES[id][1],"color":g.ABILITIES[id][2]})
  cards.append_array(g.branches(id))
 # Stat cards are included in normal offers, independently of unlocked abilities.
 for i in 40:
  g.offer_cards()
  for card in g.offered:
   if card.kind == "stat" and not cards.any(func(c): return c.id == card.id): cards.append(card)
 var checked = 0
 for card in cards:
  g.clear_ui(g.panel)
  var b = g.ability_card(card,0)
  await process_frame
  for node_name in ["CardTitle","CardDescription"]:
   var label = b.get_node(node_name)
   var font = label.get_theme_font("font")
   var font_size = label.get_theme_font_size("font_size")
   var text_height = label.get_line_count() * font.get_height(font_size) + maxi(0,label.get_line_count()-1)*label.get_theme_constant("line_spacing")
   if label.size.x > 202.1 or text_height > label.size.y + 1:
    push_error("CARD_OVERFLOW: " + card.id + " / " + card.title + " / " + node_name + " height=" + str(text_height) + " bounds=" + str(label.size))
    quit(1)
    return
  checked += 1
 print("CARD_LAYOUT_OK: ",checked," card variants fit")
 quit()
