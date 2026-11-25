extends "res://interfaces/rondas.gd"

const STANCE_ICONS=[preload("res://interfaces/icones/lamina.png"),preload("res://interfaces/icones/arco.png"),preload("res://interfaces/icones/magia.png")]
const Map=preload("res://interfaces/cartografia.gd")
const Mentor=preload("res://personagens/mentor.gd")
var xpbar:ColorRect
var level_label:Label
var prompt_panel:Panel
var stance:TextureRect
var hpbar:ColorRect
var mpbar:ColorRect
var hplabel:Label
var mplabel:Label
var objective_label:Label
var prompt:Label
var region_label:Label
var style_label:Label
var hud_timer=0.0
var map_selection=0
var map_text:Label
var travel_btn:Button
var book_page=0
var book_ch=0
var bearing:Label
var touch_controls
var boss_card:Panel
var boss_portrait:TextureRect
var boss_health:ColorRect
var boss_label:Label

func update_hud():
	clear(hud)
	box(hud,15,13,224,77,Color("#131e2bed"),LINE)
	tex(hud,"res://personagens/s0.png",24,24,38,50)
	level_label=label(hud,"",71,16,68,22,14,GOLD)
	stance=glyph(hud,"lamina",133,17,17)
	style_label=label(hud,"",153,15,78,22,14,PALE)
	glyph(hud,"vida",70,41,13)
	glyph(hud,"mana",70,59,13)
	line(hud,88,45,91,6,Color("#41434b"))
	line(hud,88,63,91,6,Color("#314650"))
	hpbar=line(hud,88,45,91,6,Color("#dc8975"))
	mpbar=line(hud,88,63,91,6,Color("#81cabb"))
	hplabel=label(hud,"",181,36,51,21,12,PALE,false,HORIZONTAL_ALIGNMENT_RIGHT)
	mplabel=label(hud,"",181,54,51,21,12,PALE,false,HORIZONTAL_ALIGNMENT_RIGHT)
	xpbar=line(hud,22,84,1,2,GOLD)
	box(hud,649,13,296,97,Color("#141e2bee"),LINE)
	glyph(hud,"rumo",660,23,23)
	region_label=label(hud,"",690,21,246,24,15,GOLD,true)
	line(hud,663,51,268,1,LINE)
	objective_label=label(hud,"",663,55,267,51,15,PALE)
	var touch=DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if not touch:
		var actions=[["Diário","diario",journal],["Mapa","mapa",open_map],["Mochila","mochila",bag],["Pausa","pausa",pause_page]]
		for i in actions.size():
			var entry=actions[i]
			var b=button(hud,entry[0],15+i*101,486,94,38,entry[2])
			button_icon(b,entry[1])
			b.add_theme_font_size_override("font_size",14)
			b.focus_mode=Control.FOCUS_NONE
	prompt_panel=box(hud,300,424,360,39,Color("#121c2beb"),LINE)
	prompt=label(hud,"",304,426,352,34,17,PALE,true,HORIZONTAL_ALIGNMENT_CENTER)
	boss_card=box(hud,261,100 if touch else 14,351,54,Color("#181c29ed"),LINE)
	boss_portrait=tex(boss_card,"res://personagens/bestiario/g0.png",4,4,54,45)
	boss_label=label(boss_card,"",68,4,276,38,15,GOLD,true)
	line(boss_card,68,44,270,4,Color("#45303b"))
	boss_health=line(boss_card,68,44,270,4,Color("#df886c"))
	boss_card.hide()
	var bx=336 if touch else 611
	box(hud,bx,486,287 if touch else 334,38,Color("#14202ce8"),LINE)
	glyph(hud,"rumo",bx+10,494,22)
	bearing=label(hud,"",bx+40,489,239 if touch else 282,32,15,GOLD)
	if touch:
		touch_controls=preload("res://interfaces/toque.gd").new()
		touch_controls.game=game
		hud.add_child(touch_controls)
	hud_tick()

func _process(dt):
	super(dt)
	hud_timer-=dt
	if mode=="play" and hud_timer<0:
		hud_timer=.12
		hud_tick()

