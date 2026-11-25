extends CharacterBody2D

const STATES=["idle","walk","run","attack","cast","dodge","hurt","death","interact"]
static var collections:Dictionary={}
var sprite:AnimatedSprite2D
var facing=Vector2.DOWN
var visual=0
var idle_clock=0.0
var flash=0.0
var shadow_size=6
var actor_id=0

func make_actor(id:int,radius:float):
	actor_id=id
	visual=id
	collision_layer=2
	collision_mask=1
	var col=CollisionShape2D.new()
	var shape=CircleShape2D.new()
	shape.radius=radius
	col.shape=shape
	add_child(col)
	sprite=AnimatedSprite2D.new()
	sprite.centered=true
	add_child(sprite)
	pose("idle")

func pose(state:String):
	var idx=actor_id
	if actor_id==0:
		if state=="attack": idx=3
		elif abs(facing.x)>abs(facing.y): idx=2
		elif facing.y<0: idx=1
	if not collections.has(idx):
		var tex=load("res://animacoes/a%d.png"%idx)
		var size=Vector2(tex.get_width()/4,tex.get_height()/9)
		var frames=SpriteFrames.new()
		for a in STATES.size():
			var n=STATES[a]
			frames.add_animation(n)
			frames.set_animation_loop(n,n in ["idle","walk","run"])
			frames.set_animation_speed(n,4 if n=="idle" else 12)
			for j in 4:
				var sub=AtlasTexture.new()
				sub.atlas=tex
				sub.region=Rect2(Vector2(j,a)*size,size)
				frames.add_frame(n,sub)
		collections[idx]=frames
	sprite.sprite_frames=collections[idx]
	sprite.flip_h=(facing.x<0 and idx in [2,3]) or (actor_id in [11,13] and facing.x>0)
	sprite.play(state)
	var frame=sprite.sprite_frames.get_frame_texture(state,0)
	sprite.position.y=-frame.get_height()/2.0+6

func _draw():
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.34))
	draw_circle(Vector2.ZERO,shadow_size,Color(0.04,0.1,0.1,.38))

