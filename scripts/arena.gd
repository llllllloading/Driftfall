extends Node2D

@export var arena_center: Vector2 = Vector2(960.0, 540.0)
@export var arena_radius: float = 1290.0
@export var void_padding: float = 2200.0
@export var shrink_enabled: bool = true
@export var shrink_start_time: float = 16.0
@export var shrink_mid_time: float = 30.0
@export var shrink_late_time: float = 42.0
@export var shrink_end_time: float = 54.0
@export var shrink_mid_radius_scale: float = 0.84
@export var shrink_late_radius_scale: float = 0.58
@export var shrink_final_radius_scale: float = 0.34
@export var shrink_tiny_radius_scale: float = 0.14
@export var shrink_post_end_speed: float = 34.0
@export var shrink_stage_1_center_shift_ratio: float = 0.12
@export var shrink_stage_2_center_shift_ratio: float = 0.22
@export var shrink_stage_3_center_shift_ratio: float = 0.32
@export var shrink_stage_4_center_shift_ratio: float = 0.40
@export var void_color: Color = Color(0.03, 0.03, 0.06)
@export var island_color: Color = Color(0.36, 0.36, 0.38)
@export var shadow_color: Color = Color(0.00, 0.00, 0.00, 0.22)
@export var rim_color: Color = Color(0.58, 0.62, 0.70, 0.42)
@export var inner_ring_color: Color = Color(0.17, 0.18, 0.22, 0.50)
@export var surface_glow_color: Color = Color(0.46, 0.48, 0.54, 0.14)
@export var shrink_warning_color: Color = Color(0.98, 0.58, 0.22, 0.34)
@export var shrink_edge_color: Color = Color(1.0, 0.76, 0.34, 0.70)
@export var shrink_next_center_color: Color = Color(1.0, 0.90, 0.52, 0.88)
@export var shrink_stage_pulse_time: float = 0.85

var current_arena_radius: float = 0.0
var next_phase_radius: float = 0.0
var current_arena_center: Vector2 = Vector2.ZERO
var next_phase_center: Vector2 = Vector2.ZERO
var stage_1_center: Vector2 = Vector2.ZERO
var stage_2_center: Vector2 = Vector2.ZERO
var stage_3_center: Vector2 = Vector2.ZERO
var stage_4_center: Vector2 = Vector2.ZERO
var shrink_rng := RandomNumberGenerator.new()
var stage_pulse_left: float = 0.0
var last_shrink_stage: int = 0


func _ready() -> void:
	z_index = -10
	shrink_rng.randomize()
	reset_round_state()


func _process(delta: float) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	if not scene_root.has_method("get_round_time_seconds") or not scene_root.has_method("is_round_active"):
		return
	if not scene_root.is_round_active():
		return

	var round_time: float = float(scene_root.get_round_time_seconds())
	var effective_round_time: float = _get_effective_shrink_time(scene_root, round_time)
	var current_stage: int = _get_shrink_stage_for_time(effective_round_time)
	if current_stage != last_shrink_stage:
		last_shrink_stage = current_stage
		if current_stage > 0:
			stage_pulse_left = shrink_stage_pulse_time
	var updated_center: Vector2 = _get_center_for_time(effective_round_time)
	var updated_radius: float = _get_radius_for_time(effective_round_time)
	var updated_next_phase_center: Vector2 = _get_next_phase_center(effective_round_time)
	var updated_next_phase_radius: float = _get_next_phase_radius(effective_round_time)
	var had_pulse: bool = stage_pulse_left > 0.0
	if stage_pulse_left > 0.0:
		stage_pulse_left = maxf(0.0, stage_pulse_left - delta)
	if (
		updated_center.is_equal_approx(current_arena_center)
		and is_equal_approx(updated_radius, current_arena_radius)
		and updated_next_phase_center.is_equal_approx(next_phase_center)
		and is_equal_approx(updated_next_phase_radius, next_phase_radius)
		and not had_pulse
	):
		return

	current_arena_center = updated_center
	current_arena_radius = updated_radius
	next_phase_center = updated_next_phase_center
	next_phase_radius = updated_next_phase_radius
	queue_redraw()