func hud_tick():
	if not is_instance_valid(hpbar) or not is_instance_valid(game.hero):return
	hpbar.size.x=91*Saga.data.hp/Saga.max_hp()
	mpbar.size.x=91*Saga.data.mp/Saga.max_mp()
	hplabel.text="%d/%d"%[ceili(Saga.data.hp),int(Saga.max_hp())]
	mplabel.text="%d/%d"%[int(Saga.data.mp),int(Saga.max_mp())]
	style_label.text=["Lâmina","Arco","Magia"][Saga.data.style]
	var c=game.region()
	region_label.text=("Caldeira de Aster" if c==6 else Saga.regions[c].place).to_upper()
	objective_label.text="Siga a inscrição e abra o relicário." if game.world.room_type=="crypt" else Saga.objective()
	if int(Saga.data.care_route)>=0:
		objective_label.text="Saia para a estrada." if game.world.interior else "Ronda · "+Saga.rounds[int(Saga.data.care_route)].place
	level_label.text="Nível %d"%Saga.level()
	xpbar.size.x=(int(Saga.data.xp)%100)*2.1
	stance.texture=STANCE_ICONS[int(Saga.data.style)]
	var destination=game.route_target()
	var trail=game.world.trail
	trail.follow(game.hero.position,destination)
	var delta=trail.next_point-game.hero.position
	var directions=["Leste","Sudeste","Sul","Sudoeste","Oeste","Noroeste","Norte","Nordeste"]
	if Saga.data.won and not game.world.interior and int(Saga.data.care_route)<0:
		bearing.text="Exploração livre"
		trail.visible=false
	elif game.hero.position.distance_to(destination)<32:bearing.text="Você chegou ao objetivo"
	elif trail.available:bearing.text="%s   ·   %d passos pela trilha"%[directions[posmod(roundi(delta.angle()/(PI/4)),8)],ceili(trail.remaining/8)]
	else:bearing.text="Consulte o mapa do reino"
	if game.world.room_type=="crypt":region_label.text="TEMPLO DO RIO ANTIGO"
	var n=game.world.nearest(game.hero.position)
	prompt.text=""
	prompt_panel.visible=n!=null
	if n:
		var s=(Saga.regions[n.c].resident if n.resident else Saga.regions[n.c].name) if n is Mentor else n.label
		prompt.text=("Interagir · "+s) if is_instance_valid(touch_controls) else "[%s]  %s"%[Saga.keyname("use"),s]
	var nearest_boss=null
	var max_distance=240.0
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead or not e.boss:continue
		var distance=game.hero.position.distance_to(e.position)
		if distance<max_distance:
			nearest_boss=e
			max_distance=distance
	boss_card.visible=nearest_boss!=null
	if nearest_boss!=null:
		var caption=nearest_boss.bestiary_name()
		if nearest_boss.kind==3:caption+=" · Escudo pulsante" if nearest_boss.shielded() else " · Escudo aberto"
		boss_label.text="%s   %d/%d"%[caption,nearest_boss.hp,nearest_boss.hp_max]
		boss_portrait.texture=nearest_boss.portrait()
		boss_health.size.x=270.0*nearest_boss.hp/nearest_boss.hp_max

func footer():
	button(view,"Voltar à aventura",108,449,191,38,play,true)

func pause_page():
	panel_page("pause","Jornada em curso","Acampamento")
	label(view,Saga.objective(),108,149,744,55,19)
	button(view,"Retomar",108,229,352,48,play,true)
	button(view,"Salvar jornada",482,229,367,48,func():toast("Jornada salva." if Saga.save() else "Não foi possível salvar."))
	button(view,"Configurações",108,293,352,48,settings_page)
	button(view,"Como jogar",482,293,367,48,tutorial)
	button(view,"Enciclopédia",108,357,352,48,codex)
	button(view,"Salvar e voltar ao título",482,357,367,48,game.return_title)
	focus_default()

func open_map():
	map_selection=mini(game.region(),5)
	map_page()

func tutorial():
	panel_page("help","Guia do viajante","Primeiros passos")
	var touch=DisplayServer.is_touchscreen_available()
	var cards=[
		["rumo","Explorar","Arraste o direcional. Empurre até a borda para correr." if touch else "Caminhe com as setas ou as teclas de movimento. Segure Shift para correr."],
		["diario","Descobrir","Siga a trilha dourada. Aproxime-se de Iria e toque em Interagir." if touch else "Siga a trilha dourada. Aproxime-se de Iria e pressione %s para conversar."%Saga.keyname("use")],
		["lamina","Combater","Toque em Estilo para trocar de arma. Segure Atacar para carregar o arco." if touch else "%s troca o estilo de combate. Use %s para atacar e segure para carregar o arco."%[Saga.keyname("style"),Saga.keyname("attack")]]
	]
	for i in cards.size():
		var x=108+i*251
		box(view,x,166,238,212,PANEL,LINE)
		glyph(view,cards[i][0],x+17,186,32)
		label(view,cards[i][1],x+17,228,205,33,24,GOLD,true)
		label(view,cards[i][2],x+17,271,203,89,17,PALE)
	label(view,"Abra o Caderno de rondas no diário para explorar os postos de enfermagem com Lia.",109,386,740,51,16,MUTED)
	footer()
	focus_default()

