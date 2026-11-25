extends Control

var kind:int=0
var night:bool=false

func _draw():
	var sx=size.x/38.0
	var sy=size.y/32.0
	draw_set_transform(Vector2.ZERO,0,Vector2(sx,sy))
	var gold=Color("#ffde91")
	var cloud=Color("#d4dfe6")
	var shadow=Color("#869caf")
	var drops=Color("#7dd9e2")
	if kind==0:
		if night:
			draw_colored_polygon(PackedVector2Array([Vector2(23,4),Vector2(14,5),Vector2(9,13),Vector2(10,21),Vector2(16,26),Vector2(25,26),Vector2(30,21),Vector2(22,21),Vector2(17,15),Vector2(17,10)]),gold)
			draw_rect(Rect2(30,6,2,2),cloud)
		else:
			draw_rect(Rect2(12,9,14,14),gold)
			draw_rect(Rect2(15,7,8,18),gold)
			for p in [Vector2(18,1),Vector2(18,27),Vector2(4,14),Vector2(30,14),Vector2(7,5),Vector2(28,5),Vector2(7,23),Vector2(28,23)]:
				draw_rect(Rect2(p,Vector2(3,3)),gold)
	elif kind==4:
		for i in 3:
			draw_rect(Rect2(4+i*3,7+i*7,26-i*4,2),cloud)
			draw_rect(Rect2(27-i,5+i*7,3,3),cloud)
	else:
		draw_rect(Rect2(4,14,30,7),shadow)
		for r in [Rect2(6,12,25,6),Rect2(12,7,13,10),Rect2(22,10,8,7)]:draw_rect(r,cloud)
		if kind in [2,3,5]:
			for i in (5 if kind==3 else 3):
				var x=7+i*(5 if kind==3 else 9)
				var y=24+i%2*2
				if kind==5:
					draw_rect(Rect2(x,y,5,1),cloud)
					draw_rect(Rect2(x+2,y-2,1,5),cloud)
				else:draw_line(Vector2(x+2,y),Vector2(x,y+4),drops,2)
