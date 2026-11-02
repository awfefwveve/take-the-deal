extends RefCounted

# Preview rewards never represent an ad impression or an SSV-verified reward.
# Production deliberately fails closed until a real native + server adapter exists.
enum Mode { PREVIEW, PRODUCTION }
var mode = Mode.PREVIEW
var pending = ""
var issued = {}
var sequence = 0

func begin() -> String:
	if not pending.is_empty() or mode == Mode.PRODUCTION:
		return ""
	sequence += 1
	pending = "%s-%s" % [Time.get_ticks_usec(), sequence]
	return pending

func complete_preview(ticket: String, completed: bool) -> bool:
	if mode != Mode.PREVIEW or ticket.is_empty() or ticket != pending or issued.has(ticket):
		return false
	pending = ""
	if not completed:
		return false
	issued[ticket] = true
	return true

func cancel() -> void:
	pending = ""
