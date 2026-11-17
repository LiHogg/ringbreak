extends Node2D

const CENTER = Vector2(270, 418)
const BALL_R = 8.0
const GRAVITY = 520.0
const BASE_SHRINK = 1.8
const SpellArt = preload("res://spell_art.gd")
const PackCatalog = preload("res://pack_catalog.gd")
const PackScreen = preload("res://pack_screen.gd")
const PROC_CHANCES = {"bounce": 0.12, "recoil": 0.20, "fire": 0.25, "frost": 0.15, "slow": 0.20, "lightning": 0.25, "heavy": 0.17, "pressure": 0.14, "fortune": 0.25}
const STAGE_COLORS = ["#70e9d0", "#77b7ff", "#b69aff", "#ff8d9e", "#ffc56d", "#9ae376", "#7de1f5", "#e99bef"]
const SAVE = "user://progress.json"
const ABILITIES = {
 "bounce": ["МОЩНЫЙ ОТСКОК", "С шансом 12%: разгон и двойной урон на 3 сек.", "#ffb85c"],
 "fire": ["ГОРЕНИЕ", "Шанс 25% при ударе: горение на 3 сек.", "#ff755f"],
 "frost": ["ЗАМОРОЗКА", "Шанс 15%: хрупкость и остановка сжатия на 2 сек.", "#8ddfff"],
 "slow": ["ЗАМЕДЛЕНИЕ", "Шанс 20%: вращение поражённого кольца −35% на 3 сек.", "#b7a0ff"],
 "lightning": ["МОЛНИЯ", "Шанс 25% при ударе: урон следующему кольцу.", "#f7e384"],
 "heavy": ["ТЯЖЁЛЫЙ УДАР", "Шанс 17% при касании: тройной урон.", "#ff92b8"],
 "pressure": ["ДАВЛЕНИЕ", "Шанс 14% при ударе: расширение колец.", "#65e9c6"],
 "fortune": ["ЗОЛОТАЯ СЕРИЯ", "Шанс 25%: награда за удар или кольцо +50%.", "#ffd76d"]
}
var profile = {"coins": 0, "diamonds": 30, "stage": 1, "selected_stage": 0, "slots": 3, "pity": 0, "power": 0, "owned": ["bounce", "fire", "frost", "slow"], "ranks": {}, "copies": {}, "pending_pack": {}}
var pack_reveal_index = -1
var pack_tween: Tween
var stat_upgrades: Dictionary = {}
var round_energy = 0
var energy_gain = 1.0
var energy_production = 100.0
var energy_remainder = 0.0
var energy_upgrades = {"damage":0,"energy":0}
var run_stage = 1
var hud_elapsed = 0.0
var ring_meshes: Array[ArrayMesh] = []
var ring_visuals: Array[MeshInstance2D] = []
var mode = "menu"
var rings: Array = []
var particles: Array = []
var waves: Array = []
var trail: Array = []
var ball = CENTER
var velocity = Vector2(185, -215)
var earned = 0
var destroyed = 0
var total_rings = 48
var battle_lvl = 1
var xp = 0
var needed = 1
var build: Dictionary = {}
var damage = 10.0
var speed = 280.0
var income = 1.0
var crit = 0.05
var hits = 0
var bounce_left = 0.0
var bounce_duration = 3.0
var bounce_force = 1.65
var bounce_damage = 2.0
var recoil = 0.0
var clock = 0.0
var ring_age = 0.0
var toast = ""
var toast_left = 0.0
var flash = 0.0
var panel: Control
var hud: Control
var labels: Dictionary = {}
var resume_mode = "play"
var auto_test = false
var test_steps = 0
var offered: Array = []
var offer_initial = false
var reroll_used = false
var take_all_used = false

func _ready():
 randomize()
 for gaps in 3: ring_meshes.append(make_ring_mesh(gaps))
 var scenery = load("res://arena_backdrop.gd").new()
 scenery.show_behind_parent = true
 add_child(scenery)
 auto_test = "--smoke-test" in OS.get_cmdline_user_args()
 load_progress()
 var theme = Theme.new()
 theme.default_font_size = 19
 var font = load("res://font.ttf")
 theme.default_font = font
 var canvas = CanvasLayer.new()
 add_child(canvas)
 hud = Control.new()
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.theme = theme
 canvas.add_child(hud)
 panel = Control.new()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel.theme = theme
 canvas.add_child(panel)
 if auto_test:
  start_run()
 else:
  show_menu()
  if not profile.pending_pack.is_empty(): PackScreen.receipt(self)

func load_progress():
 if FileAccess.file_exists(SAVE):
  var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  if data is Dictionary:
   profile.copies = data.get("copies",{}).duplicate() if data.get("copies",{}) is Dictionary else {}
   for k in profile:
    if data.has(k): profile[k] = data[k]

func save_progress() -> bool:
 var path = SAVE+".tmp"
 var f = FileAccess.open(path, FileAccess.WRITE)
 if not f: return false
 f.store_string(JSON.stringify(profile))
 f.flush()
 var error = f.get_error()
 f.close()
 if error != OK: return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(SAVE)) == OK

func clear_ui(root: Control):
 for child in root.get_children():
  root.remove_child(child)
  child.queue_free()

func text_at(root: Control, value: String, pos: Vector2, size: int = 20, color: Color = Color.WHITE, width: float = 460, wrap: bool = false) -> Label:
 var l = Label.new()
 if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.text = value
 l.position = pos
 l.size = Vector2(width, 40)
 l.add_theme_font_size_override("font_size", size)
 l.add_theme_color_override("font_color", color)
 root.add_child(l)
 return l

func button(root: Control, value: String, rect: Rect2, callback: Callable, color: Color = Color("173246")) -> Button:
 var b = Button.new()
 b.text = value
 b.position = rect.position
 b.size = rect.size
 b.add_theme_font_size_override("font_size", 19)
 for state in ["normal", "hover", "pressed", "focus"]:
  var s = StyleBoxFlat.new()
  s.bg_color = color.lightened(0.12) if state == "pressed" else color
  s.corner_radius_top_left = 16
  s.corner_radius_top_right = 16
  s.corner_radius_bottom_left = 16
  s.corner_radius_bottom_right = 16
  s.border_width_bottom = 2
  s.border_color = color.lightened(0.25)
  b.add_theme_stylebox_override(state, s)
 b.pressed.connect(callback)
 root.add_child(b)
 return b

func backdrop():
 var bg = load("res://ui_backdrop.gd").new()
 bg.size = Vector2(540, 960)
 panel.add_child(bg)

func stage_ring_count() -> int:
 return 48 + mini(maxi(0, current_stage() - 1), 6) * 6

func ring_health(index: int, stage: int) -> float:
 var depth = float(maxi(0,index))
 var difficulty = float(maxi(0,stage-1))
 return (32.0+depth*10.0+depth*depth*0.25)*(1.0+difficulty*0.4+difficulty*difficulty*0.025)

func current_stage() -> int:
 return clampi(int(profile.selected_stage) if int(profile.selected_stage) > 0 else int(profile.stage), 1, maxi(1, int(profile.stage)))

func stage_color(stage: int) -> Color:
 var base = Color(STAGE_COLORS[(stage - 1) % STAGE_COLORS.size()])
 return Color.from_hsv(fmod(base.h + int((stage - 1) / STAGE_COLORS.size()) * 0.07, 1.0), base.s, base.v)

func select_stage(stage: int):
 profile.selected_stage = clampi(stage,1,maxi(1,int(profile.stage)))
 save_progress()
 show_menu()

