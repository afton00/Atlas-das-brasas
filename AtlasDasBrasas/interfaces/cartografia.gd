extends Control
signal selected(region:int)
var here=Vector2.ZERO
var inside=false
var picked=0
const NAMES=["Junco","Lume","Ocre","Agulha","Nascente","Basalto"]
const COLORS=["779a67","679084","b29b6e","91a2a2","5b9573","847d92"]
func point(c):return Vector2(75,73)+Vector2(Saga.REGIONS[c])*Vector2(159,112)
func _gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed:
		for c in 6:
			if get_local_mouse_position().distance_to(point(c))<48:
				picked=c
				selected.emit(c)
				queue_redraw()
func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("#172d35"))
	for i in 22:draw_line(Vector2(i*24,0),Vector2(i*24,size.y),Color("#233b41"))
	for i in 12:draw_line(Vector2(0,i*24),Vector2(size.x,i*24),Color("#233b41"))
	var rng=RandomNumberGenerator.new()
	rng.seed=879
	for c in 6:
		var p=point(c)
		var pts=PackedVector2Array()
		for a in 18:
			var ang=a*TAU/18
			pts.append(p+Vector2(cos(ang)*77,sin(ang)*53)*rng.randf_range(.86,1.12))
		draw_colored_polygon(pts,Color(COLORS[c]).darkened(.35))
		for j in 15:
			var t=p+Vector2(rng.randf_range(-52,52),rng.randf_range(-34,34))
			draw_polyline(PackedVector2Array([t+Vector2(-3,2),t+Vector2(0,-3),t+Vector2(3,2)]),Color(COLORS[c]),1)
	for c in 5:draw_dashed_line(point(c),point(c+1),Color("#b2a27e"),2,6)
	for c in 6:
		var p=point(c)
		draw_circle(p,6,Color("#e8bd78") if c==picked else Color("#cad1bd"))
		draw_circle(p,3,Color("#21373b"))
		if c==picked:draw_arc(p,11,0,TAU,24,Color("#f4cf8b"),1)
		draw_string(preload("res://interfaces/LiberationSerif-Bold.ttf"),p+Vector2(-65,26),NAMES[c],HORIZONTAL_ALIGNMENT_CENTER,130,16,Color("#fff1d5"))
	var local=here/Saga.AREA
	var loc=Vector2(75,73)+(local-Vector2(.5,.5))*Vector2(159,112)
	draw_circle(loc,4,Color("#8ff4e5"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x-34,23),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e6c889"))