func _draw() -> void:
	var draw_center := get_arena_center()
	var draw_radius := get_arena_radius()
	var pulse_ratio: float = 0.0
	if shrink_stage_pulse_time > 0.001:
		pulse_ratio = clampf(stage_pulse_left / shrink_stage_pulse_time, 0.0, 1.0)
	var pulse_glow: float = sin(pulse_ratio * PI)
	var void_extent := arena_radius + void_padding
	var void_position := draw_center - Vector2(void_extent, void_extent)
	var void_size := Vector2.ONE * void_extent * 2.0
	draw_rect(Rect2(void_position, void_size), void_color, true)

	draw_circle(draw_center + Vector2(0.0, 12.0), draw_radius + 20.0, shadow_color)
	draw_circle(draw_center, draw_radius, island_color)

	if shrink_enabled and next_phase_radius < draw_radius - 1.0:
		if pulse_glow > 0.0:
			draw_circle(next_phase_center, next_phase_radius + 10.0 + 22.0 * pulse_glow, Color(
				shrink_warning_color.r,
				shrink_warning_color.g,
				shrink_warning_color.b,
				0.08 * pulse_glow
			))
		draw_circle(next_phase_center, next_phase_radius, Color(
			shrink_warning_color.r,
			shrink_warning_color.g,
			shrink_warning_color.b,
			0.05 + 0.05 * pulse_glow
		))
		draw_arc(next_phase_center, next_phase_radius, 0.0, TAU, 96, Color(
			shrink_warning_color.r,
			shrink_warning_color.g,
			shrink_warning_color.b,
			0.64 + 0.22 * pulse_glow
		), 5.0 + 2.0 * pulse_glow)
		draw_arc(
			next_phase_center,
			next_phase_radius - 10.0,
			0.0,
			TAU,
			96,
			Color(
				shrink_warning_color.r,
				shrink_warning_color.g,
				shrink_warning_color.b,
				0.18
			),
			2.0
		)
		draw_line(
			next_phase_center + Vector2(-10.0, 0.0),
			next_phase_center + Vector2(10.0, 0.0),
			shrink_next_center_color,
			2.4
		)
		draw_line(
			next_phase_center + Vector2(0.0, -10.0),
			next_phase_center + Vector2(0.0, 10.0),
			shrink_next_center_color,
			2.4
		)
		draw_circle(next_phase_center, 3.6, shrink_next_center_color)

	if pulse_glow > 0.0:
		draw_arc(draw_center, draw_radius + 8.0 * pulse_glow, 0.0, TAU, 96, Color(
			shrink_edge_color.r,
			shrink_edge_color.g,
			shrink_edge_color.b,
			0.34 * pulse_glow
		), 10.0 + 8.0 * pulse_glow)
	draw_arc(draw_center, draw_radius, 0.0, TAU, 96, rim_color, 10.0)
	draw_arc(draw_center, draw_radius - 18.0, 0.0, TAU, 96, inner_ring_color, 4.0)
	draw_arc(draw_center, draw_radius, 0.0, TAU, 96, Color(
		shrink_edge_color.r,
		shrink_edge_color.g,
		shrink_edge_color.b,
		0.92
	), 3.2 + 1.2 * pulse_glow)
	draw_arc(draw_center, draw_radius * 0.68, 0.0, TAU, 96, surface_glow_color, 2.0)
	draw_arc(draw_center, draw_radius * 0.36, 0.0, TAU, 96, surface_glow_color, 1.0)


func get_arena_center() -> Vector2:
	if current_arena_center == Vector2.ZERO:
		return arena_center
	return current_arena_center


func get_arena_radius() -> float:
	if current_arena_radius <= 0.0:
		return arena_radius
	return current_arena_radius


func get_base_arena_radius() -> float:
	return arena_radius


func is_shrink_started() -> bool:
	return get_arena_radius() < arena_radius - 0.5


