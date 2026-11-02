extends RefCounted

# This is corruption detection and input validation, NOT a security boundary.
# Never accept these offline balances as authoritative server balances.
const PATH = "user://playtest_profile_v1.json"
var data = {"version": 1, "level": 1, "coins": 0, "wins": 0, "skin": 0, "upgrades": [0, 0, 0], "sound": true, "haptics": true}
var warning = ""

func load_profile() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f = FileAccess.open(PATH, FileAccess.READ)
	if f == null or f.get_length() > 16384:
		warning = "Save unavailable. Started a fresh local profile."
		return
	var envelope = JSON.parse_string(f.get_as_text())
	if not envelope is Dictionary or not envelope.get("payload") is String:
		warning = "Damaged save ignored."
		return
	if envelope.payload.sha256_text() != envelope.get("checksum", ""):
		warning = "Save checksum mismatch. Local profile reset."
		return
	var parsed = JSON.parse_string(envelope.payload)
	if not valid(parsed):
		warning = "Invalid save values ignored."
		return
	data = parsed

static func valid(d: Variant) -> bool:
	if not d is Dictionary:
		return false
	for key in ["version", "level", "coins", "wins", "skin", "upgrades", "sound", "haptics"]:
		if not d.has(key):
			return false
	for key in ["version", "level", "coins", "wins", "skin"]:
		if not (d[key] is int or d[key] is float) or not is_finite(float(d[key])) or float(d[key]) != floor(float(d[key])):
			return false
	if d.version != 1 or d.level < 1 or d.level > 100000 or d.coins < 0 or d.coins > 10000000 or d.wins < 0 or d.wins > 100000 or d.skin < 0 or d.skin > 11:
		return false
	if not d.sound is bool or not d.haptics is bool or not d.upgrades is Array or d.upgrades.size() != 3:
		return false
	for n in d.upgrades:
		if not (n is int or n is float) or n < 0 or n > 6 or float(n) != floor(float(n)):
			return false
	if d.has("stars"):
		if not d.stars is Dictionary or d.stars.size() > 100000: return false
		for stage in d.stars:
			if not str(stage).is_valid_int() or int(stage) < 1 or int(stage) > 100000: return false
			var value = d.stars[stage]
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 3 or float(value) != floor(float(value)): return false
	return true

func save() -> void:
	var payload = JSON.stringify(data)
	var f = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"payload": payload, "checksum": payload.sha256_text()}))
	f.close()
	DirAccess.rename_absolute(PATH + ".tmp", PATH)
