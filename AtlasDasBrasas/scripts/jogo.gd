extends Node2D

const World=preload("res://mapas/mundo.gd")
const UI=preload("res://interfaces/interface.gd")
const Hero=preload("res://personagens/aventureiro.gd")
const Enemy=preload("res://personagens/criatura.gd")
const Mentor=preload("res://personagens/mentor.gd")
const Bolt=preload("res://scripts/projetil.gd")
var world
var ui
var hero
var enemies:Array=[]
var music:AudioStreamPlayer
var fx:AudioStreamPlayer
var active=false
var autosave=0.0
var last_region=-1
var gather_clock={}
var recovering=false
var encounter=false
var escort_time=0.0
var escort_tick=0.0
var familiar:Sprite2D

func _ready():
	world=World.new()
	add_child(world)
	world.configure(self)
	ui=UI.new()
	add_child(ui)
	ui.configure(self)
	music=AudioStreamPlayer.new()
	add_child(music)
	music.stream=preload("res://audio/rio.wav")
	music.volume_db=-9
	music.finished.connect(func():music.play())
	if AudioServer.get_driver_name()!="Dummy":music.play()
	fx=AudioStreamPlayer.new()
	add_child(fx)
	Saga.notice.connect(toast)
	ui.title_menu()

func is_locked():return not active or ui.mode!="play" or recovering
func region():return world.region if world.interior else Saga.region_at(hero.position)
func toast(s):ui.toast(s)
func sound(s):
	if AudioServer.get_driver_name()=="Dummy":return
	fx.stream=load("res://audio/"+s+".wav")
	fx.play()

func new_game():
	Saga.reset()
	active=true
	last_region=-1
	gather_clock.clear()
	build(false,0,Vector2(329,269))
	ui.cinematic("Prólogo  /  Vila do Junco","O dia em que o rio subiu","O sino toca antes do amanhecer. Do fundo do rio sobem brasas frias, e a ponte que liga as duas margens pende de uma corda. Você ainda nunca saiu da vila. Iria põe uma régua em sua mão.","Descer até a margem",ui.tutorial,0)
	Saga.save()

func confirm_new():
	ui.cinematic("Arquivo de viagem","Começar outra história?","Uma nova jornada substituirá o progresso salvo. Você também pode voltar ao título e continuar a expedição atual.","Começar nova jornada",new_game)
	ui.button(ui.view,"Voltar ao título",370,449,223,42,ui.title_menu)

func continue_game():
	if not Saga.restore():
		toast("O arquivo de viagem não pôde ser lido.")
		return
	active=true
	last_region=-1
	gather_clock.clear()
	build(Saga.data.inside,Saga.data.interior,Vector2(Saga.data.pos[0],Saga.data.pos[1]),Saga.data.room)
	ui.play()

func build(inside:bool,c:int,pos:Vector2,room:String="hall"):
	recovering=false
	encounter=false
	enemies.clear()
	familiar=null
	escort_time=0
	world.rebuild(inside,c,room)
	hero=Hero.new()
	world.objects.add_child(hero)
	hero.setup(self,pos,Rect2(Vector2.ZERO,Vector2(512,320) if inside else Saga.AREA*Vector2(3,2)))
	Saga.data.room=room
	Saga.data.inside=inside
	Saga.data.interior=c
	Saga.data.pos=[pos.x,pos.y]
	if inside and c==6 and not Saga.data.won:spawn(3,6,Vector2(250,109),true,"dragon")
	elif inside and room=="crypt" and "cripta"+str(c) not in Saga.data.kills:
		spawn(2,c,Vector2(410,201),false,"cripta"+str(c))
	elif not inside:
		for i in 6:
			var base=Saga.origin(i)
			for j in 3:
				var id="roam%d_%d"%[i,j]
				if id not in Saga.data.kills:spawn([0,1,2,1,0,2][i] if j!=1 else (i+1)%3,i,base+[Vector2(423,374),Vector2(684,331),Vector2(65,183)][j],false,id)
			if i in [2,5] and "side"+str(i) not in Saga.data.kills:spawn(2,i,base+World.CACHE+Vector2(20,8),false,"side"+str(i))
	world.refresh()

func spawn(kind,c,pos,boss,id):
	var e=Enemy.new()
	world.objects.add_child(e)
	e.setup(self,kind,c,pos,boss,id)
	enemies.append(e)
	return e

func closest_enemy(pos:Vector2,reach:float):
	var best=null
	for e in enemies:
		if not is_instance_valid(e) or e.dead:continue
		var d=pos.distance_to(e.position)
		if d<reach:
			reach=d
			best=e
	return best