func reset_round_state(round_time: float = 0.0) -> void:
	_build_shrink_centers()
	current_arena_center = _get_center_for_time(round_time)
	current_arena_radius = _get_radius_for_time(round_time)
	next_phase_center = _get_next_phase_center(round_time)
	next_phase_radius = _get_next_phase_radius(round_time)
	last_shrink_stage = _get_shrink_stage_for_time(round_time)
	stage_pulse_left = 0.0
	queue_redraw()


func get_shrink_progress() -> float:
	if not shrink_enabled or shrink_end_time <= shrink_start_time:
		return 0.0

	var current_radius := get_arena_radius()
	var min_radius := arena_radius * shrink_tiny_radius_scale
	if arena_radius <= min_radius + 0.001:
		return 1.0

	return clampf(
		1.0 - ((current_radius - min_radius) / (arena_radius - min_radius)),
		0.0,
		1.0
	)


func is_point_inside_arena(world_position: Vector2, edge_margin: float = 0.0) -> bool:
	var safe_radius := maxf(0.0, get_arena_radius() - edge_margin)
	return world_position.distance_squared_to(get_arena_center()) <= safe_radius * safe_radius


func _get_center_for_time(round_time: float) -> Vector2:
	if not shrink_enabled or round_time <= shrink_start_time:
		return arena_center

	if round_time < shrink_mid_time:
		return arena_center.lerp(
			stage_1_center,
			_inverse_lerp_safe(shrink_start_time, shrink_mid_time, round_time)
		)
	if round_time < shrink_late_time:
		return stage_1_center.lerp(
			stage_2_center,
			_inverse_lerp_safe(shrink_mid_time, shrink_late_time, round_time)
		)
	if round_time < shrink_end_time:
		return stage_2_center.lerp(
			stage_3_center,
			_inverse_lerp_safe(shrink_late_time, shrink_end_time, round_time)
		)

	var stage_3_radius := arena_radius * shrink_final_radius_scale
	var stage_4_radius := arena_radius * shrink_tiny_radius_scale
	var total_post_distance := maxf(1.0, stage_3_radius - stage_4_radius)
	var post_end_elapsed := maxf(0.0, round_time - shrink_end_time)
	var post_distance := minf(total_post_distance, shrink_post_end_speed * post_end_elapsed)
	var post_ratio := clampf(post_distance / total_post_distance, 0.0, 1.0)
	return stage_3_center.lerp(stage_4_center, post_ratio)


func _get_radius_for_time(round_time: float) -> float:
	if not shrink_enabled:
		return arena_radius
	if round_time <= shrink_start_time:
		return arena_radius

	var stage_1_radius := arena_radius * shrink_mid_radius_scale
	var stage_2_radius := arena_radius * shrink_late_radius_scale
	var stage_3_radius := arena_radius * shrink_final_radius_scale
	var stage_4_radius := arena_radius * shrink_tiny_radius_scale

	if round_time < shrink_mid_time:
		return lerpf(
			arena_radius,
			stage_1_radius,
			_inverse_lerp_safe(shrink_start_time, shrink_mid_time, round_time)
		)
	if round_time < shrink_late_time:
		return lerpf(
			stage_1_radius,
			stage_2_radius,
			_inverse_lerp_safe(shrink_mid_time, shrink_late_time, round_time)
		)
	if round_time < shrink_end_time:
		return lerpf(
			stage_2_radius,
			stage_3_radius,
			_inverse_lerp_safe(shrink_late_time, shrink_end_time, round_time)
		)

	var post_end_elapsed := round_time - shrink_end_time
	var post_end_radius := stage_3_radius - shrink_post_end_speed * post_end_elapsed
	return maxf(stage_4_radius, post_end_radius)


