extends Node2D

@export var body_radius: float = 24.0
@export var body_color: Color = Color(0.92, 0.95, 1.0)
@export var aim_direction: Vector2 = Vector2.RIGHT
@export var is_local_player: bool = false
@export var upgrade_animation_duration: float = 1.05

var upgrade_animation_left: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if upgrade_animation_left > 0.0:
		upgrade_animation_left = maxf(0.0, upgrade_animation_left - delta)
		queue_redraw()


func _draw() -> void:
	var current_body_color := body_color
	if upgrade_animation_left > 0.0:
		var upgrade_ratio: float = upgrade_animation_left / maxf(0.001, upgrade_animation_duration)
		current_body_color = current_body_color.lerp(Color(1.0, 0.88, 0.34), 0.34 + 0.26 * upgrade_ratio)

	draw_circle(Vector2.ZERO, body_radius, current_body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 32, Color(0.15, 0.22, 0.32), 3.0)
	draw_line(Vector2.ZERO, aim_direction.normalized() * (body_radius + 18.0), Color(0.40, 0.70, 1.0), 3.0)

	if is_local_player:
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 32, Color(0.96, 0.98, 1.0, 0.92), 3.0)

	if upgrade_animation_left > 0.0:
		var effect_ratio: float = upgrade_animation_left / maxf(0.001, upgrade_animation_duration)
		var reveal_ratio: float = 1.0 - effect_ratio
		var time_sec: float = Time.get_ticks_msec() / 1000.0
		draw_circle(
			Vector2.ZERO,
			body_radius + 4.0 + 7.0 * reveal_ratio,
			Color(1.0, 0.93, 0.52, 0.18 + 0.22 * effect_ratio)
		)
		draw_circle(
			Vector2.ZERO,
			body_radius + 10.0 + 10.0 * reveal_ratio,
			Color(1.0, 0.88, 0.32, 0.12 + 0.18 * effect_ratio)
		)
		draw_arc(
			Vector2.ZERO,
			body_radius + 12.0 + 8.0 * reveal_ratio,
			time_sec * 2.7,
			time_sec * 2.7 + PI * 1.28,
			40,
			Color(1.0, 0.82, 0.24, 0.9 - 0.35 * reveal_ratio),
			4.0
		)
		for spark_index in range(4):
			var spark_angle: float = time_sec * 3.5 + float(spark_index) * TAU * 0.25
			var spark_direction := Vector2.RIGHT.rotated(spark_angle)
			var spark_start := spark_direction * (body_radius + 6.0)
			var spark_end := spark_direction * (body_radius + 24.0 + 14.0 * reveal_ratio)
			draw_line(spark_start, spark_end, Color(1.0, 0.93, 0.48, 0.92), 3.0)


func play_upgrade_animation() -> void:
	upgrade_animation_left = maxf(upgrade_animation_left, upgrade_animation_duration)
	queue_redraw()
