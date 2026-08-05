extends CharacterBody2D

@export var body_radius: float = 26.0
@export var body_color: Color = Color(0.96, 0.73, 0.28)
@export var ring_color: Color = Color(0.45, 0.22, 0.05)
@export var knockback_decay: float = 1300.0

var knockback_velocity: Vector2 = Vector2.ZERO
var spawn_position: Vector2


func _ready() -> void:
	add_to_group("push_targets")
	spawn_position = global_position
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 32, ring_color, 3.0)
	draw_line(Vector2(-10.0, -10.0), Vector2(10.0, 10.0), ring_color, 3.0)
	draw_line(Vector2(-10.0, 10.0), Vector2(10.0, -10.0), ring_color, 3.0)


func _physics_process(delta: float) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	_check_holes()


func get_hit_radius() -> float:
	return body_radius


func apply_knockback(push_direction: Vector2, strength: float) -> void:
	if push_direction.length_squared() <= 0.001:
		return

	knockback_velocity += push_direction.normalized() * strength


func _check_holes() -> void:
	for hole in get_tree().get_nodes_in_group("holes"):
		if not is_instance_valid(hole):
			continue
		if not hole.has_method("get_hole_radius"):
			continue

		var hole_radius: float = hole.get_hole_radius()
		var fall_radius := maxf(12.0, hole_radius - body_radius * 0.35)
		if global_position.distance_squared_to(hole.global_position) > fall_radius * fall_radius:
			continue

		_respawn_from_hole()
		return


func _respawn_from_hole() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
