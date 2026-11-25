extends "res://interfaces/rondas.gd"

const Weather=preload("res://scripts/tempo.gd")
const SkyGlyph=preload("res://interfaces/ceu.gd")
const Place=preload("res://mapas/lugar.gd")
const LOG_NAMES=["Junco","Lume"]

func sky_glyph(parent,kind:int,night:bool,x,y,w,h):
	var icon=SkyGlyph.new()
	icon.kind=kind
	icon.night=night
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	rect(icon,x,y,w,h)
	return icon

func beside_instrument(tag:String)->bool:
	if game.world.interior:return false
	var near=game.world.nearest(game.hero.position)
	return near is Place and near.tag==tag

func track_weather(enabled:bool):
	Saga.data.rain_route=enabled
	if enabled:Saga.data.care_route=-1
	Saga.save()
	play()

func weather_page(c:int):
	var minutes=float(Saga.data.world_minutes)
	var d=Weather.day(minutes)
	var period=Weather.period(minutes)
	panel_page("weather",Weather.date_name(d)+"   /   "+Weather.clock_text(minutes), "Boletim das margens")
	var picture=tex(view,"res://mapas/margens/vista-%d.png"%c,108,150,274,144,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	picture.modulate=Weather.lighting(minutes)
	label(view,Saga.regions[c].place,108,298,277,35,20,GOLD,true)
	label(view,"Previsão local",406,143,432,38,22,SEA_GLASS,true)
	for i in 3:
		var slot=(period+i)%4
		var relative_day=d+floori((period+i)/4.0)
		var kind=Weather.sky(c,relative_day,slot)
		var x=406+i*149
		box(view,x,190,141,108,PANEL,LINE)
		sky_glyph(view,kind,slot in [0,3],x+10,202,44,35)
		label(view,"Agora" if i==0 else "%02dh"%(slot*6),x+62,201,71,36,17,GOLD,true)
		label(view,Weather.SKY_NAMES[kind],x+9,250,124,33,16)
	label(view,"A água dos viveiros",406,309,439,35,22,SEA_GLASS,true)
	var hint=game.rain_objective()
	if int(Saga.data.rain_recipient)>=0:hint="A carroça abasteceu o viveiro de "+LOG_NAMES[int(Saga.data.rain_recipient)]+". O relatório está no caderno."
	elif int(Saga.data.rain_day)<0:hint="Dois viveiros pedem água. Leia o pedido no quadro ao sul da oficina de Iria, na Vila do Junco."
	label(view,hint,407,349,438,64,17)
	label(view,"A previsão muda a cada seis horas no mundo do jogo.",108,342,270,72,16,MUTED)
	button(view,"Voltar à aventura",108,449,190,40,play)
	if int(Saga.data.rain_recipient)>=0:
		button(view,"Relatório dos viveiros",594,449,256,40,cart_page,true)
	elif int(Saga.data.rain_day)<0 and beside_instrument("weather_board"):
		button(view,"Ler o pedido",594,449,256,40,rain_brief,true)
	else:
		button(view,"Retomar trilha principal" if Saga.data.rain_route else "Seguir a expedição",594,449,256,40,track_weather.bind(not Saga.data.rain_route),true)
	if c==game.region() and game.world.interior and c<6 and game.world.room_type=="hall":
		button(view,"Aguardar o amanhecer",316,449,250,40,wait_for_morning.bind(c))
	focus_default()

func wait_for_morning(c:int):
	if not game.world.interior or game.world.room_type!="hall" or game.region()!=c or c>=6:return
	var now=float(Saga.data.world_minutes)
	var dawn=Weather.day(now)*1440.0+360.0
	Saga.data.world_minutes=dawn if dawn>now else dawn+1440.0
	Saga.save()
	weather_page(c)

func rain_brief():
	panel_page("rain_brief","Pedido da cooperativa   /   Vila do Junco","A água dos viveiros")
	tex(view,"res://mapas/estacao/carroca.png",117,162,224,146)
	label(view,"Uma carroça, dois canteiros",375,154,474,45,24,SEA_GLASS,true)
	label(view,"As mudas do Junco e de Lume ocupam canteiros iguais, com o mesmo solo e a mesma reserva inicial. O depósito dispõe de uma carroça para levar água a quem recebeu menos chuva.",375,203,470,119,18)
	label(view,"O pluviômetro mede a altura da chuva acumulada. Um milímetro equivale a um litro por metro quadrado. Registre os totais do mesmo dia nos dois viveiros. Depois, volte à carroça no Junco.",109,330,733,92,18)
	button(view,"Mais tarde",108,449,169,40,play)
	button(view,"Assumir a entrega",594,449,256,40,accept_delivery,true)
	focus_default()

func accept_delivery():
	if not beside_instrument("weather_board") or int(Saga.data.rain_day)>=0:return
	Saga.data.rain_day=Weather.day(Saga.data.world_minutes)-1
	track_weather(true)

func gauge_page(c:int):
	if c not in [0,1] or not beside_instrument("gauge") or game.region()!=c:return
	var assigned=int(Saga.data.rain_day)>=0
	var d=int(Saga.data.rain_day) if assigned else Weather.day(Saga.data.world_minutes)-1
	var mm=Weather.daily_rain(c,d)
	panel_page("gauge","Viveiro de "+LOG_NAMES[c]+"   /   "+Weather.date_name(d), "Leitura do pluviômetro")
	box(view,108,154,246,261,PANEL,LINE)
	tex(view,"res://mapas/estacao/pluviometro.png",124,189,84,151)
	var foot=372
	line(view,227,178,35,194,LINE)
	line(view,230,181,29,191,INK)
	if mm>0:line(view,230,foot-mm*12,29,mm*12,SEA_GLASS)
	for tick in range(0,17,2):
		var y=foot-tick*12
		line(view,253,y,15,1,GOLD)
		label(view,str(tick),274,y-11,52,23,15,MUTED)
	label(view,"mm",277,385,48,24,15,GOLD)
	label(view,"Registro de 24 horas",382,157,461,42,26,SEA_GLASS,true)
	label(view,"%d mm de chuva"%mm,382,211,461,56,34,PALE,true)
	label(view,"A régua mostra a coleta entre 0h e 24h do dia indicado. Mesmo que o céu mude durante a viagem, o arquivo conserva essa leitura.",383,271,444,95,18)
	if not assigned:label(view,"A cooperativa recebe pedidos no quadro do Junco.",383,370,447,43,16,MUTED)
	button(view,"Voltar à estrada",108,449,190,40,play)
	if assigned and not Saga.data.rain_readings.has(str(c)):
		button(view,"Anotar a leitura",594,449,256,40,record_gauge.bind(c),true)
	focus_default()

func record_gauge(c:int):
	if not beside_instrument("gauge") or game.region()!=c or int(Saga.data.rain_day)<0:return
	Saga.data.rain_readings[str(c)]=Weather.daily_rain(c,int(Saga.data.rain_day))
	track_weather(true)
	toast("Leitura anotada · "+game.rain_objective())

func cart_page(feedback:String=""):
	var complete=int(Saga.data.rain_recipient)>=0
	panel_page("rain_cart","Cooperativa do Junco   /   Caderno de campo","Relatório dos viveiros" if complete else "Despacho da carroça")
	var readings=Saga.data.rain_readings
	for c in 2:
		var x=108+c*374
		box(view,x,151,359,123,PANEL,LINE)
		tex(view,"res://mapas/margens/vista-%d.png"%c,x+8,159,115,106,TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		label(view,LOG_NAMES[c],x+138,160,209,32,21,GOLD,true)
		var amount=("%d mm"%int(readings[str(c)])) if readings.has(str(c)) else "Sem leitura"
		label(view,amount,x+138,198,209,56,25,PALE,true)
	var message=game.rain_objective()
	if complete:message="A carroça levou água para "+LOG_NAMES[int(Saga.data.rain_recipient)]+". As mudas desse viveiro voltaram a brotar. A cooperativa registrou sua entrega e concedeu 60 XP."
	elif readings.size()==2:message="Os registros cobrem as mesmas 24 horas. Qual viveiro recebeu menos chuva e deve receber a carroça?"
	label(view,message,110,292,733,72,19)
	label(view,feedback if feedback!="" else Weather.date_name(int(Saga.data.rain_day))+" · Acumulado em 24 horas" if int(Saga.data.rain_day)>=0 else "O pedido está no quadro do Junco.",110,366,734,62,17,GOLD)
	button(view,"Voltar à aventura",108,449,190,40,play)
	if not complete and readings.size()==2 and beside_instrument("water_cart"):
		for c in 2:button(view,"Enviar a "+LOG_NAMES[c],382+c*236,449,220,40,deliver_water.bind(c))
	elif not complete:button(view,"Seguir a expedição",594,449,256,40,track_weather.bind(true),true)
	focus_default()

func deliver_water(c:int):
	var readings=Saga.data.rain_readings
	if not beside_instrument("water_cart") or c not in [0,1] or int(Saga.data.rain_recipient)>=0 or readings.size()!=2:return
	if int(readings[str(c)])>int(readings[str(1-c)]):
		cart_page("%s já recebeu mais água da chuva. Compare os dois valores e escolha o menor."%LOG_NAMES[c])
		return
	Saga.data.rain_recipient=c
	Saga.data.rain_route=false
	Saga.award(60)
	Saga.save()
	game.world.refresh()
	game.sound("sino")
	cart_page()
