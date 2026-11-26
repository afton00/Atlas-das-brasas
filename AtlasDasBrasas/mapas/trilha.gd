extends Node2D
const Sectors=preload("res://mapas/setores.gd")
const Place=preload("res://mapas/lugar.gd")

var grid=AStarGrid2D.new()
var steps:Array[Vector2i]=[]
var target_cell=Vector2i(-1,-1)
var last_cell=Vector2i(-1,-1)
var next_point=Vector2.ZERO
var remaining=0.0
var available=false
var exterior=false
var corridor:Array[Vector2i]=[]
var start_sector:=Vector2i(-1,-1)
var finish_sector:=Vector2i(-1,-1)

func configure_grid(rect:Rect2i):
	grid.region=rect
	grid.cell_size=Vector2(16,16)
	grid.offset=Vector2(8,8)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	grid.fill_solid_region(rect,true)

func reset_path():
	steps.clear()
	available=false
	target_cell=Vector2i(-1,-1)
	last_cell=Vector2i(-1,-1)

func block_footprints(nodes:Array):
	for obj in nodes:
		if not is_instance_valid(obj) or not obj is Place or not obj.solid:continue
		var size_body=Vector2(obj.shadow_size*1.45,7)
		var footprint=Rect2(obj.position-Vector2(0,4)-size_body/2,size_body).grow(5)
		for y in range(floori(footprint.position.y/16),floori(footprint.end.y/16)+1):
			for x in range(floori(footprint.position.x/16),floori(footprint.end.x/16)+1):
				var at=Vector2i(x,y)
				if grid.is_in_boundsv(at) and footprint.has_point(center(at)):grid.set_point_solid(at)

func start_exterior():
	exterior=true
	var world_rect=Sectors.bounds()
	configure_grid(Rect2i(Vector2i(world_rect.position/16),Vector2i(world_rect.size/16)))

func sync_sector(world,cell:Vector2i):
	var rect=Rect2i(cell*Vector2i(48,32),Vector2i(48,32))
	if world.loaded.has(cell):
		for y in range(rect.position.y,rect.end.y):
			for x in range(rect.position.x,rect.end.x):
				var p=Vector2i(x,y)
				var tile=world.terrain.get_cell_tile_data(p)
				grid.set_point_solid(p,tile==null or tile.get_collision_polygons_count(0)>0)
		block_footprints(world.loaded[cell].nodes)
	else:
		grid.fill_solid_region(rect,true)
	reset_path()

func rebuild(world):
	exterior=not world.interior
	if exterior:
		start_exterior()
		for cell in world.loaded:sync_sector(world,cell)
	else:
		configure_grid(world.terrain.get_used_rect())
		for p in world.terrain.get_used_cells():
			grid.set_point_solid(p,world.terrain.get_cell_tile_data(p).get_collision_polygons_count(0)>0)
		block_footprints(world.objects.get_children())
		reset_path()

func center(cell:Vector2i)->Vector2:return Vector2(cell)*16+Vector2(8,8)

func open_cell(pos:Vector2)->Vector2i:
	var cell=Vector2i((pos/16).floor())
	if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):return cell
	var best=Vector2i(-1,-1)
	var distance=INF
	for y in range(cell.y-2,cell.y+3):
		for x in range(cell.x-2,cell.x+3):
			var candidate=Vector2i(x,y)
			var d=pos.distance_squared_to(center(candidate))
			if d<distance and grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
				best=candidate
				distance=d
	return best

# Historical outdoor saves may now fall inside a bank, a tree or a new building.
func can_stand(pos:Vector2)->bool:
	for offset in [Vector2.ZERO,Vector2(-5,-5),Vector2(5,-5),Vector2(-5,5),Vector2(5,5)]:
		var p=Vector2i(((pos+offset)/16).floor())
		if not grid.is_in_boundsv(p) or grid.is_point_solid(p):return false
	return true

func resume_position(pos:Vector2)->Vector2:
	if can_stand(pos):return pos
	var base=Sectors.origin(Sectors.at(pos))
	var cross=open_cell(base+Sectors.CROSSROAD)
	var first=Vector2i((pos/16).floor())
	for radius in range(1,49):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				if maxi(absi(x),absi(y))!=radius:continue
				var p=first+Vector2i(x,y)
				var candidate=center(p)
				if Sectors.at(candidate)==Sectors.at(pos) and can_stand(candidate) and not grid.get_id_path(cross,p).is_empty():return candidate
	return center(cross)

func follow(pos:Vector2,dest:Vector2):
	if exterior:
		var start=Sectors.at(pos)
		var finish=Sectors.at(dest)
		if start!=start_sector or finish!=finish_sector:
			corridor=Sectors.route(start,finish)
			start_sector=start
			finish_sector=finish
		if corridor.size()>1:
			var direction=Vector2(corridor[1]-start)
			var crossing=Vector2(328,264)
			if direction.x>0:crossing.x=Vector2(Sectors.SIZE).x+24
			elif direction.x<0:crossing.x=-24
			elif direction.y>0:crossing.y=Vector2(Sectors.SIZE).y+24
			else:crossing.y=-24
			var ahead=Sectors.origin(start)+crossing
			find_path(pos,ahead,pos.distance_to(dest))
			return
	find_path(pos,dest)

func find_path(pos:Vector2,dest:Vector2,estimate:float=0.0):
	var current=open_cell(pos)
	var goal=open_cell(dest)
	if current!=last_cell or goal!=target_cell:
		var index=steps.find(current) if goal==target_cell else -1
		if index>=0:steps=steps.slice(index)
		elif current.x>=0 and goal.x>=0:steps=grid.get_id_path(current,goal)
		else:steps.clear()
		last_cell=current
		target_cell=goal
		available=not steps.is_empty()
		remaining=0.0
		for i in range(1,steps.size()):remaining+=center(steps[i]).distance_to(center(steps[i-1]))
		remaining+=center(goal).distance_to(dest) if available else 0.0
		queue_redraw()
	remaining=maxf(remaining,estimate)
	next_point=center(steps[1]) if steps.size()>1 else dest

func _draw():
	if not Saga.settings.get_value("game","trail",true):return
	for i in range(1,mini(steps.size(),7)):
		var p=center(steps[i])
		var dir=(p-center(steps[i-1])).normalized()
		var wing=dir.orthogonal()*2
		var color=Color("#ffe2a8")
		color.a=.70-float(i)*.066
		draw_polyline(PackedVector2Array([p-dir*2+wing,p+dir,p-dir*2-wing]),color,1)
