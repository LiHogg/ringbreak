extends SceneTree
func _initialize():
 call_deferred("capture")
func capture():
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 if "--stage2" in OS.get_cmdline_user_args():
  game.profile.stage = 2
  game.profile.selected_stage = 2
 if "--arena" in OS.get_cmdline_user_args():
  game.start_run()
  game.choose_card({"id": "bounce", "kind": "new"})
  game.set_physics_process(false)
  game.update_hud()
  game.queue_redraw()
 if "--cards" in OS.get_cmdline_user_args(): game.start_run()
 if "--energy" in OS.get_cmdline_user_args():
  game.set_physics_process(false)
  game.start_run()
  game.choose_card({"id":"bounce","kind":"new"})
  game.round_energy = 75
  game.buy_energy_upgrade("damage")
  game.buy_energy_upgrade("energy")
  game.update_hud()
  game.queue_redraw()
 if "--damage50" in OS.get_cmdline_user_args():
  game.set_physics_process(false)
  game.profile.power = 0
  game.start_run()
  game.choose_card({"id":"bounce","kind":"new"})
  game.round_energy = 1000000
  for i in 49: game.buy_energy_upgrade("damage")
  game.update_hud()
  game.queue_redraw()
 if "--stages" in OS.get_cmdline_user_args():
  game.profile.stage = 8
  game.show_stages()
 if "--build" in OS.get_cmdline_user_args():
  game.set_physics_process(false)
  game.start_run()
  game.choose_card({"id":"bounce","kind":"new"})
  game.choose_card({"id":"bounce","kind":"upgrade","branch":"force"})
  game.choose_card({"id":"bounce","kind":"upgrade","branch":"recoil"})
  game.choose_card({"id":"bounce","kind":"upgrade","branch":"chance"})
  game.round_energy = 18
  game.buy_energy_upgrade("damage")
  game.show_build()
 if "--workshop" in OS.get_cmdline_user_args():
  game.profile.copies = {"bounce":2,"fire":1,"slow":3}
  game.show_workshop()
 if "--upgrade" in OS.get_cmdline_user_args():
  game.profile.copies = {"bounce":2}
  game.show_card_upgrade("bounce")
 if "--packs" in OS.get_cmdline_user_args():
  game.profile.diamonds = 250
  game.show_pack_shop()
 if "--pack-receipt" in OS.get_cmdline_user_args():
  game.profile.diamonds = 250
  game.buy_pack("crown")
  game.skip_pack_reveal()
 if "--pack-opening" in OS.get_cmdline_user_args():
  game.profile.diamonds = 250
  game.buy_pack("crown")
 if "--pack-card" in OS.get_cmdline_user_args():
  game.profile.diamonds = 250
  game.buy_pack("crown")
  game.pack_tween.kill()
  game.pack_reveal_index = 1
  game.PackScreen.opening(game)
 await create_timer(0.5).timeout
 await process_frame
 await RenderingServer.frame_post_draw
 var tag = "arena" if "--arena" in OS.get_cmdline_user_args() else ("cards" if "--cards" in OS.get_cmdline_user_args() else "menu")
 if "--stage2" in OS.get_cmdline_user_args(): tag = "arena-stage2"
 if "--stages" in OS.get_cmdline_user_args(): tag = "stages"
 for screen in ["build","workshop","upgrade","packs","pack-receipt","pack-opening","pack-card","energy","damage50"]:
  if "--"+screen in OS.get_cmdline_user_args(): tag = screen
 var destination = ProjectSettings.globalize_path("res://outputs/screenshots/")
 DirAccess.make_dir_recursive_absolute(destination)
 root.get_texture().get_image().save_png(destination + tag + ".png")
 quit()
