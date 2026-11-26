extends Node2D
# Small ambient details drawn only inside the camera viewport.
const Weather=preload("res://scripts/tempo.gd")
var weather_kind=0
var world
var time=0.0
var frame=0.0
func _process(dt):
	if world.game.is_locked():return
	time+=dt
	frame+=dt
	if frame>.10:
		frame=0
		if not world.interior and is_instance_valid(world.game.hero):
			var minutes=float(Saga.data.world_minutes)
			weather_kind=Weather.sky(world.game.region(),Weather.day(minutes),Weather.period(minutes))
			var light=Weather.lighting(minutes)
			if weather_kind in [1,2,3,5]:light*=Color("#e5ecf7")
			world.modulate=light
		queue_redraw()

func _draw():
	if not is_instance_valid(world.game.hero) or not world.game.active:return
	var reduced=Saga.settings.get_value("game","still",false)
	if reduced:return
	var h=world.game.hero.position
	if world.interior:
		for i in 12:
			var p=Vector2(fmod(39*i+time*4,482)+10,68+fmod(27*i-time*3+3200,240))
			draw_rect(Rect2(p,Vector2.ONE),Color("#b4ac8055"))
		return
	var lo=Vector2i((h-Vector2(270,170))/16)
	var hi=Vector2i((h+Vector2(270,170))/16)
	for y in range(lo.y,hi.y+1):
		for x in range(lo.x,hi.x+1):
			if (x+y*3)%5!=0:continue
			var a=world.terrain.get_cell_atlas_coords(Vector2i(x,y)).x
			var p=Vector2(x,y)*16
			if a in [8,9,10]:
				p+=Vector2(5+floor(sin(time*1.3+y)*2),8)
				draw_line(p,p+Vector2(5,0),Color("#b3ded599"),1)
			elif a in [0,1,2,3,17] and (x*7+y)%11==0:
				p+=Vector2(4+floor(sin(time*1.4+x)*2),5+floor(cos(time+y)*2))
				draw_rect(Rect2(p,Vector2(2,1)),Color("#f8d998"))

	if weather_kind>=2:
		draw_weather()

func draw_weather():
	var area:Rect2=get_canvas_transform().affine_inverse()*get_viewport_rect()
	var number=48 if weather_kind==3 else 27 if weather_kind==5 else 18
	for i in number:
		var dx=time*(-65 if weather_kind==4 else -10)
		var dy=time*(96 if weather_kind in [2,3] else 13 if weather_kind==5 else 4)
		if weather_kind==5:dx+=sin(time+i)*4
		var point=area.position+Vector2(fposmod(i*113.7+dx,area.size.x),fposmod(i*53.1+dy,area.size.y))
		match weather_kind:
			2,3:draw_line(point,point+Vector2(-2,5),Color("#b8daea99"),1)
			4:draw_line(point,point+Vector2(5,-1),Color("#e8ddb583"),1)
			5:draw_rect(Rect2(point.round(),Vector2(2,2)),Color("#ebedf5bd"))
