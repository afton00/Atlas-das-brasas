extends RefCounted

const KEYS=["labirinto_ocre","gelo_azul","gruta_raizes","gruta_brasa"]
const TITLES=["A olaria esquecida","O abrigo dos guias","O herbário das raízes","A sala do fundidor"]
const CONTACTS=["Nara, oleira","Lino, guia","Iara, guardiã","Bento, fundidor"]
const ITEMS=["Molde do primeiro canal","Carta da neve azul","Caderno das raízes","Cunho do primeiro tear"]
const HINTS=["Uma marca de cerâmica no canto sudoeste repete a do antigo canal.","Uma seta riscada no gelo aponta para baixo da galeria oeste.","Sementes secas formam uma linha até a parede sudoeste.","Uma sequência de rebites termina na parede sudoeste."]
const TALES=["Meu avô assinava os tijolos por baixo. Quando a cidade cresceu, os nomes ficaram escondidos. Este molde conserva uma assinatura.","Minha irmã anotava as primeiras neves daqui. Em cada página ela marcava a data e a altitude, para que outro guia pudesse comparar os anos.","Antes de a copa se fechar, as folhas que cresciam aqui eram outras. Guardei cada desenho com a data e o lugar da coleta.","Esta peça marcou as rodas do primeiro tear. O ritmo que agora se ouve na fortaleza começou nesta oficina."]
const PANEL=Vector2(85,239)
const KEEPER=Vector2(364,119)
const ARRIVAL=Vector2(253,254)

static func index_for(area:Array)->int:
	return -1 if area.is_empty() else KEYS.find(area[2])

static func draw_room(w,realm:int,i:int):
	for y in 20:
		for x in 32:
			var wall=x in [0,31] or y<2 or (y==10 and x in range(5,24) and x not in [12,13,14])
			w.terrain.set_cell(Vector2i(x,y),0,Vector2i(16 if wall else 15,realm))
	w.walls(Rect2(0,0,512,320))
	w.prop(Vector2(255,290),5,"field_chamber_exit","Voltar à galeria",false,9)
	w.prop(Vector2(151,91),10,"field_script","Memória da galeria",false,8)
	var portrait=AtlasTexture.new()
	portrait.atlas=load("res://animacoes/a%d.png"%(16+realm))
	portrait.region=Rect2(Vector2.ZERO,portrait.atlas.get_size()/Vector2(4,9))
	w.place(KEEPER,portrait,"field_witness",CONTACTS[i],false,7)
	var scenery=[["poco","stones"],["crystals","rock"],["fungus","plant"],["forja","oficina"]][i]
	for j in 2:w.margem(Vector2(142+j*224,219),scenery[j],"","",false,12)

static func read_clue(g,realm:int,i:int):
	g.ui.dialogue(realm,"Uma marca fora da trilha",HINTS[i],[["Examinar a parede",func():
		Saga.data.expedition["passage_"+KEYS[i]]=true
		Saga.save()
		for site in g.world.sites:
			if site.tag=="field_passage":site.visible=true
		g.ui.play()]],true)

static func witness(g,realm:int,i:int):
	if "custodia_"+KEYS[i] not in Saga.data.kills:
		g.toast("A sentinela ainda guarda o arquivo desta câmara.")
		return
	var flag="archive_"+KEYS[i]
	var choices=[["Voltar",g.ui.play]]
	if not Saga.data.expedition.get(flag,false):
		choices.push_front(["Receber "+["o molde","a carta","o caderno","o cunho"][i],func():
			if not Saga.data.expedition.get(flag,false):
				Saga.data.expedition[flag]=true
				Saga.data.points+=1
				Saga.award(55)
				Saga.save()
			g.ui.play()
			g.toast(ITEMS[i]+" · um ponto de habilidade.")])
	g.ui.dialogue(realm,TITLES[i],TALES[i],choices,true,{"nome":CONTACTS[i].split(",")[0],"retrato":"res://personagens/morador_%d.png"%realm})
