extends Node2D

func _draw():
 for i in 45:
  var star = Vector2(fmod(i*137.3+17,540),fmod(i*219.7+39,960))
  draw_circle(star,0.8 if i%4 else 1.3,Color(0.4,0.7,0.85,0.12))
 draw_circle(Vector2(270,418),238,Color("081423"))
 draw_arc(Vector2(270,418),242,0,TAU,100,Color("173044"),1,true)
 for i in 4:
  var axis = Vector2.from_angle(i*PI/2+PI/4)
  var c = Vector2(270,418)+axis*245
  var side = axis.orthogonal()
  draw_polyline(PackedVector2Array([c-axis*6,c+side*4,c+axis*6,c-side*4,c-axis*6]),Color("c6a76e",0.65),1,true)
 for i in 48:
  var axis = Vector2.from_angle(i*TAU/48)
  draw_line(Vector2(270,418)+axis*244,Vector2(270,418)+axis*(249 if i%4 else 253),Color("294657"),1,true)
