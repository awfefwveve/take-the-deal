extends RefCounted

const POWERS = [
	["GIANT", "BREAK THE RULES", "size", 2.8],
	["MEGA GIANT", "BIGGER. MUCH BIGGER.", "size", 3.8],
	["TANK", "MAKE YOUR OWN ROAD", "vehicle", 1.0],
	["JETPACK", "THE FLOOR IS OPTIONAL", "flight", 1.0],
	["LASER EYES", "LOOK. IT'S GONE.", "beam", 1.0],
	["TIME STOP", "EVERYBODY FREEZE", "time", 1.0],
	["CLONE x10", "BRING YOUR FRIENDS", "clone", 10.0],
	["CLONE x50", "BRING EVERYBODY", "clone", 50.0],
	["INVINCIBLE", "NOT A SCRATCH", "shield", 1.0],
	["SUPER SPEED", "BLINK AND YOU'LL MISS IT", "speed", 1.0],
	["LONG LEGS", "STEP OVER THE PROBLEM", "flight", 1.0],
	["LONG ARMS", "PERSONAL SPACE?", "beam", 1.0],
	["MAGNET", "ALL MINE", "magnet", 1.0],
	["MONSTER MODE", "LET IT OUT", "size", 3.0],
	["ROCKET", "NEXT STOP: CHAOS", "flight", 1.0],
	["WRECKING BALL", "DEMOLITION DAY", "vehicle", 1.0],
	["DRAGON", "A LITTLE OVERKILL", "flight", 1.0],
	["GIANT HAMMER", "PROBLEM. SOLVED.", "beam", 1.0],
	["REVENGE MODE", "YOUR TURN NOW", "size", 3.5],
	["DESTROY EVERYTHING", "YES, EVERYTHING", "beam", 2.0]
]
const SKINS = ["ORIGINAL", "NINJA", "ROBOT", "ZOMBIE", "POLICE", "CLOWN", "KNIGHT", "ALIEN", "DINO", "DEMON", "HERO", "GOLD"]
const COLORS = ["ff713e", "666191", "a7c6e0", "8bc65f", "4987ee", "f066be", "8a94aa", "a4f36a", "30bd9c", "d04b64", "60d4ed", "ffcc54"]
const BOSSES = ["거인 수문장", "아이언 로봇", "탱크 대장", "캐니언 괴수", "자이언트 킹", "메가 로봇"]
const PRICES = [100, 250, 500, 900, 1500, 2500]
const MODULES = ["wall", "crowd", "laser", "car", "bridge", "moving", "crusher", "ball", "water", "fire", "gate", "spinner", "hole", "wall", "crowd"]
const POWER_NAMES = ["거인", "초거대 거인", "탱크", "제트팩", "레이저 눈", "시간 정지", "분신 10명", "분신 50명", "무적 보호막", "초고속 질주", "롱다리", "롱암 펀치", "코인 자석", "몬스터", "로켓", "철거공", "드래곤", "거대 망치", "복수의 거인", "전부 파괴"]
const POWER_DESC = ["벽도 적도 한 번에 쿵!", "화면을 가득 채우는 파괴력", "묵직한 궤도로 전진!", "장애물 위로 날아가요", "바라보면 사라지는 장애물", "움직이는 위험을 멈춰요", "친구들과 함께 돌파!", "작은 군단의 큰 돌격", "부딪혀도 아무렇지 않아요", "더 빠르게, 더 시원하게", "높은 곳에서 성큼성큼", "멀리 있는 장애물까지 펀치", "놓칠 뻔한 코인도 쏙", "참을 수 없는 파괴 본능", "하늘을 가르는 주황 로켓", "커다란 철구로 밀어버려요", "날개를 펴고 날아올라요", "문제는 망치로 해결!", "이제 내 차례야", "길 위의 모든 것을 쓸어버려요"]
const SKIN_NAMES = ["오렌지", "닌자", "로봇", "좀비", "경찰", "광대", "기사", "외계인", "공룡", "악마", "히어로", "골든 킹"]
const WORLDS = [
	{"name": "코코넛 해변", "kinds": ["wall", "crowd", "hole", "car"], "powers": [0, 2, 3]},
	{"name": "선셋 캐니언", "kinds": ["ball", "bridge", "wall", "car"], "powers": [15, 14, 1]},
	{"name": "캔디 가든", "kinds": ["spinner", "gate", "crowd", "moving"], "powers": [6, 7, 12]},
	{"name": "프로즌 피크", "kinds": ["laser", "water", "crusher", "hole"], "powers": [5, 8, 10]},
	{"name": "로봇 팩토리", "kinds": ["crusher", "laser", "car", "moving"], "powers": [4, 11, 17]},
	{"name": "스타라이트 시티", "kinds": ["fire", "bridge", "crowd", "spinner"], "powers": [16, 18, 19]}
]
const ROUTES = ["11100111222111100", "11222111000111222", "11000111222110001", "12211100011122211", "10011122111000111"]
const RHYTHMS = ["00100122001300120", "01230123012301230", "00112233001122330", "03210321032103210", "01023201023201230"]

static func level_data(level: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = 10937 + level * 7919
	var rows: Array = []
	var count = 12 if level == 1 else 17
	if level % 5 == 0: count = 15
	var zone = mini(5, int((level - 1) / 5)) if level <= 30 else int((level - 1) / 5) % 6
	var chapter_stage = (level - 1) % 5
	var last_safe = 1
	for i in range(count):
		var safe = int(ROUTES[chapter_stage][i]) if level <= 30 else clampi(last_safe + rng.randi_range(-1, 1), 0, 2)
		var kind = WORLDS[zone].kinds[int(RHYTHMS[chapter_stage][i])]
		if level == 1:
			kind = "wall" if i % 2 == 0 else "crowd"
		if i == 0:
			safe = 1
		rows.append({"distance": 30.0 + i * 15.0, "safe": safe, "kind": kind})
		last_safe = safe
	var deals: Array = []
	if level > 1:
		deals = [53.0, 188.0]
		if level > 10:
			deals.append(233.0)
	var showcase = WORLDS[zone].powers[chapter_stage % 3]
	var mission = chapter_stage % 3
	if mission == 2: showcase = 0 if zone < 3 else 19
	return {"level": level, "rows": rows, "deals": deals, "length": 225.0 if level == 1 else (278.0 if level % 5 == 0 else 310.0), "boss": level % 5 == 0, "biome": zone, "mission": mission, "showcase": showcase, "showcase_distance": 105.0}
