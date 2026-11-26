extends RefCounted

const Weather=preload("res://scripts/tempo.gd")
const Sectors=preload("res://mapas/setores.gd")
const Lands=preload("res://mapas/territorios.gd")
const Stops=[
	[Vector2i(8,2),Vector2i(10,0),Vector2i(11,3)],
	[Vector2i(8,7),Vector2i(10,4),Vector2i(8,6)],
	[Vector2i(6,7),Vector2i(7,7),Vector2i(4,6)],
	[Vector2i(1,7),Vector2i(0,4),Vector2i(3,5)]
]
const Dock=Vector2(370,285)
const Letters=["A lista de rações","O perfil da serra","O registro de sementes","A carta dos mineiros"]
const Recipients=[Vector2i(8,4),Vector2i(5,4),Vector2i(1,4),Vector2i(8,0)]

static func today(realm:int)->Vector2i:
	return Stops[realm-2][posmod(Weather.day(Saga.data.world_minutes)+realm,3)]

static func add_trader(w,cell:Vector2i,realm:int):
	if realm<2 or cell not in Stops[realm-2]:return
	var trader=w.margem(Sectors.origin(cell)+Dock,"provisoes","field_caravan","Caravana de passagem",false,9)
	trader.visible=cell==today(realm)
	w.caravans.append(trader)

static func refresh(w):
	for trader in w.caravans:
		var cell=Sectors.at(trader.position)
		trader.visible=cell==today(Sectors.realm_at(cell))

static func board(cell:Vector2i,realm:int)->String:
	if realm<2 or cell not in Stops[realm-2]:return ""
	return "\nCaravana de hoje · "+Lands.AREAS[Sectors.key(today(realm))][0]

static func talk(g,realm:int):
	var i=realm-2
	var flag="letter_"+str(realm)
	var state=int(Saga.data.expedition.get(flag,0))
	var name_place=Lands.AREAS[Sectors.key(Recipients[i])][0]
	var text="Levarei minha banca a outro povoado amanhã."
	var choices=[]
	if state==0:
		text+=" Você pode levar uma carta até o posto de pesquisa em "+name_place+"?"
		choices.append(["Aceitar a carta",func():
			Saga.data.expedition[flag]=1
			Saga.save()
			g.ui.play()
			g.toast("Carta guardada · "+name_place)])
	elif state==1:text+=" A carta ainda precisa chegar ao posto de pesquisa em "+name_place+"."
	else:text+=" Já recebi a notícia da sua entrega."
	choices.append(["Trocar 2 ervas",func():
		g.ui.play()
		if Saga.data.herbs<2:
			g.toast("A bolsa precisa conter duas ervas para a troca.")
			return
		Saga.data.herbs-=2
		Saga.data.ore+=2
		Saga.save()
		g.toast("Troca concluída · dois minérios.")])
	choices.append(["Seguir viagem",g.ui.play])
	g.ui.dialogue(realm,"Caravana de passagem",text+" Troco duas ervas por dois minérios.",choices,true)

static func offer_delivery(g,cell:Vector2i)->bool:
	var i=Recipients.find(cell)
	if i<0:return false
	var flag="letter_"+str(i+2)
	if int(Saga.data.expedition.get(flag,0))!=1:return false
	g.ui.dialogue(Sectors.realm_at(cell),Letters[i],"A destinatária reconhece o lacre da caravana. A cópia da carta ficará no arquivo do posto.",[["Entregar a carta",func():
		if int(Saga.data.expedition.get(flag,0))==1:
			Saga.data.expedition[flag]=2
			Saga.data.potions+=1
			Saga.award(25)
			Saga.save()
		g.ui.play()
		g.toast("Carta entregue · uma poção de viagem.")],["Examinar o posto",g.world.Expedition.Studies.examine.bind(g,cell,Sectors.realm_at(cell))]],true)
	return true
