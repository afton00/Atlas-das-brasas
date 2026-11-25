extends RefCounted

const MINUTES_PER_DAY = 1440
const GAME_MINUTES_PER_SECOND = 3.0
const SKY_NAMES = ["Céu limpo", "Nublado", "Chuva leve", "Chuva forte", "Vento", "Neve"]
const PERIODS = ["Madrugada", "Manhã", "Tarde", "Noite"]
# Simulated six-hour observations. Each regional schedule drives both sky and gauge.
const RIVER_SKIES = [[1,0,2,1], [2,1,3,0], [0,0,1,0], [1,2,2,1]]
const DRY_SKIES = [0,4,4,1,0,0,4,0]
const ALPINE_SKIES = [1,5,0,4,5,1,4,0]
const FOREST_SKIES = [2,1,3,0,1,2,0,2]
const BASALT_SKIES = [4,0,1,4,1,0,4,1]

static func day(minutes:float)->int:
	return floori(minutes/MINUTES_PER_DAY)

static func period(minutes:float)->int:
	return floori(fposmod(minutes,MINUTES_PER_DAY)/360.0)

static func clock_text(minutes:float)->String:
	var minute=posmod(floori(minutes),MINUTES_PER_DAY)
	return "%02d:%02d"%[floori(minute/60.0),minute%60]

static func date_name(d:int)->String:
	return "Véspera da jornada" if d==0 else "Dia %d"%d

static func sky(region:int,d:int,slot:int)->int:
	if region in [0,1]:
		return RIVER_SKIES[posmod(d+region*2,4)][slot]
	var sequence=[DRY_SKIES,ALPINE_SKIES,FOREST_SKIES,BASALT_SKIES][clampi(region,2,5)-2]
	return sequence[posmod(d*3+slot+region,sequence.size())]

static func daily_rain(region:int,d:int)->int:
	var total=0
	for slot in 4:
		var weather=sky(region,d,slot)
		if weather==2:total+=3
		if weather==3:total+=9
	return total

static func lighting(minutes:float)->Color:
	var hour=fposmod(minutes,1440.0)/60.0
	var stops=[0,4.5,6,8.5,15.5,18,20.5,24]
	var colors=[Color("#9badd1"),Color("#9badd1"),Color("#e8c1ac"),Color.WHITE,Color.WHITE,Color("#f0c7a5"),Color("#9badd1"),Color("#9badd1")]
	for i in range(1,stops.size()):
		if hour<=stops[i]:
			return colors[i-1].lerp(colors[i],inverse_lerp(stops[i-1],stops[i],hour))
	return colors[0]
