extends Control
signal selected(region:int)
var here=Vector2.ZERO
var picked=0
const NAMES=["Junco","Lume","Ocre","Agulha","Nascente","Basalto"]
const FONT=preload("res://interfaces/LiberationSerif-Bold.ttf")
const MAP=preload("res://interfaces/carta.png")
const World=preload("res://mapas/mundo.gd")
const CLINIC=preload("res://mapas/margens/insignia.png")
const VIEWS=[
	preload("res://mapas/margens/vista-0.png"),preload("res://mapas/margens/vista-1.png"),
	preload("res://mapas/margens/vista-2.png"),preload("res://mapas/margens/vista-3.png"),
	preload("res://mapas/margens/vista-4.png"),preload("res://mapas/margens/vista-5.png")
]
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
	var cell=size/Vector2(3,2)
	for c in 6:
		var start=Vector2(Saga.REGIONS[c])*cell
		var plate=Rect2(start+Vector2(2,2),cell-Vector2(4,4))
		var border=GOLD if c==picked else Color("#78684c")
		var brightness=1.0 if c==picked else .79 if c in Saga.data.seen else .54
		draw_texture_rect(VIEWS[c],plate,false,Color(brightness,brightness,brightness))
		draw_rect(plate,Color("#1b283426"))
		draw_rect(plate,border,false,2 if c==picked else 1)
	for c in 5:
		draw_dashed_line(point(c),point(c+1),Color("#3c3226"),2,5)
		draw_dashed_line(point(c),point(c+1),Color("#edd296"),1,5)
	for c in 6:
		var p=point(c)
		var tint=GOLD if c==picked else Color("#f2edce") if c in Saga.data.seen else Color("#c0bca9")
		draw_circle(p,6,INK)
		draw_colored_polygon(PackedVector2Array([p+Vector2.UP*4,p+Vector2.RIGHT*4,p+Vector2.DOWN*4,p+Vector2.LEFT*4]),tint)
		var w=FONT.get_string_size(NAMES[c],HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+22
		var name_pos=p+Vector2(-w/2,cell.y/2-27)
		draw_rect(Rect2(name_pos,Vector2(w,22)),Color("#132331ef"))
		draw_string(FONT,name_pos+Vector2(0,16),NAMES[c],HORIZONTAL_ALIGNMENT_CENTER,w,16,tint)
		var clinic=(Saga.origin(c)+World.CARE_POINTS[c])/(Saga.AREA*Vector2(3,2))*size
		draw_texture(CLINIC,(clinic-Vector2(5,14)).round())
	var loc=here/(Saga.AREA*Vector2(3,2))*size
	draw_circle(loc,5,INK)
	draw_circle(loc,3,Color("#8cf1da"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("#a79066"),false,1)