func bolt(pos:Vector2,dir:Vector2,speed:float,damage:int,enemy:bool,kind:String,life:float):
	var b=Bolt.new()
	b.position=pos
	b.dir=dir
	b.speed=speed
	b.damage=damage
	b.enemy=enemy
	b.kind=kind
	b.life=life
	b.game=self
	world.objects.add_child(b)

func effect(pos:Vector2,col:Color,radius:float):
	var ring=Line2D.new()
	ring.position=pos-Vector2(0,5)
	ring.z_index=3
	ring.width=1.5
	ring.default_color=col
	for i in 17:ring.add_point(Vector2.from_angle(i*TAU/16)*radius)
	world.objects.add_child(ring)
	var tween=ring.create_tween()
	ring.scale=Vector2(.4,.4)
	tween.tween_property(ring,"scale",Vector2.ONE,.14)
	tween.parallel().tween_property(ring,"modulate:a",0,.27)
	tween.tween_callback(ring.queue_free)

func summon(pos):
	escort_time=8
	escort_tick=0
	if not is_instance_valid(familiar):
		familiar=Sprite2D.new()
		familiar.texture=preload("res://personagens/s10.png")
		familiar.scale=Vector2(.55,.55)
		familiar.modulate=Color("#9af7e3")
		world.objects.add_child(familiar)
	familiar.position=pos

func enemy_fell(e):
	if e.quest_id=="treino":
		enemies.erase(e)
		e.queue_free()
		if not Saga.data.get("trained",false):
			Saga.data.trained=true
			Saga.award(20)
			Saga.save()
		toast("Treino concluído.")
		return
	if e.quest_id not in Saga.data.kills and not e.boss:Saga.data.kills.append(e.quest_id)
	enemies.erase(e)
	Saga.award(15 if not e.boss else 30)
	if not e.boss:
		Saga.data.ore+=1
		Saga.save()
		var fade=e.create_tween()
		fade.tween_interval(.32)
		fade.tween_property(e,"modulate:a",0,.12)
		fade.tween_callback(e.queue_free)
	elif e.quest_id=="dragon":
		Saga.data.won=true
		Saga.save()
		sound("sino")
		ui.cinematic("Epílogo  /  A sétima margem","O nome do dragão","Sem a máquina para prendê-lo, Aster dobra as asas. As brasas eram escamas: o rio as levava até a aldeia sempre que o dragão tentava respirar. No vale, seis sinos soam em tempos diferentes. Juntos, anunciam água.","Escrever o último registro",ending)
	else:
		var c=Saga.data.chapter
		Saga.finish_chapter()
		encounter=false
		sound("sino")
		e.queue_free()
		world.refresh()
		ui.cinematic("Selo %d de 6  /  %s"%[c+1,Saga.regions[c].reward],Saga.regions[c].title,Saga.regions[c].outro+" "+["Iria lhe entrega um machado e seu fôlego mágico se recupera mais depressa.","Os marcos de viagem agora respondem à voz do arquivo e permitem sair de recantos distantes.","O conselho lhe entrega uma lança; a bênção da cisterna reduz o dano recebido.","A bússola acelera seus passos e a água fria fortalece seus feitiços.","A nascente libera a técnica de cura no estilo mágico.","O arco a nordeste da Forja agora conduz à Caldeira."][c],"Continuar a jornada",ui.play,c)

func ending():
	var trust=0
	for v in Saga.data.choices.values():
		if v=="partilhar":trust+=1
	var line="Os mestres concordam em guardar cópias nas seis escolas." if trust>=3 else "Os mestres pedem que o conselho abra o arquivo uma vez a cada lua."
	ui.cinematic("Atlas das Brasas  /  Fim da campanha","Uma carta de volta para casa",line+" Você assina ao lado das lavadeiras, dos vigias e da carpinteira. De volta ao Junco, uma criança abre o atlas na primeira página e pergunta como se mede uma ponte.","Voltar ao mundo aberto",func():travel(0))

func defeated():
	if recovering:return
	recovering=true
	await get_tree().create_timer(.48).timeout
	ui.cinematic("Vila do Junco","De volta à margem","Iria recolhe sua mochila. Os mapas secaram junto ao fogo, as anotações ficaram legíveis e há uma trilha de volta ao ponto onde você parou.","Recuperar o fôlego",func():
		Saga.data.hp=Saga.max_hp()
		Saga.data.mp=Saga.max_mp()
		travel(0))

