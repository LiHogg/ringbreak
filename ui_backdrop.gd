extends Control
func _draw():
 draw_rect(Rect2(Vector2.ZERO,size),Color("080d19"))
 for i in 18:
  var alpha = 0.012*(1-float(i)/18)
  draw_circle(Vector2(480,90),60+i*15,Color(0.25,0.3,0.7,alpha))
 for i in 42:
  var p = Vector2(fmod(i*137.3+19,size.x),fmod(i*219.7+31,size.y))
  draw_circle(p,0.8 if i%5 else 1.3,Color("b79a65",0.17))
 draw_line(Vector2(24,18),Vector2(size.x-24,18),Color("b79a65",0.23),1,true)
 draw_line(Vector2(24,size.y-18),Vector2(size.x-24,size.y-18),Color("b79a65",0.23),1,true)
 for p in [Vector2(24,18),Vector2(size.x-24,18),Vector2(24,size.y-18),size-Vector2(24,18)]:
  draw_circle(p,2,Color("b79a65",0.55))
