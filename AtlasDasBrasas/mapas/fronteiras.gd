extends RefCounted

const NAMES=["Arquipélago de Íris","Terras Corrompidas","A Sétima Margem"]
const ORIGINS=[0,5,3]
const GATES=[Vector2(469,382),Vector2(237,123),Vector2(408,203)]
const BRIEF=[
	"A barqueira escondeu o rumo entre duas boias. No ancoradouro, leia a carta e navegue até o farol para registrar a rota.",
	"Um cristal despeja calor na fenda a intervalos regulares. Consulte o sismógrafo para descobrir quando o antigo passadiço pode ser acionado.",
	"Depois que Aster se libertou, três ilhas reapareceram sobre a serra. O mapa de sombras indica como girar o espelho que sustenta a última ponte."
]
const CLUES=[
	"Na carta, o norte fica no alto. A boia de partida está em B3 e o farol em D1. As letras crescem para a direita e os números crescem para baixo.",
	"O sismógrafo marcou pulsos aos 2, 5 e 8 segundos. A diferença se repete. Programe o próximo pulso para que a passarela cristalize sobre a fenda.",
	"A rosa dos ventos da ilha tem o norte no alto. O espelho aponta para o sul. Um quarto de volta no sentido anti-horário muda sua direção em 90 graus."
]
const SITE_NAMES=[["Carta das boias","Barco de travessia","Farol de Íris"],["Sismógrafo","Comando da passarela","Cristal da fenda"],["Rosa dos ventos","Espelho suspenso","Arquivo das nuvens"]]
const POSITIONS=[
	[Vector2(88,110),Vector2(165,184),Vector2(420,130)],
	[Vector2(78,202),Vector2(182,152),Vector2(429,121)],
	[Vector2(68,123),Vector2(230,169),Vector2(431,133)]]
const EXIT=Vector2(76,224)
const ARRIVAL=Vector2(83,196)
const EAST_PIER=Vector2(343,181)

static func id_from_room(room:String)->int:
	return ["iris","corrupcao","setima"].find(room)

static func room_for(i:int)->String:
	return ["iris","corrupcao","setima"][i]

static func stage(i:int)->int:
	return int(Saga.data.voyages.get(str(i),0))

static func unlocked(i:int)->bool:
	return i==0 or (i==1 and Saga.data.chapter>=3) or (i==2 and Saga.data.won)

static func requirement(i:int)->String:
	return ["Acesso pelo cais do Junco.","Restaure três selos para abrir a fenda de Basalto.","Volte à Serra da Agulha depois do encontro final com Aster."][i]

static func register_tiles(atlas:TileSet):
	var src=TileSetAtlasSource.new()
	src.texture=preload("res://mapas/fronteiras/terreno.png")
	src.texture_region_size=Vector2i(16,16)
	for j in 3:
		for x in 24:src.create_tile(Vector2i(x,j))
	atlas.add_source(src,1)
	for j in 3:
		for x in 3:
			var td=src.get_tile_data(Vector2i(x,j),0)
			td.set_collision_polygons_count(0,1)
			td.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))

static func in_island(tile:Vector2i,center:Vector2,radius:Vector2)->bool:
	var offset=(Vector2(tile)+Vector2(.5,.5)-center)/radius
	return offset.length_squared()<1.0+.07*sin(tile.y*1.7+center.x)

static func land(i:int,p:Vector2i)->bool:
	if i==2:
		return in_island(p,Vector2(5,11),Vector2(4.5,5.5)) or in_island(p,Vector2(14.6,10.3),Vector2(3.4,3.8)) or in_island(p,Vector2(26,10),Vector2(4.7,5.5))
	if i==1:
		return in_island(p,Vector2(5,11),Vector2(8,8)) or in_island(p,Vector2(26,10),Vector2(8,8))
	return in_island(p,Vector2(6.6,11),Vector2(5.8,6.4)) or in_island(p,Vector2(25,10.4),Vector2(5.7,6.5))

static func bridge(i:int,p:Vector2i)->bool:
	if i==1:return stage(i)>=2 and p.x in range(10,24) and p.y in [9,10]
	if i==2:return p.y in [10,11] and (p.x in range(6,15) or (stage(i)>=2 and p.x in range(14,26)))
	return false

static func terrain(w,i:int):
	var dirs=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	for y in 20:
		for x in 32:
			var p=Vector2i(x,y)
			var k=posmod(x*19+y*31,3)
			if land(i,p):
				var mask=0
				for n in 4:
					if not land(i,p+dirs[n]):mask|=1<<n
				k=6+mask if mask else 3+k
			elif bridge(i,p):k=22
			w.terrain.set_cell(p,1,Vector2i(k,i))

