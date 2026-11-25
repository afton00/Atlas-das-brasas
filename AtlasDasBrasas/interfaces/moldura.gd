extends Panel

# Brass corner fittings share the same pixel grid as the field instruments.
func _draw():
	var corners=[Vector2(3,3),Vector2(size.x-3,3),Vector2(3,size.y-3),size-Vector2(3,3)]
	for i in 4:
		var p=corners[i]
		var dx=1 if i in [0,2] else -1
		var dy=1 if i<2 else -1
		draw_line(p,p+Vector2(9*dx,0),Color("#b89664"),1)
		draw_line(p,p+Vector2(0,5*dy),Color("#b89664"),1)
