extends "res://scripts/ator.gd"

const TRAVELER_SHEET=preload("res://animacoes/viajante.png")
const MOVING_STATES=["idle","walk","run"]
const ACTION_ROWS=["blade","bow","fire","guard","dodge","hurt","death","ice","interact","sweep","surge"]
const FRAME_SIZE=Vector2i(72,44)
static var traveler_frames:SpriteFrames

var game
var cooldown=0.0
var invincible=0.0
var action_time=0.0
var action="idle"
var dodge_time=0.0
var charge=0.0
var charging=false
var guard=false
var combo=0
var combo_window=0.0
var spell_cd=0.0
var target_dir=Vector2.DOWN
var camera:Camera2D

func setup(g,pos:Vector2,bounds:Rect2):
	game=g
	position=pos
	make_actor(0,5)
	camera=Camera2D.new()
	camera.zoom=Vector2(2,2)
	camera.limit_left=int(bounds.position.x)
	camera.limit_top=int(bounds.position.y)
	camera.limit_right=int(bounds.end.x)
	camera.limit_bottom=int(bounds.end.y)
	add_child(camera)
	camera.make_current()

func add_strip(frames:SpriteFrames, key:String, row:int, speed:float, looped:bool, count:int=4):
	frames.add_animation(key)
	frames.set_animation_speed(key,speed)
	frames.set_animation_loop(key,looped)
	for column in count:
		var cell=AtlasTexture.new()
		cell.atlas=TRAVELER_SHEET
		cell.region=Rect2(Vector2i(column,row)*FRAME_SIZE,FRAME_SIZE)
		frames.add_frame(key,cell)

func build_traveler_frames():
	traveler_frames=SpriteFrames.new()
	var row=0
	for direction in ["south","west","east","north"]:
		for state in MOVING_STATES:
			var speed=4 if state=="idle" else 12 if state=="run" else 8
			add_strip(traveler_frames,state+"_"+direction,row,speed,true)
			row+=1
	for key in ACTION_ROWS:
		add_strip(traveler_frames,key,row,10 if key=="death" else 18,false)
		row+=1
	# Hold the drawn bow until the player releases the attack.
	add_strip(traveler_frames,"charge",12+ACTION_ROWS.find("bow"),7,false,3)

func pose(state:String):
	if traveler_frames==null:build_traveler_frames()
	if sprite.sprite_frames!=traveler_frames:
		sprite.sprite_frames=traveler_frames
		sprite.position=Vector2(0,-17)
	var key=state
	sprite.flip_h=false
	if state in MOVING_STATES:
		var direction="north" if facing.y<0 else "south"
		if absf(facing.x)>absf(facing.y):direction="west" if facing.x<0 else "east"
		key=state+"_"+direction
	else:
		sprite.flip_h=facing.x<0
		if state=="attack":key="bow" if Saga.data.style==1 else "sweep" if combo==3 else "blade"
		if state=="cast":key="ice" if Saga.data.chapter>=4 else "fire"
	if sprite.animation!=key:sprite.play(key)

func _physics_process(dt):
	if not is_instance_valid(game) or game.is_locked():
		charging=false
		guard=false
		return
	cooldown=maxf(0,cooldown-dt)
	invincible=maxf(0,invincible-dt)
	action_time=maxf(0,action_time-dt)
	dodge_time=maxf(0,dodge_time-dt)
	spell_cd=maxf(0,spell_cd-dt)
	combo_window-=dt
	if combo_window<=0:combo=0
	var dir=Input.get_vector("left","right","up","down")
	guard=Input.is_action_pressed("guard") and not charging
	if dir!=Vector2.ZERO and dodge_time<=0:facing=dir
	if Input.is_action_just_pressed("style"):
		Saga.data.style=(int(Saga.data.style)+1)%3
		charging=false
		game.toast(["Espada e escudo","Arco de viagem","Magia elemental"][Saga.data.style])
	if Input.is_action_just_pressed("potion"):game.toast(Saga.drink())
	if Input.is_action_just_pressed("dodge") and cooldown<=0:
		dodge_time=.21
		invincible=.27
		target_dir=facing
		cooldown=.4
		charging=false
		game.sound("passo")
	if Input.is_action_just_pressed("special") and spell_cd<=0: special()
	if not guard and dodge_time<=0:
		if Saga.data.style==1:
			if Input.is_action_just_pressed("attack") and cooldown<=0:
				charging=true
				charge=0
			if charging:
				charge=minf(1.2,charge+dt)
				if Input.is_action_just_released("attack"):
					shoot_arrow()
		elif Input.is_action_pressed("attack") and cooldown<=0:attack()
	var speed=90.0+(14 if Saga.has_skill(0) else 0)+(5 if Saga.data.chapter>=4 else 0)
	var running=Input.is_key_pressed(KEY_SHIFT) or (is_instance_valid(game.ui.touch_controls) and game.ui.touch_controls.running)
	velocity=target_dir*244 if dodge_time>0 else dir*speed*(1.42 if running else 1.0)*(.42 if guard or charging else 1.0)
	move_and_slide()
	pose("dodge" if dodge_time>0 else action if action_time>0 else "charge" if charging else "guard" if guard else ("run" if running else "walk") if dir!=Vector2.ZERO else "idle")
	sprite.modulate=Color(1,.65,.6) if invincible>.27 else Color.WHITE
	Saga.data.hp=clampf(Saga.data.hp,0,Saga.max_hp())
	Saga.data.mp=minf(Saga.max_mp(),Saga.data.mp+dt*(3 if Saga.data.chapter>=1 else 2))
	Saga.data.pos=[position.x,position.y]
	queue_redraw()

