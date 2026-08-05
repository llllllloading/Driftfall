extends CharacterBody2D

const ABILITY_TREE_DATA_SCRIPT := preload("res://scripts/ability_tree_data.gd")
const FIREBALL_SCRIPT := preload("res://scripts/fireball.gd")
const MINE_SCRIPT := preload("res://scripts/mine.gd")
const FIREBALL_ABILITY_SCRIPT := preload("res://scripts/abilities/fireball_ability.gd")
const MINE_ABILITY_SCRIPT := preload("res://scripts/abilities/mine_ability.gd")
const DASH_ABILITY_SCRIPT := preload("res://scripts/abilities/dash_ability.gd")
const REFLECT_SHIELD_ABILITY_SCRIPT := preload("res://scripts/abilities/reflect_shield_ability.gd")
const TREE_ABILITY_IDS := {
	"fireball": "fireball",
	"mine": "breach_mine",
	"dash": "ram_dash",
	"reflect_shield": "reflect_shield"
}

enum ControlMode {
	HUMAN_MOUSE,
	HUMAN_KEYBOARD,
	BOT
}

@export var control_mode: ControlMode = ControlMode.HUMAN_MOUSE
@export var fighter_name: String = ""
@export var debug_upgrade_ids: PackedStringArray = []
@export var move_left_action: String = "move_left"
@export var move_right_action: String = "move_right"
@export var move_up_action: String = "move_up"
@export var move_down_action: String = "move_down"
@export var fireball_action: String = ""
@export var mine_action: String = "ability_mine"
@export var dash_action: String = "ability_dash"
@export var reflect_shield_action: String = "ability_reflect_shield"
@export var use_mouse_aim: bool = true
@export var use_mouse_fire: bool = true
@export var move_speed: float = 192.0
@export var move_acceleration: float = 1050.0
@export var move_deceleration: float = 1460.0
@export var body_radius: float = 24.0
@export var body_color: Color = Color(0.92, 0.95, 1.0)
@export var fireball_cooldown: float = 2.45
@export var fireball_speed_multiplier: float = 2.3
@export var fireball_push_strength: float = 1050.0
@export var fireball_hit_stun: float = 0.20
@export var fireball_recovery_sec: float = 0.28
@export var fireball_recovery_move_multiplier: float = 0.32
@export var mine_cooldown: float = 5.4
@export var mine_place_time: float = 0.46
@export var mine_place_move_multiplier: float = 0.42
@export var dash_cooldown: float = 4.35
@export var dash_duration: float = 0.17
@export var dash_speed: float = 1180.0
@export var dash_windup_sec: float = 0.24
@export var dash_push_strength: float = 1320.0
@export var dash_hit_radius_bonus: float = 18.0
@export var knockback_decay: float = 1800.0
@export var instability_gain_per_hit: float = 0.2
@export var instability_max_bonus: float = 0.8
@export var instability_decay_delay: float = 3.0
@export var instability_decay_rate: float = 0.0
@export var bot_preferred_distance: float = 300.0
@export var bot_retreat_distance: float = 175.0
@export var bot_action_interval: float = 0.98
@export var bot_strafe_interval: float = 1.2
@export var bot_fireball_preferred_range: float = 680.0
@export var bot_hazard_padding: float = 34.0
@export var bot_dash_commit_range: float = 195.0
@export var bot_dash_finisher_range: float = 145.0
@export var bot_mine_combo_memory: float = 3.4
@export var bot_distance_bias: float = 1.0
@export var bot_side_bias: float = 1.0
@export var bot_commit_bias: float = 1.0
@export var bot_duel_break_interval: float = 2.9
@export var upgrade_animation_duration: float = 1.05
@export var final_save_control_lock: float = 0.85
@export var final_save_fall_grace: float = 0.9
@export var outside_grace_time: float = 0.15
@export var outside_time_max: float = 4.0
@export var outside_time_min: float = 0.7
@export var hole_grace_time: float = 0.08
@export var hole_time_max: float = 0.2
@export var hole_time_min: float = 0.2

var aim_direction: Vector2 = Vector2.RIGHT
var ability_tree: Dictionary = {}
var ability_specs: Dictionary = {}
var upgrade_specs: Dictionary = {}
var abilities: Dictionary = {}
var ability_order: Array[String] = []
var base_ability_configs: Dictionary = {}
var ability_runtime_configs: Dictionary = {}
var owned_upgrade_ids: Array[String] = []
var selected_choice_groups: Dictionary = {}
var move_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var spawn_position: Vector2
var is_dashing: bool = false
var dash_windup_left: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_hit_targets: Array = []
var dash_hit_count: int = 0
var dash_first_hit_extended: bool = false
var bot_action_timer: float = 0.0
var bot_strafe_timer: float = 0.0
var bot_strafe_sign: float = 1.0
var bot_last_mine_position: Vector2 = Vector2.ZERO
var bot_last_mine_time_left: float = 0.0
var bot_duel_break_left: float = 0.0
var bot_reflect_punish_left: float = 0.0
var instability_bonus: float = 0.0
var instability_decay_delay_left: float = 0.0
var temporary_move_speed_multiplier: float = 1.0
var temporary_move_speed_left: float = 0.0
var temporary_incoming_knockback_multiplier: float = 1.0
var temporary_incoming_knockback_left: float = 0.0
var powerup_move_speed_multiplier: float = 1.0
var powerup_move_speed_left: float = 0.0
var powerup_incoming_knockback_multiplier: float = 1.0
var powerup_incoming_knockback_left: float = 0.0
var reflect_shield_config: Dictionary = {}
var reflect_shield_active: bool = false
var reflect_shield_left: float = 0.0
var reflect_shield_reflects_left: int = 0
var reflect_shield_burst_left: float = 0.0
var control_lock_left: float = 0.0
var fall_grace_left: float = 0.0
var outside_grace_left: float = 0.0
var outside_time_left: float = 0.0
var is_outside_arena: bool = false
var hole_grace_left: float = 0.0
var hole_time_left: float = 0.0
var is_inside_hole: bool = false
var last_attacker: Node = null
var last_attacker_left: float = 0.0
var last_hit_credit_time: float = 4.0
var is_eliminated: bool = false
var round_locked: bool = false
var upgrade_animation_left: float = 0.0
var hit_feedback_left: float = 0.0


func _ready() -> void:
	add_to_group("push_targets")
	spawn_position = global_position
	bot_action_timer = bot_action_interval
	bot_strafe_timer = bot_strafe_interval
	bot_duel_break_left = bot_duel_break_interval
	_load_ability_tree_data()
	_capture_base_ability_configs()
	_rebuild_ability_configs()
	_apply_debug_upgrade_loadout()
	_build_abilities()
	queue_redraw()


