extends RefCounted

const Sectors=preload("res://mapas/setores.gd")
const Lands=preload("res://mapas/territorios.gd")
const DESK=Vector2(491,250)
const RESULTS=Vector2(474,299)
const CASES=[
	{
		"id":"canais", "title":"Os nomes do canal", "cells":[Vector2i(8,0),Vector2i(10,0),Vector2i(10,1)],
		"sites":["Ladrilho assinado","Livro de rações","Mesa da inscrição"],
		"text":["Na argila ainda mole, três famílias imprimiram suas marcas ao lado de «abrimos a primeira vala». A camada que cobre o ladrilho traz o selo real de uma obra posterior.","Na folha do ano 12, a despensa entregou rações às três famílias de oleiros por escavarem a vala. O pagamento da ampliação real aparece no ano 19."],
		"lesson":"Duas fontes independentes podem confirmar uma hipótese. Compare o que cada uma diz e quando foi produzida.",
		"demand":"A quem a inscrição deve atribuir a primeira escavação?",
		"choices":["À corte do ano 19","Às famílias de oleiros"],"correct":1,
		"hint":"A corte ampliou a obra no ano 19. Que grupo aparece nas duas fontes ligadas à primeira vala?",
		"result":"Os nomes das famílias voltaram à praça. A caravana abriu aqui um marco de viagem."
	},
	{
		"id":"cotas","title":"Entre duas altitudes","cells":[Vector2i(8,4),Vector2i(10,4),Vector2i(9,4)],
		"sites":["Régua do vale","Mira do observatório","Posto da passarela alta"],
		"text":["A marca da vila indica 640 m acima do nível médio do mar. Copie a cota e use a mesma referência no observatório.","A mira do observatório indica 820 m acima do nível médio do mar. A carta pede o desnível em relação à vila."],
		"lesson":"O desnível entre dois pontos é a diferença entre suas altitudes. Para uma subida de 100 m para 130 m, o desnível é de 30 m.",
		"demand":"Registre no marco o desnível entre a vila e o observatório. Cada toque acrescenta ou retira 20 metros.",
		"hint":"Parta de 640 e conte os metros até chegar a 820. A soma das duas altitudes não mede a subida.",
		"result":"O perfil foi aceito pelos guias. A ponte alta agora permite cruzar a fenda ao norte da estrada."
	},
	{
		"id":"margens","title":"O rastro da chuva","cells":[Vector2i(5,4),Vector2i(4,5),Vector2i(6,5)],
		"sites":["Frasco entre raízes","Frasco da margem nua","Bancada do viveiro"],
		"text":["A coleta foi feita depois da chuva. Após uma hora em repouso, o frasco da margem com raízes tem 2 mm de sedimento no fundo.","Na mesma chuva, com o mesmo volume e tempo de repouso, o frasco da margem sem cobertura acumulou 12 mm de sedimento."],
		"lesson":"Raízes ajudam a reter o solo. Para comparar amostras, mantenha iguais o volume de água e o tempo de repouso.",
		"demand":"Há mudas para recuperar uma margem. Escolha a primeira área de plantio a partir das amostras.",
		"choices":["Margem de Barro","Brejo dos Juncos"],"correct":0,
		"hint":"O frasco com mais sedimento veio do trecho sem raízes. Priorize a cobertura do solo nesse trecho.",
		"result":"Uma faixa de mudas foi plantada na Margem de Barro. As guardiãs deixaram ervas no ponto de coleta."
	},
	{
		"id":"sinos","title":"A porta das duas equipes","cells":[Vector2i(1,4),Vector2i(2,5),Vector2i(2,4)],
		"sites":["Sinos das equipes","Registro de partidas","Comando das runas"],
		"text":["A runa azul representa a equipe da mina, a âmbar representa a da forja. Cada sinal pode estar aceso ou apagado.","O livro registra três tentativas sem abertura: nenhum sinal, só o azul e só o âmbar. A porta exige a presença das duas equipes."],
		"lesson":"Na lógica, a condição A E B só é verdadeira quando as duas condições são verdadeiras ao mesmo tempo.",
		"demand":"Acenda as runas que satisfazem a condição da porta e teste o comando.",
		"hint":"Observe cada runa. Para a condição E, as duas precisam estar acesas na mesma tentativa.",
		"result":"O ferrolho se moveu. A porta de carga dá acesso ao depósito secreto da fortaleza."
	}
]

static func key(realm:int,suffix:String)->String:
	return CASES[realm-2].id+"_"+suffix

