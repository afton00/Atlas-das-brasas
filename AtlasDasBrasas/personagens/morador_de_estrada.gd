extends "res://scripts/ator.gd"

const Weather=preload("res://scripts/tempo.gd")
var game
var realm:int
var tag="field_neighbor"
var label="Morador da estrada"
var base:Vector2
var path:Array[Vector2i]=[]
var timer=0.0
var waypoint:=Vector2.ZERO
var schedule:=-1
var workplace=""
var sheltered=false

func setup(owner_game,c:int,sector_origin:Vector2,settlement:String,work:String=""):
	game=owner_game
	realm=c
	base=sector_origin
	workplace=work
	position=base+(Vector2(176,264) if work!="" else Vector2(287,280))
	label="Morador · "+settlement if work=="" else "Responsável · "+work
	make_actor(16+c,5)

func _physics_process(delta:float):
	if game.is_locked():return
	if game.hero.position.distance_squared_to(position)>280.0*280.0:return
	timer-=delta
	if timer<=0:
		timer=1.0
		var minutes=float(Saga.data.world_minutes)
		var slot=Weather.period(minutes)
		var sky=Weather.sky(realm,Weather.day(minutes),slot)
		sheltered=sky in [2,3,5]
		var activity=2 if slot in [0,3] or sheltered else slot-1
		if activity!=schedule or position.distance_to(waypoint)>5 and velocity.is_zero_approx():
			schedule=activity
			waypoint=base+[Vector2(264,264),Vector2(341,298),Vector2(422,281)][activity]
			if workplace!="":
				waypoint=base+[Vector2(159,263),Vector2(354,298),Vector2(408,281)][activity]
			var nav=game.world.trail
			var start=nav.open_cell(position)
			var goal=nav.open_cell(waypoint)
			if start.x>=0 and goal.x>=0:path=nav.grid.get_id_path(start,goal)
			if path.size()>1:path.pop_front()
	if path.is_empty():
		velocity=Vector2.ZERO
		pose("idle")
		return
	var point:Vector2=game.world.trail.center(path[0])
	if position.distance_to(point)<3:
		path.pop_front()
	else:
		facing=position.direction_to(point)
		velocity=facing*21
		move_and_slide()
		pose("walk")


func conversation()->String:
	if sheltered:return "Vou esperar o tempo melhorar na pousada. A estrada fica mais difícil de ler quando as marcas no chão se apagam."
	if schedule==2:return "O mercado já recolheu as bancas. Vou descansar antes da próxima viagem."
	if schedule==1:
		for neighbor in game.world.sites:
			if neighbor!=self and neighbor.get("tag")=="field_neighbor" and position.distance_to(neighbor.position)<34:
				return "Estávamos trocando notícias sobre a estrada. O quadro na encruzilhada indica os próximos povoados."
	if workplace!="":return "Hoje fico em "+workplace+". A porta está aberta para quem quiser consultar a bancada."
	return ""
