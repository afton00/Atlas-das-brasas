extends "res://interfaces/base.gd"

var study:Dictionary
var reviewing=false
var attempt=0
var dial=0
var steps:Array=[]
var grid_cell=""
var response:Label
var number:Label
var draft=""
var writing:TextEdit
var seq_buttons=[]
var status_label:Label

func challenge(lesson:Dictionary,review=false):
	study=lesson
	reviewing=review
	attempt=0
	dial=0
	steps=[]
	grid_cell=""
	draft=""
	practice()

func practice():
	var c=int(study.ch)
	panel_page("challenge","%s  /  %s"%[Saga.regions[c].subject,"Revisão" if reviewing else "Trabalho de campo"],study.title)
	label(view,study.task,108,145,740,66,18)
	response=label(view,"",108,393,744,49,15,GOLD)
	match study.type:
		"pick":
			for i in study.opts.size():
				var idx=i
				button(view,study.opts[i],108,220+51*i,744,43,func():evaluate(idx))
		"dial":
			box(view,186,214,588,171,PANEL,LINE)
			number=label(view,str(dial),340,217,280,77,53,GOLD,true,HORIZONTAL_ALIGNMENT_CENTER)
			button(view,"−",290,242,53,44,func():adjust(-1))
			button(view,"+",617,242,53,44,func():adjust(1))
			var s=HSlider.new()
			s.name="Regua"
			s.min_value=study.opts[0]
			s.max_value=study.opts[1]
			s.value=dial
			s.step=1
			view.add_child(s)
			rect(s,258,303,444,24)
			var scale_marks=preload("res://interfaces/medida.gd").new()
			scale_marks.minimum=int(study.opts[0])
			scale_marks.maximum=int(study.opts[1])
			scale_marks.value=dial
			view.add_child(scale_marks)
			rect(scale_marks,250,333,460,38)
			scale_marks.selected.connect(func(n):s.value=n)
			s.value_changed.connect(func(v):scale_marks.value=int(v);scale_marks.queue_redraw())
			s.value_changed.connect(func(v):dial=int(v);number.text=str(dial))
			button(view,"Aplicar medida",605,449,246,38,func():evaluate(dial),true)
		"order":
			seq_buttons=[]
			var indices=[2,0,1] if attempt%2==0 else [1,2,0]
			for i in indices.size():
				var idx=indices[i]
				var b=button(view,study.opts[idx],108,218+i*48,505,40,func():add_step(idx))
				seq_buttons.append(b)
			box(view,627,217,224,138,PANEL,LINE)
			status_label=label(view,"Sequência\n—",636,219,218,130,17,GOLD)
			button(view,"Recomeçar",605,449,246,38,func():steps=[];practice())
		"grid":
			for y in 5:
				for x in 5:
					var cell=char(65+x)+str(y+1)
					button(view,cell,210+55*x,211+35*y,50,31,func():evaluate(cell))
			label(view,"N  ↑\n\nO  ←     →  L\n\nS  ↓",553,213,203,157,17,GOLD,false,HORIZONTAL_ALIGNMENT_CENTER)
		"write":
			writing=TextEdit.new()
			writing.placeholder_text="Escreva o aviso que será afixado no cais…"
			writing.text=draft
			writing.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
			writing.add_theme_font_size_override("font_size",18)
			view.add_child(writing)
			rect(writing,108,221,744,140)
			button(view,"Revisar meu aviso",605,449,246,38,review_writing,true)
	button(view,"Reler ensinamento",108,449,207,38,show_teaching)
	button(view,"Voltar",325,449,102,38,leave_challenge)
	focus_default()

func adjust(inc):
	var slider=view.get_node_or_null("Regua")
	if slider:slider.value=clampi(dial+inc,int(study.opts[0]),int(study.opts[1]))

func add_step(idx):
	steps.append(idx)
	for b in seq_buttons:
		if b.text==study.opts[idx]:b.disabled=true
	var labels=[]
	for j in steps:labels.append(str(study.opts[j]).get_slice(" · ",0))
	status_label.text="Sequência\n"+" → ".join(labels)
	if steps.size()==study.opts.size():evaluate(steps)

func review_writing():
	draft=writing.text.strip_edges()
	if draft.length()>300:
		response.text="A placa comporta 300 caracteres. Encurte a frase e preserve as informações essenciais."
		return
	if draft.split(" ",false).size()<6:
		response.text="Escreva uma frase completa. Diga o que fazer, onde e por quê."
		return
	panel_page("challenge","Oficina de escrita  /  Autorrevisão","O aviso está pronto?")
	label(view,"«"+draft+"»",108,143,744,94,16,PALE,true)
	var checks=[]
	for i in 3:
		var cb=CheckBox.new()
		cb.text=["O leitor encontra um pedido de ação.","O lugar está identificado.","Expliquei a razão do pedido."][i]
		view.add_child(cb)
		rect(cb,108,243+41*i,725,36)
		checks.append(cb)
	response=label(view,"",108,371,736,53,16,GOLD)
	button(view,"Editar texto",108,445,174,42,practice)
	button(view,"Afixar aviso",615,445,235,42,func():
		for box_item in checks:
			if not box_item.button_pressed:
				response.text="Releia os três critérios e ajuste a frase se faltar algum."
				return
		if not reviewing:Saga.data.letter=draft
		complete_practice(),true)
	focus_default()

func show_teaching():
	if study.type=="write" and is_instance_valid(writing):draft=writing.text
	panel_page("challenge","Caderno de campo  /  "+Saga.regions[int(study.ch)].subject,study.title)
	tex(view,"res://personagens/retrato_%d.png"%int(study.ch),110,169,112,112)
	label(view,study.teach,252,162,597,197,20)
	button(view,"Voltar à prática",108,444,228,42,func():steps=[];practice(),true)
	focus_default()

func evaluate(val):
	var ok=val==study.answer
	if study.type=="order":
		ok=val.size()==study.answer.size()
		for i in val.size():
			if int(val[i])!=int(study.answer[i]):ok=false
	if ok:
		complete_practice()
		return
	attempt+=1
	var note=""
	match study.type:
		"pick":note=study.hints[val]
		"dial":note=("A medida ficou abaixo. " if val<study.answer else "A medida ficou acima. ")+study.hints
		"order":
			steps=[]
			practice()
			note=study.hints
		_:note=study.hints
	response.text=note
	response.add_theme_color_override("font_color",Color("#f8bda0"))
	if not Saga.settings.get_value("game","still",false):
		response.modulate.a=.45
		response.create_tween().tween_property(response,"modulate:a",1.0,.18)

func complete_practice():
	var c=int(study.ch)
	if reviewing:
		Saga.data.review[study.title]=int(Saga.data.review.get(study.title,0))+1
		Saga.save()
	else:Saga.master_lesson()
	game.sound("sino")
	dialogue(c,"Revisão concluída" if reviewing else "Descoberta registrada",study.solution,[["Voltar à enciclopédia" if reviewing else "Voltar à aventura",Callable(self,"codex") if reviewing else Callable(self,"play")]])

func leave_challenge():
	if reviewing:call("codex")
	else:play()

