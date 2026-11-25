extends Node2D
# Small ambient details drawn only inside the camera viewport.
var world
var time=0.0
var frame=0.0
func _process(dt):
	if world.game.is_locked():return
	time+=dt
	frame+=dt
	if frame>.12:
		frame=0
		queue_redraw()

func _draw():
	if not is_instance_valid(world.game.hero) or not world.game.active:return
	var h=world.game.hero.position
	if world.interior:
		for i in 12:
			var p=Vector2(fmod(39*i+time*4,482)+10,68+fmod(27*i-time*3+3200,240))
			draw_rect(Rect2(p,Vector2.ONE),Color("#b4ac8055"))
		return
	var lo=Vector2i((h-Vector2(270,170))/16)
	var hi=Vector2i((h+Vector2(270,170))/16)
	for y in range(maxi(0,lo.y),mini(64,hi.y+1)):
		for x in range(maxi(0,lo.x),mini(144,hi.x+1)):
			if (x+y*3)%5!=0:continue
			var a=world.terrain.get_cell_atlas_coords(Vector2i(x,y)).x
			var p=Vector2(x,y)*16
			if a in [8,9,10]:
				p+=Vector2(5+floor(sin(time*1.3+y)*2),8)
				draw_line(p,p+Vector2(5,0),Color("#b3ded599"),1)
			elif a in [0,1,2,3,17] and (x*7+y)%11==0:
				p+=Vector2(4+floor(sin(time*1.4+x)*2),5+floor(cos(time+y)*2))
				draw_rect(Rect2(p,Vector2(2,1)),Color("#f8d998"))

