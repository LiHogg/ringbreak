extends Control
var ink = Color("ffd184")
func _draw():
 var gold = Color("b79a65")
 for origin in [Vector2(12,12),Vector2(size.x-12,12),Vector2(12,size.y-12),size-Vector2(12,12)]:
  var direction = Vector2(1 if origin.x < size.x/2 else -1,1 if origin.y < size.y/2 else -1)
  draw_line(origin,origin+Vector2(direction.x*27,0),gold,1,true)
  draw_line(origin,origin+Vector2(0,direction.y*27),gold,1,true)
  draw_circle(origin+direction*4,1.5,ink)
 var c = Vector2(size.x/2,95)
 for angle in 12:
  var axis = Vector2.from_angle(angle*TAU/12)
  draw_line(c+axis*57,c+axis*61,Color(gold,0.7),1,true)
 draw_line(Vector2(18,size.y-39),Vector2(size.x-18,size.y-39),Color(gold,0.3),1,true)
