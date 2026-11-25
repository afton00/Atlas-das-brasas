extends CanvasLayer

const SERIF=preload("res://interfaces/LiberationSerif-Bold.ttf")
const SANS=preload("res://interfaces/LiberationSans-Regular.ttf")
const GOLD=Color("#edc68b")
const PALE=Color("#f5e8cf")
const MUTED=Color("#b9c8c8")
const INK=Color("#141d2a")
const PANEL=Color("#202c39")
const LINE=Color("#52616a")
var root:Control
var view:Control
var hud:Control
var tip:Label
var message:Label
var message_timer=0.0
var mode="menu"
var game
var typed:Label
var typing=0.0
var rebind=""
var first_button:Button
var notices:Control

func configure(g):
	game=g
	root=Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud=layer_control(root)
	view=layer_control(root)
	notices=layer_control(root)
	message=label(notices,"",195,67,570,26,15,GOLD,false,HORIZONTAL_ALIGNMENT_CENTER)
	message.add_theme_constant_override("outline_size",5)
	message.add_theme_color_override("font_outline_color",INK)

func layer_control(parent):
	var c=Control.new()
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return c

func clear(node):
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func rect(n,x,y,w,h):
	n.position=Vector2(x,y)
	n.size=Vector2(w,h)

func style(bg:Color,border:Color,width=1):
	var s=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.corner_detail=1
	s.content_margin_left=9
	s.content_margin_right=9
	return s

func box(parent,x,y,w,h,bg=PANEL,edge=LINE):
	var n=preload("res://interfaces/moldura.gd").new()
	n.add_theme_stylebox_override("panel",style(bg,edge))
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	rect(n,x,y,w,h)
	return n

func line(parent,x,y,w,h,col):
	var n=ColorRect.new()
	n.color=col
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	rect(n,x,y,w,h)
	return n

func label(parent,t,x,y,w,h,sz=16,col=PALE,big=false,align=HORIZONTAL_ALIGNMENT_LEFT):
	var n=Label.new()
	n.size=Vector2(w,h)
	n.text=str(t)
	n.add_theme_font_override("font",SERIF if big else SANS)
	n.add_theme_font_size_override("font_size",sz)
	n.add_theme_color_override("font_color",col)
	n.horizontal_alignment=align
	n.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	rect(n,x,y,w,h)
	return n

func tex(parent,res,x,y,w,h,fit=TextureRect.STRETCH_KEEP_ASPECT_CENTERED):
	var t=TextureRect.new()
	t.texture=load(res)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=fit
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	rect(t,x,y,w,h)
	return t

func glyph(parent,key,x,y,extent):
	return tex(parent,"res://interfaces/icones/%s.png"%key,x,y,extent,extent)

func button_icon(b,key):
	b.icon=load("res://interfaces/icones/%s.png"%key)
	b.add_theme_constant_override("icon_max_width",20)
	b.add_theme_constant_override("h_separation",9)
	return b

func button(parent,t,x,y,w,h,cb:Callable,primary=false):
	var b=Button.new()
	b.text=t
	if primary:
		for state in ["icon_normal_color","icon_focus_color","icon_hover_color","icon_pressed_color"]:b.add_theme_color_override(state,Color("#3d5058"))
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font",SANS)
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",INK if primary else PALE)
	b.add_theme_color_override("font_focus_color",INK if primary else PALE)
	b.add_theme_color_override("font_hover_color",Color.WHITE if not primary else INK)
	b.add_theme_color_override("font_pressed_color",INK)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else Color("#283643"),Color("#e8ca98") if primary else LINE))
	b.add_theme_stylebox_override("hover",style(Color("#f1cc91") if primary else Color("#3d5260"),GOLD))
	b.add_theme_stylebox_override("pressed",style(GOLD,GOLD))
	var focus=style(Color.TRANSPARENT,GOLD,2)
	b.add_theme_stylebox_override("focus",focus)
	b.pressed.connect(cb)
	parent.add_child(b)
	rect(b,x,y,w,h)
	if first_button==null:first_button=b
	return b

func wipe(m):
	mode=m
	typed=null
	rebind=""
	first_button=null
	clear(view)
	hud.visible=m=="play"
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE if m=="play" else Control.MOUSE_FILTER_STOP

