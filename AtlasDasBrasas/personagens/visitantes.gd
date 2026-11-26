extends RefCounted

const REGIAO = ["", "livia", "eron", "asterion", "nox", "kael"]
const ARTE = "res://personagens/visitas/"
const VISITANTES = {
	"livia": {
		"nome": "Lívia", "papel": "Estudiosa da magia",
		"fala": "Olhe a margem deste poema. Alguém raspou uma palavra com tanta força que a pena marcou a página seguinte. Bento guarda as duas folhas.",
		"pergunta": "O que sobrou da palavra?",
		"resposta": "Um pingo e duas hastes. Seria fácil inventar o resto. Prefiro pôr as cópias lado a lado e procurar no segundo verso quem estava lavando a roupa.",
		"depois": "Bento deixou a rasura à vista. Hoje uma menina pôde perguntar por que havia dois textos. Antes, teria lido só o que mandaram."
	},
	"eron": {
		"nome": "Eron", "papel": "Capitão da guarda",
		"fala": "Vim devolver a chave da cisterna. Quando aceitei o posto disseram que uma só família havia cavado o canal. Minha avó passou três verões tirando barro daqui.",
		"pergunta": "Como ouvir as outras famílias?",
		"resposta": "Procure a vigia no abrigo a noroeste. Ela viu quem trabalhava em cada turno. Com o depoimento e o decreto de Nilo, o conselho terá duas fontes para comparar.",
		"depois": "Pendurei a chave junto ao quadro dos turnos. Quem chega com um cântaro já sabe a quem pedir ajuda."
	},
	"asterion": {
		"nome": "Asterion", "papel": "Mestre dos caminhos",
		"fala": "Antes do farol, os carteiros se orientavam por uma casa de telhado azul. Um inverno levou o telhado. No mapa continuou desenhado por mais vinte anos.",
		"pergunta": "Como corrigir o rumo?",
		"resposta": "Maíra começa no marco geodésico. Ele tem posição conhecida. Dali ela confere o relevo e pergunta aos moradores como chamam cada lugar. Um mapa também se aprende a ouvir.",
		"depois": "Ontem vi no mapa a aldeia que visitava quando menino. Era o próprio nome, com o acento que minha mãe fazia questão de pronunciar."
	},
	"nox": {
		"nome": "Nox", "papel": "Eco do Esquecimento",
		"fala": "Tirei os nomes das amostras. Dois frascos claros continuam sendo dois frascos claros. Você saberia dizer de onde veio cada um?",
		"pergunta": "O que faltaria no registro?",
		"resposta": "A nascente, o trecho abaixo dela e a hora da coleta. Dandara anotou tudo no viveiro. Enquanto alguém puder reconstituir o caminho da água, minha névoa não dura.",
		"depois": "Você devolveu as raízes à margem. Amanhã alguém esquecerá como era antes. A menos que encontre, entre as sementes, o caderno dela."
	},
	"kael": {
		"nome": "Kael", "papel": "Ferreiro-mestre",
		"fala": "Troquei três engrenagens antes de perceber que todas obedeciam à mesma instrução errada. Teca ainda guarda as três na bancada.",
		"pergunta": "Como testar a instrução?",
		"resposta": "Ela escreve o que a comporta deve fazer se o nível subir e o que deve fazer se baixar. Depois percorre cada caso no papel, um passo de cada vez, antes de religar o mecanismo.",
		"depois": "Hoje a máquina parou quando a água voltou à marca. Foi a primeira vez que ouvi o som do sino sem precisar correr."
	}
}

static func adicionar(world, c: int):
	if c < 0 or c >= REGIAO.size() or REGIAO[c] == "":
		return
	var id: String = REGIAO[c]
	world.place(Vector2(365,155),load(ARTE+id+"_campo.png"),"visita_"+id,VISITANTES[id].nome,true,6)

static func interagir(ui, tag: String):
	var id := tag.trim_prefix("visita_")
	if not VISITANTES.has(id):
		return
	var c := REGIAO.find(id)
	var pessoa: Dictionary = VISITANTES[id]
	var ficha := {"nome":pessoa.nome,"retrato":ARTE+id+".png"}
	var fala: String = pessoa.depois if Saga.data.chapter > c else pessoa.fala
	var esclarecer := func():
		ui.dialogue(c,pessoa.papel,pessoa.resposta,[["Voltar à expedição",ui.play]],false,ficha)
	ui.dialogue(c,pessoa.papel,fala,[[pessoa.pergunta,esclarecer],["Despedir-se",ui.play]],false,ficha)
