extends Node

var g
var checks=0
var failures=[]
func check(value,what):
	checks+=1
	if not value:
		failures.append(what)
		push_error(what)

func click(prefix:String):
	for b in g.ui.view.get_children():
		if b is Button and b.text.begins_with(prefix) and not b.disabled:
			b.pressed.emit()
			return
	check(false,"Botão ausente em %s: %s"%[g.ui.mode,prefix])

func walk_to(pos):
	g.hero.position=pos
	Saga.data.pos=[pos.x,pos.y]

func talk(c):
	var n=g.world.mentors[c] if not g.world.interior else g.world.mentors[0]
	walk_to(n.position+Vector2(0,4))
	g.interact()

func _ready():
	if Saga.exists():
		print("Use XDG_DATA_HOME temporário para preservar o arquivo existente.")
		get_tree().quit(2)
		return
	g=preload("res://cenas/Atlas.tscn").instantiate()
	add_child(g)
	call_deferred("run")

func check_crypt():
	walk_to(g.world.CRYPT+Vector2(0,4))
	g.interact()
	click("Examinar o templo")
	check(g.world.room_type=="crypt" and g.world.interior,"Entrada no templo")
	walk_to(Vector2(257,83))
	g.interact()
	check(int(Saga.data.ruins.get("0",0))==0,"Erro rúnico permite recomeçar")
	for spot in [Vector2(68,119),Vector2(258,81),Vector2(431,130)]:
		walk_to(spot)
		g.interact()
	check(int(Saga.data.ruins.get("0",0))==3,"Ordem das três runas")
	var sentinel=g.enemies.front()
	walk_to(sentinel.position+Vector2(-12,0))
	var previous=int(sentinel.hp)
	g.hero.guard=true
	g.hero.facing=Vector2.RIGHT
	var hp=float(Saga.data.hp)
	g.hero.hurt(12,sentinel.position)
	check(hp-Saga.data.hp==3,"Bloqueio direcional")
	g.hero.guard=false
	g.hero.invincible=0
	g.hero.charge=1.1
	g.hero.shoot_arrow()
	for i in 7:await get_tree().physics_frame
	check(sentinel.hp<previous or sentinel.dead,"Colisão da flecha carregada")
	if not sentinel.dead:
		Saga.data.style=2
		g.hero.cooldown=0
		g.hero.attack()
		for i in 12:await get_tree().physics_frame
		check(sentinel.dead or sentinel.hp<previous,"Projétil mágico")
	Saga.data.style=0
	if not sentinel.dead:sentinel.hit(200)
	walk_to(Vector2(425,244))
	g.interact()
	click("Registrar no diário")
	check("0" in Saga.data.relics,"Relicário aberto")
	walk_to(Vector2(256,292))
	g.interact()
	check(not g.world.interior and g.hero.position.distance_to(g.world.CRYPT)<27,"Retorno pela saída do templo")

func check_guidance():
	var trail=g.world.trail
	trail.follow(Vector2(440,264),Vector2(596,264))
	check(trail.available,"Rota até a margem oposta")
	var crossing=false
	var clear_route=true
	for cell in trail.steps:
		var tile=g.world.terrain.get_cell_atlas_coords(cell)
		if tile.x in [11,12] and cell.y in [8,9,23,24]:crossing=true
		if tile.x in [8,9,10,16]:clear_route=false
	check(crossing and clear_route,"Trilha usa uma ponte transitável")
	var controls=preload("res://interfaces/toque.gd").new()
	controls.game=g
	g.ui.hud.add_child(controls)
	var finger=InputEventScreenTouch.new()
	finger.index=0
	finger.position=controls.STICK+Vector2(41,0)
	finger.pressed=true
	controls._input(finger)
	var attack=InputEventScreenTouch.new()
	attack.index=1
	attack.pressed=true
	attack.position=Vector2(797,480)
	controls._input(attack)
	check(Input.is_action_pressed("right") and Input.is_action_pressed("attack"),"Movimento e ataque com dois dedos")
	attack.pressed=false
	controls._input(attack)
	check(Input.is_action_pressed("right") and not Input.is_action_pressed("attack"),"Soltar ataque conserva o direcional")
	controls.hide()
	check(not Input.is_action_pressed("right"),"Painel oculto solta direcional")
	controls.queue_free()

