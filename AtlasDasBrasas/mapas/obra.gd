extends RefCounted

const Weather = preload("res://scripts/tempo.gd")
const POSITION = Vector2(245, 365)
const TAG = "workshop"
const NAMES = ["Canteiro do mutirão", "Abrigo do mutirão", "Oficina do mutirão"]
const ART = [
	preload("res://mapas/mutirao/canteiro.png"),
	preload("res://mapas/mutirao/abrigo.png"),
	preload("res://mapas/mutirao/oficina.png")
]
const COSTS = [2, 3]
const SWORD_COST = 4

static func level() -> int:
	return clampi(int(Saga.data.get("workshop_level", 0)), 0, ART.size() - 1)

static func install(world):
	var stage = level()
	return world.place(Saga.origin(0) + POSITION, ART[stage], TAG, NAMES[stage], true, 17)

static func refresh(site):
	var stage = level()
	site.art.texture = ART[stage]
	site.art.offset = Vector2(0, -ART[stage].get_height() / 2.0)
	site.label = NAMES[stage]
	site.queue_redraw()

# Material costs and unlocks form a single save operation. Restore the previous
# values in memory if writing the new save fails.
static func record(changes: Dictionary, success: String) -> String:
	var previous = Saga.data.duplicate()
	Saga.data.merge(changes, true)
	if not Saga.save():
		Saga.data = previous
		return "Não foi possível registrar o serviço. Tente novamente."
	Saga.changed.emit()
	return success

static func construct(expected: int) -> String:
	if expected != level() or expected < 0 or expected >= COSTS.size():
		return "Esta etapa da obra já foi concluída."
	var cost: int = COSTS[expected]
	if Saga.data.ore < cost:
		return "Faltam %d minério(s). Há um afloramento a oeste da obra." % (cost - Saga.data.ore)
	return record({"ore": Saga.data.ore - cost, "workshop_level": expected + 1},
		"Abrigo construído. Já há um lugar para descansar." if expected == 0 else
		"Oficina inaugurada. A bancada e a forja estão prontas.")

static func rest() -> String:
	if level() < 1:
		return "Erga o abrigo para usar o catre."
	var day = Weather.day(Saga.data.world_minutes)
	if int(Saga.data.get("workshop_rest_day", -1)) == day:
		return "Você já usou o catre hoje. Ele ficará disponível amanhã."
	if Saga.data.hp >= Saga.max_hp() and Saga.data.mp >= Saga.max_mp():
		return "Você já está com vida e mana completas. O catre segue disponível."
	return record({"hp": Saga.max_hp(), "mp": Saga.max_mp(), "workshop_rest_day": day},
		"Descanso concluído. Vida e mana restauradas.")

static func brew() -> String:
	if level() < 2:
		return "A bancada precisa da oficina coberta."
	if Saga.data.herbs < 3:
		return "O lote usa três ervas. Procure mais na margem do Junco."
	var order = {"herbs": Saga.data.herbs - 3, "potions": Saga.data.potions + 2}
	if int(Saga.data.side.get("4", 0)) == 1:
		order["brew_after_request"] = true
	return record(order, "Duas poções de aventura guardadas na mochila.")

static func reforge() -> String:
	if level() < 2:
		return "A forja precisa da oficina coberta."
	if Saga.data.get("ember_sword", false):
		return "Sua espada curta já se tornou a Espada das Brasas."
	if Saga.data.ore < SWORD_COST:
		return "A forja precisa de quatro minérios."
	return record({"ore": Saga.data.ore - SWORD_COST, "ember_sword": true},
		"Espada das Brasas pronta. Ela ocupa o lugar da espada curta.")

static func announce(game, site, message: String):
	refresh(site)
	game.ui.play()
	game.toast(message)

static func confirm_sword(game, site):
	var text = "Posso reforjar sua espada curta. Ela passará a se chamar Espada das Brasas e seus golpes com ela ganharão 3 de dano. O serviço custa quatro minérios. Você tem %d." % int(Saga.data.ore)
	game.ui.dialogue(0, "Uma lâmina para a travessia", text, [
		["Reforjar por 4 minérios", func(): announce(game, site, reforge())],
		["Voltar à oficina", func(): interact(game, site)]
	])

static func interact(game, site):
	var stage = level()
	var ore = int(Saga.data.ore)
	var choices = []
	var text = ""
	match stage:
		0:
			text = "Depois da cheia, ninguém tinha onde secar a manta. O povo trouxe as vigas. Com dois minérios para as ferragens, erguemos um abrigo de descanso na estrada sul. Na sua mochila há %d." % ore
			choices.append(["Erguer abrigo · 2 minérios", func(): announce(game, site, construct(0))])
		1:
			text = "O catre restaura vida e mana uma vez por dia. Com três minérios, cobrimos a bancada e montamos a forja. Poderemos preparar duas poções com três ervas ou reforjar sua espada curta. Você tem %d minérios." % ore
			choices.append(["Ampliar · 3 minérios", func(): announce(game, site, construct(1))])
		2:
			text = "Na mochila, duas poções pedem quatro ervas. Aqui a bancada permite preparar as duas juntas usando três. Você traz %d ervas. O catre continua à sua disposição." % int(Saga.data.herbs)
			choices.append(["Lote · 3 ervas", func(): announce(game, site, brew())])
			if not Saga.data.get("ember_sword", false):
				choices.append(["Reforjar espada", func(): confirm_sword(game, site)])
	if stage >= 1:
		choices.append(["Descansar", func(): announce(game, site, rest())])
	choices.append(["Voltar", game.ui.play])
	game.ui.dialogue(0, NAMES[stage], text, choices)
