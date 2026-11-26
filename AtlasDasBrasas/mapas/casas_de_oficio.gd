extends RefCounted

const Resident=preload("res://personagens/morador_de_estrada.gd")
const DOOR=Vector2(158,248)
const BENCH=Vector2(293,132)
const SERVICES={
	"cidade_sabios":["livraria","Casa dos Livreiros","reading"], "grande_biblioteca":["biblioteca","Salão do Índice","reading"],
	"academia_arcana":["academia","Sala de Leitura da Academia","reading"], "escribas":["oficina","Oficina de Cópias","reading"],
	"mercado_sombras":["oficina","Oficina do Mercado","craft"], "portas_capital":["biblioteca","Arquivo da Muralha","reading"],
	"aldeia_cabos":["oficina","Oficina dos Cabos","craft"], "observatorio_zenite":["torre","Sala das Cartas","reading"],
	"aldeia_salgueiro":["boticario","Casa da Botica","care"], "santuario_mudas":["jardim","Casa das Guardiãs","care"],
	"cidade_chamines":["forja","Forja da Cisterna","craft"], "vila_mineiros":["oficina","Oficina do Vagão","craft"]
}

static func populate(w,base:Vector2,area:Array):
	if SERVICES.has(area[2]):
		var service:Array=SERVICES[area[2]]
		w.margem(base+DOOR,service[0],"field_service",service[1],true,15)
		var worker=Resident.new()
		w.objects.add_child(worker)
		var realm=w.Sectors.realm_at(w.Sectors.at(base))
		worker.setup(w.game,realm,base,area[0],service[1])
		w.sites.append(worker)

static func build(w,realm:int,area:Array):
	var service:Array=SERVICES[area[2]]
	var kind=service[2]
	for y in 20:
		for x in 32:
			var tile=16 if y<2 or x in [0,31] else 14 if kind=="reading" else 15
			w.terrain.set_cell(Vector2i(x,y),0,Vector2i(tile,realm))
	w.walls(Rect2(0,0,512,320))
	w.prop(Vector2(255,290),5,"field_exit","Voltar à rua",false,8)
	var art=["biblioteca","livraria"] if kind=="reading" else ["boticario","plant"] if kind=="care" else ["oficina","mineiro"]
	w.margem(Vector2(135,127),art[0],"","",true,14)
	w.margem(Vector2(391,177),art[1],"","",true,9)
	w.prop(BENCH,10,"field_bench",service[1],true,10)

static func work(g,realm:int,area:Array):
	var service:Array=SERVICES[area[2]]
	var kind=service[2]
	var text=area[3]
	var choices=[]
	match kind:
		"reading":choices.append(["Consultar enciclopédia",g.ui.codex])
		"care":choices.append(["Consultar rondas de Lia",g.ui.care_index])
		"craft":choices.append(["Trabalhar na bancada",g.ui.bag])
	choices.append(["Fechar o livro",g.ui.play])
	g.ui.dialogue(realm,service[1],text,choices,true)
