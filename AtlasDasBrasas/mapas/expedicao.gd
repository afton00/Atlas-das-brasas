extends RefCounted

const Sectors=preload("res://mapas/setores.gd")
const Weather=preload("res://scripts/tempo.gd")
const Lands=preload("res://mapas/territorios.gd")
const Guilds=preload("res://mapas/casas_de_oficio.gd")
const Chambers=preload("res://mapas/camaras.gd")
const Caravan=preload("res://mapas/caravana.gd")
const Studies=preload("res://mapas/inqueritos.gd")
const Villager=preload("res://personagens/morador_de_estrada.gd")
const HUB_NAMES=["Vila do Junco","Lume das Letras","Reino de Ocre","Serra da Agulha","Mata da Nascente","Forja de Basalto"]
const DATA={
	"0,0":["Floresta dos Pinheiros","woods","pinheiros","A madeira caída conserva umidade e serve de abrigo a insetos. As trilhas de caça contornam os troncos.",1],
	"1,0":["Fazenda das Colinas","farm","fazenda","Na encosta, os canteiros seguem o contorno do morro. A água corre mais devagar quando não encontra um sulco direto até o vale.",0],
	"2,0":["Povoado da Amieira","village","amieira","Os agricultores compartilham ferramentas no galpão central. Depois da cheia, trocaram a palha dos telhados por ripas.",1],
	"3,0":["Moinho Abandonado","ruin","moinho","A velha roda ainda tem marcas de cheias diferentes. A mais alta deixou barro acima do eixo.",2],
	"0,1":["Povoado das Faias","village","faias","As tintureiras juntam cascas caídas na mata. Cortar toda a casca em volta de uma árvore danificaria o transporte de açúcares.",0],
	"2,1":["Porto dos Viajantes","water","porto","Os barqueiros amarram dois nós na régua quando o nível da água sobe. A primeira ponte fica a leste da pousada.",1],
	"3,1":["Ponte das Duas Margens","water","ponte","Quando se assentam tábuas de mesma largura lado a lado, o comprimento total é a soma dessas larguras.",1],
	"0,2":["Bosque das Águas","water","bosque","As raízes junto ao córrego seguram parte do solo. A água que passa pela margem nua carrega mais sedimentos.",0],
	"1,2":["Povoado da Ponte Velha","village","ponte_velha","Os moradores abriram um atalho pelo sul. O caminho segue a margem até a casa da vigia.",0],
	"2,2":["Rio das Margens","water","rio","Em curvas, a água pode desgastar mais a margem externa e depositar sedimentos na interna.",1],
	"3,2":["Estrada dos Carreiros","road","carreiros","Os marcos dos carreiros apontam para o Junco a oeste e para Lume a leste.",2],
	"0,3":["Acampamento dos Caçadores","camp","cacadores","Os rastros aparecem nas clareiras, mas os animais se abrigam entre as árvores.",0],
	"1,3":["Ruínas da Fortaleza do Freixo","ruin","fortaleza","As pedras reaproveitadas trazem marcas de dois períodos. A muralha atual é mais recente que a primeira fundação.",2],
	"2,3":["Gruta do Veado","cave","veado","Diferentes camadas da rocha se formaram em tempos distintos. As mais baixas costumam ser anteriores quando as camadas não foram invertidas.",2],
	"3,3":["Colo dos Mercadores","camp","colo","A estrada cruza a crista antes de descer para a Mata. Os viajantes dividem mantas e notícias por aqui.",1],
	"4,1":["Entreposto do Livro","village","entreposto","As remessas para Lume circulam com uma cópia da lista em cada carroça.",1],
	"4,0":["Floresta dos Manuscritos","woods","manuscritos","Escribas ergueram o abrigo sobre pedras para proteger os papéis da umidade do chão.",0],
	"5,0":["Vila dos Aprendizes","village","aprendizes","O sino avisa a hora das aulas. As casas abrigam viajantes que chegaram para copiar o atlas.",2],
	"4,2":["Caminho dos Copistas","road","copistas","As placas indicam o destino e a distância. A distância em linha reta é menor que o caminho com curvas.",0]
}
const LAYOUT={
	"village":["pousada","casa-junco","venda","fazenda","vigia","casa-junco"],
	"farm":["fazenda","serraria","poco","casa-junco","flowers","stub"],
	"water":["provisoes","casa-lume","vigia","willow","green","poco"],
	"woods":["pine","pine","green","pine","rock","willow"],
	"ruin":["fortaleza","stones","vigia","rock","gold","crystals"],
	"camp":["provisoes","poco","pine","green","stones","stub"],
	"road":["vigia","poco","willow","rock","gold","flowers"],
	"cave":["mineiro","rock","stones","crystals","pine","rock"]
}
const POINT=Vector2(331,216)
const LODGE=Vector2(399,267)
const MARKET=Vector2(240,247)
const CAMP=Vector2(346,321)
const SHORTCUT_ROW=6
const GATE_ROW=16
const BRIDGE_CELL=Vector2i(28,GATE_ROW)
const LODGE_EXIT=Vector2(255,290)
const ROAD_X=20
const ROAD_Y=16