func show_stages(page: int = -1):
 clear_ui(panel)
 backdrop()
 if page < 0: page = int((current_stage() - 1) / 12)
 text_at(panel,"ВЫБОР ЭТАПА",Vector2(32,48),29)
 text_at(panel,"Открыто: %d · Можно переиграть любой" % profile.stage,Vector2(32,100),16,Color("91a7bd"))
 for i in 12:
  var stage = page * 12 + i + 1
  var unlocked = stage <= int(profile.stage)
  var col = stage_color(stage)
  var b = button(panel,"%02d\n%s" % [stage,"ВЫБРАН" if stage == current_stage() else ("ОТКРЫТ" if unlocked else "ЗАКРЫТ")],Rect2(32+(i%3)*164,178+int(i/3)*141,148,120),func():select_stage(stage),col.darkened(0.77) if unlocked else Color("101927"))
  b.add_theme_font_size_override("font_size",17)
  b.disabled = not unlocked
  b.modulate = col if unlocked else Color("647084")
 if page > 0: button(panel,"←",Rect2(32,773,100,50),func():show_stages(page-1))
 if (page+1)*12 < int(profile.stage): button(panel,"→",Rect2(408,773,100,50),func():show_stages(page+1))
 button(panel,"←  ГЛАВНОЕ МЕНЮ",Rect2(32,851,476,60),show_menu)

func next_stage():
 profile.selected_stage = mini(run_stage + 1,int(profile.stage))
 start_run()

func make_ring_mesh(gaps: int) -> ArrayMesh:
 var vertices = PackedVector3Array()
 var colors = PackedColorArray()
 var indices = PackedInt32Array()
 var arcs = maxi(1,gaps)
 var half = PI * (0.20 if gaps == 1 else 0.11)
 for arc in arcs:
  var a = 0.0 if gaps == 0 else arc * TAU/arcs + half
  var b = TAU if gaps == 0 else (arc+1)*TAU/arcs - half
  var segments = maxi(16,int(ceil((b-a)*16)))
  var offset = vertices.size()
  for j in segments + 1:
   var axis = Vector2.from_angle(lerpf(a,b,float(j)/segments))
   for k in 4:
    var radius = [0.994,0.999,1.001,1.006][k]
    vertices.append(Vector3(axis.x*radius,axis.y*radius,0))
    colors.append(Color(1,1,1,0 if k == 0 or k == 3 else 1))
  for j in segments:
   for k in 3:
    var n = offset+j*4+k
    indices.append_array(PackedInt32Array([n,n+1,n+4,n+1,n+5,n+4]))
 var arrays = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_COLOR] = colors
 arrays[Mesh.ARRAY_INDEX] = indices
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return mesh

func sync_ring_visuals():
 var theme_color = stage_color(run_stage)
 for i in rings.size():
  var r = rings[i]
  var visual = ring_visuals[r.index]
  visual.visible = i > 0 and r.r > 0 and r.r <= 238
  if not visual.visible: continue
  visual.position = CENTER
  visual.rotation = r.angle
  visual.scale = Vector2.ONE * r.r
  var color = theme_color.darkened(0.55 if i % 6 else 0.30)
  if r.burn > 0: color = Color("ff8a5b")
  if r.freeze > 0: color = Color("9cddff")
  elif r.slow > 0: color = Color("b7a0ff")
  visual.self_modulate = color

func ability_card(card: Dictionary, index: int):
 var col = Color(card.color)
 var x = 24 + (index % 2) * 256
 var y = 166 + int(index / 2) * 350
 var b = button(panel, "", Rect2(x, y, 236, 334), func(): choose_card(card))
 b.pivot_offset = b.size * 0.5
 var ornament = load("res://card_decoration.gd").new()
 ornament.ink = col
 ornament.size = b.size
 ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
 b.add_child(ornament)
 for state in ["normal", "hover", "pressed", "focus"]:
  var s = StyleBoxFlat.new()
  s.bg_color = Color("10172a").lerp(col, 0.06 if state == "normal" else 0.14)
  s.set_corner_radius_all(15)
  s.set_border_width_all(1 if state == "normal" else 2)
  s.border_color = Color("b79a65").lerp(col,0.35) if state == "normal" else col
  s.shadow_color = Color(0, 0, 0, 0.55)
  s.shadow_size = 9
  s.shadow_offset = Vector2(0, 6)
  b.add_theme_stylebox_override(state, s)
 var inset = Panel.new()
 inset.position = Vector2(7,7)
 inset.size = Vector2(222,320)
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var edge = StyleBoxFlat.new()
 edge.bg_color = Color.TRANSPARENT
 edge.set_border_width_all(1)
 edge.border_color = Color(col,0.12)
 edge.set_corner_radius_all(10)
 inset.add_theme_stylebox_override("panel",edge)
 b.add_child(inset)
 var kind = "УЛУЧШЕНИЕ" if card.kind == "upgrade" else ("УСИЛЕНИЕ" if card.kind == "stat" else "СПОСОБНОСТЬ")
 var badge = text_at(b,kind,Vector2(17,13),10,col,185)
 badge.size.y = 18
 var number = text_at(b,"%02d" % (index+1),Vector2(199,12),12,Color(col,0.65),25)
 number.size.y = 20
 var art = SpellArt.new()
 art.ability = card.id
 art.ink = col
 art.position = Vector2(14,40)
 art.size = Vector2(208,111)
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 b.add_child(art)
 var divider = ColorRect.new()
 divider.position = Vector2(17,157)
 divider.size = Vector2(202,1)
 divider.color = Color(col,0.3)
 divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
 b.add_child(divider)
 var title = text_at(b,card.title,Vector2(17,169),17,Color("f4ebd6"),202,true)
 title.name = "CardTitle"
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 title.size = Vector2(202,46)
 var desc = text_at(b,card.desc,Vector2(17,220),14,Color("b9cbdd"),202,true)
 desc.name = "CardDescription"
 desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 desc.size = Vector2(202,72)
 var pick = text_at(b,"ВЫБРАТЬ  →",Vector2(17,303),11,col,202)
 pick.size.y = 18
 for child in b.get_children():
  if child is Control: child.mouse_filter = Control.MOUSE_FILTER_IGNORE
 b.modulate.a = 0
 var intro = b.create_tween()
 intro.tween_interval(index * 0.035)
 intro.tween_property(b,"modulate:a",1.0,0.18)
 return b

func show_menu(message: String = ""):
 mode = "menu"
 for visual in ring_visuals: visual.hide()
 queue_redraw()
 clear_ui(panel)
 clear_ui(hud)
 backdrop()
 text_at(panel, "RINGBREAK", Vector2(38, 58), 42, Color("73f4d1"))
 text_at(panel, "П Р О Р Ы В   /   АРКАНЫ И НЕОН", Vector2(40, 116), 13, Color("c6a76e"))
 text_at(panel, "ПРОТОТИП 0.1.10", Vector2(40, 145), 10, Color("7188a1"))
 text_at(panel, "%d монет       ◇ %d алмазов" % [profile.coins, profile.diamonds], Vector2(40, 188), 22)
 text_at(panel, "ЭТАП %d" % current_stage(), Vector2(40, 258), 32,stage_color(current_stage()),260)
 button(panel,"ВЫБОР ЭТАПА",Rect2(310,256,190,47),show_stages,stage_color(current_stage()).darkened(0.8))
 text_at(panel, "%d колец · Сжатие ускорено" % stage_ring_count(), Vector2(40, 310), 18, Color("a7bed0"))
 button(panel, "НАЧАТЬ ЭТАП  →", Rect2(40, 365, 460, 68), start_run, Color("176a60"))
 button(panel, "КОЛЛЕКЦИЯ", Rect2(40, 454, 224, 60), show_collection)
 button(panel, "ПРОКАЧКА КАРТ", Rect2(276, 454, 224, 60), show_workshop,Color("51412a"))
 button(panel, "ХРАНИЛИЩЕ АРКАНОВ  ·  ПАКЕТЫ", Rect2(40, 528, 460, 60), show_pack_shop,Color("39304d"))
 text_at(panel, ("Слоты: %d / 8     До гарантии слота: %d" % [profile.slots, 50 - int(profile.pity)]) if profile.slots < 8 else "Все 8 слотов открыты", Vector2(42, 600), 17, Color("b7a0ff"))
 var cost = 60 + int(profile.power) * 45
 button(panel, "БАЗОВЫЙ УРОН +10%%  ·  %d монет" % cost, Rect2(40, 650, 460, 60), upgrade_power)
 text_at(panel, "Постоянный бонус урона: +%d%%" % (int(profile.power) * 10), Vector2(42, 720), 17, Color("91a7bd"))
 var note = message if message != "" else "Новая сборка в каждой попытке.\nПри поражении сохраняется 40% заработка."
 var l = text_at(panel, note, Vector2(40, 782), 18, Color("f3d58a"),460,true)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.size.y = 125
 save_progress()

