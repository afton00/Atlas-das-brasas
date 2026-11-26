extends RefCounted

const REGIONAL_BEASTS=[
	["cogumelo","lobo","arqueiro"], ["rato","morcego","bruxa"],
	["javali","serpente","cristal"], ["aranha","corvo","espectro"],
	["trepadeira","lobo","fagulha"], ["vigia","cavaleiro","cultista"]]
const CRYPT_BEASTS=["vigia","bruxa","pedra","espectro","ent","lava"]
const GUARDIANS=["lobo","vazio","colosso","abissal","raiz","lava","dragao"]
const GUARDIAN_NAMES=["Lobo do Junco","Arauto de Lume","Colosso de Ocre","Cavaleiro da Agulha","Ent da Nascente","Elemental de Basalto","Aster"]
const GALLERY="res://personagens/bestiario/"
const SECTIONS=[
	["cogumelo","lobo","lodo","pedra","aranha","selo0"],
	["morcego","bruxa","rato","selo1"],
	["javali","cristal","arqueiro","cavaleiro","selo2"],
	["corvo","serpente","espectro","selo3"],
	["trepadeira","fagulha","aranha","ent","selo4"],
	["cultista","vigia","lava","selo5","selo6"]]
const REGION_LABELS=["Junco","Lume","Ocre","Agulha","Nascente","Basalto"]
const TRAIL_BEASTS=["lodo","rato","arqueiro","serpente","aranha","cultista"]
const ROAM_KINDS=[0,1,2,1,0,2]
const GUARDIAN_KINDS=[0,1,2,1,2,2,3]
# Name, habitat, and attack pattern witnessed in the field.
const NOTES={
	"cogumelo":["Cogumelo da margem","Sob a sombra úmida da estrada do Junco.",0],
	"lobo":["Lobo sombrio","Nas trilhas abertas do Junco e na Floresta dos Pinheiros.",1],
	"lodo":["Lodo corrompido","Na margem oeste do Junco, longe do cais.",0],
	"pedra":["Sentinela de pedra","Na escola de combate do Junco e na cripta de Ocre.",2],
	"morcego":["Morcego sanguíneo","Sobre a estrada dos copistas de Lume.",1],
	"bruxa":["Bruxa das cinzas","Nas trilhas e no templo do rio antigo em Lume.",2],
	"rato":["Rato das ruínas","Nas pedras soltas da trilha ocidental de Lume.",1],
	"javali":["Javali feral","Nos caminhos arenosos de Ocre.",0],
	"cristal":["Estátua de cristal","Na estrada de Ocre e no abrigo de Basalto.",2],
	"arqueiro":["Arqueiro renegado","Vigia a trilha oeste de Ocre.",2],
	"cavaleiro":["Soldado corrompido","Guarda o recanto da vigia de Ocre.",2],
	"corvo":["Corvo da neblina","Voa rente às trilhas da Serra da Agulha.",1],
	"serpente":["Serpente da serra","Na encosta oeste da Serra da Agulha.",1],
	"espectro":["Espectro errante","Na câmara leste do templo da Serra da Agulha.",2],
	"trepadeira":["Trepadeira venenosa","Junto aos caminhos da Mata da Nascente.",0],
	"fagulha":["Fogo-fátuo","Flutua sobre a estrada da Nascente.",2],
	"aranha":["Aranha da mata","Nos atalhos da Nascente e nas galerias úmidas do Junco.",0],
	"ent":["Ent do rio antigo","Junto ao relicário da cripta da Nascente.",2],
	"cultista":["Cultista das brasas","Protege as estradas da Forja de Basalto.",2],
	"vigia":["Vigia de ossos","Nas trilhas de Basalto e na cripta do Junco.",0],
	"lava":["Autômato incandescente","Na câmara do relicário de Basalto.",2]}
const PATTERNS=[
	"Encurta a distância a pé. O círculo âmbar anuncia um golpe curto. Recue enquanto ele brilha e volte após o avanço.",
	"Fixa o rumo antes de arrancar. A linha no chão revela a direção da investida. Saia de lado quando a linha aparecer.",
	"Para e aponta uma linha antes de lançar uma brasa. Cruze a trajetória pelo lado e aproveite o intervalo entre disparos.",
	"O escudo pulsa em âmbar, azul fraco e azul forte. Quando o último anel se apaga, há uma abertura. Desvie entre os disparos em leque."]
const SHARED_PATTERNS={
	"vigia":"Na estrada avança de perto. Na cripta lança brasas da câmara leste. Observe a linha âmbar e saia da direção indicada."}
const PLATES=["lobo","lodo","morcego","rato","javali","arqueiro","cavaleiro","espectro","trepadeira","fagulha","aranha","ent","cultista","lava","pedra","bruxa"]

