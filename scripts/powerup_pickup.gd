extends Node2D

@export var pickup_radius: float = 26.0
@export var life_time: float = 9.0
@export var reveal_time: float = 1.0

var powerup_id: String = "burst_bomb"
var owner_controller: Node = null
var life_left: float = 0.0
var reveal_left: float = 0.0


func setup(spawn_point: Vector2, new_powerup_id: String, controller: Node = null) -> void:
	global_position = spawn_point
	powerup_id = new_powerup_id
	owner_controller = controller
	life_left = life_time
	reveal_left = reveal_time


func _ready() -> void:
	add_to_group("powerups")
	queue_redraw()


func _exit_tree() -> void:
	remove_from_group("powerups")


func _physics_process(delta: float) -> void:
	if reveal_left > 0.0:
		reveal_left = maxf(0.0, reveal_left - delta)
		queue_redraw()
		return

	life_left = maxf(0.0, life_left - delta)
	if life_left <= 0.0:
		queue_free()
		return

	for node in get_tree().get_nodes_in_group("push_targets"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_hit_radius") or not node.has_method("collect_powerup"):
			continue

		var hit_radius: float = float(node.get_hit_radius())
		var combined_radius: float = pickup_radius + hit_radius
		if global_position.distance_squared_to(node.global_position) > combined_radius * combined_radius:
			continue

		if node.collect_powerup(powerup_id):
			if owner_controller != null and is_instance_valid(owner_controller) and owner_controller.has_method("notify_powerup_collected"):
				owner_controller.notify_powerup_collected(self, node, powerup_id)
			queue_free()
			return

	queue_redraw()


func _draw() -> void:
	var reveal_ratio: float = 1.0
	if reveal_time > 0.001:
		reveal_ratio = 1.0 - clampf(reveal_left / reveal_time, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	var alpha: float = 0.52 + 0.38 * reveal_ratio
	var outline_alpha: float = 0.62 + 0.28 * pulse

	var accent := _get_powerup_color()
	var outer_radius: float = 18.0 + 7.0 * reveal_ratio
	var core_radius: float = 8.0 + 3.0 * reveal_ratio
	var halo_radius: float = 36.0 + 12.0 * pulse
	var spin_angle: float = Time.get_ticks_msec() / 520.0

	draw_circle(Vector2.ZERO, halo_radius, Color(accent.r, accent.g, accent.b, 0.10 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, pickup_radius + 10.0, 0.0, TAU, 64, Color(accent.r, accent.g, accent.b, outline_alpha), 3.0)
	draw_arc(Vector2.ZERO, pickup_radius + 4.0, spin_angle, spin_angle + PI * 1.35, 28, Color(1.0, 1.0, 1.0, 0.42), 2.2)
	draw_circle(Vector2.ZERO, outer_radius, Color(accent.r, accent.g, accent.b, alpha))
	draw_circle(Vector2.ZERO, outer_radius * 0.62, Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45, 0.92))
	draw_circle(Vector2.ZERO, core_radius, Color(1.0, 0.98, 0.92, 0.96))

	match powerup_id:
		"burst_bomb":
			for step in range(8):
				var angle := TAU * float(step) / 8.0
				var dir := Vector2.RIGHT.rotated(angle)
				draw_line(dir * 12.0, dir * 26.0, Color(1.0, 0.78, 0.36, 0.98), 2.8)
			draw_circle(Vector2.ZERO, 6.4, Color(1.0, 0.72, 0.30, 0.95))
		"haste":
			for offset in [-10.0, 0.0, 10.0]:
				draw_line(Vector2(-12.0, offset), Vector2(10.0, offset - 8.0), Color(0.44, 1.0, 0.58, 0.95), 3.0)
				draw_line(Vector2(-2.0, offset + 2.0), Vector2(14.0, offset - 3.0), Color(0.84, 1.0, 0.90, 0.55), 1.6)
		"shield":
			draw_arc(Vector2.ZERO, 17.0, PI * 0.14, PI * 0.86, 24, Color(0.50, 0.92, 1.0, 1.0), 3.2)
			draw_arc(Vector2.ZERO, 17.0, PI * 1.14, PI * 1.86, 24, Color(0.50, 0.92, 1.0, 1.0), 3.2)
			draw_circle(Vector2.ZERO, 4.2, Color(0.82, 1.0, 1.0, 0.95))


func _get_powerup_color() -> Color:
	match powerup_id:
		"burst_bomb":
			return Color(1.0, 0.48, 0.18)
		"haste":
			return Color(0.24, 0.95, 0.42)
		"shield":
			return Color(0.34, 0.82, 1.0)
	return Color(1.0, 1.0, 1.0)