func journal():
	panel_page("journal","Caderno de viagem","Diário da expedição")
	var c=mini(Saga.data.chapter,5)
	var r=Saga.regions[c]
	tex(view,"res://interfaces/cena_%d.png"%c,108,152,231,184,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	gradient(view,108,246,231,90,PackedColorArray([Color("#111b2a00"),Color("#111b2ae6")]),true)
	label(view,"EPÍLOGO" if Saga.data.won else "CAPÍTULO %02d"%(c+1),122,294,205,31,15,GOLD)
	label(view,"O despertar de Aster" if Saga.data.chapter==6 else r.title,364,148,486,45,27,PALE,true)
	label(view,Saga.objective(),364,196,477,65,18,PALE)
	var count=Saga.chapter_lessons(c).size()
	var done=count if Saga.data.chapter>c else int(Saga.data.stage)
	label(view,"%d de %d descobertas"%[done,count],364,261,477,27,14,MUTED)
	for i in count:line(view,364+i*48,300,42,5,GOLD if i<done else LINE)
	var cur=game.region()
	if cur<6:
		var state=int(Saga.data.side.get(str(cur),0))
		var hint=["Converse com o mestre local.",Saga.regions[cur].side_hint,"Concluída."][state]
		label(view,Saga.regions[cur].side+"   ·   "+hint,108,343,744,47,16,MUTED)
	button_icon(button(view,"Habilidades",108,396,223,40,skills),"lamina")
	button_icon(button(view,"Enciclopédia",347,396,223,40,codex),"diario")
	button_icon(button(view,"Relações e cartas",586,396,265,40,memories),"interagir")
	button(view,"Caderno de rondas · %d/6"%care_count(),586,449,265,38,care_index)
	footer()
	focus_default()

func memories():
	panel_page("memories","Diário  /  Encontros","Vozes das margens")
	for i in 6:
		var s=Saga.data.bonds.get(str(i),"Ainda não se conheceram")
		label(view,Saga.regions[i].name+"   ·   "+s,108,146+i*30,744,29,17)
	label(view,"Aviso do cais     ·     %d/6 relíquias encontradas"%Saga.data.relics.size(),108,332,736,28,19,GOLD,true)
	label(view,Saga.data.letter if Saga.data.letter!="" else "O arquivo de Lume ainda aguarda sua carta.",108,365,736,67,16,MUTED)
	button(view,"Voltar ao diário",108,449,191,38,journal,true)
	focus_default()

func bag():
	panel_page("bag","Equipamentos e oficina","Mochila")
	line(view,467,152,1,259,LINE)
	label(view,"Equipamento",108,146,332,32,23,GOLD,true)
	label(view,"%s   ·   %s"%[Saga.WEAPONS[Saga.data.weapon],"Cota de malha" if Saga.data.armor else "Túnica de viagem"],108,185,340,32,16)
	label(view,"Acessório · "+(Saga.data.charm if Saga.data.charm!="" else "Nenhum"),108,218,342,31,15,MUTED)
	button(view,"Alternar arma",108,263,162,38,func():
		var a=Saga.data.weapons
		Saga.data.weapon=int(a[(a.find(Saga.data.weapon)+1)%a.size()])
		Saga.save()
		bag())
	button(view,"Acessórios",280,263,165,38,accessories)
	label(view,"Oficina de campanha",487,146,360,32,23,GOLD,true)
	var resources=[
		["erva","Ervas",Saga.data.herbs],
		["minerio","Minérios",Saga.data.ore],
		["pocao","Poções",Saga.data.potions]
	]
	for i in resources.size():
		var x=487+i*122
		var item=resources[i]
		box(view,x,188,116,51,Color("#24323e"),LINE)
		glyph(view,item[0],x+7,198,30)
		label(view,item[1],x+42,192,69,17,13,MUTED)
		label(view,str(item[2]),x+42,209,69,23,19,PALE,true)
	for i in 3:
		var k=["poção","cota","lança"][i]
		var recipe=button(view,["Preparar poção   ·   2 ervas","Forjar cota   ·   3 minérios","Forjar lança   ·   4 minérios"][i],487,255+i*49,360,40,func():toast(Saga.craft(k));bag())
		button_icon(recipe,["pocao","cota","minerio"][i])
	button_icon(button(view,"Beber poção",108,315,337,40,func():toast(Saga.drink());bag()),"pocao")
	var spell=button(view,"Magia equipada · "+Saga.data.magic,108,369,337,38,func():
		var spells=["lume"]
		if Saga.has_skill(3):spells.append("égide")
		if Saga.has_skill(4) or Saga.data.chapter>=5:spells.append("cura")
		Saga.data.magic=spells[(spells.find(Saga.data.magic)+1)%spells.size()]
		Saga.save()
		bag())
	button_icon(spell,{"lume":"fogo","égide":"escudo","cura":"erva"}.get(Saga.data.magic,"magia"))
	footer()
	focus_default()

func accessories():
	panel_page("accessories","Mochila","Acessórios das margens")
	var row=0
	for i in 6:
		if int(Saga.data.side.get(str(i),0))==2:
			var s=Saga.regions[i].side_item
			button(view,s+("  · equipado" if Saga.data.charm==s else "  · +2 de ataque"),108+(row%2)*370,160+int(row/2)*55,353,45,func():Saga.data.charm=s;Saga.save();accessories())
			row+=1
	if row==0:label(view,"Ajude os habitantes nas missões locais para receber um acessório.",108,170,740,60,19)
	button(view,"Voltar à mochila",108,449,191,38,bag,true)
	focus_default()

func skills():
	panel_page("skills","Nível %d   /   %d de experiência   /   %d ponto(s)"%[Saga.level(),Saga.data.xp,Saga.data.points],"Árvore de habilidades")
	var desc=["Movimento +14","Golpes +4 · após Passo leve","Flechas +5","Escudo mágico com a técnica","Técnica de cura · após Égide","Lume aliado · após Égide"]
	for i in 6:
		var id=i
		var x=108+(i%2)*376
		var y=153+floori(i/2.0)*89
		var skill_button=button(view,Saga.SKILLS[i]+("   ✓" if Saga.has_skill(i) else "   ·   %d pt"%Saga.COSTS[i]),x,y,360,44,func():toast(Saga.train(id));skills())
		button_icon(skill_button,["passo","lamina","arco","escudo","erva","fogo"][i])
		label(view,desc[i],x+3,y+46,356,26,14,MUTED)
	footer()
	focus_default()

func codex():
	panel_page("codex","Enciclopédia  /  %d descobertas"%Saga.data.learned.size(),"Atlas dos saberes")
	for c in 6:
		var n=c
		var b=button(view,Saga.regions[c].subject,108,151+c*43,221,35,func():book_ch=n;codex(),c==book_ch)
		b.add_theme_font_size_override("font_size",14)
	var arr=Saga.chapter_lessons(book_ch)
	var shown=0
	for lesson in arr:
		if lesson.title in Saga.data.learned:
			var l=lesson
			var count=int(Saga.data.review.get(l.title,0))
			button(view,l.title+("   ·   ↺ %d"%count if count else ""),352,151+shown*49,500,42,func():study=l;reviewing=true;attempt=0;dial=0;steps=[];draft="";show_teaching())
			shown+=1
	if shown==0:label(view,"As descobertas de "+Saga.regions[book_ch].place+" aparecerão aqui ao concluir os trabalhos de campo.",363,171,470,150,19,MUTED)
	footer()
	focus_default()

func map_page():
	panel_page("map","Cartografia  /  Seis margens","Mapa dos reinos")
	var map=Map.new()
	view.add_child(map)
	rect(map,108,156,472,260)
	map.here=Saga.origin(mini(game.region(),5))+Vector2(327,265) if game.world.interior else game.hero.position
	map.picked=map_selection
	map_text=label(view,"",600,145,251,163,18,PALE,true)
	travel_btn=button(view,"Viajar",603,323,246,42,func():game.travel(map_selection),true)
	button(view,"Próxima região",603,376,246,39,func():map_selection=(map_selection+1)%6;map_page())
	map.selected.connect(func(c):map_selection=c;map_details())
	map_details()
	label(view,"◆ Região     ● Você",109,413,160,28,14,MUTED)
	tex(view,"res://mapas/margens/insignia.png",260,418,18,20)
	label(view,"Posto de cuidado",283,413,220,28,14,MUTED)
	var shown=Saga.settings.get_value("game","trail",true)
	button(view,"Trilha · "+("visível" if shown else "oculta"),603,448,247,39,func():
		Saga.settings.set_value("game","trail",not shown)
		Saga.settings.save(Saga.SETTINGS)
		game.world.trail.queue_redraw()
		map_page())
	footer()
	focus_default()

func map_details():
	var r=Saga.regions[map_selection]
	map_text.text=r.place+"\n\n"+r.building+"\n"+("Rota conhecida" if map_selection in Saga.data.seen else "Explore para abrir a rota")
	travel_btn.disabled=map_selection not in Saga.data.seen or not game.can_travel()
	if not game.can_travel():map_text.text+="\nAproxime-se de um marco."