func upgrade_power():
 var cost = 60 + int(profile.power) * 45
 if profile.coins < cost:
  show_menu("Не хватает монет. Заработай их в этапе.")
  return
 profile.coins -= cost
 profile.power += 1
 show_menu("Базовый урон увеличен для всех попыток.")

func open_pack():
 buy_pack("spark")

func show_pack_shop():
 PackScreen.shop(self)

func show_pack_odds():
 PackScreen.odds(self)

func buy_pack(id: String):
 var receipt = PackCatalog.purchase(self,id)
 if receipt.is_empty(): return
 pack_reveal_index = -1
 PackScreen.opening(self)

func advance_pack_reveal():
 if mode != "pack_opening": return
 pack_reveal_index += 1
 if pack_reveal_index >= profile.pending_pack.rewards.size(): PackScreen.receipt(self)
 else: PackScreen.opening(self)

func skip_pack_reveal():
 if mode == "pack_opening": PackScreen.receipt(self)

func dismiss_pack(workshop: bool = false):
 if mode != "pack_results": return
 var receipt: Dictionary = profile.pending_pack.duplicate(true)
 profile.pending_pack = {}
 if not save_progress():
  profile.pending_pack = receipt
  return
 if workshop:
  mode = "menu"
  show_workshop()
 else: show_pack_shop()

func receive_card(id: String) -> bool:
 if id in profile.owned:
  profile.copies[id] = int(profile.copies.get(id,0))+1
  return true
 profile.owned.append(id)
 return false

func upgrade_cost(id: String) -> int:
 return int(profile.ranks.get(id,0))+1

func upgrade_card(id: String) -> bool:
 if mode != "menu" or not id in profile.owned: return false
 var cost = upgrade_cost(id)
 if int(profile.copies.get(id,0)) < cost: return false
 profile.copies[id] = int(profile.copies.get(id,0))-cost
 profile.ranks[id] = int(profile.ranks.get(id,0))+1
 save_progress()
 return true

func scroll_content(top: float = 155, height: float = 660) -> VBoxContainer:
 var scroll = ScrollContainer.new()
 scroll.position = Vector2(28,top)
 scroll.size = Vector2(484,height)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 var content = VBoxContainer.new()
 content.custom_minimum_size.x = 466
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",14)
 scroll.add_child(content)
 return content

func info_block(parent: Control, title: String, body: String, col: Color) -> PanelContainer:
 var box = PanelContainer.new()
 var style = StyleBoxFlat.new()
 style.bg_color = Color("101d2c").lerp(col,0.06)
 style.border_color = Color(col,0.35)
 style.set_border_width_all(1)
 style.set_corner_radius_all(14)
 style.content_margin_left = 18
 style.content_margin_right = 18
 style.content_margin_top = 16
 style.content_margin_bottom = 18
 box.add_theme_stylebox_override("panel",style)
 parent.add_child(box)
 var stack = VBoxContainer.new()
 stack.add_theme_constant_override("separation",10)
 box.add_child(stack)
 for entry in [[title,18,col],[body,15,Color("bfd1e1")]]:
  var label = Label.new()
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.text = entry[0]
  label.add_theme_font_size_override("font_size",entry[1])
  label.add_theme_color_override("font_color",entry[2])
  stack.add_child(label)
 return box

func show_workshop():
 clear_ui(panel)
 backdrop()
 text_at(panel,"ПРОКАЧКА КАРТ",Vector2(28,44),29,Color("ffcf84"))
 text_at(panel,"Повторы копятся. Выбирай, какую карту усилить.",Vector2(28,96),15,Color("91a7bd"))
 var content = scroll_content()
 for id in ABILITIES:
  var owned = id in profile.owned
  var card_id: String = id
  var line = "%s\nРанг %d · Копии %d/%d" % [ABILITIES[id][0],int(profile.ranks.get(id,0))+1,int(profile.copies.get(id,0)),upgrade_cost(id)] if owned else ABILITIES[id][0]+"\nЕщё не открыта"
  var b = button(content,line,Rect2(0,0,466,88),func():show_card_upgrade(card_id),Color(ABILITIES[id][2]).darkened(0.8))
  b.custom_minimum_size.y = 88
  b.add_theme_font_size_override("font_size",17)
 button(panel,"←  ГЛАВНОЕ МЕНЮ",Rect2(28,851,484,60),show_menu)

func show_card_upgrade(id: String):
 clear_ui(panel)
 backdrop()
 var col = Color(ABILITIES[id][2])
 text_at(panel,"ПОСТОЯННАЯ КАРТА",Vector2(28,38),12,col)
 var title = text_at(panel,ABILITIES[id][0],Vector2(28,74),26,Color.WHITE,484,true)
 title.size = Vector2(484,65)
 var art = SpellArt.new()
 art.ability = id
 art.ink = col
 art.position = Vector2(28,146)
 art.size = Vector2(484,135)
 panel.add_child(art)
 var content = scroll_content(302,397)
 var rank = int(profile.ranks.get(id,0))
 var owned = id in profile.owned
 info_block(content,"РАНГ %d  ·  СИЛА +%d%%" % [rank+1,rank*5] if owned else "КАРТА НЕ ОТКРЫТА",ABILITIES[id][1]+"\nПостоянный ранг усиливает эффект; шанс повышается карточками внутри этапа.",col)
 var count = int(profile.copies.get(id,0))
 var cost = upgrade_cost(id)
 info_block(content,"КОПИИ %d / %d" % [count,cost],"Следующий ранг: %d → %d.\nПостоянная сила: +%d%% → +%d%%.\nПовторы выпадают из пакетов. Ранги сохраняются между попытками." % [rank+1,rank+2,rank*5,(rank+1)*5] if owned else "Открой карту в случайном пакете. Затем её повторы можно тратить на повышение ранга.",Color("ffcf84"))
 var can_upgrade = owned and count >= cost
 var action = button(panel,"ПОВЫСИТЬ · %d КОП." % cost if can_upgrade else ("НЕ ХВАТАЕТ КОПИЙ" if owned else "НУЖНО ОТКРЫТЬ КАРТУ"),Rect2(28,729,484,66),func():
  if upgrade_card(id): show_card_upgrade(id),col.darkened(0.6))
 action.disabled = not can_upgrade
 button(panel,"←  К ПРОКАЧКЕ КАРТ",Rect2(28,851,484,60),show_workshop)

func show_collection():
 clear_ui(panel)
 backdrop()
 text_at(panel, "КОЛЛЕКЦИЯ КАРТ", Vector2(32, 48), 29)
 text_at(panel, "Карты открываются из случайных пакетов", Vector2(32, 95), 17, Color("91a7bd"))
 var y = 155
 for id in ABILITIES:
  var owned = id in profile.owned
  text_at(panel, ("● " if owned else "○ ") + ABILITIES[id][0], Vector2(32, y), 21, Color(ABILITIES[id][2]) if owned else Color("59677e"))
  var desc = ABILITIES[id][1] if owned else "Не открыто · случайная карта из пакета"
  text_at(panel, desc, Vector2(32, y + 32), 14, Color("a7bed0"))
  y += 82
 button(panel, "←  НАЗАД", Rect2(32, 850, 476, 60), show_menu)