static func entry(cell:Vector2i)->Array:
	var id=Sectors.key(cell)
	return DATA[id] if DATA.has(id) else Lands.AREAS.get(id,[])

static func name_at(cell:Vector2i)->String:
	var area=entry(cell)
	if not area.is_empty():return area[0]
	var realm=Sectors.realm_at(cell)
	if realm<0:return ""
	return HUB_NAMES[realm] if cell==Sectors.hub(realm) else "Arredores de "+HUB_NAMES[realm]

static func is_bridge_site(cell:Vector2i)->bool:
	return cell==Vector2i(3,1)

static func set_bridge(w,cell:Vector2i,opened:bool):
	var base=cell*Vector2i(48,32)
	for y in [15,16,17]:
		for x in range(27,32):w.terrain.set_cell(base+Vector2i(x,y),0,Vector2i(12 if opened else [9,8,8,8,10][x-27],0))

static func road(x:int,y:int,type:String,form:String="",bend:int=0)->bool:
	var vertical=ROAD_X
	var horizontal=ROAD_Y
	if form!="":
		# Branches rejoin the central clearing and each shared sector entrance.
		if x>=2 and x<=16:horizontal+=bend*mini(x-2,16-x)/2
		if x>=29 and x<=45:horizontal-=bend*mini(x-29,45-x)/2
		if y>=2 and y<=12:vertical+=bend*mini(y-2,12-y)/2
		if y>=21 and y<=29:vertical-=bend*mini(y-21,29-y)/2
	return absi(x-vertical)<=1 or absi(y-horizontal)<=1 or (type in ["village","farm","water"] and absi(y-SHORTCUT_ROW)<=1) or (type in ["woods","ruin","cave"] and y==25 and x in range(8,44))

static func paint(w,cell:Vector2i,realm:int):
	var area=entry(cell)
	var type="woods" if area.is_empty() else str(area[1])
	var form=str(area[5]) if area.size()>5 else ""
	var base=cell*Vector2i(48,32)
	var entrance=Sectors.origin(cell)
	var seed_value=cell.x*1103+cell.y*601+42
	var bend=1 if seed_value%2==0 else -1
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value
	for y in 32:
		for x in 48:
			var variant=rng.randi_range(0,3)
			var track=road(x,y,type,form,bend)
			var tile=variant
			if track:
				var border=0
				for i in 4:
					var neighbor=Vector2i(x,y)+[Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN,Vector2i.RIGHT][i]
					if not road(neighbor.x,neighbor.y,type,form,bend):border|=1<<i
				tile=4+variant if border==0 else 18+border
			if type=="water" and form=="" and x in range(27,32):
				tile=12 if y in [5,6,7,15,16,17,26,27] else [9,8,8,8,10][x-27]
			if (type=="farm" or (type=="village" and form=="")) and x in range(6,16) and y in range(20,28):
				tile=13 if (x+y)%2==0 else 14
			var relief=Lands.relief(form,Vector2i(x,y),seed_value) if form!="" else -1
			if relief>=0 and (not track or form in ["rift","lava","oasis","pool","marsh"]):
				if form in ["rift","lava"] and track and absi(y-ROAD_Y)<=4:relief=12
				if form=="lava" and relief!=12:
					w.terrain.set_cell(base+Vector2i(x,y),2,Vector2i(posmod(x+y,3),0))
					continue
				tile=relief
			w.terrain.set_cell(base+Vector2i(x,y),0,Vector2i(tile,realm))
	if is_bridge_site(cell):
		set_bridge(w,cell,Saga.data.expedition.get("bridge",false))
	var accents=Lands.accents(form,realm) if form!="" else LAYOUT[type]
	var positions=[Vector2(232,147),Vector2(112,202),Vector2(206,322),Vector2(672,208),Vector2(620,328),Vector2(604,125)]
	for i in positions.size():
		if form!="":
			var tile_pos=Vector2i(positions[i]/16)
			if Lands.relief(form,tile_pos,seed_value) in [8,9,10,16] or road(tile_pos.x,tile_pos.y,type,form,bend):continue
		w.margem(entrance+positions[i],accents[i],"","",true,14 if i<3 else 8)
	var flora=w.REGIONAL_FLORA[realm]
	if type=="woods" and realm==0:flora=["pine","green","pine","hazel","rock"]
	for y in range(46,490,35):
		for x in range(24,750,36):
			var local=Vector2(x+rng.randi_range(-7,7),y+rng.randi_range(-8,8))
			var map_xy=Vector2i(local/16)
			if road(map_xy.x,map_xy.y,type,form,bend) or (type=="water" and map_xy.x in range(25,34)):continue
			if form!="":
				if Lands.relief(form,map_xy,seed_value)>=0:continue
				if Guilds.SERVICES.has(area[2]) and local.distance_to(Guilds.DOOR)<40:continue
				if local.distance_to(Studies.DESK)<45 or local.distance_to(Studies.RESULTS)<86 or local.distance_to(Vector2(641,363))<25:continue
				if cell==Studies.CASES[1].cells[2] and map_xy.y in range(6,11) and map_xy.x in range(29,41):continue
			if positions.any(func(p):return local.distance_to(p)<37) or local.distance_to(Sectors.CROSSROAD)<135:continue
			if rng.randf()<(.78 if type=="woods" else .38):
				var art=flora[rng.randi_range(0,flora.size()-1)]
				w.margem(entrance+local,art,"","",art not in ["flowers","fungus","plant"],7)
	if not area.is_empty():populate(w,cell,realm,area)