func _draw() -> void:
	var current_body_color := body_color
	var instability_ratio: float = 0.0
	if instability_max_bonus > 0.001:
		instability_ratio = clampf(instability_bonus / instability_max_bonus, 0.0, 1.0)
	var instability_outline_color := _get_instability_display_color(instability_ratio)
	var effect_pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	if is_dashing:
		current_body_color = Color(0.82, 0.55, 1.0)
	elif dash_windup_left > 0.0:
		current_body_color = current_body_color.lerp(Color(0.84, 0.58, 1.0), 0.42)
	if reflect_shield_active:
		current_body_color = current_body_color.lerp(Color(0.74, 0.97, 1.0), 0.48)
	if upgrade_animation_left > 0.0:
		var upgrade_color_ratio: float = upgrade_animation_left / maxf(0.001, upgrade_animation_duration)
		current_body_color = current_body_color.lerp(Color(1.0, 0.88, 0.34), 0.34 + 0.26 * upgrade_color_ratio)

	draw_circle(Vector2.ZERO, body_radius, current_body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 32, instability_outline_color, 4.0)
	draw_line(Vector2.ZERO, aim_direction * (body_radius + 18.0), Color(0.40, 0.70, 1.0), 3.0)

	if powerup_move_speed_left > 0.0:
		var haste_ratio: float = clampf(powerup_move_speed_left / 4.5, 0.0, 1.0)
		var haste_color := Color(0.28, 1.0, 0.54, 0.92)
		draw_arc(
			Vector2.ZERO,
			body_radius + 12.0,
			-PI * 0.15 + effect_pulse * 0.30,
			PI * 0.95 + effect_pulse * 0.30,
			28,
			Color(haste_color.r, haste_color.g, haste_color.b, 0.55 + 0.25 * effect_pulse),
			3.0 + 1.5 * haste_ratio
		)
		for lane in [-10.0, 0.0, 10.0]:
			draw_line(
				Vector2(-body_radius - 18.0, lane),
				Vector2(-body_radius - 2.0, lane - 6.0),
				Color(0.66, 1.0, 0.78, 0.34 + 0.18 * effect_pulse),
				2.2
			)

	if powerup_incoming_knockback_left > 0.0:
		var shield_ratio: float = clampf(powerup_incoming_knockback_left / 2.8, 0.0, 1.0)
		var shield_color := Color(0.42, 0.90, 1.0, 0.98)
		draw_circle(
			Vector2.ZERO,
			body_radius + 8.0 + 3.0 * effect_pulse,
			Color(shield_color.r, shield_color.g, shield_color.b, 0.05 + 0.05 * effect_pulse)
		)
		draw_arc(
			Vector2.ZERO,
			body_radius + 10.0,
			effect_pulse * 0.65,
			effect_pulse * 0.65 + PI * 1.55,
			32,
			Color(shield_color.r, shield_color.g, shield_color.b, 0.70 + 0.18 * shield_ratio),
			3.2 + 1.2 * shield_ratio
		)
		draw_arc(
			Vector2.ZERO,
			body_radius + 15.0,
			effect_pulse * -0.52 + PI,
			effect_pulse * -0.52 + PI * 2.25,
			32,
			Color(0.78, 1.0, 1.0, 0.38 + 0.18 * effect_pulse),
			2.0
		)

	if reflect_shield_active:
		var reflect_duration: float = maxf(0.001, float(reflect_shield_config.get("duration_sec", 2.0)))
		var reflect_ratio: float = clampf(reflect_shield_left / reflect_duration, 0.0, 1.0)
		var reflect_radius: float = body_radius * float(reflect_shield_config.get("shield_radius_multiplier", 1.35))
		var reflect_color := Color(0.44, 0.92, 1.0, 0.98)
		draw_circle(
			Vector2.ZERO,
			reflect_radius,
			Color(reflect_color.r, reflect_color.g, reflect_color.b, 0.05 + 0.03 * effect_pulse)
		)
		draw_arc(
			Vector2.ZERO,
			reflect_radius + 2.0,
			effect_pulse * 0.7,
			effect_pulse * 0.7 + PI * (1.35 + 0.22 * reflect_ratio),
			36,
			Color(reflect_color.r, reflect_color.g, reflect_color.b, 0.78 + 0.14 * reflect_ratio),
			5.5
		)
		draw_arc(
			Vector2.ZERO,
			reflect_radius + 8.0,
			PI + effect_pulse * -0.56,
			PI + effect_pulse * -0.56 + PI * (1.10 + 0.18 * reflect_ratio),
			36,
			Color(0.82, 1.0, 1.0, 0.42 + 0.14 * effect_pulse),
			3.0
		)
		for marker_index in range(4):
			var marker_angle: float = effect_pulse * 0.6 + float(marker_index) * TAU * 0.25
			var marker_direction := Vector2.RIGHT.rotated(marker_angle)
			draw_line(
				marker_direction * (reflect_radius + 4.0),
				marker_direction * (reflect_radius + 14.0),
				Color(0.70, 0.98, 1.0, 0.82),
				3.0
			)

	if reflect_shield_burst_left > 0.0:
		var burst_ratio: float = reflect_shield_burst_left / 0.24
		var burst_radius: float = body_radius + 16.0 + 22.0 * (1.0 - burst_ratio)
		draw_arc(
			Vector2.ZERO,
			burst_radius,
			0.0,
			TAU,
			42,
			Color(0.58, 0.96, 1.0, 0.24 + 0.52 * burst_ratio),
			6.0
		)
		draw_circle(
			Vector2.ZERO,
			body_radius + 7.0 + 9.0 * (1.0 - burst_ratio),
			Color(0.60, 0.95, 1.0, 0.05 + 0.10 * burst_ratio)
		)

	if instability_bonus > 0.01:
		var timer_ratio: float = 0.0
		if instability_decay_delay > 0.001:
			timer_ratio = clampf(instability_decay_delay_left / instability_decay_delay, 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			body_radius + 7.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * timer_ratio,
			40,
			Color(
				instability_outline_color.r,
				instability_outline_color.g,
				instability_outline_color.b,
				0.92
			),
			4.0
		)
		draw_circle(
			Vector2.ZERO,
			body_radius + 2.0,
			Color(
				instability_outline_color.r,
				instability_outline_color.g,
				instability_outline_color.b,
				0.05 + 0.10 * instability_ratio
			)
		)

	if hit_feedback_left > 0.0:
		var flash_ratio: float = hit_feedback_left / 0.18
		draw_arc(
			Vector2.ZERO,
			body_radius + 12.0 + 7.0 * (1.0 - flash_ratio),
			0.0,
			TAU,
			36,
			Color(1.0, 0.96, 0.90, 0.35 + 0.40 * flash_ratio),
			4.0
		)
		draw_circle(
			Vector2.ZERO,
			body_radius + 3.0,
			Color(1.0, 0.92, 0.82, 0.05 + 0.08 * flash_ratio)
		)

	if is_dashing:
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 32, Color(0.72, 0.38, 1.0, 0.75), 4.0)
	elif dash_windup_left > 0.0:
		var windup_ratio: float = 1.0 - dash_windup_left / maxf(0.001, dash_windup_sec)
		var telegraph_length: float = body_radius + 26.0 + 28.0 * windup_ratio
		var telegraph_color := Color(0.92, 0.68, 1.0, 0.40 + windup_ratio * 0.38)
		var left_offset := dash_direction.rotated(-0.22) * (body_radius + 6.0)
		var right_offset := dash_direction.rotated(0.22) * (body_radius + 6.0)
		draw_line(left_offset, left_offset + dash_direction * telegraph_length, telegraph_color, 3.0)
		draw_line(right_offset, right_offset + dash_direction * telegraph_length, telegraph_color, 3.0)
		draw_arc(
			Vector2.ZERO,
			body_radius + 10.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * windup_ratio,
			32,
			Color(0.88, 0.62, 1.0, 0.85),
			4.0
		)

	var fall_status := get_fall_timer_status()
	if bool(fall_status.get("active", false)):
		var outside_progress: float = clampf(float(fall_status.get("progress", 0.0)), 0.0, 1.0)
		var grace_left: float = maxf(0.0, float(fall_status.get("grace_left", 0.0)))
		var bar_width: float = body_radius * 2.1
		var bar_height: float = 4.0
		var bar_y: float = -(body_radius + 18.0)
		var bar_position := Vector2(-bar_width * 0.5, bar_y)
		var back_color := Color(0.08, 0.10, 0.14, 0.86)
		var is_hole_timer: bool = str(fall_status.get("source", "")) == "hole"
		var fill_color := Color(1.0, 0.82, 0.26, 0.96) if grace_left > 0.0 else Color(1.0, 0.28, 0.20, 0.96)
		if is_hole_timer:
			fill_color = Color(0.94, 0.58, 0.22, 0.98) if grace_left > 0.0 else Color(0.92, 0.20, 0.14, 0.98)
		if grace_left <= 0.0:
			fill_color = Color(1.0, 0.24, 0.18, 0.96).lerp(Color(1.0, 0.82, 0.22, 0.96), outside_progress)
			if is_hole_timer:
				fill_color = Color(0.88, 0.18, 0.12, 0.96).lerp(Color(1.0, 0.70, 0.22, 0.96), outside_progress)
		draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), back_color, true)
		draw_rect(Rect2(bar_position + Vector2(1.0, 1.0), Vector2(maxf(0.0, (bar_width - 2.0) * outside_progress), bar_height - 2.0)), fill_color, true)
		draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color(1.0, 1.0, 1.0, 0.08), false, 1.0)

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
		draw_arc(
			Vector2.ZERO,
			body_radius + 20.0 + 12.0 * reveal_ratio,
			-time_sec * 2.1,
			-time_sec * 2.1 + PI,
			40,
			Color(1.0, 0.95, 0.58, 0.82 - 0.32 * reveal_ratio),
			3.0
		)
		draw_arc(
			Vector2.ZERO,
			body_radius + 30.0 + 16.0 * reveal_ratio,
			time_sec * 1.6,
			time_sec * 1.6 + PI * 0.8,
			40,
			Color(1.0, 0.78, 0.18, 0.72 - 0.28 * reveal_ratio),
			3.0
		)
		for spark_index in range(4):
			var spark_angle: float = time_sec * 3.5 + float(spark_index) * TAU * 0.25
			var spark_direction := Vector2.RIGHT.rotated(spark_angle)
			var spark_start := spark_direction * (body_radius + 6.0)
			var spark_end := spark_direction * (body_radius + 24.0 + 14.0 * reveal_ratio)
			draw_line(spark_start, spark_end, Color(1.0, 0.93, 0.48, 0.92), 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if control_mode == ControlMode.BOT or is_eliminated or round_locked:
		return

	if use_mouse_fire and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		use_ability("fireball")
	elif fireball_action != "" and event.is_action_pressed(fireball_action):
		use_ability("fireball")
	elif mine_action != "" and event.is_action_pressed(mine_action):
		use_ability("mine")
	elif dash_action != "" and event.is_action_pressed(dash_action):
		use_ability("dash")
	elif reflect_shield_action != "" and event.is_action_pressed(reflect_shield_action):
		use_ability("reflect_shield")


func _process(delta: float) -> void:
	if is_eliminated:
		return

	if upgrade_animation_left > 0.0:
		upgrade_animation_left = maxf(0.0, upgrade_animation_left - delta)
	if hit_feedback_left > 0.0:
		hit_feedback_left = maxf(0.0, hit_feedback_left - delta)

	if control_mode == ControlMode.BOT:
		var bot_target := _get_bot_target()
		if bot_target != null:
			var target_direction: Vector2 = bot_target.global_position - global_position
			if target_direction.length_squared() > 0.001:
				aim_direction = target_direction.normalized()
	elif use_mouse_aim:
		var mouse_direction: Vector2 = get_global_mouse_position() - global_position
		if mouse_direction.length_squared() > 0.001:
			aim_direction = mouse_direction.normalized()

	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_eliminated:
		move_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		return

	_update_temporary_effects(delta)

	var input_vector: Vector2 = Vector2.ZERO
	if round_locked or control_lock_left > 0.0 or dash_windup_left > 0.0:
		input_vector = Vector2.ZERO
	elif control_mode == ControlMode.BOT:
		input_vector = _get_bot_move_input(delta)
	else:
		input_vector = _get_move_input()

	if is_mine_placing_active():
		input_vector *= mine_place_move_multiplier

	if control_mode != ControlMode.BOT and not use_mouse_aim and input_vector.length_squared() > 0.001:
		aim_direction = input_vector.normalized()

	if is_dashing:
		move_velocity = Vector2.ZERO
		velocity = dash_direction * dash_speed + knockback_velocity
	elif dash_windup_left > 0.0:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, move_deceleration * 1.8 * delta)
		velocity = move_velocity + knockback_velocity
	else:
		var target_move_velocity := input_vector * _get_current_move_speed()
		var accel_rate := move_acceleration if target_move_velocity.length_squared() > 0.001 else move_deceleration
		move_velocity = move_velocity.move_toward(target_move_velocity, accel_rate * delta)
		velocity = move_velocity + knockback_velocity

	move_and_slide()

	if control_lock_left > 0.0:
		control_lock_left = maxf(0.0, control_lock_left - delta)
	if fall_grace_left > 0.0:
		fall_grace_left = maxf(0.0, fall_grace_left - delta)

	if last_attacker_left > 0.0:
		last_attacker_left = maxf(0.0, last_attacker_left - delta)
		if last_attacker_left <= 0.0:
			last_attacker = null
	if bot_last_mine_time_left > 0.0:
		bot_last_mine_time_left = maxf(0.0, bot_last_mine_time_left - delta)
	if bot_duel_break_left > 0.0:
		bot_duel_break_left = maxf(0.0, bot_duel_break_left - delta)
	if bot_reflect_punish_left > 0.0:
		bot_reflect_punish_left = maxf(0.0, bot_reflect_punish_left - delta)

	if instability_decay_delay_left > 0.0:
		instability_decay_delay_left = maxf(0.0, instability_decay_delay_left - delta)
	elif instability_bonus > 0.0:
		instability_bonus = 0.0

	if is_dashing:
		dash_timer = maxf(0.0, dash_timer - delta)
		_check_dash_hits()
		if dash_timer <= 0.0:
			_stop_dash(true)
	elif dash_windup_left > 0.0:
		dash_windup_left = maxf(0.0, dash_windup_left - delta)
		if dash_windup_left <= 0.0:
			_begin_dash()

	_update_abilities(delta)

	if control_mode == ControlMode.BOT and not round_locked:
		_try_bot_reflect_response()
		bot_action_timer = maxf(0.0, bot_action_timer - delta)
		_try_bot_actions()

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	_check_holes(delta)
	_check_outside_arena(delta)


func _build_abilities() -> void:
	abilities.clear()
	ability_order.clear()

	_register_ability(FIREBALL_ABILITY_SCRIPT.new())
	_register_ability(MINE_ABILITY_SCRIPT.new())
	_register_ability(DASH_ABILITY_SCRIPT.new())
	_register_ability(REFLECT_SHIELD_ABILITY_SCRIPT.new())