func start_run():
 run_stage = current_stage()
 for visual in ring_visuals: visual.queue_free()
 ring_visuals.clear()
 rings.clear()
 trail.clear()
 particles.clear()
 waves.clear()
 build.clear()
 stat_upgrades.clear()
 reroll_used = false
 take_all_used = false
 round_energy = 0
 energy_gain = 1.0
 energy_production = 100.0
 energy_remainder = 0.0
 energy_upgrades = {"damage":0,"energy":0}
 earned = 0
 destroyed = 0
 battle_lvl = 1
 xp = 0
 needed = 1
 hits = 0
 bounce_left = 0
 bounce_duration = 3
 bounce_force = 1.65
 bounce_damage = 2
 recoil = 0
 damage = 10.0 * (1.0 + profile.power * 0.1)
 speed = 280
 income = 1
 crit = 0.05
 ring_age = 0
 ball = CENTER
 velocity = Vector2.from_angle(randf() * TAU) * speed
 total_rings = stage_ring_count()
 for i in total_rings:
  var gaps = 0 if i % 3 == 0 else (2 if i % 3 == 2 else 1)
  var hp = ring_health(i,run_stage)
  var visual = MeshInstance2D.new()
  visual.mesh = ring_meshes[gaps]
  add_child(visual)
  ring_visuals.append(visual)
  rings.append({"r": 70.0 + i * minf(12, 156.0 / (total_rings - 1)), "start_r": 70.0 + i * minf(12, 156.0 / (total_rings - 1)), "hp": hp, "max_hp": hp, "angle": randf() * TAU, "omega": randf_range(0.22, 0.7) * (-1 if i % 2 else 1), "gaps": gaps, "burn": 0.0, "freeze": 0.0, "slow": 0.0, "index": i})
 create_hud()
 sync_ring_visuals()
 offer_cards(true)

func create_hud():
 clear_ui(hud)
 clear_ui(panel)
 labels.stage = text_at(hud, "", Vector2(24, 34), 24)
 labels.money = text_at(hud, "", Vector2(24, 72), 18, Color("f7d77a"))
 button(hud, "Ⅱ", Rect2(460, 28, 56, 55), pause_game)
 labels.progress = text_at(hud, "", Vector2(24, 122), 17, Color("91a7bd"))
 labels.hp = text_at(hud, "", Vector2(24, 704), 19)
 labels.status = text_at(hud, "", Vector2(24, 742), 16, Color("91a7bd"))
 labels.energy = text_at(hud,"",Vector2(24,779),19,Color("9cf6ed"),300)
 labels.energy.size.y = 28
 labels.build = text_at(hud, "", Vector2(24, 812), 14, Color("91a7bd"),300,true)
 labels.build.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 labels.build.size = Vector2(300, 28)
 button(hud,"СБОРКА",Rect2(345,783,171,54),show_build,Color("235148"))
 labels.buy_damage = button(hud,"",Rect2(24,853,236,58),func():buy_energy_upgrade("damage"),Color("235148"))
 labels.buy_energy = button(hud,"",Rect2(280,853,236,58),func():buy_energy_upgrade("energy"),Color("51412a"))
 labels.buy_damage.add_theme_font_size_override("font_size",14)
 labels.buy_energy.add_theme_font_size_override("font_size",14)
 labels.tip = text_at(hud, "Энергия действует только в текущей попытке", Vector2(24, 925), 12, Color("91a7bd"))

func energy_upgrade_cost(id: String) -> int:
 var production_factor = upgrade_price_multiplier(int(energy_upgrades.energy))
 if id == "damage": return int((18 + int(energy_upgrades.damage)*12) * upgrade_price_multiplier(int(energy_upgrades.damage)) * production_factor)
 return int((15 + int(energy_upgrades.energy)*10) * production_factor)

func upgrade_price_multiplier(level: int) -> float:
 var factor = 1.0
 for milestone in range(10,level+1,10): factor *= damage_milestone(milestone)
 return factor

func next_energy_production() -> float:
 var level = int(energy_upgrades.energy)+1
 return (energy_production+damage_increment(level))*damage_milestone(level)

func energy_button_title() -> String:
 var level = int(energy_upgrades.energy)+1
 var label = "ДОБЫЧА +%s" % compact_number(damage_increment(level))
 var multiplier = damage_milestone(level)
 if multiplier > 1: label += " · ×%.0f" % multiplier
 return label

func damage_increment(level: int) -> float:
 var first = [2,4,6,10,15,20]
 return float(first[level-1]) if level <= 6 else 20.0+(level-6)*5

func damage_milestone(level: int) -> float:
 if level <= 0 or level % 10 != 0: return 1.0
 return 5.0 if level >= 50 else 2.0

func next_damage_value() -> float:
 var level = int(energy_upgrades.damage)+1
 return (damage+damage_increment(level))*damage_milestone(level)

func compact_number(value: float) -> String:
 for unit in [[1e12,"трлн"],[1e9,"млрд"],[1e6,"млн"],[1e3,"тыс"]]:
  if value >= unit[0]: return "%.1f%s" % [value/unit[0],unit[1]]
 return "%.0f" % value

func damage_button_title() -> String:
 var level = int(energy_upgrades.damage)+1
 var label = "УРОН +%s" % compact_number(damage_increment(level))
 var multiplier = damage_milestone(level)
 if multiplier > 1: label += " · ×%.0f" % multiplier
 return label

func buy_energy_upgrade(id: String) -> bool:
 if not mode in ["play","pause"] or not id in ["damage","energy"]: return false
 var cost = energy_upgrade_cost(id)
 if round_energy < cost: return false
 var new_damage = next_damage_value()
 var new_production = next_energy_production()
 round_energy -= cost
 energy_upgrades[id] += 1
 stat_upgrades[id] = int(stat_upgrades.get(id,0))+1
 if id == "damage": damage = new_damage
 else:
  energy_production = new_production
  energy_gain = energy_production/100.0
 notify("УРОН · %s (LV %d)" % [compact_number(damage),energy_upgrades.damage] if id == "damage" else "ДОБЫЧА · %s (LV %d)" % [compact_number(energy_production),energy_upgrades.energy])
 update_hud()
 if mode == "pause":
  mode = "play"
  pause_game()
 return true

func gain_energy(base_amount: int):
 var total = base_amount * energy_gain + energy_remainder
 var whole = int(floor(total + 0.000000001))
 round_energy += whole
 energy_remainder = maxf(0,total-whole)

func pause_game():
 if mode != "play": return
 mode = "pause"
 clear_ui(panel)
 backdrop()
 text_at(panel, "ПАУЗА", Vector2(40, 105), 36)
 text_at(panel,"Энергия: %d · Добыча ×%.2f" % [round_energy,energy_gain],Vector2(40,178),17,Color("9cf6ed"))
 text_at(panel,"Усиления действуют до конца попытки",Vector2(40,220),14,Color("91a7bd"))
 button(panel, "ПРОДОЛЖИТЬ", Rect2(40, 290, 460, 65), func():
  clear_ui(panel)
  mode = "play")
 button(panel, "МОЯ СБОРКА", Rect2(40, 378, 460, 65), show_build)
 for id in ["damage","energy"]:
  var key: String = id
  var b = button(panel,(damage_button_title() if id == "damage" else energy_button_title())+"\n%s энергии" % compact_number(energy_upgrade_cost(id)),Rect2(40 if id == "damage" else 278,482,222,70),func():buy_energy_upgrade(key))
  b.add_theme_font_size_override("font_size",15)
  b.disabled = round_energy < energy_upgrade_cost(id)
 button(panel, "ЗАВЕРШИТЬ · СОХРАНИТЬ 40%", Rect2(40, 620, 460, 65), func(): finish_run(false))

func card_pool(initial: bool = false) -> Array:
 var pool: Array = []
 if build.size() < int(profile.slots):
  for id in profile.owned:
   if not build.has(id): pool.append({"id": id, "kind": "new", "title": ABILITIES[id][0], "desc": ABILITIES[id][1], "color": ABILITIES[id][2]})
 if not initial:
  for id in build:
   for branch in branches(id): pool.append(branch)
  pool.append({"id": "speed", "kind": "stat", "title": "СКОРОСТЬ +12%", "desc": "Больше отскоков. Максимум: 480.", "color": "#73f4d1"})
  pool.append({"id": "crit", "kind": "stat", "title": "КРИТИЧЕСКИЙ ШАНС +8%", "desc": "Крит наносит двойной урон. Максимум: 65%.", "color": "#ff92b8"})
 return pool