static func populate(w,cell:Vector2i,realm:int,area:Array):
	var start=Sectors.origin(cell)
	var type=area[1]
	w.prop(start+POINT,10,"field_board",area[0],true,8)
	if type in ["village","water","farm","camp","road"]:
		w.prop(start+CAMP,9,"field_camp","Catre de viagem",true,7)
	if type in ["village","water","farm"]:
		w.margem(start+LODGE,w.VILLAGES[realm] if realm>=2 else "pousada","field_lodge","Pousada · "+area[0],true,15)
		w.margem(start+MARKET,"venda","field_market","Banca de suprimentos",true,11)
		var villager=Villager.new()
		w.objects.add_child(villager)
		villager.setup(w.game,realm,start,area[0])
		w.sites.append(villager)
	if type in ["cave","ruin"]:
		w.margem(start+LODGE,"mineiro" if type=="cave" else "fortaleza","field_cave","Entrada · "+area[0],true,16)
	if type in ["woods","road","ruin","cave"]:
		var id="trail_"+area[2]
		if id not in Saga.data.kills:w.game.spawn(int(area[4]),realm,start+Vector2(641,363),false,id)
	if is_bridge_site(cell):
		w.prop(start+Vector2(425,263),9,"field_bridge","Passarela em reparo",true,9)
	Guilds.populate(w,start,area)
	Caravan.add_trader(w,cell,realm)
	Studies.populate(w,cell,realm)
	if cell in [Vector2i(2,1),Vector2i(4,1),Vector2i(8,0),Vector2i(10,4),Vector2i(4,6),Vector2i(1,6)]:
		w.prop(start+Vector2(250,275),5,"field_marker","Marco · "+area[0],true,12)

