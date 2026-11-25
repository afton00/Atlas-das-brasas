extends "res://interfaces/aprendizagem.gd"

const SEA_GLASS = Color("#8fdfd0")
const NURSE_PORTRAIT = "res://personagens/enfermeira.png"

# A field decision depends on what the player found at this location.
# The journal keeps only the itinerary and the completed handovers.
var care_region := 0
var care_observed: Array[int] = []
var care_feedback := ""

func care_count() -> int:
	return Saga.data.care_records.size()

func care_index():
	panel_page("care_index","Expedição de enfermagem","Caderno de rondas")
	label(view,"Enfermeira Lia",108,146,355,36,25,SEA_GLASS,true)
	label(view,"Escolha um posto para ouvir a orientação e marcar o caminho. Você também pode descobrir os postos explorando.",108,182,741,51,17)
	for i in Saga.rounds.size():
		var entry=Saga.rounds[i]
		var x=108+(i%2)*376
		var y=246+floori(i/2.0)*59
		var status="Registrado" if Saga.data.care_records.has(str(i)) else Saga.regions[i].place
		button(view,entry.topic,x,y,360,38,care_brief.bind(i))
		label(view,status,x+5,y+37,350,18,13,MUTED)
	button(view,"Voltar ao diário",108,451,173,38,Callable(self,"journal"))
	if int(Saga.data.care_route)>=0:
		button(view,"Seguir a campanha",295,451,194,38,func():set_care_route(-1);play())
	label(view,"%d de 6 registros"%care_count(),597,449,249,39,17,SEA_GLASS,true,HORIZONTAL_ALIGNMENT_RIGHT)
	focus_default()

func at_care_site(c:int) -> bool:
	if game.world.interior or game.region()!=c:return false
	var site=game.world.nearest(game.hero.position)
	return site!=null and site.get("tag")=="care"

func set_care_route(c:int):
	Saga.data.care_route=c
	Saga.save()

func care_brief(c:int):
	care_region=c
	var entry=Saga.rounds[c]
	panel_page("care_brief",Saga.regions[c].place+"  /  "+entry.place,entry.title)
	box(view,108,150,169,241,PANEL,LINE)
	tex(view,NURSE_PORTRAIT,117,163,151,150)
	label(view,"Enfermeira Lia",111,325,163,45,21,SEA_GLASS,true,HORIZONTAL_ALIGNMENT_CENTER)
	label(view,entry.topic,304,152,545,38,25,SEA_GLASS,true)
	label(view,entry.teach,305,199,531,133,19)
	var recorded=Saga.data.care_records.has(str(c))
	label(view,entry.record if recorded else "Na ronda, examine o local e decida como ajudar a equipe.",305,337,530,78,17,MUTED)
	button(view,"Caderno",108,449,147,40,care_index)
	if recorded:
		if at_care_site(c):button(view,"Refazer a ronda",332,449,201,40,care_begin.bind(c))
		button(view,"Ver registro",591,449,258,40,care_record.bind(c),true)
	elif at_care_site(c):
		button(view,"Examinar o posto",591,449,258,40,care_begin.bind(c),true)
	else:
		button(view,"Marcar rota até o posto",591,449,258,40,func():set_care_route(c);play(),true)
	focus_default()

func care_begin(c:int):
	if not at_care_site(c):return
	care_region=c
	care_observed.clear()
	care_feedback=""
	care_inspect()