func offer_cards(initial: bool = false, forced: Dictionary = {}):
 mode = "cards"
 offer_initial = initial
 var pool = card_pool(initial)
 pool.shuffle()
 offered.clear()
 if not forced.is_empty(): offered.append(forced)
 # Guarantee an equipped ability upgrade; base damage/income use energy instead.
 if not initial:
  var useful = pool.filter(func(c): return c.kind == "upgrade")
  if not useful.is_empty():
   if not offered.any(func(c):return c.kind == "upgrade"): offered.append(useful.pick_random())
  else:
   for c in pool:
    if c.kind == "stat" and ((c.id == "crit" and crit < 0.65) or (c.id == "speed" and speed < 480)):
     offered.append(c)
     break
 for c in pool:
  if offered.size() >= 4: break
  if not c in offered: offered.append(c)
 offered.shuffle()
 render_card_offer(initial)

func card_key(card: Dictionary) -> String:
 return "%s:%s:%s" % [card.kind,card.id,card.get("branch","")]

func reroll_candidates() -> Array:
 var keys: Array = offered.map(func(c):return card_key(c))
 return card_pool(offer_initial).filter(func(c):return not card_key(c) in keys)

func reroll_cards() -> bool:
 if mode != "cards" or reroll_used: return false
 var fresh = reroll_candidates()
 if fresh.is_empty(): return false
 reroll_used = true
 offer_cards(offer_initial,fresh.pick_random())
 return true

func offer_new_slots() -> int:
 return offered.filter(func(c):return c.kind == "new" and not build.has(c.id)).size()

func can_take_all() -> bool:
 return not take_all_used and offered.size() == 4 and build.size()+offer_new_slots() <= int(profile.slots)

func take_all_cards() -> bool:
 if mode != "cards" or not can_take_all(): return false
 take_all_used = true
 var selected = offered.duplicate(true)
 for card in selected: choose_card(card)
 return true

func render_card_offer(initial: bool = false):
 mode = "cards"
 clear_ui(panel)
 backdrop()
 text_at(panel, "СОБЕРИ СВОЮ СИЛУ", Vector2(24, 27), 11, Color("c6a76e"))
 text_at(panel, "ВЫБЕРИ КАРТУ", Vector2(24, 57), 31, Color("f4f5f7"))
 text_at(panel, "Начальная сборка · выбери одну" if initial else "Боевой lvl %d · выбери одну" % battle_lvl, Vector2(24, 108), 17, Color("a7bed0"))
 for i in offered.size(): ability_card(offered[i], i)
 var reroll = button(panel,"ПЕРЕБРОС %d/1" % (0 if reroll_used else 1),Rect2(24,878,174,34),reroll_cards)
 reroll.add_theme_font_size_override("font_size",12)
 reroll.disabled = reroll_used or reroll_candidates().is_empty()
 reroll.tooltip_text = "Других вариантов пока нет" if reroll_candidates().is_empty() else "Новая четвёрка. Один раз за попытку."
 var all_cards = button(panel,"ВЗЯТЬ ВСЁ %d/1" % (0 if take_all_used else 1),Rect2(210,878,164,34),take_all_cards,Color("51412a"))
 all_cards.add_theme_font_size_override("font_size",12)
 all_cards.disabled = not can_take_all()
 var inspect = button(panel,"СБОРКА",Rect2(386,878,130,34),show_build)
 inspect.add_theme_font_size_override("font_size",13)
 var footer = "Время остановлено. Каждая кнопка — 1 раз за попытку."
 if offer_new_slots() > int(profile.slots)-build.size(): footer = "Для всех карт нужно %d слотов, свободно %d. Время остановлено." % [offer_new_slots(),maxi(0,int(profile.slots)-build.size())]
 var note = text_at(panel,footer,Vector2(24,919),12,Color("91a7bd"),492,true)
 note.size = Vector2(492,34)
 update_hud()

func branches(id: String) -> Array:
 var options: Array = []
 var defs: Array
 match id:
  "bounce": defs = [["duration", "ДЛИТЕЛЬНОСТЬ ОТСКОКА", "+1.5 сек. усиленного состояния."], ["force", "СИЛА ОТСКОКА", "+20% к разгону во время способности."], ["damage", "УРОН ОТСКОКА", "+0.5 к множителю урона."], ["recoil", "ОТДАЧА", "Шанс 20% при усиленном ударе: расширение +1.5."], ["recoil_chance", "ШАНС ОТДАЧИ", "+5 п.п. к шансу отдачи, максимум 75%."]]
  "fire": defs = [["power", "ЖАР", "+40% к урону горения."], ["duration", "ДОЛГОЕ ПЛАМЯ", "+2 сек. длительности горения."]]
  "frost": defs = [["power", "ХРУПКИЙ ЛЁД", "Ещё +30% урона по замороженному кольцу."], ["duration", "ГЛУБОКИЙ ХОЛОД", "+1.5 сек. заморозки."]]
  "slow": defs = [["power", "ВЯЗКОЕ ВРЕМЯ", "Ещё −10% скорости вращения при эффекте, до −75%."], ["duration", "СДЕРЖИВАНИЕ", "+1 сек. эффекта; во время него сжатие медленнее на 12%."]]
  "lightning": defs = [["power", "НАПРЯЖЕНИЕ", "+50% к урону молнии."], ["duration", "ЧАСТЫЙ РАЗРЯД", "+5 п.п. к шансу молнии, максимум 75%."]]
  "heavy": defs = [["power", "СОКРУШЕНИЕ", "+1 к множителю тяжёлого удара."], ["duration", "РИТМ УДАРОВ", "+5 п.п. к шансу тяжёлого удара, максимум 75%."]]
  "pressure": defs = [["power", "СИЛЬНАЯ ВОЛНА", "+3 к расширению колец."], ["duration", "ПУЛЬСАЦИЯ", "+5 п.п. к шансу волны, максимум 75%."]]
  _: defs = [["power", "ЗОЛОТОЙ ПОТОК", "При срабатывании ещё +25% к награде."], ["duration", "ПРЕМИЯ ЗА РАЗРУШЕНИЕ", "При срабатывании на кольце ещё +5 монет."]]
 if id in ["bounce","fire","frost","slow","fortune"]:
  defs.append(["chance","ШАНС СПОСОБНОСТИ","+5 п.п. к шансу срабатывания, максимум 75%."])
 for d in defs:
  if d[0] in ["chance","recoil_chance"]:
   var chance = proc_chance("recoil" if d[0] == "recoil_chance" else id)
   d[2] = "%d%% → %d%% при ударе. Максимум 75%%." % [roundi(chance*100),roundi(minf(0.75,chance+0.05)*100)]
  if id == "bounce" and d[0] == "recoil":
   d[2] = "Шанс %d%% при усиленном ударе: расширение +1.5." % roundi(proc_chance("recoil")*100)
  var cap = 999
  if id == "bounce" and d[0] == "force": cap = 5
  if id == "bounce" and d[0] == "duration": cap = 4
  if id in ["lightning", "heavy", "pressure"] and d[0] == "duration": cap = int(ceil((0.75 - PROC_CHANCES[id]) / 0.05))
  if id == "slow" and d[0] == "power": cap = 4
  if d[0] == "recoil_chance":
   if build.bounce.recoil == 0: continue
   cap = 11
  if d[0] == "chance": cap = int(ceil((0.75-PROC_CHANCES[id])/0.05))
  if build[id].get(d[0], 0) >= cap: continue
  options.append({"id": id, "kind": "upgrade", "branch": d[0], "title": d[1], "desc": d[2], "color": ABILITIES[id][2]})
 return options