func focus_default():
	if is_instance_valid(first_button):first_button.grab_focus()

func shade():
	line(view,0,0,960,540,Color(0.035,.068,.085,.77))

func gradient(parent,x,y,w,h,colors:PackedColorArray,vertical=false):
	var grad=Gradient.new()
	var stops=PackedFloat32Array()
	for i in colors.size():stops.append(float(i)/(colors.size()-1))
	grad.offsets=stops
	grad.colors=colors
	var texture=GradientTexture2D.new()
	texture.gradient=grad
	texture.fill_to=Vector2.DOWN if vertical else Vector2.RIGHT
	var overlay=TextureRect.new()
	overlay.texture=texture
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	rect(overlay,x,y,w,h)
	return overlay

func panel_page(m,eyebrow,title):
	wipe(m)
	shade()
	box(view,74,32,812,476,INK,LINE)
	gradient(view,76,34,808,94,PackedColorArray([Color("#25394a"),INK]))
	line(view,108,130,744,1,LINE)
	label(view,eyebrow.to_upper(),108,51,685,23,13,GOLD)
	label(view,title,107,75,690,48,35,PALE,true)
	var icons={"map":"rumo","bag":"mochila","skills":"lamina","settings":"pausa","accessories":"mochila","pause":"brasa","challenge":"magia"}
	glyph(view,icons.get(m,"diario"),806,65,37)

func toast(t):
	message.text=t
	message_timer=3.1

func _process(dt):
	if is_instance_valid(typed) and typed.visible_ratio<1:
		typing+=dt*75
		typed.visible_characters=int(typing)
	message_timer=maxf(0,message_timer-dt)
	message.visible=message_timer>0

