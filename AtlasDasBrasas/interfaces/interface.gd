extends "res://interfaces/aprendizagem.gd"

const Map=preload("res://interfaces/cartografia.gd")
const Mentor=preload("res://personagens/mentor.gd")
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
var boss_label:Label

func update_hud():
	clear(hud)
	box(hud,18,15,209,67,Color("#12282bea"),LINE)
	tex(hud,"res://personagens/s0.png",26,24,40,49)
	label(hud,"NV. %02d"%Saga.level(),72,18,65,22,13,GOLD)
	style_label=label(hud,"",126,18,95,22,13,MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	line(hud,72,45,91,6,Color("#374844"))
	line(hud,72,61,91,6,Color("#374844"))
	hpbar=line(hud,72,45,91,6,Color("#df8c70"))
	mpbar=line(hud,72,61,91,6,Color("#81c4be"))
	hplabel=label(hud,"",164,35,53,23,11,PALE,false,HORIZONTAL_ALIGNMENT_RIGHT)
	mplabel=label(hud,"",164,52,53,23,11,PALE,false,HORIZONTAL_ALIGNMENT_RIGHT)
	box(hud,655,15,287,73,Color("#12282bea"),LINE)
	region_label=label(hud,"",666,18,263,23,13,GOLD)
	objective_label=label(hud,"",666,40,263,43,14,PALE)
	var touch=DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if not touch:
		box(hud,18,489,326,34,Color("#12282bea"),LINE)
		label(hud,"%s  Diário      %s  Mapa      %s  Mochila      Esc  Pausa"%[Saga.keyname("journal"),Saga.keyname("map"),Saga.keyname("bag")],27,491,310,28,13,MUTED)
	prompt=label(hud,"",300,445,360,32,17,PALE,true,HORIZONTAL_ALIGNMENT_CENTER)
	prompt.add_theme_constant_override("outline_size",6)
	prompt.add_theme_color_override("font_outline_color",INK)
	boss_label=label(hud,"",305,12,350,56,18,GOLD,true,HORIZONTAL_ALIGNMENT_CENTER)
	boss_label.add_theme_constant_override("outline_size",5)
	boss_label.add_theme_color_override("font_outline_color",INK)
	box(hud,336 if touch else 641,489,290 if touch else 301,34,Color("#12282bea"),LINE)
	bearing=label(hud,"",342 if touch else 652,490,279,30,14,GOLD,false,HORIZONTAL_ALIGNMENT_RIGHT)
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
	var delta=game.route_target()-game.hero.position
	var dir_names=["L","SE","S","SO","O","NO","N","NE"]
	bearing.text=("Objetivo próximo" if delta.length()<32 else "Objetivo    %s    ·    %d passos"%[dir_names[posmod(roundi(delta.angle()/(PI/4)),8)],ceili(delta.length()/8)])
	if game.world.room_type=="crypt":region_label.text="TEMPLO DO RIO ANTIGO"
	var n=game.world.nearest(game.hero.position)
	prompt.text=""
	if n:
		var s=(Saga.regions[n.c].resident if n.resident else Saga.regions[n.c].name) if n is Mentor else n.label
		prompt.text=("Interagir · "+s) if is_instance_valid(touch_controls) else "[%s]  %s"%[Saga.keyname("use"),s]
	boss_label.text=""
	for e in game.enemies:
		if is_instance_valid(e) and not e.dead and e.boss and game.hero.position.distance_to(e.position)<240:
			boss_label.text=("Aster · Escudo pulsante" if e.shielded() else "Aster · Escudo aberto") if e.kind==3 else "Guardião do selo"
			boss_label.text+="\n%d / %d"%[e.hp,e.hp_max]
			break

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

func tutorial():
	panel_page("help","Guia do viajante","Primeiros passos")
	var t="Caminhe com as setas ou %s, %s, %s e %s. Segure Shift para correr. O losango dourado indica um local da missão. Aproxime-se e pressione %s.\n\n%s alterna lâmina, arco e magia. Use %s para atacar; com o arco, segure e solte para carregar. A mira acompanha o inimigo próximo. %s bloqueia na direção do olhar, %s esquiva e %s usa a técnica do estilo.\n\n%s abre o diário com instruções e habilidades. Os marcos permitem viajar para regiões visitadas. Uma queda leva você à vila, com as descobertas preservadas."%[Saga.keyname("up"),Saga.keyname("left"),Saga.keyname("down"),Saga.keyname("right"),Saga.keyname("use"),Saga.keyname("style"),Saga.keyname("attack"),Saga.keyname("guard"),Saga.keyname("dodge"),Saga.keyname("special"),Saga.keyname("journal")]
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		t="Arraste o círculo à esquerda para caminhar. Empurre além da borda para correr. Aproxime-se do losango dourado e toque em Interagir."+char(10)+char(10)+"Use Estilo para alternar entre lâmina, arco e magia. Segure Atacar e solte para disparar o arco. Bloquear, Esquiva e Técnica ajudam a evitar os golpes dos guardiões."+char(10)+char(10)+"Abra Diário para consultar as missões ou Mochila para preparar e beber poções. Em uma aba anônima, o salvamento dura apenas enquanto a sessão privada estiver aberta."
	label(view,t,108,149,742,267,18)
	footer()
	focus_default()

func journal():
	panel_page("journal","Caderno de viagem","Diário da expedição")
	var c=mini(Saga.data.chapter,5)
	var r=Saga.regions[c]
	label(view,"CAMPANHA  /  "+("EPÍLOGO" if Saga.data.won else "CAPÍTULO %02d"%(c+1)),109,148,722,24,13,GOLD)
	label(view,"O despertar de Aster" if Saga.data.chapter==6 else r.title,108,175,730,43,30,PALE,true)
	label(view,Saga.objective(),108,225,733,55,19)
	var cur=game.region()
	var side=""
	if cur<6:
		var s=Saga.data.side.get(str(cur),0)
		side=Saga.regions[cur].side+" · "+(["Converse com o mestre local.",Saga.regions[cur].side_hint,"Concluída. O presente já pode ser equipado."][int(s)])
	label(view,side,108,294,739,62,16,MUTED)
	button(view,"Habilidades",108,382,202,42,skills)
	button(view,"Enciclopédia",328,382,202,42,codex)
	button(view,"Relações e cartas",548,382,237,42,memories)
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
	label(view,"Equipamento",108,149,332,32,23,GOLD,true)
	label(view,"%s   •   %s\nAcessório: %s"%[Saga.WEAPONS[Saga.data.weapon],"Cota de malha" if Saga.data.armor else "Túnica de viagem",Saga.data.charm if Saga.data.charm!="" else "Nenhum"],108,187,342,62,16)
	button(view,"Alternar arma",108,263,162,36,func():
		var a=Saga.data.weapons
		Saga.data.weapon=int(a[(a.find(Saga.data.weapon)+1)%a.size()])
		Saga.save()
		bag())
	button(view,"Acessórios",280,263,165,36,accessories)
	label(view,"Oficina de campanha",487,149,360,32,23,GOLD,true)
	label(view,"%d ervas    •    %d minérios    •    %d poções"%[Saga.data.herbs,Saga.data.ore,Saga.data.potions],487,192,360,40,16)
	for i in 3:
		var k=["poção","cota","lança"][i]
		button(view,["Preparar poção   ·   2 ervas","Forjar cota   ·   3 minérios","Forjar lança   ·   4 minérios"][i],487,246+i*47,363,39,func():toast(Saga.craft(k));bag())
	button(view,"Beber poção",108,315,337,40,func():toast(Saga.drink());bag())
	button(view,"Magia equipada · "+Saga.data.magic,108,369,337,36,func():
		var spells=["lume"]
		if Saga.has_skill(3):spells.append("égide")
		if Saga.has_skill(4) or Saga.data.chapter>=5:spells.append("cura")
		Saga.data.magic=spells[(spells.find(Saga.data.magic)+1)%spells.size()]
		Saga.save()
		bag())
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
		button(view,Saga.SKILLS[i]+("   ✓" if Saga.has_skill(i) else "   ·   %d pt"%Saga.COSTS[i]),x,y,360,44,func():toast(Saga.train(id));skills())
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
	map_text=label(view,"",602,156,246,155,20,PALE,true)
	travel_btn=button(view,"Viajar",603,323,246,42,func():game.travel(map_selection),true)
	button(view,"Próxima região",603,376,246,39,func():map_selection=(map_selection+1)%6;map_page())
	map.selected.connect(func(c):map_selection=c;map_details())
	map_details()
	footer()
	focus_default()

func map_details():
	var r=Saga.regions[map_selection]
	map_text.text=r.place+"\n\n"+r.building+"\n"+("Rota conhecida" if map_selection in Saga.data.seen else "Explore para abrir a rota")
	travel_btn.disabled=map_selection not in Saga.data.seen or not game.can_travel()
	if not game.can_travel():map_text.text+="\nAproxime-se de um marco."

