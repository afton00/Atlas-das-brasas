extends Control

const INK=Color("#162333ea")
const LINE=Color("#a6b3a192")
const GOLD=Color("#eecc91")
const FONT=preload("res://interfaces/LiberationSans-Regular.ttf")
const STICK=Vector2(90,444)
const ICONS=["mapa","diario","mochila","pausa","escudo","magia","arco","passo","lamina","interagir"]
var images:Array[Texture2D]=[]
const COMMANDS=[
	["map","Mapa",Rect2(264,14,72,43)],["journal","Diário",Rect2(342,14,72,43)],
	["bag","Mochila",Rect2(420,14,84,43)],["pause","Pausa",Rect2(510,14,75,43)],
	["guard","Bloquear",Rect2(649,398,94,51)],["special","Técnica",Rect2(752,398,91,51)],
	["style","Estilo",Rect2(853,398,91,51)],["dodge","Esquiva",Rect2(649,457,94,58)],
	["attack","Atacar",Rect2(752,457,91,58)],["use","Interagir",Rect2(853,457,91,58)]
]
var game
var stick_finger=-1
var thumb=Vector2.ZERO
var fingers={}
var running=false

func _ready():
	for key in ICONS:images.append(load("res://interfaces/icones/%s.png"%key))
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(release_all)

func release_all():
	for action in fingers.values():Input.action_release(action)
	fingers.clear()
	stick_finger=-1
	steer(Vector2.ZERO)

func steer(delta:Vector2):
	thumb=delta.limit_length(46)
	running=delta.length()>55
	for pair in [["left",-thumb.x],["right",thumb.x],["up",-thumb.y],["down",thumb.y]]:
		if pair[1]>5:Input.action_press(pair[0],minf(1,pair[1]/34))
		else:Input.action_release(pair[0])
	queue_redraw()

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:release_all()

func _input(event):
	if not is_visible_in_tree() or game.is_locked():return
	if event is InputEventScreenDrag and event.index==stick_finger:
		steer(event.position-STICK)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var id=event.index
		if not event.pressed:
			if id==stick_finger:
				stick_finger=-1
				steer(Vector2.ZERO)
			elif fingers.has(id):
				var action=fingers[id]
				fingers.erase(id)
				if action not in fingers.values():Input.action_release(action)
				queue_redraw()
			else:return
		elif event.position.distance_to(STICK)<77 and stick_finger==-1:
			stick_finger=id
			steer(event.position-STICK)
		else:
			var command=""
			for item in COMMANDS:
				if item[2].has_point(event.position):command=item[0]
			match command:
				"":return
				"use":game.interact()
				"map":
					game.ui.map_selection=mini(game.region(),5)
					game.ui.map_page()
				"journal":game.ui.journal()
				"bag":game.ui.bag()
				"pause":game.ui.pause_page()
				_:
					fingers[id]=command
					Input.action_press(command)
			queue_redraw()
		get_viewport().set_input_as_handled()

func _draw():
	draw_circle(STICK,57,INK)
	draw_arc(STICK,57,0,TAU,48,LINE,2)
	for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var p=STICK+d*42
		draw_polyline(PackedVector2Array([p+d.orthogonal()*4-d*3,p,p-d.orthogonal()*4-d*3]),GOLD,2)
	draw_circle(STICK+thumb,21,Color("#a8bcab"))
	for i in COMMANDS.size():
		var item=COMMANDS[i]
		var area:Rect2=item[2]
		var hot=item[0] in fingers.values()
		var emphasis=item[0] in ["attack","use"]
		draw_rect(area,Color("#58636a") if hot else Color("#293c49ec") if emphasis else INK)
		draw_rect(area,GOLD if emphasis else LINE,false,2 if emphasis else 1)
		if i>=images.size():continue
		var extent=19 if i<4 else 23
		draw_texture_rect(images[i],Rect2(area.get_center().x-extent/2,area.position.y+3,extent,extent),false)
		draw_string(FONT,Vector2(area.position.x,area.end.y-6),item[1],HORIZONTAL_ALIGNMENT_CENTER,area.size.x,14 if i<4 else 16,Color.WHITE if hot else GOLD)