func aim(reach:float):
	var e=game.closest_enemy(position,reach)
	if e!=null:return position.direction_to(e.position)
	return facing

func shoot_arrow():
	charging=false
	facing=aim(158)
	var amount=Saga.power()+int(10*charge)+(5 if Saga.has_skill(2) else 0)
	game.bolt(position,facing,225+charge*55,amount,false,"flecha",1.15)
	cooldown=.34
	act("attack",.22)
	game.sound("golpe")

func attack():
	if Saga.data.style==2:
		if Saga.data.mp<5:
			cooldown=.45
			game.toast("Mana insuficiente")
			return
		Saga.data.mp-=5
		facing=aim(135)
		game.bolt(position,facing,164,Saga.power()+6,false,"gelo" if Saga.data.chapter>=4 else "fogo",1.3)
		cooldown=.46
		act("cast",.28)
		game.sound("runa")
		return
	var w=int(Saga.data.weapon)
	var reach=[32,33,45][w]
	facing=aim(reach+6)
	combo=(combo%3)+1
	combo_window=.88
	for e in game.enemies.duplicate():
		if is_instance_valid(e) and not e.dead and position.distance_to(e.position)<reach+e.shadow_size and facing.dot(position.direction_to(e.position))>-.18:
			e.hit(Saga.power()+[1,6,2][w]+(7 if combo==3 else 0)+(4 if Saga.has_skill(1) else 0))
	cooldown=[.29,.54,.38][w]
	act("attack",.23)
	game.sound("golpe")

func act(s:String,t:float):
	action=s
	action_time=t

func special():
	if Saga.data.mp<15:
		game.toast("A técnica exige 15 de mana.")
		return
	Saga.data.mp-=15
	spell_cd=2.4
	act("surge",.3)
	game.sound("runa")
	if Saga.data.style==2 and Saga.data.magic=="cura" and (Saga.has_skill(4) or Saga.data.chapter>=5):
		Saga.data.hp=minf(Saga.max_hp(),Saga.data.hp+22)
		game.effect(position,Color("#a6e5a6"),28)
	elif Saga.data.style==2 and Saga.data.magic=="égide" and Saga.has_skill(3):
		invincible=1.8
		game.effect(position,Color("#a9e7f0"),29)
	else:
		var dir=aim(175)
		for a in [-.26,0,.26]:game.bolt(position,dir.rotated(a),176,Saga.power()+5,false,"lume",1.25)
	if Saga.has_skill(5):game.summon(position)

func hurt(dmg:int,source:Vector2):
	if invincible>0:return
	if guard and facing.dot(position.direction_to(source))>-.25:
		dmg=maxi(1,dmg/4)
		game.effect(position,Color("#d9d6b4"),11)
	if Saga.data.armor:dmg=maxi(1,dmg-3)
	if Saga.data.chapter>=3:dmg=maxi(1,dmg-2)
	if Saga.settings.get_value("game","gentle",false):dmg=maxi(1,dmg/2)
	Saga.data.hp-=dmg
	invincible=.6
	act("hurt",.2)
	if Saga.data.hp<=0:
		act("death",.8)
		pose("death")
		game.defeated()

func _draw():
	super()
	if guard:draw_arc(Vector2(0,-8),11,facing.angle()-.95,facing.angle()+.95,10,Color("#a9e4ed"),2)
	if action_time>0 and action=="attack" and Saga.data.style==0:
		draw_arc(Vector2(0,-8),20,facing.angle()-1.3,facing.angle()+.8,10,Color("#ffdc8f"),2)
	if charging:draw_rect(Rect2(-10,-37,20*charge/1.2,2),Color("#ffcd77"))