func travel(c:int):
	if c not in Saga.data.seen:return
	build(false,c,Saga.origin(c)+World.HOME+Vector2(0,42))
	ui.play()
	Saga.save()

func can_travel():
	if Saga.data.chapter>=2:return true
	return not world.interior and hero.position.distance_to(Saga.origin(region())+World.ARCH)<42

func route_target()->Vector2:
	var c=int(Saga.data.chapter)
	if world.room_type=="crypt":
		var st=int(Saga.data.ruins.get(str(world.region),0))
		return [Vector2(68,116),Vector2(256,79),Vector2(431,126),Vector2(425,240)][st]
	if world.interior:
		if world.region==6:return Vector2(256,109)
		if world.region==c and Saga.data.taught<0 and not Saga.current_lesson().is_empty():return world.mentors[0].position
		return Vector2(256,294)
	if c==6:return Saga.origin(5)+World.ARCH if not Saga.data.won else Saga.origin(0)+World.HOME
	if not Saga.data.briefed or (Saga.data.taught<0 and not Saga.current_lesson().is_empty()):return Saga.origin(c)+World.HOME
	var next=2 if Saga.current_lesson().is_empty() else int(Saga.data.stage)%3
	return Saga.origin(c)+World.POINTS[next]

func return_title():
	if not Saga.save():
		toast("Falha ao gravar a jornada.")
		return
	active=false
	ui.title_menu()

func back_from_settings():
	if active:ui.pause_page()
	else:ui.title_menu()

func _process(dt):
	if is_locked() or not is_instance_valid(hero):return
	var c=region()
	if c!=last_region:
		if c<6 and c not in Saga.data.seen:Saga.data.seen.append(c)
		if last_region!=-1:toast("Caldeira de Aster" if c==6 else Saga.regions[c].place)
		last_region=c
		Saga.save()
	autosave+=dt
	if autosave>10:
		autosave=0
		Saga.save()
	if escort_time>0 and is_instance_valid(familiar):
		escort_time-=dt
		escort_tick-=dt
		familiar.position=familiar.position.lerp(hero.position+Vector2(-15,-14),clampf(dt*6,0,1))
		var foe=closest_enemy(familiar.position,142)
		if escort_tick<=0 and foe:
			bolt(familiar.position,familiar.position.direction_to(foe.position),146,Saga.power(),false,"lume",1.2)
			escort_tick=1.2
		if escort_time<=0:familiar.queue_free()

func _input(ev):
	if not is_instance_valid(ui):return
	if ui.capture_key(ev):
		get_viewport().set_input_as_handled()
		return
	if not ev is InputEventKey or not ev.pressed or ev.echo:return
	if ev.keycode==KEY_ESCAPE:
		match ui.mode:
			"menu":return
			"scene":
				if not active:ui.title_menu()
			"settings":back_from_settings()
			"play":ui.pause_page()
			_: 
				if active:ui.play()
		get_viewport().set_input_as_handled()
		return
	if not active:return
	if is_locked():
		if ui.mode=="dialog" and is_instance_valid(ui.typed) and ui.typed.visible_ratio<1 and ev.keycode in [KEY_SPACE,KEY_ENTER]:
			ui.reveal_text()
			get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("use"):interact()
	elif ev.is_action_pressed("bag"):ui.bag()
	elif ev.is_action_pressed("map"):
		ui.map_selection=mini(region(),5)
		ui.map_page()
	elif ev.is_action_pressed("journal"):ui.journal()
	else:return
	get_viewport().set_input_as_handled()