func _register_ability(ability) -> void:
	ability.setup(self)
	abilities[ability.ability_id] = ability
	ability_order.append(ability.ability_id)


func _update_abilities(delta: float) -> void:
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		ability.physics_update(delta)


func _load_ability_tree_data() -> void:
	ability_tree = ABILITY_TREE_DATA_SCRIPT.get_tree_data()
	ability_specs = ability_tree.get("ability_index", {})
	upgrade_specs = ability_tree.get("upgrade_index", {})


func _rebuild_ability_configs() -> void:
	if base_ability_configs.is_empty():
		_capture_base_ability_configs()

	ability_runtime_configs.clear()
	ability_runtime_configs["fireball"] = _duplicate_config("fireball")
	ability_runtime_configs["mine"] = _duplicate_config("mine")
	ability_runtime_configs["dash"] = _duplicate_config("dash")
	ability_runtime_configs["reflect_shield"] = _duplicate_config("reflect_shield")

	for upgrade_id in owned_upgrade_ids:
		var upgrade_entry: Dictionary = upgrade_specs.get(upgrade_id, {})
		if upgrade_entry.is_empty():
			continue

		var tree_ability_id := str(upgrade_entry.get("ability_id", ""))
		var node: Dictionary = upgrade_entry.get("node", {})
		_apply_upgrade_node(tree_ability_id, node)

	_sync_runtime_stats_from_configs()


func _capture_base_ability_configs() -> void:
	base_ability_configs["fireball"] = _build_base_fireball_config()
	base_ability_configs["mine"] = _build_base_mine_config()
	base_ability_configs["dash"] = _build_base_dash_config()
	base_ability_configs["reflect_shield"] = _build_base_reflect_shield_config()


func _duplicate_config(ability_id: String) -> Dictionary:
	var config: Dictionary = base_ability_configs.get(ability_id, {})
	return config.duplicate(true)


func _build_base_fireball_config() -> Dictionary:
	var base_stats := _get_tree_base_stats("fireball")
	return {
		"cooldown_sec": fireball_cooldown,
		"projectile_speed": float(base_stats.get("projectile_speed", move_speed * fireball_speed_multiplier)),
		"max_distance": float(base_stats.get("max_distance", 1100.0)),
		"projectile_radius": float(base_stats.get("projectile_radius", 12.0)),
		"knockback": fireball_push_strength,
		"hit_stun_sec": fireball_hit_stun,
		"instability_gain_per_hit": instability_gain_per_hit,
		"instability_bonus_cap": instability_max_bonus,
		"fire_recovery_sec": fireball_recovery_sec,
		"fire_recovery_move_multiplier": fireball_recovery_move_multiplier,
		"long_shot_distance_threshold": 0.0,
		"long_shot_knockback": 0.0,
		"long_shot_hit_stun_sec": 0.0
	}


func _build_base_mine_config() -> Dictionary:
	var base_stats := _get_tree_base_stats("mine")
	return {
		"place_time_sec": mine_place_time,
		"arm_delay_sec": float(base_stats.get("arm_delay_sec", 3.0)),
		"trigger_radius": float(base_stats.get("trigger_radius", 96.0)),
		"trigger_to_explosion_delay_sec": float(base_stats.get("trigger_to_explosion_delay_sec", 0.7)),
		"explosion_radius": float(base_stats.get("explosion_radius", 170.0)),
		"knockback": float(base_stats.get("knockback", 880.0)),
		"hole_radius": float(base_stats.get("hole_radius", 58.0)),
		"cooldown_sec": mine_cooldown,
		"owner_safe_time_sec": float(base_stats.get("owner_safe_time_sec", 0.2)),
		"control_lock_sec": float(base_stats.get("control_lock_sec", 0.08))
	}


func _build_base_dash_config() -> Dictionary:
	var base_stats := _get_tree_base_stats("dash")
	return {
		"cooldown_sec": float(base_stats.get("cooldown_sec", dash_cooldown)),
		"dash_duration_sec": float(base_stats.get("dash_duration_sec", dash_duration)),
		"dash_speed": float(base_stats.get("dash_speed", dash_speed)),
		"dash_distance": float(base_stats.get("dash_distance", dash_speed * dash_duration)),
		"dash_knockback": float(base_stats.get("dash_knockback", dash_push_strength)),
		"hit_radius_bonus": float(base_stats.get("hit_radius_bonus", dash_hit_radius_bonus)),
		"windup_sec": float(base_stats.get("windup_sec", dash_windup_sec)),
		"extra_dash_duration_after_first_hit_sec": 0.0,
		"second_target_knockback_multiplier": 1.0,
		"post_dash_move_speed_multiplier": 1.0,
		"post_dash_move_speed_duration_sec": 0.0,
		"post_dash_incoming_knockback_multiplier": 1.0,
		"post_dash_incoming_knockback_duration_sec": 0.0
	}


func _build_base_reflect_shield_config() -> Dictionary:
	var base_stats := _get_tree_base_stats("reflect_shield")
	return {
		"unlocks_ability": 0.0,
		"cooldown_sec": float(base_stats.get("cooldown_sec", 11.0)),
		"duration_sec": float(base_stats.get("duration_sec", 2.0)),
		"max_reflects": float(base_stats.get("max_reflects", 1.0)),
		"move_speed_multiplier_while_active": float(base_stats.get("move_speed_multiplier_while_active", 0.9)),
		"shield_radius_multiplier": float(base_stats.get("shield_radius_multiplier", 1.35)),
		"reflect_speed_multiplier": float(base_stats.get("reflect_speed_multiplier", 1.0)),
		"reflect_knockback_multiplier": float(base_stats.get("reflect_knockback_multiplier", 1.0)),
		"reflect_instability_bonus": float(base_stats.get("reflect_instability_bonus", 0.0)),
		"split_projectile_count": float(base_stats.get("split_projectile_count", 0.0)),
		"split_angle_deg": float(base_stats.get("split_angle_deg", 20.0)),
		"split_knockback_multiplier": float(base_stats.get("split_knockback_multiplier", 0.4)),
		"split_speed_multiplier": float(base_stats.get("split_speed_multiplier", 0.85)),
		"phase_flicker_distance": float(base_stats.get("phase_flicker_distance", 0.0)),
		"second_reflect_bonus_speed_multiplier": float(base_stats.get("second_reflect_bonus_speed_multiplier", 1.0))
	}


func _get_tree_base_stats(runtime_ability_id: String) -> Dictionary:
	var tree_ability_id := _get_tree_ability_id(runtime_ability_id)
	if tree_ability_id == "":
		return {}

	var ability_spec: Dictionary = ability_specs.get(tree_ability_id, {})
	if ability_spec.is_empty():
		return {}

	var base_stats_value = ability_spec.get("base_stats", {})
	if typeof(base_stats_value) != TYPE_DICTIONARY:
		return {}
	return base_stats_value


func _get_tree_ability_id(runtime_ability_id: String) -> String:
	return str(TREE_ABILITY_IDS.get(runtime_ability_id, ""))


func _get_runtime_ability_id(tree_ability_id: String) -> String:
	for runtime_id in TREE_ABILITY_IDS.keys():
		if TREE_ABILITY_IDS[runtime_id] == tree_ability_id:
			return runtime_id
	return ""


func _apply_upgrade_node(tree_ability_id: String, node: Dictionary) -> void:
	var runtime_ability_id := _get_runtime_ability_id(tree_ability_id)
	if runtime_ability_id == "":
		return

	var config: Dictionary = ability_runtime_configs.get(runtime_ability_id, {})
	if config.is_empty():
		return

	var effects_value = node.get("effects", [])
	if typeof(effects_value) == TYPE_ARRAY:
		_apply_effects_to_config(config, effects_value)

	var conditional_effects_value = node.get("conditional_effects", [])
	if typeof(conditional_effects_value) == TYPE_ARRAY:
		_apply_special_upgrade_data(runtime_ability_id, conditional_effects_value, config)

	if runtime_ability_id == "reflect_shield":
		config["unlocks_ability"] = 1.0

	ability_runtime_configs[runtime_ability_id] = config


func _apply_effects_to_config(config: Dictionary, effects: Array) -> void:
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue

		var effect: Dictionary = effect_value
		var stat_name := str(effect.get("stat", ""))
		if stat_name == "":
			continue

		var operation := str(effect.get("op", "set"))
		var current_value: float = float(config.get(stat_name, 0.0))
		var next_value: float = current_value
		var raw_value: float = float(effect.get("value", 0.0))

		match operation:
			"set":
				next_value = raw_value
			"add":
				next_value = current_value + raw_value
			"mul":
				next_value = current_value * raw_value
			_:
				continue

		config[stat_name] = next_value


func _apply_special_upgrade_data(runtime_ability_id: String, conditional_effects: Array, config: Dictionary) -> void:
	match runtime_ability_id:
		"fireball":
			_apply_fireball_special_data(conditional_effects, config)
		"dash":
			_apply_dash_special_data(conditional_effects, config)
		"reflect_shield":
			_apply_reflect_shield_special_data(conditional_effects, config)


func _apply_fireball_special_data(conditional_effects: Array, config: Dictionary) -> void:
	for conditional_value in conditional_effects:
		if typeof(conditional_value) != TYPE_DICTIONARY:
			continue

		var conditional: Dictionary = conditional_value
		var conditions_value = conditional.get("conditions", {})
		if typeof(conditions_value) == TYPE_DICTIONARY:
			config["long_shot_distance_threshold"] = float(
				conditions_value.get("projectile_travel_distance_gte", config.get("long_shot_distance_threshold", 0.0))
			)

		var effects_value = conditional.get("effects", [])
		if typeof(effects_value) != TYPE_ARRAY:
			continue

		for effect_value in effects_value:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue

			var effect: Dictionary = effect_value
			var stat_name := str(effect.get("stat", ""))
			var stat_value: float = float(effect.get("value", 0.0))

			match stat_name:
				"knockback":
					config["long_shot_knockback"] = stat_value
				"hit_stun_sec":
					config["long_shot_hit_stun_sec"] = stat_value
				"max_distance":
					config["max_distance"] = stat_value


func _apply_dash_special_data(conditional_effects: Array, config: Dictionary) -> void:
	for conditional_value in conditional_effects:
		if typeof(conditional_value) != TYPE_DICTIONARY:
			continue

		var conditional: Dictionary = conditional_value
		var event_name := str(conditional.get("event", ""))
		var effects_value = conditional.get("effects", [])
		if typeof(effects_value) != TYPE_ARRAY:
			continue

		for effect_value in effects_value:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue

			var effect: Dictionary = effect_value
			var stat_name := str(effect.get("stat", ""))
			var stat_value: float = float(effect.get("value", 0.0))

			if event_name == "dash_first_target_hit" and stat_name == "remaining_dash_duration_sec":
				config["extra_dash_duration_after_first_hit_sec"] = stat_value
			elif event_name == "dash_second_target_hit" and stat_name == "dash_knockback":
				config["second_target_knockback_multiplier"] = stat_value
			elif event_name == "dash_finished" and stat_name == "temporary_move_speed_multiplier":
				config["post_dash_move_speed_multiplier"] = stat_value
			elif event_name == "dash_finished" and stat_name == "temporary_move_speed_duration_sec":
				config["post_dash_move_speed_duration_sec"] = stat_value
			elif event_name == "dash_finished" and stat_name == "temporary_incoming_knockback_multiplier":
				config["post_dash_incoming_knockback_multiplier"] = stat_value
			elif event_name == "dash_finished" and stat_name == "temporary_incoming_knockback_duration_sec":
				config["post_dash_incoming_knockback_duration_sec"] = stat_value