func choose_card(c: Dictionary):
 if c.kind == "new":
  build[c.id] = {"power": 0, "duration": 0, "force": 0, "damage": 0, "recoil": 0, "chance": 0, "recoil_chance": 0}
 elif c.kind == "upgrade":
  build[c.id][c.branch] += 1
 else:
  if not c.id in ["speed","crit"]: return
  stat_upgrades[c.id] = int(stat_upgrades.get(c.id,0))+1
  match c.id:
   "speed": speed = minf(480, speed * 1.12)
   "crit": crit = minf(0.65, crit + 0.08)
 clear_ui(panel)
 mode = "play"
 update_hud()
 queue_redraw()

func chosen_upgrades(id: String) -> String:
 var names = {"power":"Сила эффекта","duration":"Длительность","force":"Сила отскока","damage":"Урон отскока","recoil":"Отдача","chance":"Шанс способности","recoil_chance":"Шанс отдачи"}
 if id in ["lightning","heavy","pressure"]: names.duration = "Частота срабатывания"
 if id == "slow": names.duration = "Сдерживание"
 if id == "fortune": names.duration = "Премия за разрушение"
 var lines: Array[String] = []
 for key in names:
  var count = int(build[id].get(key,0))
  if count > 0: lines.append("• %s ×%d" % [names[key],count])
 return "Улучшения ещё не выбраны." if lines.is_empty() else "Выбранные улучшения:\n"+"\n".join(lines)

func ability_summary(id: String) -> String:
 var b = build[id]
 var rank = rank_bonus(id)
 var summary = "Шанс при ударе: %d%%\n" % roundi(proc_chance(id)*100)
 match id:
  "bounce":
   summary += "Длительность: %.1f сек. · Скорость ×%.2f\nУрон ×%.2f" % [3+b.duration*1.5,minf(2.5,1.65+b.force*0.2),(2+b.damage*0.5)*rank]
   if b.recoil > 0: summary += "\nОтдача: %d%% при усиленном ударе, расширение %.1f" % [roundi(proc_chance("recoil")*100),b.recoil*1.5]
  "fire": summary += "Горение: %.1f урона/сек. в течение %.1f сек." % [damage*(0.26+b.power*0.104)*rank,3+b.duration*2]
  "frost": summary += "Заморозка: %.1f сек.\nУрон по замороженному кольцу ×%.2f" % [2+b.duration*1.5,(1.5+b.power*0.3)*rank]
  "slow": summary += "Вращение −%d%% на %.1f сек.\nВо время эффекта сжатие −%d%%" % [roundi(minf(0.75,(0.35+b.power*0.1)*rank)*100),3+b.duration,roundi((1-pow(0.88,b.duration))*100)]
  "lightning": summary += "Следующему кольцу: %.1f урона" % [damage*(1.5+b.power*0.75)*rank]
  "heavy": summary += "Тяжёлый удар: урон ×%.2f" % [(3+b.power)*rank]
  "pressure": summary += "Расширение колец: %.1f" % [(5+b.power*3)*rank]
  "fortune": summary = "Шанс при выплате за удар / кольцо: %d%%\nПри срабатывании награда ×%.2f\nПремия за кольцо: +%d монет" % [roundi(proc_chance(id)*100),(1.5+b.power*0.25)*rank,b.duration*5]
 return summary+"\nПостоянный ранг: %d (+%d%% к силе)" % [int(profile.ranks.get(id,0))+1,int(profile.ranks.get(id,0))*5]

func show_build():
 if not mode in ["play","pause","cards"]: return
 resume_mode = mode
 mode = "build"
 clear_ui(panel)
 backdrop()
 text_at(panel,"МОЯ СБОРКА",Vector2(28,43),30,Color("73f4d1"))
 text_at(panel,"Этап %d · LVL %d · Слоты %d/%d" % [run_stage,battle_lvl,build.size(),profile.slots],Vector2(28,96),16,Color("91a7bd"))
 var content = scroll_content()
 info_block(content,"ПАРАМЕТРЫ ШАРИКА","Урон %.1f · Импульс %.0f\nДоход ×%.2f · Крит %d%%\nВыбрано общих усилений: %d" % [damage,speed,income,roundi(crit*100),stat_upgrade_count()],Color("ffcf84"))
 info_block(content,"ЭНЕРГИЯ ПОПЫТКИ · %d" % round_energy,"Уровень урона: %d, добычи: %d.\nПолучение энергии ×%.3f.\nСледующая цена: урон %d, добыча %d энергии.\nДобыча усиливает энергию за удары, кольца и разрезы. Монеты не затрагиваются. Дробные прибавки накапливаются. Остаток сгорает в конце попытки." % [energy_upgrades.damage,energy_upgrades.energy,energy_gain,energy_upgrade_cost("damage"),energy_upgrade_cost("energy")],Color("9cf6ed"))
 var next_energy_milestone = (int(energy_upgrades.energy)/10+1)*10
 info_block(content,"ПРОГРЕССИЯ ДОБЫЧИ · LV %d" % energy_upgrades.energy,"Значение: %s → %s; 100 = обычная добыча.\nСледующая прибавка +%s. На LV %d всё значение ×%.0f.\nЦены: множитель добычи ×%s, урона ×%s.\nДесятки добычи повышают цены обеих кнопок. Десятки урона — дополнительно его цену." % [compact_number(energy_production),compact_number(next_energy_production()),compact_number(damage_increment(int(energy_upgrades.energy)+1)),next_energy_milestone,damage_milestone(next_energy_milestone),compact_number(upgrade_price_multiplier(int(energy_upgrades.energy))),compact_number(upgrade_price_multiplier(int(energy_upgrades.damage)))],Color("9cf6ed"))
 var next_milestone = (int(energy_upgrades.damage)/10+1)*10
 info_block(content,"ПРОГРЕССИЯ УРОНА · LV %d" % energy_upgrades.damage,"Следующая покупка: +%s.\nУрон: %s → %s.\nНа LV %d весь урон ×%.0f.\nДо 50-го уровня каждая десятка даёт ×2; с 50-го — ×5." % [compact_number(damage_increment(int(energy_upgrades.damage)+1)),compact_number(damage),compact_number(next_damage_value()),next_milestone,damage_milestone(next_milestone)],Color("ffcf84"))
 if not stat_upgrades.is_empty():
  var stat_names = {"damage":"Урон","speed":"Скорость","energy":"Добыча энергии","income":"Доход","crit":"Критический шанс"}
  var lines: Array[String] = []
  for key in stat_upgrades: lines.append("• %s ×%d" % [stat_names[key],stat_upgrades[key]])
  info_block(content,"ОБЩИЕ УСИЛЕНИЯ","\n".join(lines),Color("ffcf84"))
 for id in build:
  info_block(content,ABILITIES[id][0],ability_summary(id)+"\n\n"+chosen_upgrades(id),Color(ABILITIES[id][2]))
 if build.is_empty(): info_block(content,"СБОРКА ПОКА ПУСТА","Выбери первую карту, чтобы получить способность.",Color("91a7bd"))
 button(panel,"←  К ВЫБОРУ КАРТ" if resume_mode == "cards" else ("←  К ПАУЗЕ" if resume_mode == "pause" else "ПРОДОЛЖИТЬ ЭТАП"),Rect2(28,851,484,60),close_build)

func stat_upgrade_count() -> int:
 var count = 0
 for value in stat_upgrades.values(): count += int(value)
 return count

func close_build():
 if mode != "build": return
 if resume_mode == "cards": render_card_offer(battle_lvl == 1)
 elif resume_mode == "pause":
  mode = "play"
  pause_game()
 else:
  clear_ui(panel)
  mode = "play"
  queue_redraw()

func rank_bonus(id: String) -> float:
 return 1.0 + int(profile.ranks.get(id, 0)) * 0.05

func income_mult() -> float:
 return income

func coin_reward(base: float, ring_reward: bool = false) -> int:
 if triggers("fortune"):
  if ring_reward: base += build.fortune.duration * 5
  base *= (1.5 + build.fortune.power*0.25)*rank_bonus("fortune")
 return maxi(1,int(round(base * income_mult())))

