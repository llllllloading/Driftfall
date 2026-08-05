extends Node2D

const HOLE_SCRIPT := preload("res://scripts/hole.gd")

@export var arm_delay: float = 3.0
@export var trigger_radius: float = 96.0
@export var explosion_delay: float = 0.7
@export var explosion_radius: float = 170.0
@export var explosion_strength: float = 880.0
@export var hole_radius: float = 58.0
@export var body_radius: float = 14.0
@export var owner_safe_time: float = 0.2
@export var control_lock_time: float = 0.12

var owner_node: Node = null
var armed: bool = false
var triggered: bool = false
var state_timer: float = 0.0
var owner_ignore_timer: float = 0.0


func setup(spawn_point: Vector2, source_node: Node = null, config: Dictionary = {}) -> void:
	global_position = spawn_point
	owner_node = source_node

	if not config.is_empty():
		arm_delay = float(config.get("arm_delay_sec", arm_delay))
		trigger_radius = float(config.get("trigger_radius", trigger_radius))
		explosion_delay = float(config.get("trigger_to_explosion_delay_sec", explosion_delay))
		explosion_radius = float(config.get("explosion_radius", explosion_radius))
		explosion_strength = float(config.get("knockback", explosion_strength))
		hole_radius = float(config.get("hole_radius", hole_radius))
		owner_safe_time = float(config.get("owner_safe_time_sec", owner_safe_time))
		control_lock_time = float(config.get("control_lock_sec", control_lock_time))

	state_timer = arm_delay
	owner_ignore_timer = owner_safe_time


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var shell_color := Color(0.45, 0.08, 0.10)
	var time_sec: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(time_sec * 7.0)

	draw_circle(Vector2.ZERO, body_radius, shell_color)

	if not armed:
		var arm_ratio: float = 1.0 - state_timer / maxf(0.001, arm_delay)
		draw_circle(Vector2.ZERO, trigger_radius, Color(0.88, 0.92, 1.0, 0.04))
		draw_arc(
			Vector2.ZERO,
			trigger_radius,
			-PI * 0.5,
			-PI * 0.5 + TAU * arm_ratio,
			64,
			Color(0.88, 0.92, 1.0, 0.6),
			4.0
		)
		draw_circle(Vector2.ZERO, body_radius * (0.35 + arm_ratio * 0.22), Color(0.62, 0.66, 0.75, 0.95))
		draw_circle(Vector2.ZERO, body_radius * 0.68, Color(0.22, 0.24, 0.28, 0.9))
		return

	if triggered:
		var detonation_ratio: float = 1.0 - state_timer / maxf(0.001, explosion_delay)
		var blast_alpha: float = 0.10 + pulse * 0.12
		draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.42, 0.18, blast_alpha))
		draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 64, Color(1.0, 0.44, 0.20, 0.55), 2.5)
		draw_arc(
			Vector2.ZERO,
			explosion_radius,
			-PI * 0.5,
			-PI * 0.5 + TAU * detonation_ratio,
			72,
			Color(1.0, 0.78, 0.40, 0.95),
			5.0
		)
		draw_circle(Vector2.ZERO, body_radius * 0.7, Color(1.0, 0.82, 0.48, 1.0))
		draw_circle(Vector2.ZERO, body_radius * 0.34, Color(0.55, 0.04, 0.02, 1.0))
		return

	var sensor_alpha: float = 0.05 + pulse * 0.05
	var ring_alpha: float = 0.28 + pulse * 0.22
	draw_circle(Vector2.ZERO, trigger_radius, Color(1.0, 0.16, 0.14, sensor_alpha))
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 64, Color(1.0, 0.26, 0.20, ring_alpha), 3.0)
	draw_arc(Vector2.ZERO, trigger_radius * 0.72, 0.0, TAU, 64, Color(1.0, 0.42, 0.30, 0.18 + pulse * 0.12), 2.0)
	draw_circle(Vector2.ZERO, body_radius * 0.72, Color(0.92, 0.18, 0.14, 1.0))
	draw_circle(Vector2.ZERO, body_radius * 0.34, Color(1.0, 0.78, 0.56, 0.95))


func _physics_process(delta: float) -> void:
	if owner_ignore_timer > 0.0:
		owner_ignore_timer = maxf(0.0, owner_ignore_timer - delta)

	if not armed:
		state_timer -= delta
		if state_timer <= 0.0:
			armed = true
		queue_redraw()
		return

	if triggered:
		state_timer -= delta
		if state_timer <= 0.0:
			_explode()
			return
		queue_redraw()
		return

	for node in get_tree().get_nodes_in_group("push_targets"):
		if node == owner_node and owner_ignore_timer > 0.0:
			continue
		if not is_instance_valid(node):
			continue
		if not node.has_method("get_hit_radius"):
			continue

		var target_position: Vector2 = node.global_position
		var distance: float = global_position.distance_to(target_position)
		if distance > trigger_radius + node.get_hit_radius():
			continue

		triggered = true
		state_timer = explosion_delay
		queue_redraw()
		return

	queue_redraw()


func _explode() -> void:
	for node in get_tree().get_nodes_in_group("push_targets"):
		if not is_instance_valid(node):
			continue
		if not node.has_method("get_hit_radius") or not node.has_method("apply_knockback"):
			continue

		var target_position: Vector2 = node.global_position
		var push_vector: Vector2 = target_position - global_position
		var distance: float = push_vector.length()
		if distance > explosion_radius + node.get_hit_radius():
			continue

		if distance <= 0.001:
			push_vector = Vector2.UP

		node.apply_knockback(push_vector.normalized(), explosion_strength, control_lock_time, owner_node)

	_spawn_hole()
	queue_free()


func _spawn_hole() -> void:
	var hole = HOLE_SCRIPT.new()
	var arena_layer: Node = get_tree().current_scene.get_node("Arena")
	hole.hole_radius = hole_radius
	hole.global_position = global_position
	arena_layer.add_child(hole)
