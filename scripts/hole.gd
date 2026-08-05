extends Node2D

@export var hole_radius: float = 58.0


func _ready() -> void:
	add_to_group("holes")
	z_as_relative = false
	z_index = -5
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, hole_radius, Color(0.03, 0.03, 0.06))
	draw_arc(Vector2.ZERO, hole_radius, 0.0, TAU, 48, Color(0.20, 0.22, 0.28), 3.0)
	draw_arc(Vector2.ZERO, hole_radius * 0.62, 0.0, TAU, 48, Color(0.00, 0.00, 0.00, 0.55), 2.0)


func get_hole_radius() -> float:
	return hole_radius
