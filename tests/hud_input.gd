extends SceneTree
func _initialize(): call_deferred("run")
func click_button(b: Button):
 var point = b.get_global_rect().get_center()
 for down in [true,false]:
  var event = InputEventMouseButton.new()
  event.position = point
  event.global_position = point
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  root.push_input(event,true)
 await process_frame
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.profile.owned = g.ABILITIES.keys()
 g.profile.slots = 8
 g.offer_cards()
 await process_frame
 var reroll = g.panel.get_children().filter(func(c):return c is Button and c.text.begins_with("ПЕРЕБРОС"))[0]
 await click_button(reroll)
 if not g.reroll_used or g.mode != "cards":
  push_error("Reroll button did not work")
  quit(1)
  return
 var take_all = g.panel.get_children().filter(func(c):return c is Button and c.text.begins_with("ВЗЯТЬ ВСЁ"))[0]
 await click_button(take_all)
 if not g.take_all_used or g.mode != "play":
  push_error("Take-all button did not work")
  quit(1)
  return
 await process_frame
 g.round_energy = 18
 g.update_hud()
 var before_damage = g.damage
 await click_button(g.labels.buy_damage)
 if g.round_energy != 0 or not is_equal_approx(g.damage,before_damage+2):
  push_error("HUD energy purchase did not apply")
  quit(1)
  return
 g.round_energy = 15
 g.update_hud()
 var pause = g.hud.get_children().filter(func(c): return c is Button and c.text == "Ⅱ")[0]
 await click_button(pause)
 if g.mode != "pause":
  push_error("Pause button did not receive mouse input")
  quit(1)
  return
 var income_buy = g.panel.get_children().filter(func(c):return c is Button and c.text.begins_with("ДОБЫЧА +2"))[0]
 await click_button(income_buy)
 if g.mode != "pause" or g.round_energy != 0 or not is_equal_approx(g.energy_gain,1.02):
  push_error("Paused energy purchase did not apply without resuming")
  quit(1)
  return
 var resume = g.panel.get_children().filter(func(c): return c is Button and c.text == "ПРОДОЛЖИТЬ")[0]
 await click_button(resume)
 if g.mode != "play":
  push_error("Resume button did not receive mouse input")
  quit(1)
  return
 var inspect = g.hud.get_children().filter(func(c): return c is Button and c.text == "СБОРКА")[0]
 await click_button(inspect)
 if g.mode != "build":
  push_error("Build button did not receive mouse input")
  quit(1)
  return
 g.close_build()
 g.finish_run(false)
 g.show_menu()
 g.profile.diamonds = 100
 g.show_pack_shop()
 await process_frame
 var buy = g.panel.get_children().filter(func(c):return c is Button and c.text == "ОТКРЫТЬ · 75 ◇")[0]
 await click_button(buy)
 if g.mode != "pack_opening" or g.profile.diamonds != 25:
  push_error("Pack purchase button did not debit once and start reveal")
  quit(1)
  return
 var skip = g.panel.get_children().filter(func(c):return c is Button and c.text == "ПОКАЗАТЬ ВСЁ")[0]
 await click_button(skip)
 if g.mode != "pack_results":
  push_error("Skip reveal button did not open receipt")
  quit(1)
  return
 var workshop = g.panel.get_children().filter(func(c):return c is Button and c.text == "ПРОКАЧКА КАРТ")[0]
 await click_button(workshop)
 if g.mode != "menu" or not g.profile.pending_pack.is_empty():
  push_error("Receipt navigation did not acknowledge rewards")
  quit(1)
  return
 print("HUD_INPUT_OK: pause, resume, build, pack purchase, skip and receipt buttons respond to viewport mouse events")
 quit()