func interact():
	var n=world.nearest(hero.position)
	if n==null:
		toast("Aproxime-se de uma pessoa, porta ou marco.")
		return
	hero.act("interact",.25)
	var c=region()
	if n is Mentor:
		if n.resident:resident_talk(c)
		else:mentor(c)
		return
	match n.tag:
		"door":
			build(true,c,Vector2(256,238))
			ui.play()
			Saga.save()
		"exit":
			var dest=5 if c==6 else c
			var spot=World.CRYPT if world.room_type=="crypt" else World.ARCH if c==6 else World.HOME
			build(false,dest,Saga.origin(dest)+spot+Vector2(0,22))
			ui.play()
			Saga.save()
		"arena":
			ui.dialogue(0,"Escola de combate","Pratique contra um sentinela de madeira. Observe o círculo que anuncia o disparo, bloqueie olhando para ele ou esquive para o lado. Derrube o boneco com a arma de sua escolha.",[["Treinar na arena",func():start_training()],["Voltar",ui.play]])
		"crypt":
			build(true,c,Vector2(255,261),"crypt")
			ui.cinematic("Ruínas do rio antigo", "O templo sob a estrada","Na rocha, três salas repetem as curvas do antigo rio. Há uma inscrição perto da entrada e um relicário na câmara leste.","Examinar o templo",ui.play,c)
			Saga.save()
		"inscription":
			ui.dialogue(c,"Inscrição das três águas","O mestre traduziu as marcas: «Onde nasce, a fonte. Onde corre, o curso. Onde encontra o mar, a foz.» Toque os pedestais nessa ordem para abrir o relicário.",[["Guardar a pista",ui.play]])
		"rune0","rune1","rune2":
			var progress=int(Saga.data.ruins.get(str(c),0))
			if progress==3:toast("As três runas já cantam juntas.")
			elif n.tag=="rune"+str(progress):
				Saga.data.ruins[str(c)]=progress+1
				effect(n.position,Color("#acd3cb"),20)
				sound("runa")
				toast("Runa acesa · %d de 3"%(progress+1))
			else:
				Saga.data.ruins[str(c)]=0
				toast("O fluxo se desfez. Releia a inscrição e recomece pela fonte.")
			Saga.save()
		"relic":
			if str(c) in Saga.data.relics:toast("A relíquia já consta no diário.")
			elif int(Saga.data.ruins.get(str(c),0))<3:toast("Três runas prendem a tampa.")
			elif "cripta"+str(c) not in Saga.data.kills:toast("O guardião da câmara ainda está de pé.")
			else:
				Saga.data.relics.append(str(c))
				Saga.data.points+=1
				Saga.data.ore+=2
				Saga.award(40)
				Saga.save()
				ui.dialogue(c,"Relíquia do rio",["Uma régua na qual cada aldeia gravou sua medida. Iria reconhece a marca da avó.","Uma matriz de impressão. O verso original podia ter circulado antes do decreto real.","Um sinete coletivo. A cisterna já pertenceu a várias famílias.","Uma carta estelar que situa a aldeia ausente no mapa do céu.","Sementes seladas no barro. O arquivo do viveiro guarda o nome da mata antiga.","Uma mola de retorno. O projeto original previa uma forma de desligar a máquina."][c],[["Registrar no diário",ui.play]])
		"desk":ui.book_ch=c; ui.codex()
		"cache":cache(c)
		"herb","ore":
			var key=str(c)+n.tag
			var now=Time.get_ticks_msec()
			if now<int(gather_clock.get(key,0)):
				toast("Este local precisa de um tempo para se recompor.")
			else:
				gather_clock[key]=now+30000
				if n.tag=="herb":Saga.data.herbs+=2
				else:Saga.data.ore+=2
				toast("Duas ervas colhidas." if n.tag=="herb" else "Dois minérios recolhidos.")
				sound("runa")
				Saga.save()
		"arch":
			if c==5 and Saga.data.chapter==6:
				build(true,6,Vector2(256,245))
				ui.cinematic("Caldeira de Aster","Os três pulsos","Âmbar. Azul fraco. Azul forte. Quando o último círculo se desfaz, o peito do dragão fica descoberto. Espere a abertura, dispare e desvie das brasas enquanto a proteção retorna.","Enfrentar Aster",ui.play,5)
				Saga.save()
			else:
				ui.map_selection=c
				ui.map_page()
		"altar":
			if Saga.data.won:ending()
			else:toast("A pedra vibra no mesmo ritmo do escudo.")
		_:station(c,n.tag)

func start_training():
	for e in enemies:
		if e.quest_id=="treino" and not e.dead:
			ui.play()
			toast("O boneco já está na arena.")
			return
	var dummy=spawn(2,0,Vector2(211,320),false,"treino")
	dummy.hp_max=30
	dummy.hp=30
	ui.play()

func resident_talk(c):
	var r=Saga.regions[c]
	var state=int(Saga.data.side.get(str(c),0))
	var msg=r.comment_after if state==2 else r.comment
	var options=[["Até breve",ui.play]]
	if state==0:
		options.push_front(["Ajudar",func():
			Saga.data.side[str(c)]=1
			Saga.save()
			ui.play()
			toast(r.side_hint)])
	ui.dialogue(c,r.resident_role,msg,options,true)

