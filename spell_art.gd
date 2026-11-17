extends Control

var ability = "bounce"
var ink = Color("73f4d1")

func _draw():
 var c = size * 0.5
 # Engraved constellation field and layered light, all native vector graphics.
 for i in range(12, 0, -1):
  draw_circle(c, 20 + i * 4, Color(ink, 0.008 + (12 - i) * 0.001))
 for i in 18:
  var p = Vector2(fmod(i * 73.0 + 19, size.x), fmod(i * 37.0 + 11, size.y))
  draw_circle(p, 0.8 if i % 3 else 1.3, Color(ink, 0.35))
 draw_arc(c, 47, 0, TAU, 80, Color(ink, 0.18), 1, true)
 for i in 6:
  var angle = i*TAU/6-PI/2
  var axis = Vector2.from_angle(angle)
  var tangent = axis.orthogonal()
  var p = c+axis*43
  draw_line(p-axis*2-tangent*2,p+axis*2+tangent*2,Color("c6a76e",0.55),1,true)
  draw_circle(p,0.8,Color("f4ebd6",0.5))
 draw_arc(c, 51, -0.9, 0.8, 32, Color(ink, 0.65), 1.5, true)
 draw_arc(c, 51, PI - 0.9, PI + 0.8, 32, Color(ink, 0.65), 1.5, true)
 for s in [-1, 1]:
  var p = c + Vector2(s * 84, 0)
  draw_colored_polygon(PackedVector2Array([p + Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)]), Color(ink, 0.7))
 match ability:
  "fire":
   var flame = PackedVector2Array([c+Vector2(-24,17),c+Vector2(-23,-3),c+Vector2(-10,-24),c+Vector2(-8,-9),c+Vector2(5,-38),c+Vector2(15,-12),c+Vector2(27,4),c+Vector2(26,20),c+Vector2(13,33),c+Vector2(-10,33)])
   draw_colored_polygon(flame, ink)
   draw_colored_polygon(PackedVector2Array([c+Vector2(-10,21),c+Vector2(1,-9),c+Vector2(13,18),c+Vector2(6,30),c+Vector2(-5,30)]), Color("ffe5ac"))
  "frost":
   for i in 6:
    var axis = Vector2.from_angle(i * TAU / 6 - PI/2)
    var side = axis.orthogonal()
    draw_line(c, c + axis * 36, ink, 3, true)
    for d in [17, 27]:
     for s in [-1,1]: draw_line(c+axis*d,c+axis*(d-8)+side*s*9,ink,2,true)
   draw_circle(c, 5, Color("e3fbff"))
  "slow":
   draw_arc(c, 31, 0, TAU, 72, ink, 3, true)
   for i in 12:
    var axis = Vector2.from_angle(i*TAU/12)
    draw_line(c+axis*25,c+axis*28,Color(ink,0.7),1.5,true)
   draw_line(c,c+Vector2(0,-19),Color("f0e5ff"),3,true)
   draw_line(c,c+Vector2(16,9),ink,3,true)
   draw_circle(c,4,Color("ffffff"))
   draw_arc(c,40,-2.6,-0.4,40,Color(ink,0.6),2,true)
  "lightning":
   var bolt = PackedVector2Array([c+Vector2(2,-37),c+Vector2(-25,5),c+Vector2(-3,5),c+Vector2(-12,37),c+Vector2(28,-10),c+Vector2(6,-10),c+Vector2(17,-37)])
   draw_colored_polygon(bolt, ink)
   draw_line(c+Vector2(4,-23),c+Vector2(-9,0),Color("fffce3"),3,true)
  "heavy", "damage":
   draw_line(c+Vector2(-18,30),c+Vector2(15,-13),ink,9,true)
   var head = PackedVector2Array([c+Vector2(-6,-33),c+Vector2(28,-8),c+Vector2(15,10),c+Vector2(-19,-15)])
   draw_colored_polygon(head,ink)
   draw_line(c+Vector2(-6,-27),c+Vector2(22,-7),Color("ffe3ed"),3,true)
   for i in 3: draw_line(c+Vector2(-32+i*8,6),c+Vector2(-27+i*8,-1),Color(ink,0.55),2,true)
  "pressure":
   for i in 3: draw_arc(c,14+i*12,0,TAU,80,Color(ink,1.0-i*0.27),3-i*0.5,true)
   for i in 4:
    var axis = Vector2.from_angle(i*PI/2+PI/4)
    var tip = c+axis*43
    draw_line(tip,tip-axis.rotated(0.5)*10,ink,2,true)
    draw_line(tip,tip-axis.rotated(-0.5)*10,ink,2,true)
  "fortune", "income":
   for i in 3:
    var p = c+Vector2(-15+i*14,10-i*10)
    draw_circle(p,21,Color("362c1c"))
    draw_arc(p,21,0,TAU,60,ink,2.5,true)
    draw_arc(p,16,0,TAU,60,Color(ink,0.35),1,true)
    draw_line(p+Vector2(0,-9),p+Vector2(0,9),ink,3,true)
  "crit":
   for i in 4:
    var axis = Vector2.from_angle(i*PI/2)
    draw_line(c+axis*22,c+axis*36,ink,3,true)
   draw_arc(c,21,0,TAU,60,ink,2,true)
   draw_circle(c,6,Color("fff1ee"))
  _:
   draw_arc(c+Vector2(-12,17),23,0.15,PI-0.15,48,Color(ink,0.6),2,true)
   draw_circle(c+Vector2(8,-10),16,ink)
   draw_circle(c+Vector2(4,-14),5,Color("fff1d4"))
   for i in 3: draw_line(c+Vector2(-35+i*10,29),c+Vector2(-13+i*10,5),Color(ink,0.65-i*0.15),3,true)