static func build_room(w,c:int,room:String):
	if room=="field_service":
		Guilds.build(w,c,entry(return_cell()))
		return
	var cave=room=="field_cave"
	var vault=room=="field_vault"
	var special=Chambers.index_for(entry(return_cell()))
	if room=="field_chamber" and special>=0:
		Chambers.draw_room(w,c,special)
		return
	for y in 20:
		for x in 32:
			var wall=y<2 or x in [0,31] or (cave and x in [10,21] and y not in [6,7,14,15])
			if cave and c>=2:
				match c:
					2:wall=y<2 or x in [0,31] or (y in [6,12] and x not in [4,5,15,16,24,25,26])
					3:wall=y<2 or x in [0,31] or (x in [8,16,24] and y in range(3,13) and y not in [6,7])
					4:wall=y<2 or x in [0,31] or (x in [9,20] and y in range(4,14)) or (y==9 and x in range(12,17))
					5:wall=y<2 or x in [0,31] or (x in [7,14,22] and y in range(4,16) and y not in [8,9])
			w.terrain.set_cell(Vector2i(x,y),0,Vector2i(16 if wall else 15 if cave or vault else 14,c))
	w.walls(Rect2(0,0,512,320))
	w.prop(LODGE_EXIT,5,"field_exit","Voltar à estrada",false,8)
	if vault:
		w.margem(Vector2(145,123),"oficina","","",true,13)
		w.margem(Vector2(319,107),"forja","","",true,13)
		w.prop(Vector2(367,188),15,"field_torque","Cofre do contramestre",false,9)
	elif cave:
		w.prop(Vector2(417,101),15,"field_relic","Baú de expedição",false,10)
		w.prop(Vector2(213,107),10,"field_script","Marcas na pedra",true,8)
		if special>=0:
			var seam=w.prop(Chambers.PANEL,6,"field_passage","Passagem na parede",false,6)
			seam.visible=Saga.data.expedition.get("passage_"+Chambers.KEYS[special],false)
		if c>=2:
			w.margem(Vector2(91,177),["provisoes","crystals","wisdom","forja"][c-2],"","",false,10)
			w.margem(Vector2(348,243),["poco","rock","fungus","mineiro"][c-2],"","",false,9)
	else:
		w.margem(Vector2(168,111),"provisoes","field_keeper","Anfitriã da pousada",false,9)
		w.prop(Vector2(326,122),9,"field_camp","Catre de viagem",true,8)
		w.prop(Vector2(255,74),10,"field_script","Livro de hóspedes",true,7)

static func return_cell()->Vector2i:
	var spot=Saga.data.expedition.get("return_to",[0,0])
	return Sectors.at(Vector2(float(spot[0]),float(spot[1])))

static func interact(g,site):
	var cell=return_cell() if g.world.interior else Sectors.at(site.position)
	var area=entry(cell)
	var settlement=name_at(cell)
	match site.tag:
		"field_board":
			var region=Sectors.realm_at(cell)
			var directions=[]
			for next in Sectors.neighbors(cell):
				var delta=next-cell
				var heading=["Leste","Sul","Oeste","Norte"][Sectors.DIRECTIONS.find(delta)]
				directions.append(heading+" · "+name_at(next))
			g.ui.dialogue(region,settlement,"\n".join(directions)+Caravan.board(cell,region),[["Ler a história local",func():g.ui.dialogue(region,settlement,area[3],[["Voltar à estrada",g.ui.play]],true)],["Guardar a rota",g.ui.play]])
		"field_passage":
			g.build(true,Sectors.realm_at(cell),Chambers.ARRIVAL,"field_chamber")
			g.ui.play()
			Saga.save()
		"field_chamber_exit":
			g.build(true,Sectors.realm_at(cell),Chambers.PANEL+Vector2.DOWN*15,"field_cave")
			g.ui.play()
			Saga.save()
		"field_witness":
			Chambers.witness(g,Sectors.realm_at(cell),Chambers.index_for(area))
		"field_neighbor","field_keeper","field_script":
			if site.tag=="field_script" and g.world.room_type=="field_cave" and Chambers.index_for(area)>=0:
				Chambers.read_clue(g,Sectors.realm_at(cell),Chambers.index_for(area))
				return
			var text=area[3]
			if site.tag=="field_neighbor":
				var greeting=site.conversation()
				if greeting!="":text=greeting+" "+text
			g.ui.dialogue(Sectors.realm_at(cell),settlement,text,[["Continuar viagem",g.ui.play]],true)
		"field_caravan":
			Caravan.talk(g,Sectors.realm_at(cell))
		"field_study":
			if Caravan.offer_delivery(g,cell):return
			Studies.examine(g,cell,Sectors.realm_at(cell))
		"field_herbs":
			Studies.harvest(g)
		"field_torque":
			if not Saga.data.expedition.get("torque",false):
				Saga.data.expedition.torque=true
				Saga.save()
			g.ui.dialogue(5,"O cofre do contramestre","O torque de cobre guarda a marca das duas equipes. Ele concede quatro pontos de ataque quando equipado na mochila.",[["Guardar o torque",g.ui.play]],true)
		"field_bench":
			Guilds.work(g,Sectors.realm_at(cell),area)
		"field_lodge","field_cave","field_vault","field_service":
			Saga.data.expedition.return_to=[site.position.x,site.position.y+20]
			g.build(true,Saga.region_at(site.position),Vector2(255,257),site.tag)
			g.ui.play()
			Saga.save()
		"field_exit":
			var spot=Saga.data.expedition.return_to
			g.build(false,Sectors.realm_at(cell),Vector2(float(spot[0]),float(spot[1])))
			g.ui.play()
			Saga.save()
		"field_camp":
			g.ui.dialogue(Sectors.realm_at(cell),"Uma pausa na estrada","Aqui você pode recuperar o fôlego. Cada catre fica disponível uma vez por dia.",[["Descansar",rest.bind(g,cell)],["Voltar",g.ui.play]])
		"field_market":
			g.ui.dialogue(Sectors.realm_at(cell),"Banca de suprimentos","A banca troca dois minérios por uma poção de aventura. Você tem %d minérios."%int(Saga.data.ore),[["Trocar",trade.bind(g)],["Voltar",g.ui.play]],true)
		"field_marker":
			var key="marker_"+Sectors.key(cell)
			if not Saga.data.expedition.has(key):
				Saga.data.expedition[key]=true
				Saga.save()
			g.ui.open_map()
		"field_bridge":
			bridge(g,cell)
		"field_relic":
			relic(g,cell)

