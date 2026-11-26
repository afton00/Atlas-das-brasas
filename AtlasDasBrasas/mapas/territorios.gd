extends RefCounted

# Cell coordinates are stable save keys. The final field describes a landform
# independently of the services and encounters provided by the settlement.
const AREAS = {
	"6,0":["Torre do Conhecimento","ruin","torre_saber","O catálogo da torre separa o autor de um livro da pessoa que o copiou.",2,"terrace"],
	"7,0":["Jardins da Academia","woods","jardins_academia","Os aprendizes plantaram uma alameda para cada escola de poesia.",0,"grove"],
	"6,1":["Cidade dos Sábios","village","cidade_sabios","A praça reúne livreiros e aprendizes. Procure a biblioteca ao sul.",2,"court"],
	"7,1":["Distrito dos Escribas","village","escribas","As oficinas marcam suas cópias com o nome do escriba e a data.",1,"court"],
	"5,2":["Grande Biblioteca","village","grande_biblioteca","O índice de assuntos liga textos de autores diferentes à mesma pergunta.",2,"court"],
	"6,2":["Arquivos Subterrâneos","cave","arquivos_lume","Os maços mais frágeis ficam acima da antiga marca de inundação.",0,"terrace"],
	"7,2":["Academia Arcana","village","academia_arcana","Na aula de retórica, cada tese vem acompanhada de uma passagem que a sustenta.",2,"court"],
	"4,3":["Aldeia do Papel","farm","aldeia_papel","Papéis com fibras diferentes absorvem a tinta em velocidades diferentes.",0,"grove"],
	"5,3":["Pátio das Leituras","camp","patio_leituras","À noite os leitores se revezam. Cada voz escolhe onde fazer suas pausas.",1,"court"],
	"6,3":["Universidade Antiga","ruin","universidade","Uma dedicatória riscada ainda pode ser lida à luz que entra de lado.",2,"terrace"],
	"7,3":["Passo da Encadernação","road","passo_livro","As caravanas protegem o papel da areia antes de entrar em Ocre.",1,"ridge"],
	"8,0":["Oásis da Argila","village","oasis_argila","Aqui a argila guardou marcas dos trabalhadores que abriram o primeiro canal.",0,"oasis"],
	"9,0":["Dunas do Poente","road","dunas_poente","Repare nas ondulações da areia. Uma caravana procura terreno firme entre as dunas.",1,"dune"],
	"10,0":["Oásis das Tamareiras","village","oasis_tamaras","O livro do celeiro registra rações entregues aos escavadores. Há uma cópia no armazém.",0,"oasis"],
	"11,0":["Templo do Sol Baixo","ruin","sol_baixo","Uma placa real comemora a ampliação do canal. A data pertence à obra mais recente.",2,"terrace"],
	"8,1":["Mercado das Sete Sombras","village","mercado_sombras","Os vendedores estendem toldos sobre a rua quando as sombras encurtam.",2,"court"],
	"10,1":["Arquivo dos Canais","ruin","arquivo_canais","Dois oásis conservam testemunhos sobre o primeiro canal. A praça aguarda a nova inscrição.",2,"court"],
	"11,1":["Desfiladeiro da Lua","road","garganta_lua","O vento perde força junto à base da parede. A trilha acompanha esse lado.",1,"ridge"],
	"8,2":["Acampamento da Mirra","camp","campo_mirra","As caravanas esperam o calor baixar antes de seguir para o norte.",0,"dune"],
	"9,2":["Portas da Capital","village","portas_capital","Além da muralha, as carroças seguem para o mercado e para a capital antiga.",2,"court"],
	"10,2":["Labirinto das Cisternas","cave","labirinto_ocre","Os reservatórios enterrados perdiam menos água por evaporação.",2,"terrace"],
	"11,2":["Dunas Cantantes","woods","mar_areia","Os viajantes medem o deslocamento das dunas usando estacas fixas na rocha.",0,"dune"],
	"8,3":["Vila do Sal","village","vila_sal","A água das bacias evapora e deixa sais dissolvidos na superfície.",0,"oasis"],
	"9,3":["Estrada do Açafrão","road","estrada_acafrao","Os marcos de pedra ficam acima da altura que a areia costuma alcançar.",1,"dune"],
	"10,3":["Cidade Soterrada","ruin","cidade_soterrada","A rua mais antiga passa por baixo dos alicerces das casas atuais.",2,"terrace"],
	"11,3":["Escarpa das Caravanas","camp","escarpa_caravanas","A subida para a serra começa além das últimas tendas.",1,"ridge"],
	"8,4":["Vila da Cota Baixa","village","cota_baixa","Uma régua de bronze assinala a altitude medida a partir do nível médio do mar.",1,"terrace"],
	"9,4":["Ponte das Nuvens","road","ponte_nuvens","As duas beiras da fenda têm cotas conhecidas. A passarela fica no caminho alto.",1,"rift"],
	"10,4":["Observatório do Zênite","village","observatorio_zenite","Os observadores usam o mesmo nível de referência que a vila do vale.",1,"terrace"],
	"11,4":["Torres da Vigília","ruin","torres_vigilia","Com tempo limpo a vigia enxerga a fogueira da torre vizinha.",2,"ridge"],
	"8,5":["Trilha dos Seixos","road","trilha_seixos","O cascalho solto marca o sopé da encosta mais íngreme.",1,"ridge"],
	"10,5":["Mina do Quartzo","cave","mina_quartzo","Veios claros atravessam a rocha. Os mineiros os seguem por galerias laterais.",2,"rift"],
	"11,5":["Lago do Degelo","water","lago_degelo","O lago recebe água quando a neve derrete acima da trilha.",1,"pool"],
	"8,6":["Aldeia dos Cabos","village","aldeia_cabos","Os tecelões trançam fibras para os cabos das pontes de pedestres.",0,"terrace"],
	"9,6":["Cachoeira dos Degraus","water","cachoeira","A água cai de patamar em patamar onde as rochas resistem à erosão de maneiras diferentes.",1,"rift"],
	"10,6":["Caverna de Gelo Azul","cave","gelo_azul","No verão, a entrada derrete antes da câmara profunda.",2,"rift"],
	"11,6":["Cordilheira Branca","woods","cordilheira","Na face abrigada do vento a neve pode se acumular em maior quantidade.",1,"ridge"],
	"8,7":["Pouso dos Guias","camp","pouso_guias","Os guias desenham o perfil da subida antes de escolher o passo.",1,"terrace"],
	"9,7":["Passo do Eco","road","passo_eco","O som refletido na parede retorna depois do som direto.",0,"ridge"],
	"10,7":["Aldeia da Geada","village","aldeia_geada","A água pode congelar sobre superfícies muito frias mesmo após o amanhecer.",1,"pool"],
	"11,7":["Atalaia do Sul","ruin","atalaia_sul","Do mirante se distinguem as curvas do vale e a antiga estrada.",2,"ridge"],
	"4,4":["Aldeia do Salgueiro","village","aldeia_salgueiro","Os coletores deixam faixas de vegetação nas beiras dos córregos.",0,"grove"],
	"5,4":["Brejo dos Juncos","woods","brejo_juncos","Acompanhe a água que atravessa uma margem com raízes depois da chuva.",0,"marsh"],
	"6,4":["Lago das Lanternas","water","lago_lanternas","À noite, pequenos pontos luminosos atraem insetos sobre o lago.",2,"pool"],
	"7,4":["Caverna das Raízes","cave","gruta_raizes","Raízes atravessam fendas e alcançam o teto da caverna.",0,"grove"],
	"4,5":["Margem de Barro","water","margem_barro","Um trecho perdeu a vegetação. A amostra de água foi colhida logo depois da chuva.",0,"marsh"],
	"6,5":["Santuário das Mudas","village","santuario_mudas","As guardiãs comparam amostras antes de escolher o próximo lugar de plantio.",2,"grove"],
	"7,5":["Ruínas do Cipó","ruin","ruinas_cipo","As juntas entre as pedras guardam terra e sementes.",2,"grove"],
	"4,6":["Aldeia das Palafitas","village","palafitas","O piso das casas fica acima da marca das cheias recentes.",0,"pool"],
	"5,6":["Bosque dos Gigantes","woods","bosque_gigantes","Na sombra das copas grandes crescem espécies adaptadas à pouca luz.",0,"grove"],
	"6,6":["Clareira dos Fogos-Fátuos","woods","clareira_fogos","Ao escurecer, luzes cruzam a trilha entre as árvores.",2,"marsh"],
	"7,6":["Gruta do Orvalho","cave","gruta_orvalho","O vapor de água se condensa nas superfícies frias junto à entrada.",0,"terrace"],
	"4,7":["Trilha das Sementes","road","trilha_sementes","Aves que comem frutos podem levar sementes para longe da árvore.",0,"grove"],
	"5,7":["Pântano da Névoa","water","pantano_nevoa","O terreno alagado abriga organismos adaptados a solos pobres em oxigênio.",2,"marsh"],
	"6,7":["Acampamento dos Coletores","camp","campo_coletores","As cestas separadas permitem registrar o local de cada coleta.",0,"grove"],
	"7,7":["Aldeia da Castanha","farm","aldeia_castanha","Os moradores deixam parte dos frutos disponíveis para os animais da mata.",0,"grove"],
	"0,4":["Vila da Bigorna","village","vila_bigorna","Os artesãos guardam os moldes de cada peça numa oficina comum.",0,"court"],
	"1,4":["Casa dos Dois Sinos","village","dois_sinos","Dois sinais independentes informam à máquina se as duas equipes chegaram.",0,"court"],
	"2,4":["Fortaleza do Ferrolho","ruin","forte_ferrolho","A antiga porta de transporte ainda responde ao comando das runas.",2,"terrace"],
	"3,4":["Margem da Escória","road","margem_escoria","A trilha contorna uma corrente incandescente e volta para a estrada.",2,"lava"],
	"0,5":["Minas do Poente","cave","minas_poente","Vagões vazios voltam por uma galeria paralela à de carga.",0,"rift"],
	"2,5":["Arquivo das Engrenagens","ruin","arquivo_engrenagens","Há um registro de cada tentativa de partida da máquina.",2,"terrace"],
	"3,5":["Vila dos Mineiros","village","vila_mineiros","A troca de turno passa pela praça onde estão as marcas de cada equipe.",0,"court"],
	"0,6":["Galeria do Cobre","cave","galeria_cobre","Diferentes cores nos minerais ajudam a descrever amostras.",2,"rift"],
	"1,6":["Cidade das Chaminés","village","cidade_chamines","Ferreiros, oleiros e mecânicos dividem a água da antiga cisterna.",2,"court"],
	"2,6":["Rio de Lava","road","rio_lava","Rochas vulcânicas se formam quando o material fundido esfria e se solidifica.",2,"lava"],
	"3,6":["Gruta da Brasa Fria","cave","gruta_brasa","O leito escuro registra um fluxo muito mais antigo que o brilho da outra margem.",2,"lava"],
	"0,7":["Pátio das Forjas","village","patio_forjas","Os mestres guardam moldes diferentes para peças que devem se encaixar.",0,"court"],
	"1,7":["Acampamento do Carvão","camp","campo_carvao","Carroceiros contam as cargas aqui antes de seguir para o pátio das forjas.",0,"terrace"],
	"2,7":["Ruínas do Tear Mecânico","ruin","tear_mecanico","Um tambor marcado repete a mesma sequência a cada volta.",2,"rift"],
	"3,7":["Caminho da Caldeira","road","caminho_caldeira","Os pilares apontam de volta ao arco da Forja de Basalto, a passagem para Aster.",2,"lava"]
}