static func noted(realm:int,slot:int)->bool:
	return Saga.data.expedition.get(key(realm,str(slot)),false)

static func solved(realm:int)->bool:
	return Saga.data.expedition.get(key(realm,"done"),false)

static func area_name(cell:Vector2i)->String:
	return Lands.AREAS[Sectors.key(cell)][0]

static func populate(w,cell:Vector2i,realm:int):
	if realm<2:return
	var case:Dictionary=CASES[realm-2]
	var slot=case.cells.find(cell)
	if slot<0:return
	var base=Sectors.origin(cell)
	var art=[[10,10,11],[5,5,11],[9,9,10],[11,10,11]][realm-2][slot]
	w.prop(base+DESK,art,"field_study",case.sites[slot],true,9)
	if solved(realm):place_result(w,cell,realm)

static func place_result(w,cell:Vector2i,realm:int):
	var base=Sectors.origin(cell)
	match realm:
		2:
			if cell==CASES[0].cells[2]:
				w.prop(base+RESULTS,5,"field_marker","Marco dos Oleiros",true,9)
		3:
			if cell==CASES[1].cells[2]:
				for y in [7,8]:
					for x in range(31,39):
						w.terrain.set_cell(cell*Vector2i(48,32)+Vector2i(x,y),0,Vector2i(12,realm))
		4:
			if cell==CASES[2].cells[1]:
				for i in 6:w.margem(base+RESULTS+Vector2(i*14,9*(i%2)),"plant","","",false,4)
				w.margem(base+RESULTS,"boticario","field_herbs","Cesta da margem recuperada",true,8)
		5:
			if cell==CASES[3].cells[2]:
				w.margem(base+RESULTS,"mineiro","field_vault","Depósito do Ferrolho",true,12)

static func advance_guide(realm:int,case:Dictionary):
	var old=str(Saga.data.expedition.get("field_track",""))
	if old.is_empty() or old!=str(Saga.data.expedition.get("waypoint","")):return
	if case.cells.all(func(cell):return Sectors.key(cell)!=old):return
	if solved(realm):
		Saga.data.expedition.erase("field_track")
		Saga.data.expedition.erase("waypoint")
	else:
		var next=0 if not noted(realm,0) else 1 if not noted(realm,1) else 2
		var target=Sectors.key(case.cells[next])
		Saga.data.expedition.field_track=target
		Saga.data.expedition.waypoint=target

static func examine(g,cell:Vector2i,realm:int):
	var case:Dictionary=CASES[realm-2]
	var slot=case.cells.find(cell)
	if slot<0:return
	if slot<2:
		var record=func():
			Saga.data.expedition[key(realm,str(slot))]=true
			advance_guide(realm,case)
			Saga.save()
			g.ui.play()
			g.toast("Registro guardado no diário · "+case.title)
		g.ui.dialogue(realm,case.sites[slot],case.text[slot],[[("Rever depois" if noted(realm,slot) else "Anotar no diário"),record]],true)
	elif solved(realm):
		g.ui.dialogue(realm,case.title,case.result,[["Voltar à estrada",g.ui.play]],true)
	elif not noted(realm,0) or not noted(realm,1):
		var places=[]
		for i in 2:
			if not noted(realm,i):places.append(area_name(case.cells[i]))
		g.ui.dialogue(realm,case.title,case.lesson+" Procure os registros em "+" e ".join(places)+".",[["Guardar indicação",func():
			Saga.data.expedition[key(realm,"heard")]=true
			Saga.save()
			g.ui.play()]],true)
	else:
		open_workbench(g,realm)

static func open_workbench(g,realm:int):
	var ui=g.ui
	var case:Dictionary=CASES[realm-2]
	ui.panel_page("field_work",Saga.regions[realm].place,case.title)
	ui.label(ui.view,case.lesson,108,145,741,70,19)
	ui.label(ui.view,case.demand,108,219,741,64,18,ui.GOLD,true)
	var feedback=ui.label(ui.view,"",108,365,741,63,17)
	if realm in [2,4]:
		for i in case.choices.size():
			ui.button(ui.view,case.choices[i],108+i*377,297,358,43,submit.bind(g,realm,i==case.correct,feedback))
	elif realm==3:
		var value=ui.label(ui.view,"0 m",260,292,160,47,23,ui.GOLD,true,HORIZONTAL_ALIGNMENT_CENTER)
		ui.button(ui.view,"−20 m",108,297,139,43,func():value.text="%d m"%maxi(0,int(value.text)-20))
		ui.button(ui.view,"+20 m",435,297,139,43,func():value.text="%d m"%mini(1000,int(value.text)+20))
		ui.button(ui.view,"Registrar cota",593,297,248,43,func():submit(g,realm,int(value.text)==180,feedback))
	else:
		var signals=[]
		for i in 2:
			var name_rune=["Azul","Âmbar"][i]
			var button=ui.button(ui.view,name_rune+" · apagada",108+i*239,297,226,43,func():pass)
			button.toggle_mode=true
			button.toggled.connect(func(on):button.text=name_rune+(" · acesa" if on else " · apagada"))
			signals.append(button)
		ui.button(ui.view,"Testar comando",595,297,246,43,func():submit(g,realm,signals[0].button_pressed and signals[1].button_pressed,feedback))
	ui.footer()
	ui.focus_default()

