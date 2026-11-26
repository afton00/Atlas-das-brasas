extends "res://scripts/ator.gd"

const BEAST_PATH="res://personagens/bestiario/"
const Bestiary=preload("res://interfaces/bestiario.gd")
static var beast_frames:Dictionary={}
var species:String
var encounter_noted=false
var skin_scale=1.0
var skin_height=0.0
var game
var home:Vector2
var kind=0
var tier=0
var hp=20
var hp_max=20
var dead=false
var phase="wait"
var timer=.8
var pattern=0
var dragon_clock=0.0
var slowed=0.0
var boss=false
var quest_id=""
var aim_dir=Vector2.DOWN
var age=0.0
var hit_time=0.0

func setup(g,k,c,pos:Vector2,is_boss:bool,id:String):
	game=g
	kind=k
	tier=c
	boss=is_boss
	quest_id=id
	position=pos
	home=pos
	hp_max=(155 if k==3 else 40+c*10 if is_boss else 17+c*4)
	hp=hp_max
	shadow_size=[7,8,10,23][k]
	species=Bestiary.species_for(tier,kind,quest_id,boss)
	if boss and tier in [0,5]:skin_scale=1.35
	make_actor(10+k,shadow_size*.65)
	collision_layer=4
	timer=.45+fmod(pos.x,.6)

func note_encounter():
	if encounter_noted:return
	encounter_noted=true
	var key="selo%d"%tier if boss else species
	if Bestiary.record(Saga.data,key):
		Saga.save()
		game.toast("Bestiário atualizado · "+Bestiary.title(key))

func bestiary_name()->String:
	return Bestiary.GUARDIAN_NAMES[tier]

func portrait()->Texture2D:
	return load(BEAST_PATH+"g%d.png"%tier)

func pose(state:String):
	if not beast_frames.has(species):
		var texture=load(BEAST_PATH+species+".png")
		var frames=SpriteFrames.new()
		frames.add_frame("default",texture)
		beast_frames[species]=frames
	if sprite.sprite_frames!=beast_frames[species]:
		sprite.sprite_frames=beast_frames[species]
		skin_height=sprite.sprite_frames.get_frame_texture("default",0).get_height()
	var planted=0.0
	var stretch=Vector2.ONE
	var tilt=0.0
	match state:
		"idle":
			stretch.y+=sin(age*3.2)*.015
		"walk":
			var stride=sin(age*(10.5 if kind==1 else 8.0))
			planted=-absf(stride)*1.6
			tilt=stride*.038
		"cast":
			stretch=Vector2(1.05,.94)
			tilt=-.035
		"attack":
			stretch=Vector2(.96,1.06)
			tilt=.07
		"hurt":
			tilt=-.075
		"death":
			var fall=create_tween().set_parallel()
			fall.tween_property(sprite,"rotation",.27 if facing.x>0 else -.27,.22)
			fall.tween_property(sprite,"modulate:a",.35,.32)
			return
	var leftward_asset=species in ["serpente","corvo"]
	sprite.flip_h=(facing.x>0) if leftward_asset else (facing.x<0)
	sprite.rotation=-tilt if facing.x<0 else tilt
	sprite.scale=stretch*skin_scale
	sprite.position.y=roundf(2+planted-skin_height*sprite.scale.y*.5)

func shielded():return kind==3 and fmod(dragon_clock,8.0)<4.8
func hit(amount:int):
	if dead:return
	note_encounter()
	if shielded():
		game.effect(position,Color("#94d5ea"),23)
		return
	hp-=amount
	hit_time=.18
	game.effect(position,Color("#ffce89"),9)
	if hp<=0:
		dead=true
		pose("death")
		game.enemy_fell(self)
		return
	queue_redraw()

func _physics_process(dt):
	if game.is_locked() or dead or not is_instance_valid(game.hero):return
	var p=game.hero.position
	var distance=position.distance_to(p)
	if not encounter_noted and distance<138 and get_viewport_rect().has_point(get_global_transform_with_canvas().origin):
		note_encounter()
	if not boss and quest_id.begins_with("roam") and not game.world.interior:
		var safe_spot=Saga.origin(game.region())+game.world.HOME+Vector2(0,40)
		if p.distance_to(safe_spot)<53:
			if position.distance_to(home)>4:
				velocity=position.direction_to(home)*30
				move_and_slide()
				pose("walk")
			else:pose("idle")
			phase="wait"
			return
	if distance>260 and not boss:return
	age+=dt
	dragon_clock+=dt
	hit_time=maxf(0,hit_time-dt)
	slowed=maxf(0,slowed-dt)
	sprite.modulate=Color("#ffb0a2") if hit_time>0 else Color.WHITE
	timer-=dt
	var range_limit=[20,52,94,125][kind]
	var detect=145 if not boss else 260
	velocity=Vector2.ZERO
	match phase:
		"wait":
			if distance<=detect:
				facing=position.direction_to(p)
				if distance>range_limit:
					velocity=facing*([29,42,23,27][kind]+tier*1.1)
				elif timer<=0:
					aim_dir=facing
					phase="windup"
					timer=[.48,.52,.76,.82][kind]
			elif position.distance_to(home)>3:velocity=position.direction_to(home)*22
		"windup":
			if timer<=0:
				phase="strike"
				timer=.24
				if kind>=2:
					var spread=[0.0] if kind==2 else [-.25,0,.25] if pattern%2==0 else [-.52,-.26,0,.26,.52]
					for a in spread:game.bolt(position,aim_dir.rotated(a),83+tier*4,1 if quest_id=="treino" else 6+tier*2,true,"brasa",2.3)
					pattern+=1
		"strike":
			if kind<2:
				velocity=aim_dir*(150 if kind==1 else 65)
				if distance<22:game.hero.hurt(6+tier*2,position)
			if timer<=0:
				phase="wait"
				timer=.9 if kind!=3 else .7
	if slowed>0:velocity*=.45
	move_and_slide()
	pose("hurt" if hit_time>0 else "cast" if phase=="windup" else "attack" if phase=="strike" else "walk" if velocity.length()>1 else "idle")
	queue_redraw()

func _draw():
	super()
	if dead:return
	if hp<hp_max or boss:
		draw_rect(Rect2(-12,sprite.position.y*2-7,24,2),Color("#493d45"))
		draw_rect(Rect2(-12,sprite.position.y*2-7,24.0*hp/hp_max,2),Color("#ffac85"))
	if phase=="windup":
		draw_arc(Vector2.ZERO,shadow_size+4,0,TAU,24,Color("#ffb07c"),1.3)
		draw_line(Vector2.ZERO,aim_dir*(38 if kind==1 else 17),Color("#f4a778"),2)
	if kind==3 and shielded():
		var color=Color("#e3a359") if dragon_clock<0 or fmod(dragon_clock,8)<1.6 else Color("#83c2e0") if fmod(dragon_clock,8)<3.2 else Color("#c4edff")
		draw_arc(Vector2(0,-21),29,0,TAU,36,color,2)

