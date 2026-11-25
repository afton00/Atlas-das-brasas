extends Node2D
var game
var dir:Vector2
var speed:float
var damage:int
var enemy:bool
var kind:String
var life:float
func _physics_process(dt):
	if game.is_locked():return
	var step=dir*speed*dt
	var query=PhysicsRayQueryParameters2D.create(global_position,global_position+step,1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	position+=step
	life-=dt
	if enemy:
		if position.distance_to(game.hero.position)<10:
			game.hero.hurt(damage,position-dir*12)
			queue_free()
			return
	else:
		for e in game.enemies:
			if is_instance_valid(e) and not e.dead and position.distance_to(e.position)<e.shadow_size+5:
				if kind=="gelo":e.slowed=1.3
				e.hit(damage)
				queue_free()
				return
	if life<=0:queue_free()

func _draw():
	var at=Vector2(0,-7)
	if kind=="flecha":
		draw_line(at-dir*9,at+dir*3,Color("#e5cba0"),2)
		draw_line(at,at+dir*4,Color.WHITE,2)
	else:
		var col=Color("#a1dfde") if kind in ["gelo","lume"] else Color("#fa956c")
		draw_line(at-dir*7,at,col.darkened(.3),3)
		draw_circle(at,4 if enemy else 3,col)
		draw_circle(at,1.5,Color("#fff0bd"))