func _apply_reflect_shield_special_data(conditional_effects: Array, config: Dictionary) -> void:
	for conditional_value in conditional_effects:
		if typeof(conditional_value) != TYPE_DICTIONARY:
			continue

		var conditional: Dictionary = conditional_value
		var event_name := str(conditional.get("event", ""))
		if event_name != "reflect_success":
			continue

		var effects_value = conditional.get("effects", [])
		if typeof(effects_value) != TYPE_ARRAY:
			continue

		for effect_value in effects_value:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue

			var effect: Dictionary = effect_value
			var stat_name := str(effect.get("stat", ""))
			var stat_value: float = float(effect.get("value", 0.0))
			if stat_name == "phase_flicker_distance":
				config["phase_flicker_distance"] = stat_value


func _sync_runtime_stats_from_configs() -> void:
	var fireball_config: Dictionary = ability_runtime_configs.get("fireball", {})
	if not fireball_config.is_empty():
		fireball_cooldown = float(fireball_config.get("cooldown_sec", fireball_cooldown))
		fireball_push_strength = float(fireball_config.get("knockback", fireball_push_strength))
		fireball_hit_stun = float(fireball_config.get("hit_stun_sec", fireball_hit_stun))
		instability_gain_per_hit = float(fireball_config.get("instability_gain_per_hit", instability_gain_per_hit))
		instability_max_bonus = float(fireball_config.get("instability_bonus_cap", instability_max_bonus))
		fireball_recovery_sec = float(fireball_config.get("fire_recovery_sec", fireball_recovery_sec))
		fireball_recovery_move_multiplier = float(
			fireball_config.get("fire_recovery_move_multiplier", fireball_recovery_move_multiplier)
		)
		var projectile_speed: float = float(fireball_config.get("projectile_speed", move_speed * fireball_speed_multiplier))
		if move_speed > 0.001:
			fireball_speed_multiplier = projectile_speed / move_speed

	var mine_config: Dictionary = ability_runtime_configs.get("mine", {})
	if not mine_config.is_empty():
		mine_cooldown = float(mine_config.get("cooldown_sec", mine_cooldown))
		mine_place_time = float(mine_config.get("place_time_sec", mine_place_time))

	var dash_config: Dictionary = ability_runtime_configs.get("dash", {})
	if not dash_config.is_empty():
		dash_cooldown = float(dash_config.get("cooldown_sec", dash_cooldown))
		dash_duration = float(dash_config.get("dash_duration_sec", dash_duration))
		dash_speed = float(dash_config.get("dash_speed", dash_speed))
		dash_push_strength = float(dash_config.get("dash_knockback", dash_push_strength))
		dash_hit_radius_bonus = float(dash_config.get("hit_radius_bonus", dash_hit_radius_bonus))
		dash_windup_sec = float(dash_config.get("windup_sec", dash_windup_sec))

	var shield_config: Dictionary = ability_runtime_configs.get("reflect_shield", {})
	if not shield_config.is_empty():
		reflect_shield_config = shield_config.duplicate(true)


func _refresh_abilities_from_owner() -> void:
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null or not ability.has_method("refresh_from_owner"):
			continue
		ability.refresh_from_owner()


func get_ability_config(ability_id: String) -> Dictionary:
	var config: Dictionary = ability_runtime_configs.get(ability_id, {})
	return config.duplicate(true)


func can_grant_upgrade(upgrade_id: String) -> bool:
	var upgrade_entry: Dictionary = upgrade_specs.get(upgrade_id, {})
	if upgrade_entry.is_empty():
		return false
	if owned_upgrade_ids.has(upgrade_id):
		return false

	var node: Dictionary = upgrade_entry.get("node", {})
	if node.is_empty():
		return false

	var requires_value = node.get("requires", [])
	if typeof(requires_value) == TYPE_ARRAY:
		for required_upgrade_value in requires_value:
			var required_upgrade_id := str(required_upgrade_value)
			if not owned_upgrade_ids.has(required_upgrade_id):
				return false

	var choice_group := str(node.get("choice_group", ""))
	if choice_group != "":
		var chosen_upgrade_id := str(selected_choice_groups.get(choice_group, ""))
		if chosen_upgrade_id != "" and chosen_upgrade_id != upgrade_id:
			return false

	return true


func grant_upgrade(upgrade_id: String) -> bool:
	if not can_grant_upgrade(upgrade_id):
		return false

	var upgrade_entry: Dictionary = upgrade_specs.get(upgrade_id, {})
	var node: Dictionary = upgrade_entry.get("node", {})

	var choice_group := str(node.get("choice_group", ""))
	owned_upgrade_ids.append(upgrade_id)
	if choice_group != "":
		selected_choice_groups[choice_group] = upgrade_id

	_rebuild_ability_configs()
	_refresh_abilities_from_owner()
	return true


func reset_upgrades(reapply_debug_loadout: bool = false) -> void:
	owned_upgrade_ids.clear()
	selected_choice_groups.clear()
	_rebuild_ability_configs()
	_refresh_abilities_from_owner()
	if reapply_debug_loadout:
		_apply_debug_upgrade_loadout()


func get_owned_upgrade_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for upgrade_id in owned_upgrade_ids:
		result.append(str(upgrade_id))
	return result


func get_available_upgrade_choices() -> Array:
	var choices: Array = []

	for upgrade_id in upgrade_specs.keys():
		var upgrade_id_string := str(upgrade_id)
		if not can_grant_upgrade(upgrade_id_string):
			continue

		var upgrade_entry: Dictionary = upgrade_specs.get(upgrade_id_string, {})
		var node: Dictionary = upgrade_entry.get("node", {})
		var tree_ability_id := str(upgrade_entry.get("ability_id", ""))
		var ability_spec: Dictionary = ability_specs.get(tree_ability_id, {})

		choices.append({
			"upgrade_id": upgrade_id_string,
			"ability_id": _get_runtime_ability_id(tree_ability_id),
			"ability_name": str(ability_spec.get("name", tree_ability_id)),
			"ability_name_ru": str(ability_spec.get("name_ru", ability_spec.get("name", tree_ability_id))),
			"tier": int(node.get("tier", 0)),
			"branch": str(node.get("branch", "")),
			"branch_name_ru": _get_branch_name_ru(str(node.get("branch", ""))),
			"name": str(node.get("name", upgrade_id_string)),
			"name_ru": str(node.get("name_ru", node.get("name", upgrade_id_string))),
			"summary_ru": str(node.get("summary_ru", "")),
			"choice_group": str(node.get("choice_group", ""))
		})

	choices.sort_custom(func(a, b):
		if int(a["tier"]) == int(b["tier"]):
			if str(a["ability_name_ru"]) == str(b["ability_name_ru"]):
				return str(a["name_ru"]) < str(b["name_ru"])
			return str(a["ability_name_ru"]) < str(b["ability_name_ru"])
		return int(a["tier"]) < int(b["tier"])
	)

	return choices


func _get_branch_name_ru(branch_id: String) -> String:
	match branch_id:
		"core":
			return "Базовое усиление"
		"precision":
			return "Точность"
		"impact":
			return "Сила"
		"trap_control":
			return "Контроль"
		"breach":
			return "Пролом"
		"mobility":
			return "Мобильность"
		"trickster":
			return "Трикстер"
		"punisher":
			return "Наказание"
		_:
			return branch_id


func _apply_debug_upgrade_loadout() -> void:
	if debug_upgrade_ids.is_empty():
		return

	var pending: Array = []
	for upgrade_id in debug_upgrade_ids:
		pending.append(str(upgrade_id))

	var made_progress := true
	while made_progress and not pending.is_empty():
		made_progress = false
		var current_pass: Array = pending.duplicate()
		for upgrade_id in current_pass:
			if not grant_upgrade(upgrade_id):
				continue

			pending.erase(upgrade_id)
			made_progress = true

	if not pending.is_empty():
		var pending_strings := PackedStringArray()
		for pending_upgrade_id in pending:
			pending_strings.append(str(pending_upgrade_id))
		push_warning("Unapplied upgrades on %s: %s" % [name, ", ".join(pending_strings)])


func get_ability_layout() -> Array:
	var layout: Array = []
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		if ability_id == "reflect_shield":
			var shield_config: Dictionary = ability_runtime_configs.get("reflect_shield", {})
			if float(shield_config.get("unlocks_ability", 0.0)) < 0.5:
				continue
		layout.append(ability.get_descriptor())
	return layout


func get_ability_states() -> Dictionary:
	var states: Dictionary = {}
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		states[ability_id] = ability.get_state()
	return states


func use_ability(ability_id: String) -> bool:
	var ability = abilities.get(ability_id)
	if ability == null:
		return false
	return ability.try_activate()


func can_use_ability(ability_id: String) -> bool:
	var ability = abilities.get(ability_id)
	if ability == null:
		return false
	return ability.can_activate()


func is_ability_input_locked() -> bool:
	return round_locked or control_lock_left > 0.0 or dash_windup_left > 0.0


func is_dash_active() -> bool:
	return is_dashing or dash_windup_left > 0.0


func is_reflect_shield_active() -> bool:
	return reflect_shield_active and reflect_shield_left > 0.0 and reflect_shield_reflects_left > 0


func is_mine_placing_active() -> bool:
	var mine_ability = abilities.get("mine")
	if mine_ability == null or not mine_ability.has_method("is_placing"):
		return false
	return mine_ability.is_placing()


func spawn_fireball_from_ability(projectile_config: Dictionary) -> bool:
	if is_dashing or dash_windup_left > 0.0:
		return false

	var projectile_layer := _get_projectile_layer()
	if projectile_layer == null:
		return false

	var fireball = FIREBALL_SCRIPT.new()
	var projectile_spawn_position := global_position + aim_direction * (body_radius + 20.0)

	fireball.speed = float(projectile_config.get("projectile_speed", move_speed * fireball_speed_multiplier))
	fireball.max_distance = float(projectile_config.get("max_distance", fireball.max_distance))
	fireball.radius = float(projectile_config.get("projectile_radius", fireball.radius))
	fireball.push_strength = float(projectile_config.get("knockback", fireball_push_strength))
	fireball.hit_stun_duration = float(projectile_config.get("hit_stun_sec", fireball_hit_stun))
	fireball.long_shot_threshold = float(projectile_config.get("long_shot_distance_threshold", 0.0))
	fireball.long_shot_push_strength = float(projectile_config.get("long_shot_knockback", 0.0))
	fireball.long_shot_hit_stun_duration = float(projectile_config.get("long_shot_hit_stun_sec", 0.0))
	fireball.setup(projectile_spawn_position, aim_direction, self)
	projectile_layer.add_child(fireball)
	_apply_fireball_recovery(projectile_config)
	return true


