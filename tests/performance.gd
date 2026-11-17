extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 g.set_physics_process(false)
 g.start_run()
 g.choose_card({"id":"bounce","kind":"new"})
 g.rings[0].hp = 1e12
 g.rings[0].max_hp = 1e12
 seed(991)
 for i in 30:
  g.queue_redraw()
  await process_frame
 var durations: Array[float] = []
 var physics_us = 0
 for i in 360:
  var frame_begin = Time.get_ticks_usec()
  var begin = Time.get_ticks_usec()
  g._physics_process(1.0 / 60)
  physics_us += Time.get_ticks_usec() - begin
  await process_frame
  durations.append((Time.get_ticks_usec()-frame_begin)/1000.0)
 durations.sort()
 print("PERF frames=360 physics_us_avg=",physics_us/360.0," frame_ms_median=",durations[180]," frame_ms_p95=",durations[342]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
 quit()
