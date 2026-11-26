extends Control

var game

func _draw():
	if game==null or game.world.interior:return
	var here:Vector2=game.hero.position
	var ext=size/2
	var tiles=game.world.terrain
	var hero_cell=Vector2i((here/16.0).floor())
	var zoom=3.45
	draw_rect(Rect2(Vector2.ZERO,size),Color("#15222beb"))
	for y in range(-7,8):
		for x in range(-12,13):
			var cell=hero_cell+Vector2i(x,y)
			var t=tiles.get_cell_atlas_coords(cell).x
			if t<0:continue
			var color=Color("#3f6954")
			if tiles.get_cell_source_id(cell)==2:color=Color("#f09c5b")
			elif t in [8,9,10]:color=Color("#467c98")
			elif t in [11,12] or t in range(4,8) or t>=18:color=Color("#9b8965")
			draw_rect(Rect2(ext+Vector2(x,y)*zoom,Vector2.ONE*zoom),color)
	for node in game.world.sites:
		if not node.visible:continue
		var delta=(node.position-here)*(zoom/16.0)
		if absf(delta.x)>ext.x-5 or absf(delta.y)>ext.y-5:continue
		draw_circle(ext+delta,1.85,Color("#ffe0a6") if node.get("active")==true else Color("#9ec5b6"))
	draw_rect(Rect2(ext-Vector2(2,2),Vector2(4,4)),Color("#b9ffeb"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("#9b8965"),false,1)