func _get_next_phase_radius(round_time: float) -> float:
	if not shrink_enabled:
		return arena_radius
	if round_time < shrink_start_time:
		return arena_radius * shrink_mid_radius_scale
	if round_time < shrink_mid_time:
		return arena_radius * shrink_mid_radius_scale
	if round_time < shrink_late_time:
		return arena_radius * shrink_late_radius_scale
	if round_time < shrink_end_time:
		return arena_radius * shrink_final_radius_scale
	return arena_radius * shrink_tiny_radius_scale


func _get_next_phase_center(round_time: float) -> Vector2:
	if not shrink_enabled:
		return arena_center
	if round_time < shrink_start_time:
		return stage_1_center
	if round_time < shrink_mid_time:
		return stage_1_center
	if round_time < shrink_late_time:
		return stage_2_center
	if round_time < shrink_end_time:
		return stage_3_center
	return stage_4_center


func _inverse_lerp_safe(from_value: float, to_value: float, value: float) -> float:
	if is_equal_approx(from_value, to_value):
		return 1.0
	return clampf((value - from_value) / (to_value - from_value), 0.0, 1.0)


func _get_shrink_stage_for_time(round_time: float) -> int:
	if not shrink_enabled:
		return 0
	if round_time < shrink_start_time:
		return 0
	if round_time < shrink_mid_time:
		return 1
	if round_time < shrink_late_time:
		return 2
	if round_time < shrink_end_time:
		return 3
	return 4


func _get_effective_shrink_time(scene_root: Node, round_time: float) -> float:
	if scene_root == null:
		return round_time
	if not scene_root.has_method("is_duel_mode_active") or not scene_root.has_method("get_duel_elapsed_seconds"):
		return round_time
	if not scene_root.is_duel_mode_active():
		return round_time

	var duel_elapsed: float = float(scene_root.get_duel_elapsed_seconds())
	if duel_elapsed <= 0.0:
		return round_time

	var stage_1_delay: float = 7.0
	var stage_2_delay: float = 14.0
	var stage_1_multiplier: float = 1.7
	var stage_2_multiplier: float = 2.3

	if scene_root.has_method("get_duel_shrink_profile"):
		var profile: Dictionary = scene_root.get_duel_shrink_profile()
		stage_1_delay = float(profile.get("stage_1_delay", stage_1_delay))
		stage_2_delay = float(profile.get("stage_2_delay", stage_2_delay))
		stage_1_multiplier = float(profile.get("stage_1_speed_multiplier", stage_1_multiplier))
		stage_2_multiplier = float(profile.get("stage_2_speed_multiplier", stage_2_multiplier))

	stage_1_multiplier = maxf(1.0, stage_1_multiplier)
	stage_2_multiplier = maxf(stage_1_multiplier, stage_2_multiplier)
	stage_2_delay = maxf(stage_1_delay, stage_2_delay)

	var effective_time: float = round_time
	if duel_elapsed > stage_1_delay:
		var first_stage_elapsed: float = minf(duel_elapsed, stage_2_delay) - stage_1_delay
		effective_time += first_stage_elapsed * (stage_1_multiplier - 1.0)
	if duel_elapsed > stage_2_delay:
		var second_stage_elapsed: float = duel_elapsed - stage_2_delay
		effective_time += second_stage_elapsed * (stage_2_multiplier - 1.0)

	return effective_time


func _build_shrink_centers() -> void:
	stage_1_center = _roll_shrink_center(arena_center, arena_radius * shrink_stage_1_center_shift_ratio)
	stage_2_center = _roll_shrink_center(stage_1_center, arena_radius * shrink_stage_2_center_shift_ratio)
	stage_3_center = _roll_shrink_center(stage_2_center, arena_radius * shrink_stage_3_center_shift_ratio)
	stage_4_center = _roll_shrink_center(stage_3_center, arena_radius * shrink_stage_4_center_shift_ratio)


func _roll_shrink_center(from_center: Vector2, max_shift: float) -> Vector2:
	if max_shift <= 0.0:
		return from_center

	var direction := Vector2.RIGHT.rotated(shrink_rng.randf_range(0.0, TAU))
	var distance := shrink_rng.randf_range(max_shift * 0.35, max_shift)
	return from_center + direction * distance