static func submit(g,realm:int,correct:bool,feedback):
	var case:Dictionary=CASES[realm-2]
	if not correct:
		feedback.text=case.hint
		return
	if solved(realm) or not noted(realm,0) or not noted(realm,1):return
	Saga.data.expedition[key(realm,"done")]=true
	advance_guide(realm,case)
	var cell:Vector2i=case.cells[1 if realm==4 else 2]
	if g.world.loaded.has(cell):
		var start=g.world.objects.get_child_count()
		place_result(g.world,cell,realm)
		g.world.loaded[cell].nodes.append_array(g.world.objects.get_children().slice(start))
		g.world.trail.sync_sector(g.world,cell)
	Saga.award(50)
	Saga.save()
	g.ui.dialogue(realm,case.title,case.result,[["Voltar à estrada",g.ui.play]],true)

static func harvest(g):
	g.ui.play()
	if Saga.data.expedition.get("margens_colhidas",false):
		g.toast("A colheita desta expedição já está na mochila.")
		return
	Saga.data.expedition.margens_colhidas=true
	Saga.data.herbs+=4
	Saga.save()
	g.toast("Quatro ervas recebidas da comunidade.")

static func journal(ui,realm:int):
	var case:Dictionary=CASES[realm-2]
	ui.panel_page("field_notes","Diário / Trabalho de campo",case.title)
	for i in CASES.size():
		ui.button(ui.view,["Ocre","Agulha","Nascente","Basalto"][i],108+i*188,142,174,34,journal.bind(ui,i+2),i==realm-2)
	var known=noted(realm,0) or noted(realm,1) or solved(realm) or Saga.data.expedition.has(key(realm,"heard"))
	ui.label(ui.view,case.lesson,108,190,739,53,17)
	for i in 2:
		var label_text=case.text[i] if noted(realm,i) else "Procure o registro em "+area_name(case.cells[i])+"." if known else "Nenhuma observação registrada."
		ui.label(ui.view,label_text,108,249+58*i,739,56,16,ui.PALE if noted(realm,i) else ui.MUTED)
	ui.label(ui.view,case.result if solved(realm) else "Posto de investigação · "+area_name(case.cells[2]),108,373,739,62,17,ui.GOLD)
	var caravan=preload("res://mapas/caravana.gd")
	var delivery=int(Saga.data.expedition.get("letter_"+str(realm),0))
	if delivery>0:
		var desc="Entregue" if delivery==2 else "Levar a "+area_name(caravan.Recipients[realm-2])
		ui.label(ui.view,caravan.Letters[realm-2]+" · "+desc,108,423,739,22,15,ui.MUTED)
	ui.button(ui.view,"Voltar ao diário",108,449,192,38,ui.journal)
	if known and not solved(realm):
		var slot=0 if not noted(realm,0) else 1 if not noted(realm,1) else 2
		ui.button(ui.view,"Guiar até o posto",644,449,202,38,func():
			var destination=Sectors.key(case.cells[slot])
			Saga.data.expedition.waypoint=destination
			Saga.data.expedition.field_track=destination
			Saga.data.care_route=-1
			Saga.data.rain_route=false
			Saga.save()
			ui.play())
	elif solved(realm):
		var rooms=preload("res://mapas/camaras.gd")
		if Saga.data.expedition.get("archive_"+rooms.KEYS[realm-2],false):
			ui.button(ui.view,"Rever relíquia",644,449,202,38,func():
				ui.dialogue(realm,rooms.ITEMS[realm-2],rooms.TALES[realm-2],[["Voltar às notas",journal.bind(ui,realm)]],true))
	ui.focus_default()
