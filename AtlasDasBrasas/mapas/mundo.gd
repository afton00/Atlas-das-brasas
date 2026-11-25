extends Node2D

const Lugar=preload("res://mapas/lugar.gd")
const Mentor=preload("res://personagens/mentor.gd")
const POINTS=[Vector2(446,250),Vector2(595,383),Vector2(146,383)]
const HOME=Vector2(327,226)
const CACHE=Vector2(135,128)
const CRYPT=Vector2(85,448)
const ARCH=Vector2(661,109)
var trail
var terrain:TileMapLayer
var objects:Node2D
var sites:Array=[]
var mentors:Array=[]
var residents:Array=[]
var room_type="hall"
var interior=false
var region=0
var game
var atlas:TileSet
var hero
var nature_rng=RandomNumberGenerator.new()
var ambient=0.0
var destination=Vector2.ZERO
var last_restored=-1

func configure(owner_game):
	game=owner_game
	atlas=TileSet.new()
	atlas.tile_size=Vector2i(16,16)
	atlas.add_physics_layer()
	atlas.set_physics_layer_collision_layer(0,1)
	var source=TileSetAtlasSource.new()
	source.texture=preload("res://mapas/terrenos.png")
	source.texture_region_size=Vector2i(16,16)
	for j in 7:
		for i in 34: source.create_tile(Vector2i(i,j))
	atlas.add_source(source,0)
	for j in 7:
		for k in [8,9,10,16]:
			var td=source.get_tile_data(Vector2i(k,j),0)
			td.set_collision_polygons_count(0,1)
			td.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))

func rebuild(inside:bool,r:int,room:String="hall"):
	room_type=room
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	sites.clear()
	mentors.clear()
	residents.clear()
	interior=inside
	region=r
	last_restored=-1
	nature_rng.seed=52731
	terrain=TileMapLayer.new()
	terrain.tile_set=atlas
	add_child(terrain)
	trail=preload("res://mapas/trilha.gd").new()
	add_child(trail)
	objects=Node2D.new()
	objects.y_sort_enabled=true
	add_child(objects)
	if inside:
		if room_type=="crypt":build_crypt(r)
		else:build_room(r)
	else:
		for n in 6: build_region(n)
		walls(Rect2(Vector2.ZERO,Saga.AREA*Vector2(3,2)))
	if inside:trail.rebuild(self)
	var motes=preload("res://mapas/vestigios.gd").new()
	motes.world=self
	motes.z_index=2
	add_child(motes)
	refresh()
	queue_redraw()

func prop(pos:Vector2,idx:int,tag="",title="",solid=true,shadow=13.0):
	var n=Lugar.new()
	n.position=pos
	n.setup(tag,title,load("res://mapas/p%d.png"%idx),solid,shadow)
	objects.add_child(n)
	if tag!="":sites.append(n)
	return n

func sprite_prop(pos:Vector2,idx:int,tag="",title="",solid=true,shadow=13.0):
	var n=Lugar.new()
	n.position=pos
	n.setup(tag,title,load("res://personagens/s%d.png"%idx),solid,shadow)
	objects.add_child(n)
	if tag!="":sites.append(n)
	return n

func detail(pos:Vector2,idx:int,blocks:bool=false,radius:float=7):
	var n=Lugar.new()
	n.position=pos
	n.setup("","",load("res://mapas/biomas/%02d.png"%idx),blocks,radius)
	objects.add_child(n)
	return n

func obstacle(rect:Rect2):
	var body=StaticBody2D.new()
	var col=CollisionShape2D.new()
	var shape=RectangleShape2D.new()
	shape.size=rect.size
	col.shape=shape
	body.position=rect.get_center()
	body.add_child(col)
	objects.add_child(body)

func walls(rect:Rect2):
	obstacle(Rect2(rect.position-Vector2(10,8),Vector2(rect.size.x+20,8)))
	obstacle(Rect2(rect.position+Vector2(-10,rect.size.y),Vector2(rect.size.x+20,8)))
	obstacle(Rect2(rect.position-Vector2(8,0),Vector2(8,rect.size.y)))
	obstacle(Rect2(rect.position+Vector2(rect.size.x,0),Vector2(8,rect.size.y)))

func is_road(x:int,y:int):
	return absi(y-16)<=1 or absi(x-20)<=1 or (y in [23,24] and x>=8 and x<=38) or (x in [8,9,37,38] and y>=8 and y<=24)