func title_menu():
	wipe("menu")
	tex(view,"res://interfaces/horizonte.png",0,0,960,540,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	gradient(view,0,0,535,540,PackedColorArray([Color("#0b1122d9"),Color("#0b1122aa"),Color("#0b112200")]))
	gradient(view,0,388,960,152,PackedColorArray([Color("#0d142400"),Color("#0d1424dc")]),true)
	if not Saga.settings.get_value("game","still",false):
		var sparks=preload("res://interfaces/fagulhas.gd").new()
		sparks.mouse_filter=Control.MOUSE_FILTER_IGNORE
		view.add_child(sparks)
		rect(sparks,0,0,960,540)
	glyph(view,"rumo",52,62,34)
	label(view,"CRÔNICAS DAS SEIS MARGENS",97,63,331,30,14,GOLD)
	label(view,"Atlas das",49,109,405,76,66,PALE,true)
	label(view,"Brasas",46,170,411,105,94,GOLD,true)
	line(view,55,289,32,2,GOLD)
	label(view,"Um rio desapareceu dos mapas.\nSeis mestres ainda guardam o caminho.",55,311,362,52,17,PALE)
	var has=Saga.exists()
	var start=button(view,"Continuar jornada" if has else "Iniciar jornada",55,389,249,48,game.continue_game if has else game.new_game,true)
	button_icon(start,"rumo")
	if has:button(view,"Nova jornada",55,451,143,38,game.confirm_new)
	button(view,"Configurações",210 if has else 55,451,143,38,Callable(self,"settings_page"))
	focus_default()

func play():
	wipe("play")
	update_hud()
	game.world.refresh()

func cinematic(kicker,title,body,action,cb,illustration=-1):
	wipe("scene")
	var image_path="res://interfaces/horizonte.png" if illustration<0 else "res://interfaces/cena_%d.png"%illustration
	var backdrop=tex(view,image_path,-9,-6,978,552,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	if not Saga.settings.get_value("game","still",false):backdrop.create_tween().tween_property(backdrop,"position",Vector2(-2,-2),4.0)
	gradient(view,0,0,960,540,PackedColorArray([Color("#121c2800"),Color("#121c2860"),Color("#101724")]),true)
	box(view,36,268,888,240,Color("#111b29ee"),LINE)
	line(view,62,293,25,2,GOLD)
	label(view,kicker.to_upper(),98,280,782,28,13,GOLD)
	label(view,title,61,309,834,47,38,PALE,true)
	label(view,body,63,359,831,75,18,PALE)
	button(view,action,62,449,290,42,cb,true)
	focus_default()

func reveal_text():
	if is_instance_valid(typed):
		typing=typed.text.length()
		typed.visible_ratio=1

func dialogue(c,title,body,choices,local=false):
	wipe("dialog")
	gradient(view,0,0,960,540,PackedColorArray([Color(0,0,0,.12),Color("#131e2b44"),Color("#0c1322d9")]),true)
	box(view,36,249,888,262,INK,LINE)
	var accent=Color(Saga.regions[c].color)
	line(view,58,272,3,175,accent)
	tex(view,("res://personagens/morador_%d.png" if local else "res://personagens/retrato_%d.png")%c,68,273,127,127)
	label(view,Saga.regions[c].resident if local else Saga.regions[c].name,68,405,128,30,22,GOLD,true,HORIZONTAL_ALIGNMENT_CENTER)
	label(view,Saga.regions[c].place.to_upper(),219,265,662,26,13,accent.lightened(.25))
	label(view,title,218,293,663,32,24,PALE,true)
	typed=label(view,body,219,333,673,101,16 if str(body).length()>290 else 18,PALE)
	typed.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	typed.mouse_filter=Control.MOUSE_FILTER_STOP
	typed.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:reveal_text())
	typing=0
	typed.visible_characters=0
	if Saga.settings.get_value("game","full_text",false):reveal_text()
	var bw=(834-(choices.size()-1)*10)/choices.size()
	for i in choices.size():
		var item=choices[i]
		button(view,item[0],62+i*(bw+10),449,bw,43,item[1],i==0)
	focus_default()

func settings_page():
	panel_page("settings","Preferências","Configurações")
	label(view,"Volume geral",109,149,185,32,18)
	var slider=HSlider.new()
	slider.min_value=0
	slider.max_value=1
	slider.step=.05
	slider.value=Saga.settings.get_value("sound","volume",.6)
	view.add_child(slider)
	rect(slider,294,157,300,22)
	slider.value_changed.connect(func(v):Saga.settings.set_value("sound","volume",v); Saga.apply_audio(); Saga.settings.save(Saga.SETTINGS))
	var gentle=Saga.settings.get_value("game","gentle",false)
	button(view,"Combate suave · "+("ligado" if gentle else "desligado"),609,147,240,35,func():Saga.settings.set_value("game","gentle",not gentle);Saga.settings.save(Saga.SETTINGS);settings_page())
	label(view,"Controles",108,192,585,30,22,GOLD,true)
	var names=["Norte","Sul","Oeste","Leste","Interagir","Atacar","Estilo","Esquivar","Bloquear","Técnica","Mochila","Diário","Mapa","Poção"]
	var keys=Saga.binds.keys()
	for i in keys.size():
		var a=keys[i]
		var b=button(view,names[i]+"  ·  "+Saga.keyname(a),108+(i%4)*187,233+int(i/4)*44,178,35,func():rebind=a;toast("Pressione a nova tecla. Esc cancela."))
		b.add_theme_font_size_override("font_size",14)
	var immediate=Saga.settings.get_value("game","full_text",false)
	button(view,"Texto · "+("imediato" if immediate else "gradual"),108,405,221,33,func():Saga.settings.set_value("game","full_text",not immediate);Saga.settings.save(Saga.SETTINGS);settings_page())
	var still=Saga.settings.get_value("game","still",false)
	button(view,"Animação · "+("reduzida" if still else "completa"),339,405,232,33,func():Saga.settings.set_value("game","still",not still);Saga.settings.save(Saga.SETTINGS);settings_page())
	button(view,"Voltar",108,451,147,38,game.back_from_settings,true)
	focus_default()

func capture_key(ev):
	if rebind!="" and ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode!=KEY_ESCAPE and ev.physical_keycode not in [KEY_ENTER,KEY_SHIFT]:
			for other in Saga.binds:
				if other!=rebind and ev.physical_keycode in [Saga.settings.get_value("controls",other,Saga.binds[other]),Saga.aliases.get(other,0)]:
					toast("Essa tecla já está em uso.")
					return true
			Saga.bind(rebind,ev.physical_keycode)
			Saga.settings.save(Saga.SETTINGS)
		rebind=""
		settings_page()
		return true
	return false

func update_hud():
	pass