func start_reflect_shield_from_ability(shield_config: Dictionary) -> bool:
	if float(shield_config.get("unlocks_ability", 0.0)) < 0.5:
		return false
	if is_dashing or dash_windup_left > 0.0 or is_mine_placing_active():
		return false

	reflect_shield_config = shield_config.duplicate(true)
	reflect_shield_active = true
	reflect_shield_left = float(reflect_shield_config.get("duration_sec", 2.0))
	reflect_shield_reflects_left = maxi(1, int(round(float(reflect_shield_config.get("max_reflects", 1.0)))))
	reflect_shield_burst_left = 0.24
	queue_redraw()
	return true


func try_reflect_fireball(projectile: Node) -> bool:
	if not is_reflect_shield_active():
		return false
	if projectile == null or not is_instance_valid(projectile):
		return false

	var incoming_direction: Vector2 = projectile.direction
	if incoming_direction.length_squared() <= 0.001:
		return false

	var total_reflects: int = maxi(1, int(round(float(reflect_shield_config.get("max_reflects", 1.0)))))
	var reflect_number: int = total_reflects - reflect_shield_reflects_left + 1
	var speed_multiplier: float = float(reflect_shield_config.get("reflect_speed_multiplier", 1.0))
	if reflect_number >= 2:
		speed_multiplier *= float(reflect_shield_config.get("second_reflect_bonus_speed_multiplier", 1.0))

	var knockback_multiplier: float = float(reflect_shield_config.get("reflect_knockback_multiplier", 1.0))
	var instability_bonus_value: float = float(reflect_shield_config.get("reflect_instability_bonus", 0.0))
	if projectile.has_method("reflect_from_shield"):
		projectile.reflect_from_shield(self, -incoming_direction, speed_multiplier, knockback_multiplier, instability_bonus_value)

	reflect_shield_reflects_left -= 1

	if int(round(float(reflect_shield_config.get("split_projectile_count", 0.0)))) > 0:
		_spawn_reflect_split_projectiles(projectile, -incoming_direction)

	if float(reflect_shield_config.get("phase_flicker_distance", 0.0)) > 0.0:
		_apply_phase_flicker(-incoming_direction)

	if reflect_shield_reflects_left <= 0:
		_end_reflect_shield()
	else:
		queue_redraw()
	if control_mode == ControlMode.BOT:
		bot_reflect_punish_left = 0.95
		bot_action_timer = minf(bot_action_timer, 0.14)
	return true


func _apply_fireball_recovery(projectile_config: Dictionary) -> void:
	var recovery_time: float = float(projectile_config.get("fire_recovery_sec", fireball_recovery_sec))
	var recovery_move_multiplier: float = float(
		projectile_config.get("fire_recovery_move_multiplier", fireball_recovery_move_multiplier)
	)

	if recovery_time > 0.0:
		control_lock_left = maxf(control_lock_left, recovery_time)
	if recovery_move_multiplier < 1.0:
		move_velocity *= recovery_move_multiplier


func place_mine_from_ability(mine_config: Dictionary) -> bool:
	var mine_layer := _get_scene_layer("Mines")
	if mine_layer == null:
		return false

	var mine = MINE_SCRIPT.new()
	var spawn_offset: Vector2 = aim_direction * 88.0

	mine.setup(global_position + spawn_offset, self, mine_config)
	mine_layer.add_child(mine)
	if control_mode == ControlMode.BOT:
		bot_last_mine_position = mine.global_position
		bot_last_mine_time_left = bot_mine_combo_memory
	return true


func start_dash_from_ability() -> bool:
	if is_dashing or dash_windup_left > 0.0 or is_mine_placing_active():
		return false

	var move_direction := _get_move_input()
	if move_direction.length_squared() > 0.001:
		dash_direction = move_direction.normalized()
	else:
		if aim_direction.length_squared() > 0.001:
			dash_direction = aim_direction.normalized()
		else:
			dash_direction = Vector2.RIGHT

	dash_windup_left = dash_windup_sec
	dash_hit_targets.clear()
	dash_hit_count = 0
	dash_first_hit_extended = false
	return true


func _stop_dash(apply_after_effects: bool = false) -> void:
	if not is_dashing and dash_windup_left <= 0.0:
		return

	dash_windup_left = 0.0
	is_dashing = false
	dash_timer = 0.0
	dash_hit_count = 0
	dash_first_hit_extended = false
	if apply_after_effects:
		_activate_post_dash_effects()


func _begin_dash() -> void:
	dash_windup_left = 0.0
	is_dashing = true
	var dash_config: Dictionary = ability_runtime_configs.get("dash", {})
	var dash_distance_value: float = float(dash_config.get("dash_distance", dash_speed * dash_duration))
	if dash_speed > 0.001 and dash_distance_value > 0.0:
		dash_timer = dash_distance_value / dash_speed
	else:
		dash_timer = dash_duration


func _activate_post_dash_effects() -> void:
	var dash_config: Dictionary = ability_runtime_configs.get("dash", {})
	temporary_move_speed_multiplier = float(dash_config.get("post_dash_move_speed_multiplier", 1.0))
	temporary_move_speed_left = float(dash_config.get("post_dash_move_speed_duration_sec", 0.0))
	temporary_incoming_knockback_multiplier = float(
		dash_config.get("post_dash_incoming_knockback_multiplier", 1.0)
	)
	temporary_incoming_knockback_left = float(
		dash_config.get("post_dash_incoming_knockback_duration_sec", 0.0)
	)


func _spawn_reflect_split_projectiles(projectile: Node, reflected_direction: Vector2) -> void:
	var projectile_layer := _get_projectile_layer()
	if projectile_layer == null:
		return

	var split_count: int = int(round(float(reflect_shield_config.get("split_projectile_count", 0.0))))
	if split_count <= 0:
		return

	var angle_deg: float = float(reflect_shield_config.get("split_angle_deg", 20.0))
	var speed_multiplier: float = float(reflect_shield_config.get("split_speed_multiplier", 0.85))
	var knockback_multiplier: float = float(reflect_shield_config.get("split_knockback_multiplier", 0.4))
	var spawn_position: Vector2 = global_position + reflected_direction.normalized() * (body_radius + 26.0)

	for split_index in range(split_count):
		var sign: float = -1.0 if split_index == 0 else 1.0
		var split_direction := reflected_direction.rotated(deg_to_rad(angle_deg * sign))
		var split_projectile = FIREBALL_SCRIPT.new()
		split_projectile.speed = float(projectile.speed) * speed_multiplier
		split_projectile.max_distance = float(projectile.max_distance) * 0.78
		split_projectile.radius = maxf(8.0, float(projectile.radius) * 0.78)
		split_projectile.push_strength = float(projectile.push_strength) * knockback_multiplier
		split_projectile.hit_stun_duration = float(projectile.hit_stun_duration) * 0.72
		split_projectile.setup(spawn_position, split_direction, self)
		split_projectile.set_reflected_visuals()
		projectile_layer.add_child(split_projectile)


func _apply_phase_flicker(reflected_direction: Vector2) -> void:
	var flicker_distance: float = float(reflect_shield_config.get("phase_flicker_distance", 0.0))
	if flicker_distance <= 0.0:
		return

	var flicker_direction := move_velocity.normalized() if move_velocity.length_squared() > 0.001 else reflected_direction.normalized()
	if flicker_direction.length_squared() <= 0.001:
		flicker_direction = Vector2.RIGHT
	var target_position := global_position + flicker_direction * flicker_distance
	if _is_position_inside_arena(target_position):
		snap_to_position(target_position)


func apply_extra_instability_bonus(extra_bonus: float) -> void:
	if extra_bonus <= 0.0:
		return
	instability_bonus = minf(instability_max_bonus, instability_bonus + extra_bonus)
	instability_decay_delay_left = instability_decay_delay
	queue_redraw()


func _update_temporary_effects(delta: float) -> void:
	var had_visual_powerup: bool = powerup_move_speed_left > 0.0 or powerup_incoming_knockback_left > 0.0
	var had_reflect_visual: bool = reflect_shield_active or reflect_shield_left > 0.0

	if temporary_move_speed_left > 0.0:
		temporary_move_speed_left = maxf(0.0, temporary_move_speed_left - delta)
		if temporary_move_speed_left <= 0.0:
			temporary_move_speed_multiplier = 1.0

	if temporary_incoming_knockback_left > 0.0:
		temporary_incoming_knockback_left = maxf(0.0, temporary_incoming_knockback_left - delta)
		if temporary_incoming_knockback_left <= 0.0:
			temporary_incoming_knockback_multiplier = 1.0

	if powerup_move_speed_left > 0.0:
		powerup_move_speed_left = maxf(0.0, powerup_move_speed_left - delta)
		if powerup_move_speed_left <= 0.0:
			powerup_move_speed_multiplier = 1.0

	if powerup_incoming_knockback_left > 0.0:
		powerup_incoming_knockback_left = maxf(0.0, powerup_incoming_knockback_left - delta)
		if powerup_incoming_knockback_left <= 0.0:
			powerup_incoming_knockback_multiplier = 1.0

	if reflect_shield_left > 0.0:
		reflect_shield_left = maxf(0.0, reflect_shield_left - delta)
		if reflect_shield_left <= 0.0:
			_end_reflect_shield()
	if reflect_shield_burst_left > 0.0:
		reflect_shield_burst_left = maxf(0.0, reflect_shield_burst_left - delta)

	var has_visual_powerup: bool = powerup_move_speed_left > 0.0 or powerup_incoming_knockback_left > 0.0
	var has_reflect_visual: bool = reflect_shield_active or reflect_shield_left > 0.0 or reflect_shield_burst_left > 0.0
	if had_visual_powerup or has_visual_powerup or had_reflect_visual or has_reflect_visual:
		queue_redraw()


func _clear_temporary_effects() -> void:
	temporary_move_speed_multiplier = 1.0
	temporary_move_speed_left = 0.0
	temporary_incoming_knockback_multiplier = 1.0
	temporary_incoming_knockback_left = 0.0
	powerup_move_speed_multiplier = 1.0
	powerup_move_speed_left = 0.0
	powerup_incoming_knockback_multiplier = 1.0
	powerup_incoming_knockback_left = 0.0
	_end_reflect_shield()