func build_region(c:int):
	var base=Saga.origin(c)
	var d=Saga.regions[c]
	for y in 32:
		for x in 48:
			var tile=nature_rng.randi_range(0,3)
			if is_road(x,y):
				var mask=0
				var dirs=[Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN,Vector2i.RIGHT]
				for j in 4:
					var near=Vector2i(x,y)+dirs[j]
					if not is_road(near.x,near.y):mask|=1<<j
				tile=18+mask if mask else nature_rng.randi_range(4,7)
			terrain.set_cell(Vector2i(base/16)+Vector2i(x,y),0,Vector2i(tile,c))
	# Keep a second public crossing available while the chapter bridge is closed.
	for y in 32:
		var channel=channel_x(c,y)
		for x in 3:
			var tile=[9,8,10][x]
			if y in [8,9,23,24]:tile=12 if y in [9,23] else 11
			terrain.set_cell(Vector2i(base/16)+Vector2i(channel+x,y),0,Vector2i(tile,c))
	var reserved=[HOME,CACHE,ARCH,CRYPT,Vector2(382,172),Vector2(207,215),Vector2(500,158),Vector2(238,151),Vector2(435,330),Vector2(543,300),Vector2(120,342)]
	reserved.append_array(POINTS)
	var planted:Array=[]
	for i in 185:
		var p=Vector2(nature_rng.randf_range(12,757),nature_rng.randf_range(20,509))
		if absi(floori(p.x/16)-channel_x(c,floori(p.y/16))-1)<=2:continue
		if absf(p.y-264)<32 or absf(p.x-327)<30 or absf(p.y-383)<20 or absf(p.x-144)<15 or absf(p.x-600)<18:continue
		if reserved.any(func(v):return p.distance_to(v)<48):continue
		if planted.any(func(v):return p.distance_to(v)<24):continue
		planted.append(p)
		var palettes=[[9,11,0,9,7],[11,9,8,6,11],[4,5,5,4,5],[6,7,6,7,6],[9,8,9,8,8],[10,7,11,10,10]]
		var idx=int(palettes[c][i%5])
		detail(base+p,idx,idx not in [0,8],9 if idx in [4,6,9,11] else 7)
	# Village furniture gives the entrances and river crossings distinct silhouettes.
	for spot in [HOME+Vector2(-29,2),POINTS[1]+Vector2(20,-5),CRYPT+Vector2(22,-5)]:
		detail(base+spot,2)
	for spot in [HOME+Vector2(-49,1),HOME+Vector2(48,1)]:
		detail(base+spot,1)
	detail(base+Vector2(354,244),3)
	for k in 36:
		var spot=Vector2(35+fmod(k*91.3,684),28+fmod(k*61.2,451))
		var cell=Vector2i(base/16)+Vector2i(spot/16)
		if terrain.get_cell_atlas_coords(cell).x in [0,1,2,3]:
			if c in [0,1,4]:detail(base+spot,0 if k%3!=0 else 8)

	if c==0:sprite_prop(base+HOME,14,"door",d.building,true,24)
	else:prop(base+HOME,[0,0,1,2,3,4][c],"door",d.building,true,23)
	sprite_prop(base+Vector2(238,151),14,"","",true,22)
	prop(base+Vector2(500,158),[12,0,1,2,3,4][c],"","",true,22)
	prop(base+Vector2(435,330),[8,12,8,7,13,8][c],"","",true,10)
	for i in 3:prop(base+POINTS[i],[[9,5,11],[10,5,10],[10,5,8],[11,7,11],[13,14,13],[9,5,11]][c][i],"site"+str(i),d["site"+str(i)],true,12)
	prop(base+CACHE,15,"cache","Abrigo do recanto",false,9)
	prop(base+ARCH,5,"arch","Arco da caldeira" if c==5 else "Marco de viagem",true,16)
	prop(base+Vector2(543,300),14,"herb","Colher ervas",true,8)
	prop(base+Vector2(120,342),7,"ore","Recolher minério",true,10)
	prop(base+CRYPT,5,"crypt","Templo do rio antigo",true,16)
	if c in [0,1,2]:
		prop(base+Vector2(382,172),12,"","",true,14)
		prop(base+Vector2(207,215),8,"","",true,9)
	if c==0:prop(base+Vector2(205,297),9,"arena","Escola de combate",true,11)
	var walker=Mentor.new()
	walker.setup(c,base+Vector2(365,268),game.is_locked)
	objects.add_child(walker)
	mentors.append(walker)
	var local=Mentor.new()
	var shelter=CACHE+Vector2(-20,5) if c in [2,5] and "side"+str(c) not in Saga.data.kills else Vector2(250,262)
	local.setup(c,base+shelter,game.is_locked,true)
	objects.add_child(local)
	residents.append(local)

