extends "res://scripts/ator.gd"

var home=Vector2.ZERO
var clock=0.0
var c=0
var resident=false
var route=[Vector2.ZERO,Vector2(15,0),Vector2(15,-8),Vector2(0,-8)]
var waypoint=0
var pause=1.0
var locked:Callable

func setup(id:int,spot:Vector2,freeze:Callable,local=false):
	resident=local
	c=id
	home=spot
	position=spot
	locked=freeze
	if resident:
		route=[Vector2.ZERO,Vector2(24,0),Vector2(26,-8),Vector2(8,-8)]
	make_actor(16+id if resident else 4+id,5)

func _physics_process(dt):
	if locked.call():
		pose("idle")
		return
	if pause>0:
		pause-=dt
		pose("idle")
		return
	var dest=home+route[waypoint]
	if position.distance_to(dest)<1:
		pause=2.6
		waypoint=(waypoint+1)%route.size()
	else:
		facing=position.direction_to(dest)
		velocity=facing*12
		move_and_slide()
		pose("walk")

