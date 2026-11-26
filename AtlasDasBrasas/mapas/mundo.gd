extends Node2D

const Sectors=preload("res://mapas/setores.gd")
const Expedition=preload("res://mapas/expedicao.gd")
const Obra=preload("res://mapas/obra.gd")
const Frontier=preload("res://mapas/fronteiras.gd")
const Visitors=preload("res://personagens/visitantes.gd")
const Lugar=preload("res://mapas/lugar.gd")
const Mentor=preload("res://personagens/mentor.gd")
const POINTS=[Vector2(446,250),Vector2(595,383),Vector2(146,383)]
const WEATHER_BOARD=Vector2(305,305)
const WATER_CART=Vector2(385,338)
const GAUGES=[Vector2(419,143),Vector2(207,340)]
const HOME=Vector2(327,226)
const CACHE=Vector2(135,128)
const CRYPT=Vector2(85,448)
const ARCH=Vector2(661,109)
const CARE_POINTS=[Vector2(385,224),Vector2(575,195),Vector2(188,327),Vector2(635,328),Vector2(216,115),Vector2(695,200)]
const CARE_LABELS=["Posto da balsa","Pátio de acolhimento","Abrigo da cisterna","Pousada da serra","Viveiro das águas","Posto da forja"]
const CARE_ART=["venda","academia","poco","pousada","boticario","provisoes"]
const WORKSHOPS=["oficina","biblioteca","fortaleza","torre","jardim","forja"]
const VILLAGES=["casa-junco","casa-lume","casa-ocre","casa-serra","casa-mata","casa-basalto"]
const TRADES=["moinho","livraria","vigia","serraria","fazenda","mineiro"]
const REGIONAL_FLORA=[
	["green","willow","flowers","green","gold"],
	["pink","violet","flowers","pink","gold"],
	["rock","stub","gold","stones","rock"],
	["pine","stones","pine","crystals","rock"],
	["willow","wisdom","fungus","green","plant"],
	["hazel","stones","crystals","stub","rock"]
]
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
var nursery_plants:Array=[]
var loaded:Dictionary={}
var current_sector:=Vector2i(-1,-1)
var pending_update:=false
var queued_sectors:Array[Vector2i]=[]
var hub_rng_states:Array[int]=[]

func configure(owner_game):
	game=owner_game
	# Reproduce the legacy RNG stream for each hub regardless of load order.
	var legacy=RandomNumberGenerator.new()
	legacy.seed=52731
	var offsets=[Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN,Vector2i.RIGHT]
	for c in 6:
		hub_rng_states.append(legacy.state)
		for y in 32:
			for x in 48:
				legacy.randi_range(0,3)
				if is_road(x,y) and offsets.all(func(v):return is_road(x+v.x,y+v.y)):
					legacy.randi_range(4,7)
		for i in 185:
			legacy.randf_range(12,757)
			legacy.randf_range(20,509)
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
	Frontier.register_tiles(atlas)
	for j in 7:
		for k in [8,9,10,16]:
			var td=source.get_tile_data(Vector2i(k,j),0)
			td.set_collision_polygons_count(0,1)
			td.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))

func rebuild(inside:bool,r:int,room:String="hall",entry:Vector2=Vector2.ZERO):
	modulate=Color.WHITE
	room_type=room
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	sites.clear()
	nursery_plants.clear()
	loaded.clear()
	queued_sectors.clear()
	current_sector=Vector2i(-1,-1)
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
		var frontier=Frontier.id_from_room(room_type)
		if frontier>=0:Frontier.build(self,frontier)
		elif room_type.begins_with("field_"):Expedition.build_room(self,r,room_type=="field_cave")
		elif room_type=="crypt":build_crypt(r)
		else:build_room(r)
	else:
		walls(Sectors.bounds())
		stream(entry)
	if inside:trail.rebuild(self)
	var motes=preload("res://mapas/vestigios.gd").new()
	motes.world=self
	motes.z_index=2
	add_child(motes)
	refresh()
	queue_redraw()

func stream(position_to_load:Vector2,immediate:bool=true):
	if interior:return
	var center=Sectors.at(position_to_load)
	var moved=center!=current_sector
	if moved:
		current_sector=center
		queued_sectors.clear()
		var wanted:Dictionary={}
		for y in range(center.y-1,center.y+2):
			for x in range(center.x-1,center.x+2):
				var cell=Vector2i(x,y)
				if Sectors.realm_at(cell)>=0:wanted[cell]=true
		for cell in loaded.keys():
			if not wanted.has(cell):unload_sector(cell)
		for cell in wanted:
			if not loaded.has(cell):queued_sectors.append(cell)
		queued_sectors.sort_custom(func(a,b):return (a-center).length_squared()<(b-center).length_squared())
		Saga.data.visited_sectors[Sectors.key(center)]=true
		var area=Expedition.entry(center)
		if not area.is_empty():Saga.data.discoveries[area[2]]=true
	if not moved and queued_sectors.is_empty():return
	# On foot the next chunk is already present. Refill the outer ring over
	# several frames, prioritizing the player if entering via a warp.
	var batch=queued_sectors.size() if immediate else mini(1,queued_sectors.size())
	for i in batch:load_sector(queued_sectors.pop_front())
	pending_update=true
	refresh()