const SCENERY = {
	"court":["biblioteca","casa-lume","livraria","poco","academia","flowers"],
	"terrace":["vigia","stones","casa-serra","rock","torre","crystals"],
	"oasis":["poco","casa-ocre","provisoes","willow","green","poco"],
	"dune":["provisoes","rock","stones","casa-ocre","gold","stub"],
	"ridge":["vigia","rock","stones","rock","torre","stones"],
	"rift":["mineiro","rock","vigia","crystals","stones","rock"],
	"grove":["wisdom","willow","jardim","green","plant","flowers"],
	"marsh":["willow","casa-mata","boticario","wisdom","fungus","plant"],
	"pool":["poco","provisoes","vigia","willow","green","rock"],
	"lava":["forja","stones","mineiro","crystals","rock","vigia"]
}

static func accents(form:String,realm:int)->Array:
	if form=="court" and realm==2:return ["fortaleza","casa-ocre","venda","poco","vigia","provisoes"]
	if form=="court" and realm==5:return ["oficina","casa-basalto","forja","mineiro","vigia","provisoes"]
	return SCENERY[form]

# Negative means to retain the ground, crops or road already painted.
static func relief(form:String,p:Vector2i,seed_value:int)->int:
	var x=p.x
	var y=p.y
	var drift=posmod(seed_value,3)-1
	match form:
		"oasis","pool":
			var radius=Vector2(6,4) if form=="oasis" else Vector2(9,5)
			var norm=(Vector2(p-Vector2i(34+drift,7))/radius).length_squared()
			if norm<1.0:return 8 if norm<.63 else 9 if x<34+drift else 10
		"rift","lava":
			var bank=34+roundi(sin((y+drift)*.32)*2)
			if x in range(bank,bank+3):return 12 if y in [15,16,17] else [9,8,10][x-bank]
		"marsh":
			if (Vector2(p-Vector2i(9,8))/Vector2(7,3)).length_squared()<1 or (Vector2(p-Vector2i(37,24))/Vector2(5,4)).length_squared()<1:return 8
		"ridge","terrace":
			if x in range(3,17) and y==8+drift+absi(x-10)/3:return 16
			if form=="ridge" and x in range(25,43) and y==24+drift+absi(x-33)/4:return 16
		"dune":
			if x in range(26,45) and posmod(y+absi(x-34)/3+drift,10)==0:return 13
	return -1
