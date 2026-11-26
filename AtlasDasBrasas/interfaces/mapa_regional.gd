extends Control

signal chosen(cell:Vector2i)

const Sectors=preload("res://mapas/setores.gd")
const Expedition=preload("res://mapas/expedicao.gd")
const COLORS=[Color("#567c51"),Color("#646a81"),Color("#a17b54"),Color("#5e818e"),Color("#3f796a"),Color("#805e66")]

var realm:=0
var location:=Vector2.ZERO
var selected:=Vector2i(-1,-1)
var mission:=Vector2i(-1,-1)
var waypoint:=Vector2i(-1,-1)
var zoom:=1.0
var offset:=Vector2.ZERO
var drag_length:=0.0

func cell_size()->Vector2:
	return size*zoom/Vector2(Sectors.REGIONS[realm].size)

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:change_zoom(.25)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:change_zoom(-.25)
		elif event.button_index==MOUSE_BUTTON_LEFT:drag_length=0
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		drag_length+=event.relative.length()
		if zoom>1:offset+=event.relative
		clamp_offset()
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and drag_length<7:
		var local=Vector2i(((event.position-offset)/cell_size()).floor())
		var candidate=Sectors.REGIONS[realm].position+local
		if Sectors.REGIONS[realm].has_point(candidate):
			selected=candidate
			chosen.emit(candidate)
			queue_redraw()

func change_zoom(amount:float):
	var next=clampf(zoom+amount,1.0,2.5)
	offset=size*.5+(offset-size*.5)*next/zoom
	zoom=next
	clamp_offset()
	queue_redraw()

func clamp_offset():
	offset=offset.clamp(size*(1.0-zoom),Vector2.ZERO)

func _draw():
	var territory:Rect2i=Sectors.REGIONS[realm]
	var tile=cell_size()
	var gold=Color("#ffe0a6")
	for y in territory.size.y:
		for x in territory.size.x:
			var cell=territory.position+Vector2i(x,y)
			var pos=offset+Vector2(x,y)*tile
			var rectangle=Rect2(pos+Vector2.ONE,tile-Vector2(2,2))
			var discovered=Saga.data.visited_sectors.has(Sectors.key(cell))
			draw_rect(rectangle,COLORS[realm].darkened(.32) if discovered else Color("#1c2735"))
			if discovered:
				var cross=pos+tile*Sectors.CROSSROAD/Vector2(Sectors.SIZE)
				draw_line(Vector2(pos.x,cross.y),Vector2(pos.x+tile.x,cross.y),Color("#dbc594"),1.5)
				draw_line(Vector2(cross.x,pos.y),Vector2(cross.x,pos.y+tile.y),Color("#dbc594"),1.5)
				var area=Expedition.entry(cell)
				if area.size()>5:
					var form=area[5]
					match form:
						"pool","oasis","marsh":
							draw_circle(pos+tile*Vector2(.73,.22),minf(tile.x,tile.y)*.095,Color("#65a9c3"))
						"lava","rift":
							var water=Color("#ee945f") if form=="lava" else Color("#7497a8")
							draw_polyline(PackedVector2Array([pos+tile*Vector2(.7,.02),pos+tile*Vector2(.77,.38),pos+tile*Vector2(.69,.7),pos+tile*Vector2(.74,.97)]),water,2.5)
						"ridge","terrace":
							draw_polyline(PackedVector2Array([pos+tile*Vector2(.11,.31),pos+tile*Vector2(.17,.14),pos+tile*Vector2(.24,.31),pos+tile*Vector2(.28,.21)]),Color("#b9b8a2"),2)
					if area[1] in ["ruin","cave"]:
						var mark=pos+tile*Vector2(.75,.76)
						draw_colored_polygon(PackedVector2Array([mark+Vector2(-4,3),mark+Vector2(0,-4),mark+Vector2(4,3)]),Color("#d9ceb2"))
				elif not area.is_empty() and area[1]=="water":
					draw_line(pos+Vector2(tile.x*.62,0),pos+Vector2(tile.x*.62,tile.y),Color("#65a9c3"),3)
				var marker=Saga.data.expedition.has("marker_"+Sectors.key(cell)) or cell==Sectors.hub(realm)
				draw_circle(cross,4 if marker else 2.75,gold if marker else Color("#a5dfb9"))
				if not area.is_empty() and area[1] in ["village","water","farm"]:
					draw_rect(Rect2(cross+Vector2(8,-6),Vector2(7,7)),Color("#88d7d1"))
			if discovered and cell==mission:
				var beacon=pos+Vector2(tile.x-14,14)
				draw_colored_polygon(PackedVector2Array([beacon+Vector2.UP*6,beacon+Vector2.RIGHT*5,beacon+Vector2.DOWN*6,beacon+Vector2.LEFT*5]),gold)
			if cell==selected:draw_rect(rectangle,gold,false,2)
			if cell==waypoint:draw_circle(pos+Vector2(14,14),5,Color("#f7bc82"))
	if Sectors.realm_at(Sectors.at(location))==realm:
		var pos=offset+(location-Sectors.origin(territory.position))*tile/Vector2(Sectors.SIZE)
		draw_circle(pos,5,Color("#14202a"))
		draw_circle(pos,3,Color("#8cf1da"))