func check_care_rounds():
	g.ui.journal()
	click("Caderno de rondas")
	check(g.ui.mode=="care_index","Caderno acessível pelo diário")
	for c in Saga.rounds.size():
		var entry=Saga.rounds[c]
		g.ui.care_brief(c)
		click("Marcar rota")
		var target=Saga.origin(c)+g.world.CARE_POINTS[c]
		check(g.route_target()==target,"Orientação até "+entry.place)
		g.world.trail.follow(g.hero.position,target)
		check(g.world.trail.available,"Rota acessível a "+entry.place)
		walk_to(target+Vector2(0,7))
		g.interact()
		click("Examinar o posto")
		check(g.ui.mode=="care_field","Inspeção de "+entry.place)
		if c==5:
			click("Acionar a equipe")
		else:
			click(entry.points[(int(entry.key)+1)%3][0])
			check(not int(entry.key) in g.ui.care_observed,"Exploração livre antes da pista")
			click(entry.points[int(entry.key)][0])
			click("Escolher um cuidado")
		var xp=Saga.data.xp
		click(entry.actions[(int(entry.answer)+1)%3])
		check(g.ui.mode=="care_decision" and Saga.data.xp==xp,"Feedback e nova tentativa")
		click(entry.actions[int(entry.answer)])
		check(g.ui.mode=="care_record" and Saga.data.xp==xp+25 and int(Saga.data.care_route)==-1,"Registro e recompensa de "+entry.place)
		click("Retomar a viagem")
		g.interact()
		click("Refazer a ronda")
		click(entry.points[int(entry.key)][0])
		click("Acionar a equipe" if c==5 else "Escolher um cuidado")
		click(entry.actions[int(entry.answer)])
		check(Saga.data.xp==xp+25,"Revisão sem duplicar a recompensa")
		click("Retomar a viagem")
	check(Saga.restore() and Saga.data.care_records.size()==6,"Seis registros persistentes")
	g.build(true,0,Vector2(365,209))
	g.interact()
	check(g.ui.mode=="care_index","Conversa com Lia na oficina de Junco")

func check_weather():
	var weather=preload("res://scripts/tempo.gd")
	var match_days=true
	for d in 12:
		match_days=match_days and weather.daily_rain(0,d)!=weather.daily_rain(1,d)
	check(match_days,"Viveiros têm acumulados comparáveis e distintos")
	check(weather.period(1439)==3 and weather.period(1440)==0 and weather.day(1440)==1,"Virada do dia")
	g.build(true,0,Vector2(255,190))
	g.ui.journal()
	click("Boletim das margens")
	var before=float(Saga.data.world_minutes)
	g._process(2.0)
	check(Saga.data.world_minutes==before,"Leitura do boletim pausa o relógio")
	click("Aguardar o amanhecer")
	check(Saga.data.world_minutes>before and weather.clock_text(Saga.data.world_minutes)=="06:00","Pouso no interior avança até o amanhecer")
	g.build(false,0,g.world.WEATHER_BOARD+Vector2.DOWN*8)
	g.ui.play()
	before=Saga.data.world_minutes
	g._process(1.0)
	check(is_equal_approx(Saga.data.world_minutes-before,3.0),"Relógio avança durante exploração")
	g.interact()
	click("Ler o pedido")
	click("Assumir a entrega")
	check(Saga.data.rain_route and g.route_target()==g.world.GAUGES[0],"Missão inicia no quadro e aponta para o viveiro")
	var day_of_record=int(Saga.data.rain_day)
	for c in [1,0]:
		if c==0:
			Saga.data.world_minutes+=1440
			g.return_title()
			g.continue_game()
			check(int(Saga.data.rain_day)==day_of_record and Saga.data.rain_readings.has("1"),"Salvamento preserva período e leitura parcial")
		var pos=Saga.origin(c)+g.world.GAUGES[c]
		g.world.trail.follow(g.hero.position,pos)
		check(g.world.trail.available,"Trilha até o pluviômetro")
		walk_to(pos+Vector2.DOWN*8)
		g.interact()
		check(g.ui.mode=="gauge","Leitura presencial do instrumento")
		click("Anotar a leitura")
		check(int(Saga.data.rain_readings[str(c)])==weather.daily_rain(c,day_of_record),"Registro do período fixado")
	check(g.route_target()==g.world.WATER_CART,"As leituras apontam para a carroça")
	walk_to(g.world.WATER_CART+Vector2.DOWN*9)
	g.interact()
	var dry=0 if int(Saga.data.rain_readings["0"])<int(Saga.data.rain_readings["1"]) else 1
	var xp=Saga.data.xp
	click("Enviar a "+g.ui.LOG_NAMES[1-dry])
	check(int(Saga.data.rain_recipient)==-1 and Saga.data.xp==xp,"Erro explica a comparação e permite corrigir")
	click("Enviar a "+g.ui.LOG_NAMES[dry])
	check(int(Saga.data.rain_recipient)==dry and Saga.data.xp==xp+60 and not Saga.data.rain_route,"Carroça abastece o viveiro escolhido")
	var grown=0
	for plant in g.world.nursery_plants:
		if plant.visible and Saga.region_at(plant.position)==dry:grown+=1
	check(grown==3,"O resultado da rega aparece no cenário")
	g.ui.deliver_water(dry)
	check(Saga.data.xp==xp+60,"Reabrir o relatório não duplica a entrega")
	check(Saga.restore() and int(Saga.data.rain_recipient)==dry,"Relatório final e entrega persistem")
	g.ui.play()
	g.ui.open_map()
	click("Previsão da região")
	check(g.ui.mode=="weather","Previsão acessível pelo mapa")