func _get_current_move_speed() -> float:
	var shield_move_multiplier: float = 1.0
	if reflect_shield_active:
		shield_move_multiplier = float(reflect_shield_config.get("move_speed_multiplier_while_active", 1.0))
	return move_speed * temporary_move_speed_multiplier * powerup_move_speed_multiplier * shield_move_multiplier


func collect_powerup(powerup_id: String) -> bool:
	match powerup_id:
		"burst_bomb":
			_activate_burst_bomb_powerup()
			queue_redraw()
			return true
		"haste":
			powerup_move_speed_multiplier = maxf(powerup_move_speed_multiplier, 1.56)
			powerup_move_speed_left = maxf(powerup_move_speed_left, 4.5)
			queue_redraw()
			return true
		"shield":
			powerup_incoming_knockback_multiplier = minf(powerup_incoming_knockback_multiplier, 0.0)
			powerup_incoming_knockback_left = maxf(powerup_incoming_knockback_left, 2.8)
			queue_redraw()
			return true
	return false


func _end_reflect_shield() -> void:
	reflect_shield_active = false
	reflect_shield_left = 0.0
	reflect_shield_reflects_left = 0
	queue_redraw()


func _activate_burst_bomb_powerup() -> void:
	var projectile_layer := _get_projectile_layer()
	if projectile_layer == null:
		return

	var projectile_speed := move_speed * 3.6
	for index in range(10):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 10.0)
		var projectile = FIREBALL_SCRIPT.new()
		projectile.speed = projectile_speed
		projectile.max_distance = 640.0
		projectile.radius = 12.0
		projectile.push_strength = 1220.0
		projectile.hit_stun_duration = 0.18
		projectile.outer_color = Color(1.0, 0.56, 0.18, 1.0)
		projectile.core_color = Color(1.0, 0.84, 0.36, 0.95)
		projectile.setup(global_position + direction * (body_radius + 18.0), direction, self)
		projectile_layer.add_child(projectile)


func _interrupt_abilities() -> void:
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		ability.interrupt()


func _reset_abilities() -> void:
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		ability.reset_state()


func _force_abilities_on_cooldown() -> void:
	for ability_id in ability_order:
		var ability = abilities.get(ability_id)
		if ability == null:
			continue
		ability.start_cooldown()


func _get_projectile_layer() -> Node:
	return _get_scene_layer("Projectiles")


func _get_scene_layer(node_name: String) -> Node:
	var scene_root := get_tree().current_scene
	if scene_root != null and scene_root.has_node(node_name):
		return scene_root.get_node(node_name)
	return scene_root


func _get_arena_node() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.get_node_or_null("Arena")


func _get_move_input() -> Vector2:
	return Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action
	)


func _get_bot_move_input(delta: float) -> Vector2:
	var bot_target := _get_bot_target()
	if bot_target == null:
		return _get_bot_hazard_avoidance(Vector2.ZERO)

	bot_strafe_timer = maxf(0.0, bot_strafe_timer - delta)
	if bot_strafe_timer <= 0.0:
		bot_strafe_timer = bot_strafe_interval
		bot_strafe_sign *= -1.0

	var to_target: Vector2 = bot_target.global_position - global_position
	if to_target.length_squared() <= 0.001:
		return _get_bot_hazard_avoidance(Vector2.ZERO)

	var distance: float = to_target.length()
	var forward: Vector2 = to_target.normalized()
	var side: Vector2 = Vector2(-forward.y, forward.x) * bot_strafe_sign * bot_side_bias
	var move_vector: Vector2 = Vector2.ZERO
	var duel_active: bool = _get_alive_fighter_count() <= 2
	var preferred_distance: float = bot_preferred_distance * bot_distance_bias
	var retreat_distance: float = bot_retreat_distance * clampf(bot_distance_bias, 0.88, 1.14)
	var target_velocity: Vector2 = Vector2.ZERO
	if bot_target is CharacterBody2D:
		target_velocity = (bot_target as CharacterBody2D).velocity
	var target_is_charging: bool = target_velocity.dot(-forward) > 70.0
	var target_near_hazard: bool = _is_position_near_bot_hazard(bot_target.global_position, body_radius + 34.0)

	if bot_last_mine_time_left > 0.0 and bot_target.global_position.distance_to(bot_last_mine_position) <= 205.0:
		move_vector = (-forward + side * 0.45).normalized()
	elif target_near_hazard and distance < bot_fireball_preferred_range:
		move_vector = side.normalized()
	elif duel_active and bot_duel_break_left <= 0.0 and distance > retreat_distance + 18.0 and distance < preferred_distance + 170.0:
		move_vector = (forward + side * 0.14).normalized()
	elif distance > preferred_distance + 110.0:
		move_vector = (forward + side * 0.35).normalized()
	elif distance < retreat_distance or target_is_charging:
		move_vector = (-forward + side * 0.35).normalized()
	elif distance < preferred_distance - 35.0:
		move_vector = (-forward + side * 0.28).normalized()
	else:
		move_vector = side.normalized()

	var arena := _get_arena_node()
	if arena == null:
		return move_vector
	if not arena.has_method("get_arena_center") or not arena.has_method("get_arena_radius"):
		return move_vector

	var center_direction: Vector2 = arena.get_arena_center() - global_position
	if center_direction.length_squared() <= 0.001:
		return move_vector

	var current_arena_radius: float = maxf(1.0, float(arena.get_arena_radius()))
	var distance_to_center_ratio: float = global_position.distance_to(arena.get_arena_center()) / current_arena_radius
	var center_weight: float = 0.0
	var shrink_started: bool = arena.has_method("is_shrink_started") and arena.is_shrink_started()

	if distance_to_center_ratio >= 0.96:
		center_weight = 1.65
	elif distance_to_center_ratio >= 0.88:
		center_weight = 1.10
	elif shrink_started and distance_to_center_ratio >= 0.78:
		center_weight = 0.55
	elif shrink_started:
		center_weight = 0.18

	if center_weight <= 0.0:
		return _get_bot_hazard_avoidance(move_vector)

	move_vector = (move_vector + center_direction.normalized() * center_weight).normalized()
	return _get_bot_hazard_avoidance(move_vector)


func _try_bot_actions() -> void:
	if bot_action_timer > 0.0 or is_dashing or is_mine_placing_active():
		return

	var bot_target := _get_bot_target()
	if bot_target == null:
		return

	var to_target: Vector2 = bot_target.global_position - global_position
	var distance: float = to_target.length()
	if distance <= 0.001:
		return

	aim_direction = _get_bot_fireball_aim_direction(bot_target)
	var target_near_hazard: bool = _is_position_near_bot_hazard(bot_target.global_position, body_radius + 46.0)
	var dash_lane_safe: bool = _is_bot_dash_lane_safe(bot_target.global_position)
	var duel_active: bool = _get_alive_fighter_count() <= 2
	var duel_break_active: bool = duel_active and bot_duel_break_left <= 0.0
	var dash_commit_range: float = bot_dash_commit_range * bot_commit_bias
	var dash_finisher_range: float = bot_dash_finisher_range * bot_commit_bias
	var target_approaching: bool = false
	if bot_target is CharacterBody2D:
		var target_velocity: Vector2 = (bot_target as CharacterBody2D).velocity
		target_approaching = target_velocity.dot(-to_target.normalized()) > 80.0

	if can_use_ability("mine") and distance < 190.0 and (target_approaching or distance < 145.0 or duel_break_active):
		if use_ability("mine"):
			bot_action_timer = 1.2
			_reset_bot_duel_break_timer()
			return

	if bot_reflect_punish_left > 0.0:
		if can_use_ability("fireball") and distance < 980.0:
			if use_ability("fireball"):
				bot_action_timer = 0.52
				_reset_bot_duel_break_timer()
				return
		if can_use_ability("dash") and dash_lane_safe and distance > 120.0 and distance < dash_commit_range:
			if use_ability("dash"):
				bot_action_timer = 0.78
				_reset_bot_duel_break_timer()
				return

	if can_use_ability("fireball") and distance < 1080.0:
		if target_near_hazard or distance < bot_fireball_preferred_range or bot_last_mine_time_left > 0.0 or duel_break_active:
			if use_ability("fireball"):
				bot_action_timer = bot_action_interval + 0.22
				_reset_bot_duel_break_timer()
				return

	if can_use_ability("dash") and dash_lane_safe and distance > 110.0 and distance < dash_commit_range:
		if target_near_hazard or distance < dash_finisher_range or duel_break_active:
			if use_ability("dash"):
				bot_action_timer = 1.15
				_reset_bot_duel_break_timer()
				return

	if can_use_ability("dash") and dash_lane_safe and distance > 140.0 and distance < dash_commit_range and duel_break_active:
		if use_ability("dash"):
			bot_action_timer = 1.2
			_reset_bot_duel_break_timer()
			return

	if can_use_ability("fireball") and distance < 1080.0:
		if use_ability("fireball"):
			bot_action_timer = bot_action_interval + 0.25
			_reset_bot_duel_break_timer()


func _try_bot_reflect_response() -> void:
	if not can_use_ability("reflect_shield"):
		return
	if is_reflect_shield_active() or is_dashing or dash_windup_left > 0.0 or is_mine_placing_active():
		return

	var projectile_layer := _get_projectile_layer()
	if projectile_layer == null:
		return

	var bot_target := _get_bot_target()
	var duel_active: bool = _get_alive_fighter_count() <= 2
	var shield_radius: float = body_radius * float(reflect_shield_config.get("shield_radius_multiplier", 1.35))
	var trigger_distance: float = shield_radius + (98.0 if duel_active else 88.0)
	var trigger_distance_sq: float = trigger_distance * trigger_distance
	var target_can_shoot_now: bool = false
	var target_facing_us: bool = false
	var target_distance: float = INF
	if bot_target != null:
		target_distance = global_position.distance_to(bot_target.global_position)
		if bot_target.has_method("can_use_ability"):
			target_can_shoot_now = bot_target.can_use_ability("fireball")
		var bot_to_target: Vector2 = global_position - bot_target.global_position
		if bot_to_target.length_squared() > 0.001:
			target_facing_us = bot_target.aim_direction.normalized().dot(bot_to_target.normalized()) >= 0.90

	if duel_active and bot_target != null and target_can_shoot_now and target_facing_us and target_distance < 340.0:
		var hazard_pressure: bool = _is_position_near_bot_hazard(global_position, body_radius + 18.0)
		var instability_pressure: bool = instability_bonus >= instability_max_bonus * 0.42
		if hazard_pressure or instability_pressure:
			aim_direction = (bot_target.global_position - global_position).normalized()
			if use_ability("reflect_shield"):
				bot_action_timer = maxf(bot_action_timer, 0.46)
				return

	for projectile in projectile_layer.get_children():
		if projectile == null or not is_instance_valid(projectile):
			continue
		if not projectile.has_method("reflect_from_shield"):
			continue
		if projectile.source_node == self:
			continue

		var to_bot: Vector2 = global_position - projectile.global_position
		if to_bot.length_squared() > trigger_distance_sq:
			continue
		if projectile.direction.length_squared() <= 0.001:
			continue

		var projectile_direction: Vector2 = projectile.direction.normalized()
		var to_bot_normalized: Vector2 = to_bot.normalized()
		var incoming_alignment: float = projectile_direction.dot(to_bot_normalized)
		if incoming_alignment < (0.84 if duel_active else 0.87):
			continue

		var time_to_impact: float = to_bot.length() / maxf(1.0, float(projectile.speed))
		if time_to_impact > (0.30 if duel_active else 0.26):
			continue

		if _is_position_near_bot_hazard(global_position, body_radius + 18.0) and not duel_active:
			continue

		var reflect_direction: Vector2 = -projectile_direction
		var reflect_is_useful: bool = duel_active
		if bot_target != null:
			var to_target: Vector2 = bot_target.global_position - global_position
			if to_target.length_squared() > 0.001:
				var target_alignment: float = reflect_direction.dot(to_target.normalized())
				if target_alignment >= 0.44:
					reflect_is_useful = true
				elif to_target.length() <= 220.0:
					reflect_is_useful = true
				elif _is_position_near_bot_hazard(bot_target.global_position, body_radius + 34.0):
					reflect_is_useful = true
		elif to_bot.length() <= shield_radius + 52.0:
			reflect_is_useful = true
		if not reflect_is_useful:
			continue

		aim_direction = reflect_direction
		if use_ability("reflect_shield"):
			bot_action_timer = maxf(bot_action_timer, 0.42)
			return