static func build(w,i:int):
	terrain(w,i)
	w.walls(Rect2(0,0,512,320))
	w.prop(EXIT,5,"voy_exit","Retornar à estrada",false,9)
	var art=[[10,9,11],[10,11,7],[10,11,6]][i]
	for n in 3:w.prop(POSITIONS[i][n],art[n],["voy_clue","voy_device","voy_goal"][n],SITE_NAMES[i][n],true,10)
	if i==0:w.prop(EAST_PIER,9,"voy_ferry","Voltar de barco",true,9)
	var scenery=[
		["green","willow","provisoes","flowers","rock","casa-junco"],
		["rock","crystals","vigia","crystals","hazel","mineiro"],
		["pink","wisdom","torre","flowers","crystals","casa-serra"]][i]
	var scenery_points=[Vector2(56,163),Vector2(108,82),Vector2(111,242),Vector2(382,203),Vector2(440,181),Vector2(400,107)]
	for n in scenery.size():w.margem(scenery_points[n],scenery[n],"","",false,8)

static func objective(i:int)->String:
	var s=stage(i)
	return ("Volte à estrada quando quiser." if s==3 else ["Examine ","Use ","Registre a descoberta em "][s]+str(SITE_NAMES[i][s])+".")

static func target(g,i:int)->Vector2:
	var s=stage(i)
	if i==0 and g.hero.position.x>256 and s==3:return EAST_PIER
	if i==0 and g.hero.position.x<256 and s==2:return POSITIONS[0][1]
	return EXIT if s==3 else POSITIONS[i][s]

static func land_hero(g,p:Vector2):
	g.hero.position=p
	Saga.data.pos=[p.x,p.y]
	Saga.save()
	g.ui.play()

static func panel(g,i:int,heading:String,body:String,choices:Array):
	var u=g.ui
	u.panel_page("voyage",NAMES[i],heading)
	u.tex(u.view,"res://mapas/fronteiras/vista%d.png"%i,108,153,279,214,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	u.label(u.view,body,410,153,435,216,19)
	var width=(744-(choices.size()-1)*10)/choices.size()
	for j in choices.size():u.button(u.view,choices[j][0],108+j*(width+10),436,width,48,choices[j][1],j==0)
	u.focus_default()

static func gate(g,i:int):
	if not unlocked(i):
		panel(g,i,"Travessia fechada",requirement(i),[["Voltar",g.ui.play]])
		return
	panel(g,i,"Além das seis margens",BRIEF[i],[["Iniciar travessia",func():
		g.build(true,ORIGINS[i],ARRIVAL,room_for(i))
		Saga.save()
		g.ui.play()],["Voltar",g.ui.play]])

static func interact(g,i:int,tag:String):
	var s=stage(i)
	match tag:
		"voy_exit":
			g.build(false,ORIGINS[i],Saga.origin(ORIGINS[i])+GATES[i]+Vector2.DOWN*18)
			Saga.save()
			g.ui.play()
		"voy_clue":
			panel(g,i,SITE_NAMES[i][0],CLUES[i],[["Anotar a pista",func():
				if stage(i)==0:Saga.data.voyages[str(i)]=1
				Saga.save()
				g.ui.play()]])
		"voy_ferry":land_hero(g,POSITIONS[0][1]+Vector2.DOWN*15)
		"voy_device":
			if s==0:g.toast("Examine primeiro o marco «"+SITE_NAMES[i][0]+"».")
			elif s>=2 and i==0:land_hero(g,EAST_PIER+Vector2.DOWN*15)
			elif s>=2:g.toast("A travessia já está aberta.")
			else:mechanism(g,i)
		"voy_goal":
			if s<2:g.toast("O registro depende da travessia.")
			else:
				if s==2:
					Saga.data.voyages[str(i)]=3
					Saga.award(45)
					Saga.save()
					g.sound("sino")
				panel(g,i,"Carta de exploração",["O farol voltou a orientar as barcas entre as ilhas. A carta do arquipélago entrou no seu atlas.","O cristal estabilizou. Os mineiros podem voltar a atravessar a fenda entre os pulsos.","O arquivo voltou a refletir o sol. No último mapa, você reconhece as seis margens vistas do alto."][i],[["Guardar a carta",g.ui.play]])

static func mechanism(g,i:int,hint:String=""):
	var opts=[["Noroeste","Nordeste","Sudeste"],["10 segundos","12 segundos","11 segundos"],["Leste","Oeste","Norte"]][i]
	var question=["Trace o rumo de B3 até D1.","Quando virá o pulso seguinte?","Para onde apontará o espelho?"][i]
	var buttons=[]
	for j in 3:buttons.append([opts[j],answer.bind(g,i,j)])
	panel(g,i,SITE_NAMES[i][1],CLUES[i]+"\n\n"+(question if hint=="" else hint),buttons)

static func answer(g,i:int,value:int):
	if stage(i)!=1:return
	if value!=[1,2,0][i]:
		mechanism(g,i,["De B para D, siga a leste. De 3 para 1, siga ao norte. Tente de novo.","Some à última marca o mesmo intervalo que separa 2 de 5.","Parta do sul e gire um quarto de volta contra os ponteiros do relógio."][i])
		return
	Saga.data.voyages[str(i)]=2
	g.sound("runa")
	if i==0:land_hero(g,EAST_PIER+Vector2.DOWN*15)
	else:
		terrain(g.world,i)
		g.world.trail.rebuild(g.world)
		Saga.save()
		g.ui.play()
		g.toast("Travessia aberta · siga até "+SITE_NAMES[i][2]+".")