func run():
	await get_tree().process_frame
	check(g.ui.mode=="menu","Menu inicial")
	click("Iniciar jornada")
	click("Descer até a margem")
	click("Voltar à aventura")
	check(g.enemies.size()==20,"População regional")
	check_guidance()
	var start=g.hero.position
	Input.action_press("right")
	for i in 12:await get_tree().physics_frame
	Input.action_release("right")
	check(g.hero.position.x>start.x+8,"Movimento com entrada física")
	walk_to(g.world.HOME+Vector2(0,10))
	g.interact()
	check(g.world.interior and g.region()==0,"Entrada na oficina")
	walk_to(Vector2(255,290))
	g.interact()
	check(not g.world.interior,"Saída da oficina")
	await check_crypt()
	var menu_label=g.ui.label(g.ui.hud,"Texto curto",10,10,200,24,14)
	check(menu_label.size.y<=25,"Altura do texto após quebra automática")
	menu_label.queue_free()
	var bridge=Vector2i(g.world.channel_x(0,16)+1,16)
	check(g.world.terrain.get_cell_atlas_coords(bridge).x==8,"Travessia principal fechada no início")
	check(not g.can_travel(),"Restrições de deslocamento antes da aliança")
	walk_to(g.world.ARCH+Vector2(0,5))
	check(g.can_travel(),"Viagem liberada no marco")
	var citizen=g.world.residents[0]
	walk_to(citizen.position+Vector2(0,4))
	g.interact()
	check(g.ui.mode=="dialog","Conversa com morador")
	click("Até breve")
	for c in 6:
		talk(c)
		click("Abrir o arquivo" if c%2==0 else "Confiar no conselho")
		click("Ouvir o ensinamento")
		click("Anotar e explorar")
		check(Saga.data.taught==0,"Briefing do capítulo %d"%c)
		for stage in Saga.chapter_lessons(c).size():
			var l=Saga.current_lesson()
			if stage>0:
				talk(c)
				click("Estudar a tarefa")
				click("Anotar e explorar")
			walk_to(Saga.origin(c)+g.world.POINTS[stage%3]+Vector2(0,6))
			g.interact()
			check(g.ui.mode=="challenge","Atividade aberta: "+l.title)
			var count=Saga.data.learned.size()
			match l.type:
				"dial":
					g.ui.evaluate(int(l.answer)+1)
					check(g.ui.response.text!="" and count==Saga.data.learned.size(),"Feedback numérico")
					g.ui.adjust(int(l.answer))
					click("Aplicar medida")
				"grid":
					click("A1")
					check(g.ui.response.text!="","Feedback cartográfico")
					click(l.answer)
				"pick":
					click(l.opts[(int(l.answer)+1)%3])
					check(g.ui.response.text!="","Feedback contextual")
					click(l.opts[int(l.answer)])
				"order":
					for j in [2,1,0]:click(l.opts[j])
					check(g.ui.response.text!="" and g.ui.steps.is_empty(),"Reinício da sequência")
					for j in l.answer:click(l.opts[int(j)])
				"write":
					g.ui.writing.text="Guardem o mapa na biblioteca porque o rio voltou a subir."
					click("Revisar meu aviso")
					for node in g.ui.view.get_children():
						if node is CheckBox:node.button_pressed=true
					click("Afixar aviso")
			check(Saga.data.learned.size()==count+1,"Registro da atividade "+l.title)
			click("Voltar à aventura")
		talk(c)
		click("Pedido local")
		click("Aceitar pedido")
		if c in [2,5]:
			for e in g.enemies.duplicate():
				if e.quest_id=="side"+str(c):e.hit(500)
		if c==4:
			g.ui.bag()
			click("Preparar poção")
			click("Voltar à aventura")
		else:
			walk_to(Saga.origin(c)+g.world.CACHE)
			g.interact()
		talk(c)
		click("Pedido local")
		click("Guardar o presente")
		check(int(Saga.data.side.get(str(c),0))==2,"Missão secundária "+str(c))
		walk_to(Saga.origin(c)+g.world.POINTS[2]+Vector2(0,5))
		g.interact()
		var guardian=null
		for e in g.enemies:
			if e.boss:guardian=e
		check(guardian!=null,"Guardião do capítulo")
		if guardian:
			walk_to(guardian.position-Vector2(10,0))
			g.hero.facing=Vector2.RIGHT
			for i in 20:
				if not is_instance_valid(guardian) or guardian.dead:break
				g.hero.attack()
			check(Saga.data.chapter==c+1,"Recompensa após o combate")
			click("Continuar a jornada")
			if c==0:check(g.world.terrain.get_cell_atlas_coords(bridge).x==12,"Travessia reconstruída")
			if c==1:check(g.can_travel(),"Aliança libera viagem fora do marco")
		await get_tree().process_frame
	check(Saga.data.learned.size()==29,"29 atividades concluídas")
	g.ui.book_ch=0
	g.ui.codex()
	click("Tábuas por vão")
	click("Voltar à prática")
	g.ui.adjust(7)
	click("Aplicar medida")
	check(int(Saga.data.review.get("Tábuas por vão",0))==1 and Saga.data.learned.size()==29,"Revisão sem duplicar progresso")
	click("Voltar à enciclopédia")
	click("Voltar à aventura")
	g.ui.skills()
	click("Passo leve")
	check(Saga.has_skill(0),"Treino de habilidade")
	click("Voltar à aventura")
	walk_to(Saga.origin(5)+g.world.ARCH+Vector2(0,7))
	g.interact()
	click("Enfrentar Aster")
	check(g.region()==6 and g.enemies.size()==1,"Entrada na caldeira")
	var boss=g.enemies.front()
	var health=boss.hp
	boss.hit(200)
	check(boss.hp==health,"Escudo fechado bloqueia dano")
	Saga.data.style=2
	Saga.data.mp=Saga.max_mp()
	Input.action_press("attack")
	for i in 900:
		await get_tree().physics_frame
		if Saga.data.won:break
	Input.action_release("attack")
	check(Saga.data.won,"Abertura do escudo e vitória")
	click("Escrever o último registro")
	click("Voltar ao mundo aberto")
	g.return_title()
	# Simulate an interrupted primary file and exercise the previous atomic copy.
	var damaged=FileAccess.open(Saga.SAVE,FileAccess.WRITE)
	damaged.store_string("{}")
	damaged.close()
	g.continue_game()
	check(Saga.data.won and Saga.data.chapter==6 and Saga.data.learned.size()==29 and Saga.has_skill(0),"Carregar campanha concluída")
	check(Saga.data.letter!="","Texto autoral persistido")
	check_care_rounds()
	check_weather()
	print("ATLAS: %d verificações; %d falhas."%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