static func trade(g):
	g.ui.play()
	if Saga.data.ore<2:
		g.toast("O comerciante pede dois minérios.")
		return
	Saga.data.ore-=2
	Saga.data.potions+=1
	Saga.save()
	g.toast("Uma poção foi guardada na mochila.")

static func rest(g,cell:Vector2i):
	g.ui.play()
	var day=Weather.day(Saga.data.world_minutes)
	var key="rest_"+Sectors.key(cell)
	if int(Saga.data.expedition.get(key,-1))==day:
		g.toast("Você já descansou aqui hoje.")
		return
	Saga.data.expedition[key]=day
	Saga.data.hp=Saga.max_hp()
	Saga.data.mp=Saga.max_mp()
	Saga.save()
	g.toast("Fôlego recuperado.")

static func relic(g,cell:Vector2i):
	var id=Sectors.key(cell)
	if "deep_"+id not in Saga.data.kills:
		g.toast("O guardião ainda vigia o baú.")
	elif Saga.data.expedition.get("relic_"+id,false):
		g.toast("Você já registrou a relíquia desta câmara.")
	else:
		Saga.data.expedition["relic_"+id]=true
		Saga.data.points+=1
		Saga.data.ore+=3
		Saga.award(45)
		Saga.save()
		g.toast("Relíquia encontrada · 3 minérios e 1 ponto de habilidade.")

static func bridge(g,cell:Vector2i):
	if Saga.data.expedition.get("bridge",false):
		g.toast("A passarela principal está firme.")
		return
	g.ui.panel_page("bridge","Estrada de Lume","Tábuas da passarela")
	g.ui.label(g.ui.view,"Cada tábua mede 25 centímetros de largura. Colocadas lado a lado, as quatro tábuas existentes cobrem um metro. A passarela precisa cobrir três metros. Quantas tábuas desse tamanho devemos assentar ao todo?",108,160,710,92,21)
	var answer=SpinBox.new()
	answer.min_value=4
	answer.max_value=24
	answer.step=1
	answer.value=4
	g.ui.view.add_child(answer)
	g.ui.rect(answer,158,283,105,45)
	answer.get_line_edit().editable=false
	g.ui.button(g.ui.view,"−",108,283,42,45,func():answer.value-=1)
	g.ui.button(g.ui.view,"+",270,283,44,45,func():answer.value+=1)
	g.ui.label(g.ui.view,"Tábuas • largura coberta",109,329,224,33,16)
	var measure=g.ui.label(g.ui.view,"4 × 25 cm = 100 cm",109,365,224,39,18,g.ui.GOLD,true)
	answer.value_changed.connect(func(count):measure.text="%d × 25 cm = %d cm"%[int(count),int(count)*25])
	var feedback=g.ui.label(g.ui.view,"",342,272,499,88,18)
	g.ui.button(g.ui.view,"Aplicar a medida",556,447,282,43,func():
		if int(answer.value)!=12:
			feedback.text="Quatro tábuas cobrem cada metro. Some quatro para cada um dos três metros e tente novamente."
			return
		if Saga.data.expedition.get("bridge",false):return
		Saga.data.expedition.bridge=true
		set_bridge(g.world,cell,true)
		g.world.trail.sync_sector(g.world,cell)
		Saga.award(35)
		Saga.save()
		g.ui.play()
		g.toast("Passarela concluída. A estrada do meio está aberta."),true)
	g.ui.footer()
	g.ui.focus_default()
