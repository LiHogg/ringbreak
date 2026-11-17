extends Control
var tier = 0
var ink = Color("70e9d0")
func _draw():
 var scale_factor = minf(size.x/240.0,size.y/290.0)
 var center = size*0.5
 for i in range(10,0,-1): draw_circle(center,scale_factor*(55+i*7),Color(ink,0.012))
 for i in range(2,-1,-1):
  draw_set_transform(center+Vector2((i-1)*14,abs(i-1)*4)*scale_factor,(i-1)*0.12,Vector2.ONE*scale_factor)
  var face = PackedVector2Array([Vector2(-75,-111),Vector2(75,-111),Vector2(84,-99),Vector2(84,103),Vector2(75,115),Vector2(-75,115),Vector2(-84,103),Vector2(-84,-99)])
  draw_colored_polygon(face,Color("0e172a").lerp(ink,0.10+i*0.015))
  var outline = face.duplicate()
  outline.append(face[0])
  draw_polyline(outline,Color(ink,0.85 if i == 1 else 0.3),2,true)
  draw_rect(Rect2(-72,-99,144,202),Color(ink,0.18),false,1,true)
  for y in [-86,87]:
   draw_line(Vector2(-61,y),Vector2(61,y),Color(ink,0.45),1,true)
   for n in 8:
    var x = -57+n*16
    draw_line(Vector2(x,y-4),Vector2(x+4,y+4),Color(ink,0.7),1,true)
  for r in [41,48,56]: draw_arc(Vector2.ZERO,r,0,TAU,64,Color(ink,0.4),1,true)
  var seal = PackedVector2Array()
  for n in 7: seal.append(Vector2.from_angle(n*TAU/6-PI/2)*37)
  draw_polyline(seal,ink,1.5,true)
  var star = PackedVector2Array()
  for n in 12: star.append(Vector2.from_angle(n*TAU/12-PI/2)*(28 if n%2==0 else 13))
  draw_colored_polygon(star,Color(ink,0.8))
  draw_circle(Vector2.ZERO,6,Color("fff2cf"))
  if tier > 0:
   for s in [-1,1]:
    draw_polyline(PackedVector2Array([Vector2(s*56,-55),Vector2(s*63,0),Vector2(s*56,55)]),Color(ink,0.7),2,true)
  if tier == 2:
   draw_colored_polygon(PackedVector2Array([Vector2(-26,-68),Vector2(-30,-84),Vector2(-12,-76),Vector2(0,-94),Vector2(12,-76),Vector2(30,-84),Vector2(26,-68)]),ink)
 draw_set_transform(Vector2.ZERO)