func proc_chance(id: String) -> float:
 if id == "recoil": return minf(0.75,0.20+build.bounce.recoil_chance*0.05)
 var bonus = build[id].duration * 0.05 if id in ["lightning", "heavy", "pressure"] else build[id].get("chance",0)*0.05
 return minf(0.75, PROC_CHANCES[id] + bonus)

func triggers(id: String) -> bool:
 if id == "recoil": return build.has("bounce") and build.bounce.recoil > 0 and randf() < proc_chance(id)
 return build.has(id) and randf() < proc_chance(id)

func _physics_process(dt):
 var was_playing = mode == "play"
 if mode == "play":
  clock += dt
  toast_left = maxf(0, toast_left - dt)
  flash = maxf(0, flash - dt * 3)
  for p in particles:
   p.pos += p.vel * dt
   p.vel *= pow(0.97, dt * 120)
   p.life -= dt
  particles = particles.filter(func(p): return p.life > 0)
  for wave in waves:
   wave.r += dt * 95
   wave.life -= dt
  waves = waves.filter(func(wave): return wave.life > 0)
  ring_age += dt
  bounce_left = maxf(0, bounce_left - dt)
  var shrink = BASE_SHRINK + (run_stage - 1) * 0.16
  for r in rings:
   var slow_active = r.slow > 0 and build.has("slow")
   var slow_factor = maxf(0.25, 1.0 - (0.35 + build.slow.power * 0.1) * rank_bonus("slow")) if slow_active else 1.0
   var shrink_factor = pow(0.88, build.slow.duration) if slow_active else 1.0
   r.angle += r.omega * dt * slow_factor
   r.slow = maxf(0, r.slow - dt)
   r.freeze = maxf(0, r.freeze - dt)
   r.r -= shrink * shrink_factor * dt * (0 if r.freeze > 0 else 1)
   if r.burn > 0:
    r.burn -= dt
    r.hp -= damage * (0.26 + build.fire.power * 0.104) * rank_bonus("fire") * dt
  preserve_ring_order()
  if not rings.is_empty() and rings[0].hp <= 0:
   break_ring(false)
  if mode == "play" and not rings.is_empty():
   if rings[0].r <= BALL_R * 2.0 + 5:
    finish_run(false)
   else:
    move_ball(dt)
  trail.push_front(ball)
  if trail.size() > 18: trail.pop_back()
  sync_ring_visuals()
  hud_elapsed += dt
  if hud_elapsed >= 0.1:
   hud_elapsed = 0
   update_hud()
 if auto_test:
  test_steps += 1
  if mode == "cards": choose_card(offered[0])
  if mode == "result" or test_steps >= 72000:
   print("SMOKE_OK steps=", test_steps, " mode=", mode, " rings=", rings.size(), " destroyed=", destroyed)
   get_tree().quit(0 if mode == "result" else 1)
 if was_playing: queue_redraw()

func move_ball(dt: float):
 var multiplier = minf(2.5, 1.65 + build.bounce.force * 0.2) if bounce_left > 0 and build.has("bounce") else 1.0
 var target_speed = speed * multiplier
 # Gravity changes velocity throughout free flight; speed is a bounce impulse,
 # not a forced constant speed in the air. Bound both time and travel per step.
 var steps = maxi(1, maxi(int(ceil(dt * 240)), int(ceil((maxf(velocity.length(), target_speed) + GRAVITY * dt) * dt / 3.0))))
 var step_dt = dt / steps
 for step in steps:
  if mode != "play" or rings.is_empty(): return
  var r = rings[0]
  var next = ball + velocity * step_dt + Vector2(0, 0.5 * GRAVITY * step_dt * step_dt)
  velocity.y += GRAVITY * step_dt
  var dist = next.distance_to(CENTER)
  if dist + BALL_R >= r.r - 4:
   var angle = (next - CENTER).angle()
   var margin = asin(minf(1, (BALL_R + 4) / r.r))
   if in_gap(r, angle, margin):
    ball = next
    if dist - BALL_R >= r.r + 4: break_ring(true)
   else:
    var normal = (next - CENTER).normalized()
    ball = CENTER + normal * (r.r - BALL_R - 4.2)
    if velocity.dot(normal) > 0:
     velocity = velocity.bounce(normal) * 0.94
     hit_ring(r)
     var bounce_multiplier = minf(2.5, 1.65 + build.bounce.force * 0.2) if bounce_left > 0 and build.has("bounce") else 1.0
     # Keep the idle ball bouncing, but only impart energy at wall contact.
     velocity = velocity.normalized() * clampf(velocity.length(), speed * bounce_multiplier, 1200.0)
  else:
   ball = next

func in_gap(r: Dictionary, angle: float, margin: float = 0.0) -> bool:
 if r.gaps == 0: return false
 var half = PI * (0.20 if r.gaps == 1 else 0.11)
 for i in int(r.gaps):
  var gap_angle = r.angle + i * TAU / r.gaps
  if absf(wrapf(angle - gap_angle, -PI, PI)) < half - margin: return true
 return false

func hit_ring(r: Dictionary):
 hits += 1
 var dmg = damage
 if randf() < crit: dmg *= 2
 if build.has("bounce"):
  if triggers("bounce"):
   bounce_left = minf(8, bounce_left + 3 + build.bounce.duration * 1.5)
   notify("МОЩНЫЙ ОТСКОК")
  if bounce_left > 0:
   dmg *= (2 + build.bounce.damage * 0.5) * rank_bonus("bounce")
   if triggers("recoil"):
    expand_rings(build.bounce.recoil * 1.5)
    waves.append({"r": maxf(4,r.r-8),"life":0.4,"color":Color("ffb85c")})
 if r.freeze > 0: dmg *= (1.5 + build.frost.power * 0.3) * rank_bonus("frost")
 if triggers("heavy"):
  dmg *= (3 + build.heavy.power) * rank_bonus("heavy")
  flash = 0.5
 if triggers("fire"):
  r.burn = 3 + build.fire.duration * 2
  burst(ball,Color("ff8a5b"),9)
 if triggers("frost"):
  r.freeze = 2 + build.frost.duration * 1.5
  burst(ball,Color("9cddff"),9)
 if triggers("slow"):
  r.slow = 3 + build.slow.duration
  burst(ball,Color("b7a0ff"),7)
 if rings.size() > 1 and triggers("lightning"):
  rings[1].hp -= damage * (1.5 + build.lightning.power * 0.75) * rank_bonus("lightning")
  burst(CENTER + (ball - CENTER).normalized() * rings[1].r, Color("f7e384"), 12)
 if triggers("pressure"):
  expand_rings((5 + build.pressure.power * 3) * rank_bonus("pressure"))
  waves.append({"r": maxf(4, r.r - 12), "life": 0.5, "color": Color("65e9c6")})
 r.hp -= dmg
 earned += coin_reward(1)
 gain_energy(1)
 burst(ball, Color("73f4d1"), 5)
 if r.hp <= 0: break_ring(false)

func preserve_ring_order():
 # Rings are nested shells. A slower/frozen inner shell blocks those outside it.
 for i in range(1,rings.size()):
  var inner = rings[i-1]
  var outer = rings[i]
  var spacing = maxf(0.5,outer.start_r-inner.start_r)
  outer.r = maxf(outer.r,inner.r+spacing)

func expand_rings(amount: float) -> float:
 if amount <= 0 or rings.is_empty(): return 0.0
 preserve_ring_order()
 # Use one displacement for the whole stack. Per-ring caps used to flatten gaps.
 var allowed = amount
 for r in rings:
  allowed = minf(allowed,maxf(0,minf(232,r.start_r+20)-r.r))
 for r in rings: r.r += allowed
 return allowed

