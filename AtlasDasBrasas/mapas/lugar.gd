extends Node2D

var solid=false
var tag=""
var label=""
var active=false
var highlighted=false
var tick=0.0
var static_art:Texture2D
var art:Sprite2D
var shadow_size=10.0
var sound_radius=34.0

func setup(id:String,title:String,tex:Texture2D,is_solid:bool,shadow:float=10.0):
	solid=is_solid
	tag=id
	label=title
	shadow_size=shadow
	set_process(id!="")
	if id=="":
		static_art=tex
	else:
		art=Sprite2D.new()
		art.texture=tex
		art.offset=Vector2(0,-tex.get_height()/2.0)
		add_child(art)
	if id in ["care","nurse"]:
		var sign=Sprite2D.new()
		sign.texture=preload("res://mapas/margens/insignia.png")
		sign.position=Vector2(round(tex.get_width()*.38),-6)
		add_child(sign)
	if solid:
		var body=StaticBody2D.new()
		body.collision_layer=1
		body.collision_mask=0
		var col=CollisionShape2D.new()
		var shape=RectangleShape2D.new()
		shape.size=Vector2(shadow*1.45,7)
		col.position.y=-4
		col.shape=shape
		body.add_child(col)
		add_child(body)

func _process(dt):
	if active or highlighted:
		tick+=dt
		queue_redraw()

func _draw():
	draw_set_transform(Vector2(0,-2),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO,shadow_size,Color(0.04,0.12,0.11,0.29))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if static_art:
		draw_texture(static_art,Vector2(-static_art.get_width()*.5,-static_art.get_height()))
	if art and (active or highlighted):
		var y=-art.texture.get_height()-6+floor(sin(tick*3)*1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(0,y-5),Vector2(4,y),Vector2(0,y+5),Vector2(-4,y)]),Color("#503d45"))
		draw_colored_polygon(PackedVector2Array([Vector2(0,y-3),Vector2(2,y),Vector2(0,y+3),Vector2(-2,y)]),Color("#ffdc86"))

