extends Node

signal changed
signal notice(message: String)

const SAVE = "user://atlas_v1.json"
const SETTINGS = "user://preferencias.cfg"
const REGIONS = [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(1,1),Vector2i(0,1)]
const AREA = Vector2(768,512)
const WEAPONS = ["Espada curta","Machado do cais","Lança da guarda"]
const SKILLS = ["Passo leve","Lâmina dupla","Olho de falcão","Égide de vidro","Cura das raízes","Invocar lume"]
const COSTS = [1,2,1,1,2,2]
const PARENTS = [-1,0,-1,-1,3,3]
var regions: Array
var lessons: Array
var data: Dictionary
var settings := ConfigFile.new()
var binds = {"up":KEY_W,"down":KEY_S,"left":KEY_A,"right":KEY_D,"use":KEY_E,"attack":KEY_J,"style":KEY_Q,"dodge":KEY_SPACE,"guard":KEY_K,"special":KEY_R,"bag":KEY_I,"journal":KEY_TAB,"map":KEY_M,"potion":KEY_H}
var aliases = {"up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT}

func _ready():
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://recursos/regioes.json"))
	lessons = JSON.parse_string(FileAccess.get_file_as_string("res://recursos/licoes.json"))
	settings.load(SETTINGS)
	for action in binds:
		var key = settings.get_value("controls",action,binds[action])
		bind(action,key)
	apply_audio()
	reset()

func bind(action: String,key: int):
	if not InputMap.has_action(action): InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for code in [key,aliases.get(action,0)]:
		if code:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action,event)
	settings.set_value("controls",action,key)

func keyname(action):
	return OS.get_keycode_string(settings.get_value("controls",action,binds[action]))

func apply_audio():
	var v = settings.get_value("sound","volume",0.6)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,0.0001)))

func reset():
	data={"chapter":0,"stage":0,"briefed":false,"taught":-1,"xp":0,"hp":100.0,"mp":60.0,"style":0,"weapon":0,"armor":false,"magic":"lume","charm":"","points":1,"learned":[],"review":{},"choices":{},"bonds":{},"seen":[0],"side":{},"chests":[],"herbs":2,"ore":2,"potions":2,"skills":[],"weapons":[0],"letter":"","won":false,"pos":[324,265],"room":"hall","ruins":{},"relics":[],"inside":false,"interior":0,"kills":[],"saved_at":""}

func level() -> int: return 1 + int(float(data.xp)/100)
func max_hp() -> float: return 94.0 + level()*6.0 + (18 if data.armor else 0)
func max_mp() -> float: return 56.0 + level()*4.0
func power() -> int: return 8 + level()*2 + (2 if data.charm!="" else 0)
func has_skill(i): return i in data.skills
func chapter_lessons(c):
	return lessons.filter(func(l): return int(l.ch)==c)
func current_lesson():
	var arr=chapter_lessons(data.chapter)
	return arr[data.stage] if data.stage<arr.size() else {}
func region_at(pos: Vector2) -> int:
	return REGIONS.find(Vector2i(clampi(floori(pos.x/AREA.x),0,2),clampi(floori(pos.y/AREA.y),0,1)))
func origin(c:int) -> Vector2: return Vector2(REGIONS[c])*AREA
func award(xp:int):
	var before=level()
	data.xp+=xp
	if level()>before:
		data.points+=level()-before
		data.hp=max_hp()
		data.mp=max_mp()
		notice.emit("Nível %d · Ponto de habilidade recebido"%level())
	changed.emit()

func master_lesson():
	var lesson=current_lesson()
	if lesson.is_empty() or data.taught!=data.stage: return
	data.learned.append(lesson.title)
	data.stage+=1
	data.taught=-1
	award(35)
	save()

func finish_chapter():
	var c=int(data.chapter)
	if c>=6 or data.stage<chapter_lessons(c).size(): return
	data.chapter+=1
	data.stage=0
	data.taught=-1
	data.briefed=false
	data.points+=1
	data.ore+=2
	data.potions+=1
	if c==0 and 1 not in data.weapons: data.weapons.append(1)
	if c==4:data.magic="cura"
	if c==2 and 2 not in data.weapons: data.weapons.append(2)
	data.hp=max_hp()
	data.mp=max_mp()
	award(90)
	save()

func objective() -> String:
	if data.won: return "Visite os mestres e reveja as descobertas."
	if data.chapter==6: return "Entre na Caldeira pelo arco da Forja de Basalto."
	var r=regions[data.chapter]
	if not data.briefed: return "Encontre %s em %s."%[r.name,r.building]
	var l=current_lesson()
	if l.is_empty(): return "Proteja %s e fixe o selo."%r.site2
	if data.taught!=data.stage: return "Aprenda «%s» com %s."%[l.title,r.name]
	return "Aplique «%s» em %s."%[l.title,r["site"+str(int(data.stage)%3)]]

func save() -> bool:
	data.saved_at=Time.get_datetime_string_from_system(false,true)
	var f=FileAccess.open(SAVE+".tmp",FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	var folder=DirAccess.open("user://")
	if folder.file_exists("atlas_v1.json.bak"): folder.remove("atlas_v1.json.bak")
	if folder.file_exists("atlas_v1.json"):
		if folder.rename("atlas_v1.json","atlas_v1.json.bak")!=OK: return false
	if folder.rename("atlas_v1.json.tmp","atlas_v1.json")!=OK:
		folder.rename("atlas_v1.json.bak","atlas_v1.json")
		return false
	return true

func exists(): return FileAccess.file_exists(SAVE) or FileAccess.file_exists(SAVE+".bak")
func restore() -> bool:
	for path in [SAVE,SAVE+".bak"]:
		if not FileAccess.file_exists(path): continue
		var v=JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.has("chapter") and v.has("pos") and int(v.chapter) in range(7):
			reset()
			data.merge(v,true)
			for k in ["chapter","stage","taught","interior","style","weapon","points","xp","ore","herbs","potions"]: data[k]=int(data[k])
			for k in ["skills","weapons","seen"]:
				for i in data[k].size(): data[k][i]=int(data[k][i])
			changed.emit()
			return true
	return false

func craft(kind):
	match kind:
		"poção":
			if data.herbs<2: return "São necessárias duas ervas."
			data.herbs-=2
			if int(data.side.get("4",0))==1: data.brew_after_request=true
			data.potions+=1
		"cota":
			if data.armor: return "A cota já está equipada."
			if data.ore<3: return "São necessários três minérios."
			data.ore-=3
			data.armor=true
		"lança":
			if 2 in data.weapons: return "Você já possui uma lança."
			if data.ore<4: return "São necessários quatro minérios."
			data.ore-=4
			data.weapons.append(2)
	save()
	changed.emit()
	return "Fabricação concluída."

func drink():
	if data.potions<1: return "Mochila sem poções."
	if data.hp>=max_hp(): return "Sua vida está cheia."
	data.potions-=1
	data.hp=minf(max_hp(),data.hp+46)
	changed.emit()
	return "Poção usada · +46 de vida"

func train(i):
	if has_skill(i): return "Técnica já aprendida."
	if PARENTS[i]>=0 and not has_skill(PARENTS[i]): return "Aprenda primeiro "+SKILLS[PARENTS[i]]+"."
	if data.points<COSTS[i]: return "Pontos insuficientes."
	data.points-=COSTS[i]
	data.skills.append(i)
	if i==3:data.magic="égide"
	if i==4:data.magic="cura"
	save()
	return "Técnica aprendida · "+SKILLS[i]