func break_ring(through_gap: bool):
 if rings.is_empty(): return
 var r = rings.pop_front()
 ring_visuals[r.index].hide()
 waves.append({"r": maxf(4, r.r), "life": 0.6, "color": Color("ffce7b") if through_gap else Color("73f4d1")})
 destroyed += 1
 xp += 1
 var reward = 12 + int(maxf(0, 12 - ring_age))
 earned += coin_reward(reward,true)
 gain_energy(12 + int(maxf(0,6-ring_age)) + (4 if through_gap else 0))
 ring_age = 0
 burst(CENTER + (ball - CENTER).normalized() * r.r, Color("ffce7b") if through_gap else Color("73f4d1"), 35)
 notify("ЧИСТЫЙ ПРОХОД!" if through_gap else "КОЛЬЦО РАЗРУШЕНО")
 flash = 0.25
 if rings.is_empty():
  finish_run(true)
 elif xp >= needed:
  xp -= needed
  battle_lvl += 1
  needed = 2 if battle_lvl == 2 else (battle_lvl - 2) * 2 + 2
  offer_cards()

func finish_run(won: bool):
 if mode == "result": return
 var unused_energy = round_energy
 round_energy = 0
 energy_remainder = 0.0
 var payout = earned if won else int(floor(earned * 0.4))
 profile.coins += payout
 if won:
  if run_stage >= int(profile.stage):
   profile.stage = run_stage + 1
   profile.selected_stage = profile.stage
  profile.diamonds += 10
 save_progress()
 mode = "result"
 clear_ui(panel)
 clear_ui(hud)
 backdrop()
 text_at(panel, "ПРОРЫВ!" if won else "КОЛЬЦА СОМКНУЛИСЬ", Vector2(32, 200), 32, Color("73f4d1") if won else Color("ff927f"))
 text_at(panel, "Разрушено колец: %d / %d" % [destroyed, total_rings], Vector2(32, 275), 23)
 text_at(panel, "Заработано: %d монет" % earned, Vector2(32, 325), 22)
 text_at(panel, "Сохранено %d%%: +%d монет" % [100 if won else 40, payout], Vector2(32, 375), 24, Color("ffd76d"))
 text_at(panel, "+10 ◇ за прохождение" if won else "Коллекция и постоянные улучшения сохранены.", Vector2(32, 430), 17, Color("91a7bd"))
 text_at(panel,"Неиспользованная энергия сгорела: %d" % unused_energy,Vector2(32,472),15,Color("91a7bd"))
 button(panel, "СЛЕДУЮЩИЙ ЭТАП" if won else "ПОПРОБОВАТЬ СНОВА", Rect2(32, 520, 476, 68), next_stage if won else start_run, Color("176a60"))
 button(panel, "ГЛАВНОЕ МЕНЮ", Rect2(32, 610, 476, 62), show_menu)

func notify(value: String):
 toast = value
 toast_left = 1.7

func burst(pos: Vector2, col: Color, count: int):
 for i in count:
  if particles.size() >= 120: break
  particles.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(25, 180), "life": randf_range(0.25, 0.75), "color": col})

func update_hud():
 labels.stage.text = "ЭТАП %d   /   LVL %d" % [run_stage, battle_lvl]
 labels.stage.modulate = stage_color(run_stage)
 labels.money.text = "%d монет  ·  при поражении: %d" % [earned, int(earned * 0.4)]
 labels.progress.text = "Кольца %d/%d      До карты: %d/%d" % [destroyed, total_rings, xp, needed]
 if not rings.is_empty():
  var r = rings[0]
  labels.hp.text = "ПРОЧНОСТЬ  %d / %d" % [maxi(0, int(ceil(r.hp))), int(ceil(r.max_hp))]
  labels.status.text = "Урон %s  ·  Скорость %.0f  ·  Пространство %.0f" % [compact_number(damage), speed, maxf(0, r.r - BALL_R * 2 - 5)]
 labels.energy.text = "ЭНЕРГИЯ · %s  ×%s" % [compact_number(round_energy),compact_number(energy_gain) if energy_gain>=1000 else "%.2f" % energy_gain]
 labels.build.text = "Сборка %d/%d · Урон LV %d" % [build.size(),profile.slots,energy_upgrades.damage]
 labels.buy_damage.text = damage_button_title()+"\n%s энергии" % compact_number(energy_upgrade_cost("damage"))
 labels.buy_energy.text = energy_button_title()+"\n%s энергии" % compact_number(energy_upgrade_cost("energy"))
 labels.buy_damage.disabled = round_energy < energy_upgrade_cost("damage")
 labels.buy_energy.disabled = round_energy < energy_upgrade_cost("energy")

func _draw():
 if mode == "menu": return
 # Outer rings use shared, prebuilt meshes; only the active ring is redrawn.
 for i in mini(rings.size(),1):
  var r = rings[i]
  if r.r > 238: continue
  var col = stage_color(run_stage)
  if i == 0 and r.r < 48: col = Color("ff6e70")
  if r.burn > 0: col = Color("ff8a5b")
  if r.freeze > 0: col = Color("9cddff")
  elif r.slow > 0: col = Color("b7a0ff")
  var width = 4.0 if i == 0 else 1.0
  if r.gaps == 0:
   if i == 0: draw_arc(CENTER,r.r,0,TAU,160,Color(col,0.1),15,true)
   draw_arc(CENTER, r.r, 0, TAU, 160, col, width, true)
  else:
   var half = PI * (0.20 if r.gaps == 1 else 0.11)
   for gap in int(r.gaps):
    var a = r.angle + gap * TAU / r.gaps + half
    var b = r.angle + (gap + 1) * TAU / r.gaps - half
    if i == 0:
     draw_arc(CENTER,r.r,a,b,100,Color(col,0.1),15,true)
     for edge in [a,b]:
      var tip = CENTER + Vector2.from_angle(edge)*r.r
      draw_circle(tip,5,Color(col,0.18))
      draw_circle(tip,2.2,col)
    draw_arc(CENTER, r.r, a, b, 100, col, width, true)
  if i == 0:
   var ratio = clampf(r.hp / r.max_hp, 0, 1)
   draw_arc(CENTER, r.r - 7, -PI / 2, -PI / 2 + TAU * maxf(0.001, ratio), 100, Color(col, 0.22), 2, true)
 for wave in waves:
  if wave.r < 238: draw_arc(CENTER,wave.r,0,TAU,100,Color(wave.color,wave.life * 0.65),2,true)
 for i in trail.size():
  if i + 1 < trail.size():
   draw_line(trail[i],trail[i+1],Color(1,0.65,0.3,0.45*(1-float(i)/20)) if bounce_left>0 else Color(0.3,0.9,0.8,0.3*(1-float(i)/20)),maxf(1,4*(1-float(i)/20)),true)
  draw_circle(trail[i], BALL_R * (1.0 - float(i) / 20), Color(1, 0.65, 0.3, 0.3 * (1 - float(i) / 20)) if bounce_left > 0 else Color(0.3, 0.9, 0.8, 0.15 * (1 - float(i) / 20)))
 draw_circle(ball,BALL_R+9,Color(1,0.65,0.3,0.07) if bounce_left>0 else Color(0.3,0.9,0.8,0.07))
 draw_circle(ball, BALL_R + 4, Color(1, 0.7, 0.3, 0.18) if bounce_left > 0 else Color(0.4, 1, 0.9, 0.15))
 draw_circle(ball, BALL_R, Color("ffcd7d") if bounce_left > 0 else Color("e0fff6"))
 draw_circle(ball + Vector2(-2, -2), 2.5, Color.WHITE)
 for p in particles:
  draw_circle(p.pos, 2.2, Color(p.color, minf(1, p.life * 2)))
 if toast_left > 0 and mode == "play":
  draw_string(ThemeDB.fallback_font, Vector2(130, 675), toast, HORIZONTAL_ALIGNMENT_CENTER, 280, 18, Color("ffda93"))

func _notification(what):
 if what == NOTIFICATION_APPLICATION_PAUSED:
  if mode == "play": pause_game()
  save_progress()
 if what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if mode == "pack_opening": skip_pack_reveal()
  elif mode == "pack_results": dismiss_pack()
  elif mode == "pack_shop": show_menu()
  elif mode == "pack_odds": show_pack_shop()
  elif mode == "build": close_build()
  elif mode == "play": pause_game()
  elif mode == "pause":
   clear_ui(panel)
   mode = "play"
