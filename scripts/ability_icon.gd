class_name AbilityIcon
extends Control

@export var ability_id: String = ""
@export var tint: Color = Color(0.92, 0.95, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(28.0, 28.0)
	queue_redraw()


func set_ability(new_ability_id: String) -> void:
	ability_id = new_ability_id
	queue_redraw()


func set_tint(new_tint: Color) -> void:
	tint = new_tint
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	match ability_id:
		"fireball":
			_draw_fireball(center)
		"mine":
			_draw_mine(center)
		"dash":
			_draw_dash(center)
		"reflect_shield":
			_draw_reflect_shield(center)
		_:
			draw_circle(center, 7.0, tint)


func _draw_fireball(center: Vector2) -> void:
	draw_line(center + Vector2(-11.0, 0.0), center + Vector2(-2.0, 0.0), Color(tint.r, tint.g, tint.b, 0.45), 5.0)
	draw_line(center + Vector2(-8.0, -4.0), center + Vector2(-1.0, -1.0), Color(tint.r, tint.g, tint.b, 0.26), 3.0)
	draw_circle(center + Vector2(4.0, 0.0), 7.0, tint)
	draw_circle(center + Vector2(5.0, -1.0), 3.2, Color(0.98, 0.98, 1.0, 0.82))


func _draw_mine(center: Vector2) -> void:
	draw_arc(center, 8.0, 0.0, TAU, 28, tint, 2.2)
	draw_circle(center, 4.0, tint)
	draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, -12.0), tint, 2.0)
	draw_circle(center + Vector2(0.0, -14.0), 2.2, Color(0.98, 0.98, 1.0, 0.82))
	draw_line(center + Vector2(-8.0, 8.0), center + Vector2(8.0, 8.0), Color(tint.r, tint.g, tint.b, 0.8), 2.2)


func _draw_dash(center: Vector2) -> void:
	var points_a := PackedVector2Array([
		center + Vector2(-10.0, -6.0),
		center + Vector2(-2.0, 0.0),
		center + Vector2(-10.0, 6.0)
	])
	var points_b := PackedVector2Array([
		center + Vector2(-1.0, -6.0),
		center + Vector2(7.0, 0.0),
		center + Vector2(-1.0, 6.0)
	])
	draw_polyline(points_a, tint, 2.6)
	draw_polyline(points_b, Color(0.98, 0.98, 1.0, 0.88), 2.6)


func _draw_reflect_shield(center: Vector2) -> void:
	var impact_center := center + Vector2(-4.0, 0.0)
	draw_arc(center + Vector2(2.0, 0.0), 9.5, -PI * 0.58, PI * 0.58, 28, tint, 2.6)
	draw_arc(center + Vector2(2.0, 0.0), 6.5, -PI * 0.50, PI * 0.50, 24, Color(0.95, 1.0, 1.0, 0.88), 1.6)
	draw_circle(impact_center, 3.6, tint)
	draw_circle(impact_center, 1.7, Color(0.98, 0.98, 1.0, 0.95))
	draw_line(center + Vector2(-12.0, 0.0), center + Vector2(-6.2, 0.0), Color(tint.r, tint.g, tint.b, 0.62), 2.2)
	draw_line(center + Vector2(-10.0, -3.4), center + Vector2(-6.8, -1.2), Color(tint.r, tint.g, tint.b, 0.34), 1.6)
	draw_line(center + Vector2(-10.0, 3.4), center + Vector2(-6.8, 1.2), Color(tint.r, tint.g, tint.b, 0.34), 1.6)
