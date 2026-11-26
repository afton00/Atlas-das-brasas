extends Control
signal selected(region:int)
var here=Vector2.ZERO
var picked=0
const NAMES=["Junco","Lume","Ocre","Agulha","Nascente","Basalto"]
const Sectors=preload("res://mapas/setores.gd")
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
	return pixel(Sectors.origin(Sectors.hub(c))+Sectors.CROSSROAD)

func pixel(position:Vector2)->Vector2:
	return (position-Sectors.bounds().position)*size/Sectors.bounds().size

func _gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT:
		var bounds=Sectors.bounds()
		var world_position=bounds.position+get_local_mouse_position()*bounds.size/size
		var realm=Sectors.realm_at(Sectors.at(world_position))
		if realm<0:return
		picked=realm
		selected.emit(picked)
		queue_redraw()

func _draw():
	draw_texture_rect(MAP,Rect2(Vector2.ZERO,size),false)
	for c in Sectors.REGIONS.size():
		var bounds:Rect2i=Sectors.REGIONS[c]
		var start=pixel(Sectors.origin(bounds.position))
		var end=pixel(Sectors.origin(bounds.end))
		var plate=Rect2(start+Vector2(2,2),end-start-Vector2(4,4))
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
		var territory:Rect2i=Sectors.REGIONS[c]
		var name_pos=Vector2(p.x-w/2,pixel(Sectors.origin(territory.end)).y-28)
		draw_rect(Rect2(name_pos,Vector2(w,22)),Color("#132331ef"))
		draw_string(FONT,name_pos+Vector2(0,16),NAMES[c],HORIZONTAL_ALIGNMENT_CENTER,w,16,tint)
		var clinic=pixel(Saga.origin(c)+World.CARE_POINTS[c])
		if c in Saga.data.seen:draw_texture(CLINIC,(clinic+Vector2(12,-14)).round())
	var loc=pixel(here)
	draw_circle(loc,5,INK)
	draw_circle(loc,3,Color("#8cf1da"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("#a79066"),false,1)