func _get_bot_fireball_aim_direction(bot_target: CharacterBody2D) -> Vector2:
	var to_target: Vector2 = bot_target.global_position - global_position
	if to_target.length_squared() <= 0.001:
		return aim_direction

	var target_velocity: Vector2 = bot_target.velocity
	var fireball_config: Dictionary = ability_runtime_configs.get("fireball", {})
	var projectile_speed: float = float(
		fireball_config.get("projectile_speed", move_speed * fireball_speed_multiplier)
	)
	if projectile_speed <= 0.001:
		return to_target.normalized()

	var travel_time: float = minf(0.55, to_target.length() / projectile_speed)
	var predicted_position: Vector2 = bot_target.global_position + target_velocity * travel_time
	var predicted_direction: Vector2 = predicted_position - global_position
	if predicted_direction.length_squared() <= 0.001:
		return to_target.normalized()
	return predicted_direction.normalized()


func _get_bot_hazard_avoidance(base_move_vector: Vector2) -> Vector2:
	var avoidance := Vector2.ZERO
	var urgency: float = 0.0

	for mine in _get_tree_nodes_from_layer("Mines"):
		if mine == null or not is_instance_valid(mine):
			continue

		var mine_position: Vector2 = mine.global_position
		var from_hazard: Vector2 = global_position - mine_position
		var distance: float = from_hazard.length()
		if distance <= 0.001:
			from_hazard = Vector2.UP
			distance = 0.001

		var armed: bool = bool(mine.get("armed"))
		var triggered: bool = bool(mine.get("triggered"))
		var trigger_radius: float = float(mine.get("trigger_radius"))
		var explosion_radius: float = float(mine.get("explosion_radius"))

		var danger_radius: float = explosion_radius if triggered else trigger_radius
		var padding: float = bot_hazard_padding + body_radius
		if distance > danger_radius + padding:
			continue

		var closeness: float = 1.0 - clampf((distance - body_radius) / maxf(1.0, danger_radius + padding), 0.0, 1.0)
		var weight: float = (2.0 if triggered else 1.15) * maxf(0.18, closeness)
		avoidance += from_hazard.normalized() * weight
		urgency = maxf(urgency, weight)

	for hole in get_tree().get_nodes_in_group("holes"):
		if hole == null or not is_instance_valid(hole):
			continue
		if not hole.has_method("get_hole_radius"):
			continue

		var hole_position: Vector2 = hole.global_position
		var from_hole: Vector2 = global_position - hole_position
		var hole_distance: float = from_hole.length()
		if hole_distance <= 0.001:
			from_hole = Vector2.UP
			hole_distance = 0.001

		var hole_radius: float = float(hole.get_hole_radius())
		var safe_radius: float = hole_radius + body_radius + bot_hazard_padding
		if hole_distance > safe_radius:
			continue

		var hole_closeness: float = 1.0 - clampf((hole_distance - body_radius) / maxf(1.0, safe_radius), 0.0, 1.0)
		var hole_weight: float = 1.45 * maxf(0.15, hole_closeness)
		avoidance += from_hole.normalized() * hole_weight
		urgency = maxf(urgency, hole_weight)

	if avoidance.length_squared() <= 0.001:
		return base_move_vector
	if base_move_vector.length_squared() <= 0.001:
		return avoidance.normalized()
	if urgency >= 0.85:
		return avoidance.normalized()
	return (base_move_vector + avoidance.normalized() * minf(1.15, urgency)).normalized()


func _is_position_near_bot_hazard(check_position: Vector2, extra_padding: float = 0.0) -> bool:
	for mine in _get_tree_nodes_from_layer("Mines"):
		if mine == null or not is_instance_valid(mine):
			continue
		var armed: bool = bool(mine.get("armed"))
		var triggered: bool = bool(mine.get("triggered"))
		var danger_radius: float = float(mine.get("explosion_radius")) if triggered else float(mine.get("trigger_radius"))
		if check_position.distance_squared_to(mine.global_position) <= pow(danger_radius + extra_padding, 2.0):
			return true

	for hole in get_tree().get_nodes_in_group("holes"):
		if hole == null or not is_instance_valid(hole):
			continue
		if not hole.has_method("get_hole_radius"):
			continue
		var safe_radius: float = float(hole.get_hole_radius()) + extra_padding
		if check_position.distance_squared_to(hole.global_position) <= safe_radius * safe_radius:
			return true

	return false


func _is_bot_dash_lane_safe(target_position: Vector2) -> bool:
	var to_target: Vector2 = target_position - global_position
	if to_target.length_squared() <= 0.001:
		return false

	var dash_direction_candidate: Vector2 = to_target.normalized()
	var dash_distance_value: float = float(
		ability_runtime_configs.get("dash", {}).get("dash_distance", dash_speed * dash_duration)
	)
	var check_distance: float = minf(dash_distance_value, to_target.length())

	for step in range(1, 5):
		var sample_distance: float = check_distance * float(step) / 4.0
		var sample_position: Vector2 = global_position + dash_direction_candidate * sample_distance
		if _is_position_near_bot_hazard(sample_position, body_radius + 20.0):
			return false

	var arena := _get_arena_node()
	if arena != null and arena.has_method("is_point_inside_arena"):
		var final_position: Vector2 = global_position + dash_direction_candidate * check_distance
		if not arena.is_point_inside_arena(final_position, body_radius * 0.45):
			return false

	return true


func _get_tree_nodes_from_layer(layer_name: String) -> Array:
	var layer := _get_scene_layer(layer_name)
	if layer == null:
		return []
	return layer.get_children()


func _get_bot_target() -> CharacterBody2D:
	var closest_target: CharacterBody2D = null
	var closest_distance_sq: float = INF

	for node in get_tree().get_nodes_in_group("push_targets"):
		if node == self:
			continue
		if not is_instance_valid(node):
			continue
		if not (node is CharacterBody2D):
			continue
		if node.has_method("is_fighter_alive") and not node.is_fighter_alive():
			continue

		var fighter := node as CharacterBody2D
		var distance_sq: float = global_position.distance_squared_to(fighter.global_position)
		if distance_sq >= closest_distance_sq:
			continue

		closest_distance_sq = distance_sq
		closest_target = fighter

	return closest_target


func _get_alive_fighter_count() -> int:
	var alive_count: int = 0

	for node in get_tree().get_nodes_in_group("push_targets"):
		if not is_instance_valid(node):
			continue
		if not (node is CharacterBody2D):
			continue
		if node.has_method("is_fighter_alive") and not node.is_fighter_alive():
			continue
		alive_count += 1

	return alive_count


func _reset_bot_duel_break_timer() -> void:
	bot_duel_break_left = bot_duel_break_interval


func get_hit_radius() -> float:
	if is_reflect_shield_active():
		return body_radius * float(reflect_shield_config.get("shield_radius_multiplier", 1.35))
	return body_radius


func is_fighter_alive() -> bool:
	return not is_eliminated


func is_bot_controlled() -> bool:
	return control_mode == ControlMode.BOT


func set_spawn_position(new_spawn_position: Vector2, snap_now: bool = false) -> void:
	spawn_position = new_spawn_position
	if not snap_now:
		return

	global_position = new_spawn_position
	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	queue_redraw()


func snap_to_position(new_position: Vector2) -> void:
	global_position = new_position
	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_stop_dash(false)
	dash_hit_targets.clear()
	queue_redraw()


func play_upgrade_animation() -> void:
	upgrade_animation_left = maxf(upgrade_animation_left, upgrade_animation_duration)
	queue_redraw()


func get_instability_status() -> Dictionary:
	var instability_ratio: float = 0.0
	if instability_max_bonus > 0.001:
		instability_ratio = clampf(instability_bonus / instability_max_bonus, 0.0, 1.0)
	return {
		"bonus_ratio": instability_ratio,
		"bonus_percent": int(round(instability_bonus * 100.0)),
		"decay_seconds_left": maxf(0.0, instability_decay_delay_left),
		"decay_duration": instability_decay_delay
	}


func set_round_locked(locked: bool) -> void:
	round_locked = locked
	if locked:
		move_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		_stop_dash(false)
		dash_hit_targets.clear()
		_interrupt_abilities()
		_clear_temporary_effects()


func _get_instability_display_color(ratio: float) -> Color:
	var safe_color := Color(0.18, 0.92, 0.34, 0.95)
	var warning_color := Color(1.0, 0.82, 0.16, 0.98)
	var danger_color := Color(1.0, 0.20, 0.18, 0.98)
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	if clamped_ratio <= 0.5:
		return safe_color.lerp(warning_color, clamped_ratio / 0.5)
	return warning_color.lerp(danger_color, (clamped_ratio - 0.5) / 0.5)


func apply_knockback(
	push_direction: Vector2,
	strength: float,
	control_lock_time: float = 0.0,
	source_node: Node = null
) -> void:
	if is_eliminated or push_direction.length_squared() <= 0.001:
		return

	var incoming_strength: float = strength
	if temporary_incoming_knockback_left > 0.0:
		incoming_strength *= temporary_incoming_knockback_multiplier
	if powerup_incoming_knockback_left > 0.0:
		incoming_strength *= powerup_incoming_knockback_multiplier

	var effective_strength: float = incoming_strength * (1.0 + instability_bonus)
	knockback_velocity += push_direction.normalized() * effective_strength
	instability_bonus = minf(instability_max_bonus, instability_bonus + instability_gain_per_hit)
	instability_decay_delay_left = instability_decay_delay
	hit_feedback_left = 0.18

	if source_node != null and source_node != self and is_instance_valid(source_node):
		last_attacker = source_node
		last_attacker_left = last_hit_credit_time

	if control_lock_time > 0.0:
		control_lock_left = maxf(control_lock_left, control_lock_time)
		_stop_dash(false)
		dash_hit_targets.clear()
		_interrupt_abilities()


