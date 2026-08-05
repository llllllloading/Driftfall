extends Node

const POWERUP_PICKUP_SCRIPT := preload("res://scripts/powerup_pickup.gd")

@export var enabled: bool = true
@export var first_spawn_delay: float = 12.0
@export var spawn_interval: float = 15.0
@export var pickup_life_time: float = 9.0
@export var pickup_reveal_time: float = 1.0
@export var edge_padding: float = 180.0
@export var fighter_padding: float = 150.0

const POWERUP_IDS := ["burst_bomb", "haste", "shield"]

var owner_controller: Node = null
var rng := RandomNumberGenerator.new()
var spawn_left: float = 0.0
var current_pickup: Node = null


func setup(controller: Node) -> void:
	owner_controller = controller
	rng.randomize()
	reset_for_new_match()


func reset_for_new_match() -> void:
	clear_active_pickup()
	spawn_left = first_spawn_delay


func clear_active_pickup() -> void:
	if current_pickup != null and is_instance_valid(current_pickup):
		current_pickup.queue_free()
	current_pickup = null


func process_round(delta: float) -> void:
	if not enabled:
		return
	if owner_controller == null or not is_instance_valid(owner_controller):
		return
	if current_pickup != null and is_instance_valid(current_pickup):
		return

	spawn_left = maxf(0.0, spawn_left - delta)
	if spawn_left > 0.0:
		return

	_spawn_powerup()
	spawn_left = spawn_interval


func notify_pickup_collected(pickup: Node) -> void:
	if pickup == current_pickup:
		current_pickup = null


func _spawn_powerup() -> void:
	var powerup_layer := owner_controller.get_node_or_null("Powerups")
	if powerup_layer == null:
		return

	var spawn_position := _find_spawn_position()
	var powerup_index: int = rng.randi_range(0, POWERUP_IDS.size() - 1)
	var powerup_id: String = str(POWERUP_IDS[powerup_index])
	var pickup = POWERUP_PICKUP_SCRIPT.new()
	pickup.life_time = pickup_life_time
	pickup.reveal_time = pickup_reveal_time
	pickup.setup(spawn_position, powerup_id, owner_controller)
	powerup_layer.add_child(pickup)
	current_pickup = pickup


func _find_spawn_position() -> Vector2:
	var arena := owner_controller.get_node_or_null("Arena")
	if arena == null:
		return Vector2(960.0, 540.0)
	if not arena.has_method("get_arena_center") or not arena.has_method("get_arena_radius"):
		return Vector2(960.0, 540.0)

	var center: Vector2 = arena.get_arena_center()
	var radius: float = float(arena.get_arena_radius())
	var max_spawn_radius: float = maxf(120.0, radius - edge_padding)

	for _attempt in range(24):
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * max_spawn_radius
		var candidate := center + Vector2.RIGHT.rotated(angle) * distance
		if _is_spawn_position_valid(candidate):
			return candidate

	return center


func _is_spawn_position_valid(candidate: Vector2) -> bool:
	if owner_controller == null or not is_instance_valid(owner_controller):
		return true

	for fighter in owner_controller.get_fighter_nodes():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if candidate.distance_squared_to(fighter.global_position) < fighter_padding * fighter_padding:
			return false

	return true