func unload_sector(cell:Vector2i):
	var group:Dictionary=loaded[cell]
	for node in group.nodes:
		if not is_instance_valid(node):continue
		sites.erase(node)
		mentors.erase(node)
		residents.erase(node)
		nursery_plants.erase(node)
		game.enemies.erase(node)
		node.queue_free()
		if node.get_parent()==objects:objects.remove_child(node)
	for enemy in game.enemies.duplicate():
		if not enemy.dead and Sectors.at(enemy.home)==cell:
			game.enemies.erase(enemy)
			enemy.queue_free()
			if enemy.get_parent()==objects:objects.remove_child(enemy)
	var base=Vector2i(Sectors.origin(cell))/16
	for y in 32:
		for x in 48:terrain.erase_cell(base+Vector2i(x,y))
	loaded.erase(cell)

func load_sector(cell:Vector2i):
	var realm=Sectors.realm_at(cell)
	var previous=objects.get_child_count()
	if cell==Sectors.hub(realm):
		nature_rng.state=hub_rng_states[realm]
		build_region(realm)
		game.populate_hub(realm)
	else:
		Expedition.paint(self,cell,realm)
	loaded[cell]={"nodes":objects.get_children().slice(previous)}

func place(pos:Vector2,texture:Texture2D,tag="",title="",solid=true,shadow=13.0):
	var n=Lugar.new()
	n.position=pos
	n.setup(tag,title,texture,solid,shadow)
	objects.add_child(n)
	if tag!="":sites.append(n)
	return n

func prop(pos:Vector2,idx:int,tag="",title="",solid=true,shadow=13.0):
	return place(pos,load("res://mapas/p%d.png"%idx),tag,title,solid,shadow)

func margem(pos:Vector2,art:String,tag="",title="",solid=true,shadow=13.0):
	return place(pos,load("res://mapas/margens/%s.png"%art),tag,title,solid,shadow)

func detail(pos:Vector2,idx:int,blocks:bool=false,radius:float=7):
	return place(pos,load("res://mapas/biomas/%02d.png"%idx),"","",blocks,radius)

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
	var reserved=[CARE_POINTS[c],HOME,CACHE,ARCH,CRYPT,Vector2(382,172),Vector2(207,215),Vector2(568,105),Vector2(238,151),Vector2(435,330),Vector2(543,300),Vector2(120,342)]
	reserved.append_array(POINTS)
	if c<=1:reserved.append(GAUGES[c])
	if c==0:reserved.append_array([WEATHER_BOARD,WATER_CART,Obra.POSITION])
	var frontier=Frontier.ORIGINS.find(c)
	if frontier>=0:reserved.append(Frontier.GATES[frontier])
	var planted:Array=[]
	for i in 185:
		var p=Vector2(nature_rng.randf_range(12,757),nature_rng.randf_range(20,509))
		if absi(floori(p.x/16)-channel_x(c,floori(p.y/16))-1)<=2:continue
		if absf(p.y-264)<32 or absf(p.x-327)<30 or absf(p.y-383)<20 or absf(p.x-144)<15 or absf(p.x-600)<18:continue
		if reserved.any(func(v):return p.distance_to(v)<48):continue
		if planted.any(func(v):return p.distance_to(v)<24):continue
		planted.append(p)
		var foliage=REGIONAL_FLORA[c][i%5]
		var canopy=foliage in ["green","willow","gold","pink","violet","pine","wisdom","hazel"]
		margem(base+p,foliage,"","",canopy or foliage in ["rock","stones"],9 if canopy else 6)

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

	if c<=1:
		place(base+GAUGES[c],load("res://mapas/estacao/pluviometro.png"),"gauge","Pluviômetro do viveiro",true,7)
		for offset in [Vector2(18,5),Vector2(30,4),Vector2(24,13)]:
			var plants=margem(base+GAUGES[c]+offset,"plant","","",false,3)
			nursery_plants.append(plants)
	if c==0:
		place(base+WEATHER_BOARD,load("res://mapas/estacao/boletim.png"),"weather_board","Boletim das margens",true,8)
		place(base+WATER_CART,load("res://mapas/estacao/carroca.png"),"water_cart","Carroça de rega",true,17)
	margem(base+HOME,WORKSHOPS[c],"door",d.building,true,23)
	margem(base+Vector2(238,151),VILLAGES[c],"","",true,18)
	margem(base+Vector2(568,105),TRADES[c],"","",true,18)
	margem(base+CARE_POINTS[c],CARE_ART[c],"care",CARE_LABELS[c],true,15)

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
	if c==0:Obra.install(self)
	if frontier>=0:prop(base+Frontier.GATES[frontier],5,"frontier"+str(frontier),Frontier.NAMES[frontier],true,14)
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
		Visitors.adicionar(self,c)
		prop(Vector2(145,164),[9,10,10,11,13,9][c],"desk","Acervo de "+str(Saga.regions[c].name),true,13)
		var m=Mentor.new()
		m.setup(c,Vector2(257,144),game.is_locked)
		objects.add_child(m)
		mentors.append(m)
		if c==0:
			place(Vector2(365,205),load("res://personagens/enfermeira_campo.png"),"nurse","Enfermeira Lia",false,8)
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
	for plant in nursery_plants:
		plant.visible=Saga.region_at(plant.position)==int(Saga.data.rain_recipient)
	if not interior and (last_restored!=Saga.data.chapter or pending_update):
		pending_update=false
		last_restored=Saga.data.chapter
		for c in 6:
			if not loaded.has(Sectors.hub(c)):continue
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
		if not n is Lugar:continue
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
