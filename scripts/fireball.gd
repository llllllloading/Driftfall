extends Node2D

@export var speed: float = 805.0
@export var max_distance: float = 1100.0
@export var radius: float = 12.0
@export var outer_color: Color = Color(1.0, 0.45, 0.15)
@export var core_color: Color = Color(1.0, 0.85, 0.45)
@export var push_strength: float = 1050.0
@export var hit_stun_duration: float = 0.18
@export var long_shot_threshold: float = 0.0
@export var long_shot_push_strength: float = 0.0
@export var long_shot_hit_stun_duration: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var source_node: Node = null
var reflected: bool = false
var reflect_instability_bonus: float = 0.0


func setup(spawn_position: Vector2, shoot_direction: Vector2, owner_node: Node = null) -> void:
	global_position = spawn_position
	source_node = owner_node
	if shoot_direction.length_squared() > 0.001:
		direction = shoot_direction.normalized()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var tail_start := -direction * (radius + 24.0)
	var tail_mid := -direction * (radius + 11.0)
	draw_line(tail_start, Vector2.ZERO, Color(1.0, 0.48, 0.15, 0.20), 7.0)
	draw_line(tail_mid, Vector2.ZERO, Color(1.0, 0.72, 0.28, 0.42), 4.0)
	draw_circle(Vector2.ZERO, radius, outer_color)
	draw_circle(Vector2.ZERO, radius * 0.55, core_color)
	draw_circle(Vector2.ZERO, radius * 0.26, Color(1.0, 0.98, 0.78, 0.9))


func _physics_process(delta: float) -> void:
	var step: Vector2 = direction * speed * delta
	global_position += step
	traveled_distance += step.length()

	_check_target_hit()

	if traveled_distance >= max_distance:
		queue_free()


func _check_target_hit() -> void:
	for node in get_tree().get_nodes_in_group("push_targets"):
		if node == source_node:
			continue

		if not is_instance_valid(node):
			continue

		if not node.has_method("get_hit_radius") or not node.has_method("apply_knockback"):
			continue

		var hit_radius: float = node.get_hit_radius()
		var combined_radius: float = radius + hit_radius
		if global_position.distance_squared_to(node.global_position) > combined_radius * combined_radius:
			continue

		var effective_push_strength: float = push_strength
		var effective_hit_stun: float = hit_stun_duration
		if long_shot_threshold > 0.0 and traveled_distance >= long_shot_threshold:
			if long_shot_push_strength > 0.0:
				effective_push_strength = long_shot_push_strength
			if long_shot_hit_stun_duration > 0.0:
				effective_hit_stun = long_shot_hit_stun_duration

		if node.has_method("try_reflect_fireball") and node.try_reflect_fireball(self):
			return

		node.apply_knockback(direction, effective_push_strength, effective_hit_stun, source_node)
		if reflect_instability_bonus > 0.0 and node.has_method("apply_extra_instability_bonus"):
			node.apply_extra_instability_bonus(reflect_instability_bonus)
		queue_free()
		return


func reflect_from_shield(
	owner_node: Node,
	new_direction: Vector2,
	speed_multiplier: float = 1.0,
	knockback_multiplier: float = 1.0,
	instability_bonus_value: float = 0.0
) -> void:
	source_node = owner_node
	if new_direction.length_squared() > 0.001:
		direction = new_direction.normalized()
	traveled_distance = 0.0
	speed *= maxf(0.2, speed_multiplier)
	push_strength *= maxf(0.2, knockback_multiplier)
	reflect_instability_bonus = maxf(0.0, instability_bonus_value)
	set_reflected_visuals()
	if owner_node != null and owner_node.has_method("get_hit_radius"):
		global_position = owner_node.global_position + direction * (float(owner_node.get_hit_radius()) + radius + 10.0)
	queue_redraw()


func set_reflected_visuals() -> void:
	reflected = true
	outer_color = Color(0.42, 0.90, 1.0, 1.0)
	core_color = Color(0.86, 1.0, 1.0, 0.96)