func build_room(c:int):
	var cave=c==6
	for y in 20:
		for x in 32:
			var wall=y<3 or x in [0,31] or (cave and x in [6,25] and y>5 and y<14 and y not in [8,9])
			terrain.set_cell(Vector2i(x,y),0,Vector2i(16 if wall else 15 if cave or c in [2,3,5] else 14,c))
	walls(Rect2(0,0,512,320))
	for i in 8:
		var x=30+i*65
		prop(Vector2(x,56),7 if cave else [10,9,11][i%3],"","",true,10)
	if not cave:
		prop(Vector2(145,164),[9,10,10,11,13,9][c],"desk","Acervo de "+str(Saga.regions[c].name),true,13)
		var m=Mentor.new()
		m.setup(c,Vector2(257,144),game.is_locked)
		objects.add_child(m)
		mentors.append(m)
	else:prop(Vector2(256,78),6,"altar","Pedra das seis margens",true,20)
	prop(Vector2(256,294),5,"exit","Voltar à estrada",false,12)

func build_crypt(c):
	# The central wall has alternating doorways. The player reads the inscription,
	# follows the chambers in order and opens the reliquary beyond the last gate.
	for y in 20:
		for x in 32:
			var wall=(x==0 or x==31 or y<2 or y==19 or (x in [9,21] and y not in [5,6,7,14,15]))
			terrain.set_cell(Vector2i(x,y),0,Vector2i(16 if wall else 15,c))
	walls(Rect2(0,0,512,320))
	prop(Vector2(215,252),10,"inscription","Ler a inscrição",true,10)
	prop(Vector2(68,116),11,"rune0","Runa da fonte",true,9)
	prop(Vector2(256,79),11,"rune1","Runa do curso",true,9)
	prop(Vector2(431,126),11,"rune2","Runa da foz",true,9)
	prop(Vector2(425,240),15,"relic","Relicário das margens",true,10)
	prop(Vector2(256,291),5,"exit","Voltar à estrada",false,12)
	for pos in [Vector2(37,245),Vector2(177,56),Vector2(353,48),Vector2(472,212)]:
		prop(pos,7,"","",true,12)

func channel_x(c:int,y:int)->int:
	return 30+roundi(sin((y+c*2)*.24)*1.65)

func refresh():
	if not interior and last_restored!=Saga.data.chapter:
		last_restored=Saga.data.chapter
		for c in 6:
			var base=Vector2i(Saga.origin(c)/16)
			for y in [15,16,17]:
				for x in 3:
					var tile=([9,8,10][x] if c>=last_restored else 12 if y==16 else 11)
					terrain.set_cell(base+Vector2i(channel_x(c,y)+x,y),0,Vector2i(tile,c))
			if c<last_restored:
				for x in range(25,35):
					terrain.set_cell(base+Vector2i(x,21),0,Vector2i(17 if c==4 else 13,c))
		trail.rebuild(self)
	for n in sites:
		var c=region if interior else Saga.region_at(n.position)
		n.active=false
		if n.tag=="door" and c==Saga.data.chapter:
			n.active=not Saga.data.briefed or (Saga.data.taught<0 and not Saga.current_lesson().is_empty())
		if n.tag.begins_with("site") and c==Saga.data.chapter:
			var wanted=2 if Saga.current_lesson().is_empty() else int(Saga.data.stage)%3
			n.active=(Saga.data.taught>=0 or Saga.current_lesson().is_empty()) and n.tag=="site"+str(wanted)
		if n.tag=="arch" and c==5 and Saga.data.chapter==6:n.active=true
		if n.tag=="cache" and str(c) in Saga.data.chests:n.modulate=Color("#b5bdac")
		n.queue_redraw()

func nearest(p:Vector2):
	var best=null
	var dist=38.0
	for n in sites+mentors+residents:
		var d=p.distance_to(n.position)
		if d<dist:
			dist=d
			best=n
	return best
