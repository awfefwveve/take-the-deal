extends Control
var kind = "coin"
var color = Color("ffc54d")

func _draw() -> void:
	var c = size / 2
	var r = minf(size.x, size.y) * 0.4
	match kind:
		"coin":
			draw_circle(c + Vector2(0, 2), r, Color("d99232"))
			draw_circle(c, r, color)
			draw_arc(c, r * 0.72, 0, TAU, 32, Color("fff0a0"), 2, true)
			draw_line(c - Vector2(0, r * 0.4), c + Vector2(0, r * 0.4), Color("fff0a0"), 3, true)
		"heart":
			var points = PackedVector2Array()
			for i in range(64):
				var t = i * TAU / 64
				points.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * r / 17)
			draw_colored_polygon(points, color)
		"star":
			var points = PackedVector2Array()
			for i in range(10): points.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * r * (1.0 if i % 2 == 0 else 0.48))
			draw_colored_polygon(points, color)
		"arrow":
			draw_line(c + Vector2(-r * 0.5, -r * 0.65), c + Vector2(r * 0.25, 0), color, 4, true)
			draw_line(c + Vector2(r * 0.25, 0), c + Vector2(-r * 0.5, r * 0.65), color, 4, true)
		"pause":
			draw_style_box(_pill(color), Rect2(c + Vector2(-r * 0.5, -r * 0.6), Vector2(r * 0.3, r * 1.2)))
			draw_style_box(_pill(color), Rect2(c + Vector2(r * 0.2, -r * 0.6), Vector2(r * 0.3, r * 1.2)))
		"bolt":
			draw_colored_polygon(PackedVector2Array([c + Vector2(1, -r), c + Vector2(-r * 0.7, 2), c + Vector2(-1, 2), c + Vector2(-2, r), c + Vector2(r * 0.7, -2), c + Vector2(1, -2)]), color)

func _pill(tint: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(3)
	return style