func get_fighter_name() -> String:
	if fighter_name != "":
		return fighter_name
	return name


func _check_dash_hits() -> void:
	for node in get_tree().get_nodes_in_group("push_targets"):
		if node == self:
			continue
		if not is_instance_valid(node):
			continue
		if not node.has_method("get_hit_radius") or not node.has_method("apply_knockback"):
			continue
		if dash_hit_targets.has(node):
			continue

		var hit_radius: float = node.get_hit_radius()
		var combined_radius: float = body_radius + dash_hit_radius_bonus + hit_radius
		if global_position.distance_squared_to(node.global_position) > combined_radius * combined_radius:
			continue

		var applied_push_strength: float = dash_push_strength
		var dash_config: Dictionary = ability_runtime_configs.get("dash", {})
		if dash_hit_count >= 1:
			applied_push_strength *= float(dash_config.get("second_target_knockback_multiplier", 1.0))
		elif not dash_first_hit_extended:
			var extra_duration: float = float(dash_config.get("extra_dash_duration_after_first_hit_sec", 0.0))
			if extra_duration > 0.0:
				dash_timer += extra_duration
				dash_first_hit_extended = true

		node.apply_knockback(dash_direction, applied_push_strength, 0.08, self)
		dash_hit_targets.append(node)
		dash_hit_count += 1


func _check_holes(delta: float) -> void:
	if is_eliminated or fall_grace_left > 0.0:
		_reset_hole_fall_state()
		return

	var inside_hole: bool = false
	for hole in get_tree().get_nodes_in_group("holes"):
		if not is_instance_valid(hole):
			continue
		if not hole.has_method("get_hole_radius"):
			continue

		var hole_radius: float = hole.get_hole_radius()
		var fall_radius := maxf(16.0, hole_radius + body_radius * 0.25)
		if global_position.distance_squared_to(hole.global_position) > fall_radius * fall_radius:
			continue

		inside_hole = true
		break

	if not inside_hole:
		_reset_hole_fall_state()
		return

	if not is_inside_hole:
		is_inside_hole = true
		hole_grace_left = hole_grace_time
		hole_time_left = _get_current_hole_fall_time_limit()

	if hole_grace_left > 0.0:
		hole_grace_left = maxf(0.0, hole_grace_left - delta)
		return

	hole_time_left = maxf(0.0, hole_time_left - delta)
	if hole_time_left <= 0.0:
		_eliminate_from_fall()
		return


func _check_outside_arena(delta: float) -> void:
	if is_eliminated or fall_grace_left > 0.0:
		_reset_outside_arena_state()
		return

	var arena := _get_arena_node()
	if arena == null:
		_reset_outside_arena_state()
		return
	if not arena.has_method("is_point_inside_arena"):
		_reset_outside_arena_state()
		return
	if arena.is_point_inside_arena(global_position, body_radius * 0.45):
		_reset_outside_arena_state()
		return

	if not is_outside_arena:
		is_outside_arena = true
		outside_grace_left = outside_grace_time
		outside_time_left = _get_current_outside_time_limit()

	if outside_grace_left > 0.0:
		outside_grace_left = maxf(0.0, outside_grace_left - delta)
		return

	outside_time_left = maxf(0.0, outside_time_left - delta)
	if outside_time_left <= 0.0:
		_eliminate_from_fall()


func _get_current_outside_time_limit() -> float:
	var arena := _get_arena_node()
	if arena == null or not arena.has_method("get_shrink_progress"):
		return outside_time_max

	var shrink_progress: float = clampf(float(arena.get_shrink_progress()), 0.0, 1.0)
	return lerpf(outside_time_max, outside_time_min, shrink_progress)


func _get_current_hole_fall_time_limit() -> float:
	var arena := _get_arena_node()
	if arena == null or not arena.has_method("get_shrink_progress"):
		return hole_time_max

	var shrink_progress: float = clampf(float(arena.get_shrink_progress()), 0.0, 1.0)
	return lerpf(hole_time_max, hole_time_min, shrink_progress)


func _reset_outside_arena_state() -> void:
	is_outside_arena = false
	outside_grace_left = 0.0
	outside_time_left = 0.0


func _reset_hole_fall_state() -> void:
	is_inside_hole = false
	hole_grace_left = 0.0
	hole_time_left = 0.0


func get_outside_arena_status() -> Dictionary:
	var time_limit: float = _get_current_outside_time_limit()
	var progress: float = 0.0
	if time_limit > 0.001:
		progress = clampf(outside_time_left / time_limit, 0.0, 1.0)

	return {
		"active": is_outside_arena,
		"grace_left": outside_grace_left,
		"time_left": outside_time_left,
		"time_limit": time_limit,
		"progress": progress
	}


func get_fall_timer_status() -> Dictionary:
	if is_inside_hole:
		var hole_limit: float = _get_current_hole_fall_time_limit()
		var hole_progress: float = 0.0
		if hole_limit > 0.001:
			hole_progress = clampf(hole_time_left / hole_limit, 0.0, 1.0)
		return {
			"active": true,
			"source": "hole",
			"grace_left": hole_grace_left,
			"time_left": hole_time_left,
			"time_limit": hole_limit,
			"progress": hole_progress
		}

	var outside_status: Dictionary = get_outside_arena_status()
	outside_status["source"] = "outside"
	return outside_status


func _eliminate_from_fall() -> void:
	if is_eliminated:
		return

	var attacker: Node = null
	if last_attacker != null and is_instance_valid(last_attacker) and last_attacker_left > 0.0:
		attacker = last_attacker

	var scene_root := get_tree().current_scene
	if scene_root != null and scene_root.has_method("try_consume_final_save_for"):
		if scene_root.try_consume_final_save_for(self):
			return

	is_eliminated = true
	round_locked = true
	remove_from_group("push_targets")

	if scene_root != null and scene_root.has_method("register_fall"):
		scene_root.register_fall(self, attacker)

	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_stop_dash(false)
	dash_hit_targets.clear()
	_interrupt_abilities()
	instability_bonus = 0.0
	instability_decay_delay_left = 0.0
	hit_feedback_left = 0.0
	_clear_temporary_effects()
	control_lock_left = 0.0
	fall_grace_left = 0.0
	_reset_outside_arena_state()
	_reset_hole_fall_state()
	last_attacker = null
	last_attacker_left = 0.0
	visible = false


func reset_for_new_round() -> void:
	if not is_in_group("push_targets"):
		add_to_group("push_targets")

	is_eliminated = false
	round_locked = false
	visible = true
	global_position = _find_safe_respawn_position()
	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_stop_dash(false)
	dash_hit_targets.clear()
	_reset_abilities()
	instability_bonus = 0.0
	instability_decay_delay_left = 0.0
	hit_feedback_left = 0.0
	_clear_temporary_effects()
	control_lock_left = 0.0
	fall_grace_left = 0.0
	_reset_outside_arena_state()
	_reset_hole_fall_state()
	last_attacker = null
	last_attacker_left = 0.0
	upgrade_animation_left = 0.0
	bot_action_timer = bot_action_interval
	bot_strafe_timer = bot_strafe_interval
	bot_last_mine_time_left = 0.0
	queue_redraw()


func trigger_final_save_rescue() -> void:
	if is_eliminated:
		return

	round_locked = false
	visible = true
	global_position = _find_final_save_position()
	move_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_stop_dash(false)
	dash_hit_targets.clear()
	_interrupt_abilities()
	_force_abilities_on_cooldown()
	instability_bonus = 0.0
	instability_decay_delay_left = 0.0
	hit_feedback_left = 0.0
	_clear_temporary_effects()
	control_lock_left = maxf(control_lock_left, final_save_control_lock)
	fall_grace_left = maxf(fall_grace_left, final_save_fall_grace)
	_reset_outside_arena_state()
	_reset_hole_fall_state()
	upgrade_animation_left = 0.0
	queue_redraw()


func _find_safe_respawn_position() -> Vector2:
	var anchors: Array[Vector2] = [spawn_position]
	var arena := _get_arena_node()
	if arena != null and arena.has_method("get_arena_center"):
		var arena_center: Vector2 = arena.get_arena_center()
		if arena_center.distance_squared_to(spawn_position) > 1.0:
			anchors.append(arena_center)

	for anchor in anchors:
		if _is_respawn_position_safe(anchor):
			return anchor

	var test_radii: Array[float] = [90.0, 170.0, 250.0, 330.0]
	for anchor in anchors:
		for radius in test_radii:
			for step in range(16):
				var angle: float = TAU * float(step) / 16.0
				var candidate: Vector2 = anchor + Vector2.RIGHT.rotated(angle) * radius
				if not _is_respawn_position_safe(candidate):
					continue
				return candidate

	if arena != null and arena.has_method("get_arena_center"):
		var arena_center: Vector2 = arena.get_arena_center()
		if _is_position_inside_arena(arena_center):
			return arena_center

	return spawn_position


func _find_final_save_position() -> Vector2:
	var arena := _get_arena_node()
	if arena == null or not arena.has_method("get_arena_center"):
		return _find_safe_respawn_position()

	var arena_center: Vector2 = arena.get_arena_center()
	if _is_respawn_position_safe(arena_center):
		return arena_center

	var rescue_radii: Array[float] = [90.0, 170.0, 250.0, 330.0]
	for radius in rescue_radii:
		for step in range(16):
			var angle: float = TAU * float(step) / 16.0
			var candidate: Vector2 = arena_center + Vector2.RIGHT.rotated(angle) * radius
			if not _is_respawn_position_safe(candidate):
				continue
			return candidate

	return _find_safe_respawn_position()


func _is_respawn_position_safe(check_position: Vector2) -> bool:
	if not _is_position_inside_arena(check_position):
		return false
	if _is_position_blocked_by_hole(check_position):
		return false
	return true


func _is_position_inside_arena(check_position: Vector2) -> bool:
	var arena := _get_arena_node()
	if arena == null:
		return true
	if not arena.has_method("is_point_inside_arena"):
		return true
	return arena.is_point_inside_arena(check_position, body_radius * 1.1)


func _is_position_blocked_by_hole(check_position: Vector2) -> bool:
	for hole in get_tree().get_nodes_in_group("holes"):
		if not is_instance_valid(hole):
			continue
		if not hole.has_method("get_hole_radius"):
			continue

		var hole_radius: float = hole.get_hole_radius()
		var fall_radius := maxf(12.0, hole_radius - body_radius * 0.35)
		if check_position.distance_squared_to(hole.global_position) <= fall_radius * fall_radius:
			return true

	return false