static func species_for(region:int,kind:int,tag:String,boss:bool)->String:
	if boss:return GUARDIANS[region]
	if tag=="treino":return "pedra"
	if tag.begins_with("deep_"):return ["aranha","rato","pedra","espectro","ent","lava"][region]
	if tag=="trail_pinheiros":return "lobo"
	if tag.begins_with("cripta"):return CRYPT_BEASTS[region]
	if tag.begins_with("side"):return "cavaleiro" if region==2 else "cristal"
	if tag.begins_with("roam") and tag.ends_with("_2"):return TRAIL_BEASTS[region]
	return REGIONAL_BEASTS[region][kind]

static func record(data:Dictionary,key:String)->bool:
	if not data.has("fauna"):data.fauna=[]
	if key in data.fauna:return false
	data.fauna.append(key)
	return true

static func migrate(data:Dictionary):
	if data.get("fauna_revision",0)>=1:return
	if not data.has("fauna"):data.fauna=[]
	for raw_tag in data.get("kills",[]):
		var tag=str(raw_tag)
		for region in 6:
			if tag=="cripta%d"%region or tag=="side%d"%region:record(data,species_for(region,2,tag,false))
			for i in 3:
				if tag=="roam%d_%d"%[region,i]:
					record(data,species_for(region,(region+1)%3 if i==1 else ROAM_KINDS[region],tag,false))
	for region in clampi(int(data.get("chapter",0)),0,6):record(data,"selo%d"%region)
	if data.get("trained",false):record(data,"pedra")
	if data.get("won",false):record(data,"selo6")
	data.fauna_revision=1

static func title(key:String)->String:
	if key.begins_with("selo"):return GUARDIAN_NAMES[int(key.right(1))]
	return NOTES[key][0]

static func art(key:String)->String:
	return GUARDIANS[int(key.right(1))] if key.begins_with("selo") else key

static func plate(key:String)->String:
	if key.begins_with("selo"):return GALLERY+"g"+key.right(1)+".png"
	if key in PLATES:return GALLERY+"registro_"+key+".png"
	return GALLERY+key+".png"

static func habitat(key:String)->String:
	if key=="selo6":return "Na Caldeira de Aster, além da Academia das Engrenagens."
	if key.begins_with("selo"):
		var r=Saga.regions[int(key.right(1))]
		return "%s · %s. Surge ao fixar o selo da região."%[r.place,r.site2]
	return NOTES[key][1]

static func behavior(key:String)->String:
	if SHARED_PATTERNS.has(key):return SHARED_PATTERNS[key]
	var kind=GUARDIAN_KINDS[int(key.right(1))] if key.begins_with("selo") else int(NOTES[key][2])
	return PATTERNS[kind]

static func open(ui,region:int=0,selected:String="",back:Callable=Callable()):
	migrate(Saga.data)
	var exit_call=back if back.is_valid() else Callable(ui,"journal")
	var section=SECTIONS[clampi(region,0,5)]
	if selected not in section:
		selected=section[0]
		for key in section:
			if key in Saga.data.fauna:
				selected=key
				break
	var observed=selected in Saga.data.fauna
	ui.panel_page("bestiario","Caderno de campo","Bestiário das margens")
	for i in 6:
		var b=ui.button(ui.view,REGION_LABELS[i],108+i*125,143,119,36,open.bind(ui,i,"",exit_call),i==region)
		b.add_theme_font_size_override("font_size",15)
	ui.box(ui.view,108,190,243,249,ui.INK,ui.LINE)
	var known=0
	for i in section.size():
		var key=section[i]
		var found=key in Saga.data.fauna
		if found:known+=1
		var b=ui.button(ui.view,title(key) if found else "Rastro desconhecido",117,222+i*35,225,33,open.bind(ui,region,key,exit_call),key==selected)
		b.add_theme_font_size_override("font_size",15)
	ui.label(ui.view,"%d de %d avistados nesta margem"%[known,section.size()],120,193,225,27,15,ui.GOLD)
	ui.box(ui.view,362,190,490,249,ui.PANEL,ui.LINE)
	if observed:
		ui.box(ui.view,378,205,98,78,ui.INK,ui.LINE)
		ui.tex(ui.view,plate(selected),381,208,92,72)
		ui.label(ui.view,title(selected),490,204,283,34,22,ui.PALE,true)
		ui.label(ui.view,habitat(selected),490,240,285,54,15,ui.MUTED)
		ui.tex(ui.view,GALLERY+art(selected)+".png",786,210,55,72)
		ui.line(ui.view,380,297,454,1,ui.LINE)
		ui.label(ui.view,"Padrão de combate",381,305,431,29,17,ui.GOLD,true)
		ui.label(ui.view,behavior(selected),381,336,445,92,17,ui.PALE)
	else:
		ui.label(ui.view,"Pegadas sem identificação",383,213,436,48,24,ui.GOLD,true)
		var text="O registro aparece quando você avista a criatura de perto. Procure nas estradas, nos abrigos e no templo desta margem."
		if selected.begins_with("selo"):text="Os guardiões aparecem durante a história da margem. Observe o encontro para registrar o padrão de combate."
		ui.label(ui.view,text,383,272,426,118,18,ui.PALE)
	ui.button(ui.view,"Voltar ao diário",108,451,201,36,exit_call)
	ui.focus_default()
