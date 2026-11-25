extends CanvasLayer

const SERIF=preload("res://interfaces/LiberationSerif-Bold.ttf")
const SANS=preload("res://interfaces/LiberationSans-Regular.ttf")
const GOLD=Color("#e6be7e")
const PALE=Color("#f5e8cf")
const MUTED=Color("#b5c6c1")
const INK=Color("#132529")
const PANEL=Color("#192f32")
const LINE=Color("#53635a")
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
	s.content_margin_left=9
	s.content_margin_right=9
	return s

func box(parent,x,y,w,h,bg=PANEL,edge=LINE):
	var n=Panel.new()
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

func button(parent,t,x,y,w,h,cb:Callable,primary=false):
	var b=Button.new()
	b.text=t
	b.add_theme_font_override("font",SANS)
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",INK if primary else PALE)
	b.add_theme_color_override("font_focus_color",INK if primary else PALE)
	b.add_theme_color_override("font_hover_color",Color.WHITE if not primary else INK)
	b.add_theme_color_override("font_pressed_color",INK)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else Color("#20383a"),Color("#e8ca98") if primary else LINE))
	b.add_theme_stylebox_override("hover",style(Color("#f1cc91") if primary else Color("#335456"),GOLD))
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

func panel_page(m,eyebrow,title):
	wipe(m)
	shade()
	box(view,74,34,812,472,INK,LINE)
	line(view,74,34,812,3,GOLD)
	label(view,eyebrow.to_upper(),108,55,660,23,13,GOLD)
	label(view,title,107,77,700,45,35,PALE,true)
	line(view,108,132,744,1,LINE)

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
	var sh=Gradient.new()
	sh.colors=PackedColorArray([Color(.025,.055,.09,.94),Color(.03,.07,.11,.70),Color(.03,.07,.11,.03)])
	sh.offsets=PackedFloat32Array([0,.42,1])
	var gt=GradientTexture2D.new()
	gt.gradient=sh
	var veil=TextureRect.new()
	veil.texture=gt
	view.add_child(veil)
	rect(veil,0,0,960,540)
	line(view,52,56,38,2,GOLD)
	label(view,"CRÔNICAS DAS SEIS MARGENS",101,43,345,29,13,GOLD)
	label(view,"Atlas das",50,91,470,75,64,PALE,true)
	label(view,"Brasas",47,148,480,108,92,Color("#f2cf93"),true)
	label(view,"Um rio desapareceu dos mapas.\nSeis mestres ainda guardam o caminho.",55,267,390,57,19,PALE)
	var has=Saga.exists()
	button(view,"Continuar jornada" if has else "Iniciar jornada",55,353,221,45,game.continue_game if has else game.new_game,true)
	if has:button(view,"Nova jornada",55,408,144,38,game.confirm_new)
	button(view,"Configurações",207 if has else 55,408,145,38,Callable(self,"settings_page"))
	line(view,55,485,855,1,Color("#817e77"))
	label(view,"ATLAS DAS BRASAS",55,492,270,27,12,PALE)
	label(view,"RPG DE FANTASIA   •   EDIÇÃO EM PORTUGUÊS",460,492,450,27,12,PALE,false,HORIZONTAL_ALIGNMENT_RIGHT)
	focus_default()

func play():
	wipe("play")
	update_hud()
	game.world.refresh()

func cinematic(kicker,title,body,action,cb,illustration=-1):
	wipe("scene")
	var image_path="res://interfaces/horizonte.png" if illustration<0 else "res://interfaces/cena_%d.png"%illustration
	var backdrop=tex(view,image_path,-9,-6,978,552,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	backdrop.create_tween().tween_property(backdrop,"position",Vector2(-2,-2),4.0)
	line(view,0,0,960,540,Color(.045,.075,.095,.55))
	box(view,60,239,840,252,Color("#132529ed"),LINE)
	label(view,kicker.to_upper(),92,260,770,22,13,GOLD)
	label(view,title,90,284,784,49,37,PALE,true)
	label(view,body,92,341,770,72,19,PALE)
	button(view,action,92,428,285,41,cb,true)
	focus_default()

func dialogue(c,title,body,choices,local=false):
	wipe("dialog")
	shade()
	box(view,62,273,836,231,INK,LINE)
	line(view,62,273,836,3,GOLD)
	tex(view,("res://personagens/morador_%d.png" if local else "res://personagens/retrato_%d.png")%c,81,296,116,116)
	label(view,Saga.regions[c].resident if local else Saga.regions[c].name,81,416,116,25,21,GOLD,true,HORIZONTAL_ALIGNMENT_CENTER)
	label(view,title,219,293,647,28,21,GOLD,true)
	typed=label(view,body,219,328,647,82,17,PALE)
	typed.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	typed.visible_characters=0
	typing=0
	var bw=(641-(choices.size()-1)*9)/choices.size()
	for i in choices.size():
		var item=choices[i]
		button(view,item[0],219+i*(bw+9),438,bw,42,item[1],i==0)
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
	button(view,"Voltar",108,444,147,40,game.back_from_settings,true)
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