func mentor(c:int):
	var r=Saga.regions[c]
	if Saga.data.chapter==c and not Saga.data.briefed:
		ui.dialogue(c,r.role,r.intro+" "+r.voice,[["Abrir o arquivo ao povo",func():pledge(c,true)],["Confiar no conselho",func():pledge(c,false)]])
		return
	var opts=[]
	var text=r.voice
	if Saga.data.chapter==c and not Saga.current_lesson().is_empty():
		opts.append(["Estudar a tarefa",func():teach(c)])
		text="A estrada pede uma decisão. Vamos trabalhar em «"+Saga.current_lesson().title+"»."
	elif Saga.data.chapter>c:
		text=r.outro+" "+("Guardei uma cópia para cada casa." if Saga.data.choices.get(str(c))=="partilhar" else "O conselho quer ouvir você de novo.")
	elif Saga.data.chapter<c:text="A estrada está aberta, viajante. "+r.voice
	if int(Saga.data.side.get(str(c),0))<2:opts.append(["Pedido local",func():side(c)])
	opts.append(["Despedir-se",ui.play])
	ui.dialogue(c,r.role,text,opts)

func pledge(c,share):
	Saga.data.choices[str(c)]="partilhar" if share else "conselho"
	Saga.data.bonds[str(c)]=("Amizade · arquivo aberto" if share else "Rivalidade respeitosa · arquivo do conselho")
	Saga.data.briefed=true
	Saga.save()
	ui.dialogue(c,"Um acordo entre margens","Então haverá uma cópia para cada aldeia. Vou ensinar você a registrar o que descobrir." if share else "Discordo de deixar o livro com tão poucas pessoas. Ainda assim, vou ensinar você. Prometa que voltará para ouvir a aldeia.",[["Ouvir o ensinamento",func():teach(c)]])

func teach(c):
	var l=Saga.current_lesson()
	ui.dialogue(c,l.title,l.teach,[["Anotar e explorar",func():
		Saga.data.taught=Saga.data.stage
		Saga.save()
		ui.play()
		toast(Saga.objective())]])

func station(c,tag):
	if c!=Saga.data.chapter or not Saga.data.briefed:
		toast("Selo restaurado · "+Saga.regions[c].reward if c<Saga.data.chapter else "Procure o mestre desta margem.")
		return
	var l=Saga.current_lesson()
	if l.is_empty():
		if tag!="site2":toast(Saga.objective());return
		if encounter:toast("Derrote o guardião para fixar o selo.");return
		encounter=true
		var pos=Saga.origin(c)+World.POINTS[2]+Vector2(34,3)
		spawn([0,1,2,1,2,2][c],c,pos,true,"guardiao"+str(c))
		toast("Proteja o selo · observe o aviso antes de esquivar.")
		return
	if Saga.data.taught!=Saga.data.stage or tag!="site"+str(int(Saga.data.stage)%3):
		toast(Saga.objective())
		return
	ui.challenge(l)

func side(c):
	var r=Saga.regions[c]
	var s=int(Saga.data.side.get(str(c),0))
	if s==0:
		ui.dialogue(c,r.side,r.side_hint,[["Aceitar pedido",func():Saga.data.side[str(c)]=1;Saga.save();ui.play();toast(r.side_hint)],["Mais tarde",ui.play]])
	elif (c==4 and Saga.data.get("brew_after_request",false) and Saga.data.potions>0) or (c!=4 and str(c) in Saga.data.chests):
		if c==4:Saga.data.potions-=1
		Saga.data.side[str(c)]=2
		Saga.data.charm=r.side_item
		Saga.award(50)
		Saga.save()
		ui.dialogue(c,"Pedido atendido","A notícia chegou antes de você. Quero lhe dar este presente: "+r.side_item+". Você pode equipá-lo na mochila.",[["Guardar o presente",ui.play]])
	else:ui.dialogue(c,r.side,r.side_hint,[["Vou procurar",ui.play]])

func cache(c):
	if c in [2,5] and "side"+str(c) not in Saga.data.kills:
		toast("O sentinela ainda guarda o abrigo.")
		return
	if str(c) in Saga.data.chests:toast("Você já investigou este recanto.");return
	Saga.data.chests.append(str(c))
	Saga.data.herbs+=2
	Saga.data.ore+=1
	Saga.award(25)
	Saga.save()
	world.refresh()
	sound("sino")
	toast(["Ferramentas da barqueira recuperadas.","Cópia antiga encontrada sob o forro.","A vigia deixa o abrigo e entrega seu depoimento.","Mala do correio recuperada.","Você encontrou sementes e ervas silvestres.","A vigia do turno alcança a estrada."][c])



func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST and active and not recovering:
		Saga.save()
