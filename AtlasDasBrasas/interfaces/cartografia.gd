extends Control
signal selected(region:int)
var here=Vector2.ZERO
var picked=0
const NAMES=["Junco","Lume","Ocre","Agulha","Nascente","Basalto"]
const FONT=preload("res://interfaces/LiberationSerif-Bold.ttf")
const MAP=preload("res://interfaces/carta.png")
const GOLD=Color("#ffe0a6")
const INK=Color("#132331")
func point(c):
	return (Vector2(Saga.REGIONS[c])+Vector2(.5,.5))*size/Vector2(3,2)
func _gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT:
		var mouse=get_local_mouse_position()/size
		picked=Saga.REGIONS.find(Vector2i(clampi(floori(mouse.x*3),0,2),clampi(floori(mouse.y*2),0,1)))
		selected.emit(picked)
		queue_redraw()

func _draw():
	draw_texture_rect(MAP,Rect2(Vector2.ZERO,size),false)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#18232930"))
	for c in 5:draw_dashed_line(point(c),point(c+1),Color("#ffe5a68a"),1,4)
	for c in 6:
		var p=point(c)
		var known=c in Saga.data.seen
		var tint=GOLD if c==picked else Color("#f2edce") if known else Color("#c0bca9")
		draw_circle(p,7,INK)
		draw_colored_polygon(PackedVector2Array([p+Vector2.UP*5,p+Vector2.RIGHT*5,p+Vector2.DOWN*5,p+Vector2.LEFT*5]),tint)
		if c==picked:draw_arc(p,11,0,TAU,28,GOLD,2)
		var w=FONT.get_string_size(NAMES[c],HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+18
		draw_rect(Rect2(p+Vector2(-w/2,13),Vector2(w,21)),Color("#132331e8"))
		draw_string(FONT,p+Vector2(-w/2,29),NAMES[c],HORIZONTAL_ALIGNMENT_CENTER,w,15,tint)
	var loc=here/(Saga.AREA*Vector2(3,2))*size
	draw_circle(loc,5,INK)
	draw_circle(loc,3,Color("#8cf1da"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("#a79066"),false,1)
