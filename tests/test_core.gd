extends SceneTree

const Catalog = preload("res://scripts/catalog.gd")
const Profile = preload("res://scripts/profile.gd")
const Gate = preload("res://scripts/reward_gate.gd")
var checks = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		quit(1)

func _initialize() -> void:
	for level in range(1, 101):
		var data = Catalog.level_data(level)
		check(data == Catalog.level_data(level), "Levels must be reproducible")
		check(data.boss == (level % 5 == 0), "Boss cadence")
		var previous = 1
		for row in data.rows:
			check(row.safe >= 0 and row.safe <= 2, "Free lane exists")
			check(abs(row.safe - previous) <= 1, "Reachable lane transition")
			previous = row.safe
		check(data.length / 8.2 <= 45, "Run duration")
	var gate = Gate.new()
	check(not gate.complete_preview("forged", true), "Reject forged callback")
	var ticket = gate.begin()
	check(not ticket.is_empty(), "Issue ticket")
	check(gate.begin().is_empty(), "One pending request")
	check(gate.complete_preview(ticket, true), "Complete once")
	check(not gate.complete_preview(ticket, true), "Reject replay")
	ticket = gate.begin()
	check(not gate.complete_preview(ticket, false), "Cancellation grants nothing")
	check(not gate.complete_preview(ticket, true), "Cancelled ticket cannot grant")
	ticket = gate.begin()
	gate.cancel()
	check(not gate.complete_preview(ticket, true), "Focus-loss callback rejected")
	gate.mode = Gate.Mode.PRODUCTION
	check(gate.begin().is_empty(), "Unconfigured production fails closed")
	var profile = Profile.new()
	check(Profile.valid(profile.data), "Default profile")
	var bad = profile.data.duplicate(true)
	bad.coins = -1
	check(not Profile.valid(bad), "Negative balance rejected")
	bad.coins = 1.5
	check(not Profile.valid(bad), "Fractional balance rejected")
	bad.coins = 1000000000
	check(not Profile.valid(bad), "Out-of-range balance rejected")
	bad = profile.data.duplicate(true)
	bad.upgrades = [0, 0, 99]
	check(not Profile.valid(bad), "Invalid upgrade rejected")
	check(not Profile.valid({}), "Missing fields rejected")
	print("CORE_TESTS_PASSED ", checks)
	quit(0)