func care_inspect():
	var entry=Saga.rounds[care_region]
	panel_page("care_field",entry.place+"  /  Ronda de campo",entry.title)
	tex(view,"res://interfaces/rondas/campo_%d.png"%care_region,108,155,448,208,TextureRect.STRETCH_SCALE)
	for i in entry.points.size():
		var target=Button.new()
		target.flat=true
		target.focus_mode=Control.FOCUS_NONE
		target.accessibility_name="Examinar "+str(entry.points[i][0])
		target.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		target.add_theme_stylebox_override("hover",style(Color("#f4e2af18"),GOLD))
		target.pressed.connect(observe_care.bind(i))
		view.add_child(target)
		rect(target,108+i*149,155,149,208)
		var spot=button(view,entry.points[i][0],108+i*150,370,146,39,observe_care.bind(i),i in care_observed)
		spot.tooltip_text="Examinar "+str(entry.points[i][0]).to_lower()
	label(view,"Observação no local",580,150,266,42,22,SEA_GLASS,true)
	label(view,entry.scene,581,197,265,94,17)
	line(view,581,300,265,1,LINE)
	label(view,care_feedback if care_feedback!="" else "Toque no nome de um elemento da cena para examiná-lo.",581,308,265,98,17,GOLD)
	button(view,"Sair do posto",108,449,164,39,play)
	# Urgent help is available immediately. Other decisions use a concrete clue.
	if int(entry.key) in care_observed or care_region==5:
		button(view,"Acionar a equipe" if care_region==5 else "Escolher um cuidado",579,449,270,39,care_decide,true)
	focus_default()

func observe_care(i:int):
	if i not in care_observed:care_observed.append(i)
	care_feedback=Saga.rounds[care_region].points[i][1]
	care_inspect()

func care_decide(feedback:String=""):
	var entry=Saga.rounds[care_region]
	panel_page("care_decision",entry.place+"  /  Decisão em equipe",entry.topic)
	tex(view,"res://interfaces/rondas/campo_%d.png"%care_region,108,156,324,151,TextureRect.STRETCH_SCALE)
	label(view,entry.points[int(entry.key)][1],109,315,324,83,18)
	label(view,"Qual ação você toma?",458,148,386,44,23,SEA_GLASS,true)
	for i in entry.actions.size():
		button(view,entry.actions[i],459,201+i*51,390,43,apply_care.bind(i))
	label(view,feedback,460,356,385,78,17,GOLD)
	button(view,"Reexaminar o local",108,449,220,39,care_inspect)
	focus_default()

func apply_care(i:int):
	var c=care_region
	if not at_care_site(c):return
	var entry=Saga.rounds[c]
	if i!=int(entry.answer):
		care_decide(entry.feedback[i])
		return
	if not Saga.data.care_records.has(str(c)):
		Saga.data.care_records[str(c)]=true
		if int(Saga.data.care_route)==c:Saga.data.care_route=-1
		Saga.award(25)
		if care_count()==Saga.rounds.size():Saga.data.points+=1
		Saga.save()
		game.sound("sino")
		game.world.refresh()
	care_record(c)

func care_record(c:int):
	if not Saga.data.care_records.has(str(c)):return
	var entry=Saga.rounds[c]
	panel_page("care_record","Caderno de rondas  /  "+entry.place,"Passagem de plantão")
	tex(view,"res://interfaces/rondas/campo_%d.png"%c,108,156,276,129,TextureRect.STRETCH_SCALE)
	label(view,entry.topic,108,299,274,43,21,SEA_GLASS,true)
	label(view,"%d de 6 rondas registradas · 25 XP por ronda"%care_count(),109,351,276,42,15,MUTED)
	label(view,"O que observamos",409,153,431,37,22,SEA_GLASS,true)
	label(view,entry.points[int(entry.key)][1],410,192,436,68,18)
	label(view,"Cuidado realizado",409,263,431,37,22,SEA_GLASS,true)
	label(view,entry.record,410,300,433,95,18)
	if care_count()==6:label(view,"Rede de cuidado concluída · 1 ponto de habilidade",108,407,743,30,17,GOLD)
	button(view,"Retomar a viagem",108,449,191,40,play,true)
	button(view,"Caderno",311,449,120,40,care_index)
	var source_btn=button(view,"Consultar fonte oficial",618,449,231,40,func():OS.shell_open(entry.url))
	source_btn.tooltip_text=entry.source
	focus_default()
