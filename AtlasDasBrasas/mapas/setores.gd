extends RefCounted

const SIZE := Vector2i(768, 512)
const REGION_SIZE := Vector2i(3072, 2048)
const VERSION := 2
const LEGACY_REALMS := [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1), Vector2i(1,1), Vector2i(0,1)]
# The index is a campaign ID. Positions and bounds may be changed independently.
const REGIONS := [
	Rect2i(0,0,4,4), Rect2i(4,0,4,4), Rect2i(8,0,4,4),
	Rect2i(8,4,4,4), Rect2i(4,4,4,4), Rect2i(0,4,4,4)
]
const DIRECTIONS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const CROSSROAD := Vector2(328,264)

static func at(pos: Vector2) -> Vector2i:
	return Vector2i((pos / Vector2(SIZE)).floor())

static func origin(cell:Vector2i) -> Vector2:
	return Vector2(cell * SIZE)

static func hub(realm:int) -> Vector2i:
	return REGIONS[realm].position + Vector2i.ONE

static func realm_at(cell:Vector2i) -> int:
	for i in REGIONS.size():
		if REGIONS[i].has_point(cell):
			return i
	return -1

static func bounds() -> Rect2:
	var rect:Rect2i=REGIONS[0]
	for region in REGIONS:
		rect=rect.merge(region)
	return Rect2(Vector2(rect.position*SIZE),Vector2(rect.size*SIZE))

static func key(cell:Vector2i) -> String:
	return "%d,%d" % [cell.x,cell.y]

static func neighbors(cell:Vector2i) -> Array[Vector2i]:
	var linked:Array[Vector2i]=[]
	for direction in DIRECTIONS:
		if realm_at(cell+direction)>=0:
			linked.append(cell+direction)
	return linked

static func route(start:Vector2i, finish:Vector2i) -> Array[Vector2i]:
	var path:Array[Vector2i]=[]
	if realm_at(start)<0 or realm_at(finish)<0:
		return path
	var queue:Array[Vector2i]=[start]
	var previous={start:start}
	var cursor=0
	while cursor<queue.size() and not previous.has(finish):
		for cell in neighbors(queue[cursor]):
			if not previous.has(cell):
				previous[cell]=queue[cursor]
				queue.append(cell)
		cursor+=1
	if not previous.has(finish):
		return path
	var cell=finish
	while cell!=start:
		path.push_front(cell)
		cell=previous[cell]
	path.push_front(start)
	return path

static func migrate(state: Dictionary, original_version:int):
	if state.inside or original_version>=VERSION:
		return
	var position=Vector2(float(state.pos[0]),float(state.pos[1]))
	var legacy_cell=Vector2i((position/Vector2(SIZE)).floor()).clamp(Vector2i.ZERO,Vector2i(2,1))
	var realm=LEGACY_REALMS.find(legacy_cell)
	var offset=(position-origin(legacy_cell)).clamp(Vector2(8,8),Vector2(SIZE)-Vector2(8,8))
	position=origin(hub(realm))+offset
	state.pos=[position.x,position.y]
