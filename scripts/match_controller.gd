extends Node2D

const BOT_PLAYER_SCRIPT := preload("res://scripts/bot_player.gd")
const UPGRADE_STAGE_AVATAR_SCRIPT := preload("res://scripts/upgrade_stage_avatar.gd")
const ABILITY_ICON_SCRIPT := preload("res://scripts/ability_icon.gd")
const POWERUP_MANAGER_SCRIPT := preload("res://scripts/powerup_manager.gd")
const AUTO_BOT_POSITIONS := [
	Vector2(1280.0, 540.0),
	Vector2(760.0, 800.0),
	Vector2(760.0, 280.0),
	Vector2(1160.0, 840.0),
	Vector2(1160.0, 240.0)
]

@export var round_restart_delay: float = 3.5
@export var between_round_upgrade_duration: float = 12.0
@export var match_total_rounds: int = 5
@export var desired_bot_count: int = 3
@export var edge_spawn_padding: float = 130.0
@export var upgrade_stage_radius: float = 118.0
@export var upgrade_stage_panel_gap: float = 135.0
@export var upgrade_stage_vertical_spacing: float = 112.0
@export var starting_os: int = 1
@export var passive_os_interval: float = 32.0
@export var passive_os_amount: int = 1
@export var kill_reward_os: int = 2
@export var round_end_os_stipend: int = 2
@export var round_winner_bonus_os: int = 1
@export var tier_1_upgrade_cost: int = 2
@export var tier_2_upgrade_cost: int = 3
@export var tier_3_upgrade_cost: int = 5
@export var final_save_enabled: bool = true
@export var bot_auto_upgrades_enabled: bool = true
@export var bot_upgrade_think_interval_min: float = 0.45
@export var bot_upgrade_think_interval_max: float = 1.10
@export var duel_shrink_stage_1_delay: float = 7.0
@export var duel_shrink_stage_2_delay: float = 14.0
@export var duel_shrink_stage_1_speed_multiplier: float = 1.7
@export var duel_shrink_stage_2_speed_multiplier: float = 2.3

const BOT_BUILD_PLANS := [
	{
		"id": "aggressor",
		"label_ru": "Агрессор",
		"steps": [
			"fireball_l1_stable_core",
			"dash_l1_boosters",
			"reflect_l1_mirror_core",
			"dash_l2_ram",
			"fireball_l2_impact_core",
			"reflect_l2_charged_shell",
			"dash_l3_breach_run",
			"reflect_l3_heavy_return",
			"mine_l1_quick_deploy",
			"fireball_l3_siege_fireball"
		]
	},
	{
		"id": "skirmisher",
		"label_ru": "Скирмишер",
		"steps": [
			"fireball_l1_stable_core",
			"dash_l1_boosters",
			"reflect_l1_mirror_core",
			"fireball_l2_marksman",
			"dash_l2_quick_step",
			"reflect_l2_charged_shell",
			"dash_l3_slipstream",
			"fireball_l3_sniper_flame",
			"reflect_l3_split_reflect",
			"mine_l1_quick_deploy"
		]
	},
	{
		"id": "controller",
		"label_ru": "Контроллер",
		"steps": [
			"mine_l1_quick_deploy",
			"reflect_l1_mirror_core",
			"mine_l2_wide_sensor",
			"fireball_l1_stable_core",
			"reflect_l2_charged_shell",
			"mine_l3_control_blast",
			"fireball_l2_impact_core",
			"reflect_l3_split_reflect",
			"dash_l2_quick_step",
			"fireball_l3_siege_fireball"
		]
	},
	{
		"id": "saboteur",
		"label_ru": "Саботажник",
		"steps": [
			"mine_l1_quick_deploy",
			"dash_l1_boosters",
			"reflect_l1_mirror_core",
			"mine_l2_deep_breach",
			"fireball_l1_stable_core",
			"reflect_l2_charged_shell",
			"dash_l2_quick_step",
			"fireball_l2_marksman",
			"reflect_l3_heavy_return",
			"dash_l3_slipstream"
		]
	}
]

var fighter_stats: Dictionary = {}
var fighter_round_wins: Dictionary = {}
var fighter_economy: Dictionary = {}
var bot_upgrade_states: Dictionary = {}
var current_round_number: int = 1
var completed_rounds: int = 0
var match_finished: bool = false
var final_save_owner: Node = null
var final_save_consumed: bool = false
var round_time: float = 0.0
var round_active: bool = true
var duel_mode_active: bool = false
var duel_elapsed_time: float = 0.0
var upgrade_phase_active: bool = false
var upgrade_phase_time_left: float = 0.0
var restart_time_left: float = 0.0
var upgrade_menu_open: bool = false
var upgrade_choice_entries: Array = []

var hud_remaining_value: Label
var hud_round_value: Label
var hud_os_value: Label
var hud_kills_value: Label
var hud_time_value: Label
var hud_hint_label: Label

var scoreboard_panel: PanelContainer
var scoreboard_rows: VBoxContainer
var result_panel: PanelContainer
var result_title: Label
var result_subtitle: Label
var ability_panel: PanelContainer
var ability_row: VBoxContainer
var ability_cards: Dictionary = {}
var ability_panel_height: float = 0.0
var instability_panel: PanelContainer
var instability_bonus_value: Label
var instability_decay_value: Label
var instability_bar_fill: ColorRect
var instability_decay_fill: ColorRect
var upgrade_panel: PanelContainer
var upgrade_title: Label
var upgrade_subtitle: Label
var upgrade_options: VBoxContainer
var upgrade_menu_root: Control
var upgrade_skills_list: VBoxContainer
var upgrade_tree_header: Label
var upgrade_details_name_label: Label
var upgrade_details_meta_label: Label
var upgrade_details_cost_label: Label
var upgrade_details_role_label: Label
var upgrade_details_requirement_label: Label
var upgrade_build_summary_label: Label
var selected_upgrade_choice_index: int = 0
var selected_upgrade_skill_name: String = ""
var filtered_upgrade_choice_entries: Array = []
var draft_mode_enabled: bool = true
var draft_choices: Array = []
var draft_history_recent: Array[String] = []
var draft_roll_iteration: int = 0
var tracked_camera: Camera2D
var default_camera_parent: Node
var local_player: Node
var bot_rng := RandomNumberGenerator.new()
var powerup_manager: Node
var upgrade_stage_root: Node2D
var upgrade_stage_avatars: Dictionary = {}


func _ready() -> void:
	bot_rng.randomize()
	_ensure_bot_roster()
	_register_existing_fighters()
	_assign_edge_spawn_positions(true)
	_cache_local_player()
	_build_ui()
	_build_upgrade_stage_root()
	_build_powerup_manager()
	_cache_camera()
	_refresh_hud()
	_refresh_ability_hud()
	_refresh_scoreboard()


func _process(delta: float) -> void:
	if round_active and not upgrade_menu_open:
		round_time += delta
		_update_duel_mode(delta)
		_update_fighter_economy(delta)
		if powerup_manager != null and is_instance_valid(powerup_manager) and powerup_manager.has_method("process_round"):
			powerup_manager.process_round(delta)
	elif upgrade_phase_active:
		upgrade_phase_time_left = maxf(0.0, upgrade_phase_time_left - delta)
		_update_bot_upgrade_ai(delta)
		_refresh_result_panel()
		if upgrade_phase_time_left <= 0.0:
			_end_upgrade_phase_and_restart_round()
	elif restart_time_left > 0.0:
		restart_time_left = maxf(0.0, restart_time_left - delta)
		_refresh_result_panel()
		if restart_time_left <= 0.0:
			if match_finished:
				_restart_match()
			else:
				_restart_round()

	_refresh_hud()
	_refresh_ability_hud()
	if upgrade_menu_open:
		_refresh_upgrade_panel()


func get_round_time_seconds() -> float:
	return round_time


func is_round_active() -> bool:
	return round_active


func is_duel_mode_active() -> bool:
	return duel_mode_active


func get_duel_elapsed_seconds() -> float:
	return duel_elapsed_time


func get_duel_shrink_profile() -> Dictionary:
	return {
		"stage_1_delay": duel_shrink_stage_1_delay,
		"stage_2_delay": duel_shrink_stage_2_delay,
		"stage_1_speed_multiplier": duel_shrink_stage_1_speed_multiplier,
		"stage_2_speed_multiplier": duel_shrink_stage_2_speed_multiplier
	}


func get_active_fighter_count() -> int:
	return _active_fighter_count()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if upgrade_menu_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_U:
				_close_upgrade_panel()
				return
			if draft_mode_enabled:
				if event.keycode == KEY_Q or event.keycode == KEY_A or event.keycode == KEY_LEFT:
					_cycle_draft_choice_selection(-1)
					return
				if event.keycode == KEY_E or event.keycode == KEY_D or event.keycode == KEY_RIGHT:
					_cycle_draft_choice_selection(1)
					return
			else:
				if event.keycode == KEY_Q or event.keycode == KEY_A or event.keycode == KEY_LEFT:
					_cycle_upgrade_skill_selection(-1)
					return
				if event.keycode == KEY_E or event.keycode == KEY_D or event.keycode == KEY_RIGHT:
					_cycle_upgrade_skill_selection(1)
					return

			var choice_index := _keycode_to_choice_index(event.keycode)
			if choice_index >= 0:
				_select_upgrade_choice(choice_index)
				return
			if draft_mode_enabled and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE):
				_select_upgrade_choice(selected_upgrade_choice_index)
				return

		elif upgrade_phase_active and event.keycode == KEY_U:
			_toggle_upgrade_panel()
			return

	if event is InputEventKey and event.keycode == KEY_TAB:
		if scoreboard_panel != null:
			scoreboard_panel.visible = event.pressed
		return

	if not round_active and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			if match_finished:
				_restart_match()
			elif upgrade_phase_active:
				_end_upgrade_phase_and_restart_round()
			else:
				_restart_round()


func register_fall(victim: Node, attacker: Node = null) -> void:
	if victim == null or not round_active:
		return

	_ensure_fighter_entry(victim)
	fighter_stats[victim]["deaths"] += 1

	if attacker != null and attacker != victim and is_instance_valid(attacker):
		_ensure_fighter_entry(attacker)
		fighter_stats[attacker]["kills"] += 1
		_award_os(attacker, kill_reward_os)

	_update_camera_target()
	_refresh_hud()
	_refresh_scoreboard()

	if _active_fighter_count() <= 1:
		_finish_round()


func _register_existing_fighters() -> void:
	var players_root := get_node_or_null("Players")
	if players_root == null:
		return

	for child in players_root.get_children():
		_ensure_fighter_entry(child)


func _get_fighter_nodes_in_spawn_order() -> Array:
	var fighters: Array = []
	var players_root := get_node_or_null("Players")
	if players_root == null:
		return fighters

	for child in players_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not fighter_stats.has(child):
			continue
		fighters.append(child)

	return fighters


func get_fighter_nodes() -> Array:
	return _get_fighter_nodes_in_spawn_order()


func _assign_edge_spawn_positions(snap_now: bool = false) -> void:
	var fighters := _get_fighter_nodes_in_spawn_order()
	if fighters.is_empty():
		return

	var arena := get_node_or_null("Arena")
	if arena == null:
		return
	if not arena.has_method("get_arena_center") or not arena.has_method("get_base_arena_radius"):
		return

	var center: Vector2 = arena.get_arena_center()
	var base_radius: float = float(arena.get_base_arena_radius())
	var max_hit_radius := 24.0
	for fighter in fighters:
		if fighter.has_method("get_hit_radius"):
			max_hit_radius = maxf(max_hit_radius, float(fighter.get_hit_radius()))

	var spawn_radius := maxf(120.0, base_radius - edge_spawn_padding - max_hit_radius)
	var angle_step := TAU / float(fighters.size())
	var start_angle := -PI * 0.5

	for index in range(fighters.size()):
		var fighter = fighters[index]
		var angle := start_angle + angle_step * float(index)
		var spawn_point := center + Vector2.RIGHT.rotated(angle) * spawn_radius
		if fighter.has_method("set_spawn_position"):
			fighter.set_spawn_position(spawn_point, snap_now)


func _ensure_bot_roster() -> void:
	var players_root := get_node_or_null("Players")
	if players_root == null:
		return

	var current_bots := 0
	for child in players_root.get_children():
		if _is_bot_fighter(child):
			current_bots += 1

	while current_bots < desired_bot_count:
		var bot := BOT_PLAYER_SCRIPT.new()
		bot.name = "Bot%d" % (current_bots + 1)
		bot.position = AUTO_BOT_POSITIONS[min(current_bots, AUTO_BOT_POSITIONS.size() - 1)]
		players_root.add_child(bot)
		current_bots += 1


func _ensure_fighter_entry(fighter: Node) -> void:
	if fighter == null:
		return
	if fighter_stats.has(fighter):
		return

	fighter_stats[fighter] = {
		"kills": 0,
		"deaths": 0
	}
	fighter_round_wins[fighter] = 0
	_ensure_fighter_economy(fighter)
	_ensure_bot_upgrade_state(fighter)


func _build_ui() -> void:
	var ui_root := get_node_or_null("UI")
	if ui_root == null:
		return

	var hud_panel := PanelContainer.new()
	hud_panel.position = Vector2(18.0, 18.0)
	hud_panel.size = Vector2(250.0, 206.0)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_theme_stylebox_override("panel", _make_panel_style(0.84))
	ui_root.add_child(hud_panel)

	var hud_margin := MarginContainer.new()
	hud_margin.add_theme_constant_override("margin_left", 14)
	hud_margin.add_theme_constant_override("margin_top", 12)
	hud_margin.add_theme_constant_override("margin_right", 14)
	hud_margin.add_theme_constant_override("margin_bottom", 12)
	hud_panel.add_child(hud_margin)

	var hud_stack := VBoxContainer.new()
	hud_stack.add_theme_constant_override("separation", 8)
	hud_margin.add_child(hud_stack)

	hud_stack.add_child(_make_hud_row("Осталось", true))
	hud_stack.add_child(_make_hud_row("Раунд", false))
	hud_stack.add_child(_make_hud_row("ОС", false))
	hud_stack.add_child(_make_hud_row("Убийства", false))
	hud_stack.add_child(_make_hud_row("Время", false))

	var hint := Label.new()
	hint.text = "Tab - таблица | U - улучшения"
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.72, 0.78, 0.86, 0.85)
	hud_stack.add_child(hint)
	hud_hint_label = hint

	scoreboard_panel = PanelContainer.new()
	scoreboard_panel.position = Vector2(520.0, 120.0)
	scoreboard_panel.size = Vector2(420.0, 300.0)
	scoreboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scoreboard_panel.visible = false
	scoreboard_panel.add_theme_stylebox_override("panel", _make_panel_style(0.92))
	ui_root.add_child(scoreboard_panel)

	var score_margin := MarginContainer.new()
	score_margin.add_theme_constant_override("margin_left", 18)
	score_margin.add_theme_constant_override("margin_top", 16)
	score_margin.add_theme_constant_override("margin_right", 18)
	score_margin.add_theme_constant_override("margin_bottom", 16)
	scoreboard_panel.add_child(score_margin)

	var score_stack := VBoxContainer.new()
	score_stack.add_theme_constant_override("separation", 10)
	score_margin.add_child(score_stack)

	var title := Label.new()
	title.text = "Таблица"
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.96, 0.98, 1.0)
	score_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Нажми и удерживай Tab"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.modulate = Color(0.72, 0.78, 0.86)
	score_stack.add_child(subtitle)

	scoreboard_rows = VBoxContainer.new()
	scoreboard_rows.add_theme_constant_override("separation", 6)
	score_stack.add_child(scoreboard_rows)

	result_panel = PanelContainer.new()
	result_panel.position = Vector2(520.0, 24.0)
	result_panel.size = Vector2(420.0, 120.0)
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.visible = false
	result_panel.add_theme_stylebox_override("panel", _make_panel_style(0.94))
	ui_root.add_child(result_panel)

	var result_margin := MarginContainer.new()
	result_margin.add_theme_constant_override("margin_left", 18)
	result_margin.add_theme_constant_override("margin_top", 16)
	result_margin.add_theme_constant_override("margin_right", 18)
	result_margin.add_theme_constant_override("margin_bottom", 16)
	result_panel.add_child(result_margin)

	var result_stack := VBoxContainer.new()
	result_stack.add_theme_constant_override("separation", 6)
	result_margin.add_child(result_stack)

	result_title = Label.new()
	result_title.text = ""
	result_title.add_theme_font_size_override("font_size", 26)
	result_title.modulate = Color(0.96, 0.98, 1.0)
	result_stack.add_child(result_title)

	result_subtitle = Label.new()
	result_subtitle.text = ""
	result_subtitle.add_theme_font_size_override("font_size", 15)
	result_subtitle.modulate = Color(0.72, 0.78, 0.86)
	result_stack.add_child(result_subtitle)

	ability_panel = PanelContainer.new()
	ability_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ability_panel.offset_left = -168.0
	ability_panel.offset_top = 188.0
	ability_panel.offset_right = -10.0
	ability_panel.offset_bottom = 560.0
	ability_panel.add_theme_stylebox_override("panel", _make_panel_style(0.0))
	ui_root.add_child(ability_panel)

	var ability_margin := MarginContainer.new()
	ability_margin.add_theme_constant_override("margin_left", 0)
	ability_margin.add_theme_constant_override("margin_top", 0)
	ability_margin.add_theme_constant_override("margin_right", 0)
	ability_margin.add_theme_constant_override("margin_bottom", 0)
	ability_panel.add_child(ability_margin)

	ability_row = VBoxContainer.new()
	ability_row.add_theme_constant_override("separation", 6)
	ability_margin.add_child(ability_row)

	instability_panel = PanelContainer.new()
	instability_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instability_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	instability_panel.offset_left = -168.0
	instability_panel.offset_top = 96.0
	instability_panel.offset_right = -10.0
	instability_panel.offset_bottom = 176.0
	instability_panel.add_theme_stylebox_override("panel", _make_panel_style(0.0))
	ui_root.add_child(instability_panel)

	var instability_margin := MarginContainer.new()
	instability_margin.add_theme_constant_override("margin_left", 0)
	instability_margin.add_theme_constant_override("margin_top", 0)
	instability_margin.add_theme_constant_override("margin_right", 0)
	instability_margin.add_theme_constant_override("margin_bottom", 0)
	instability_panel.add_child(instability_margin)

	var instability_stack := VBoxContainer.new()
	instability_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	instability_stack.add_theme_constant_override("separation", 3)
	instability_margin.add_child(instability_stack)

	var meter_back := ColorRect.new()
	meter_back.custom_minimum_size = Vector2(14.0, 66.0)
	meter_back.color = Color(0.08, 0.10, 0.13, 0.92)
	instability_stack.add_child(meter_back)

	instability_bar_fill = ColorRect.new()
	instability_bar_fill.color = Color(0.18, 0.92, 0.34)
	instability_bar_fill.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	instability_bar_fill.anchor_top = 1.0
	instability_bar_fill.anchor_bottom = 1.0
	instability_bar_fill.offset_top = 0.0
	instability_bar_fill.offset_bottom = 0.0
	meter_back.add_child(instability_bar_fill)

	instability_decay_value = Label.new()
	instability_decay_value.text = "3.0с"
	instability_decay_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instability_decay_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instability_decay_value.add_theme_font_size_override("font_size", 14)
	instability_decay_value.modulate = Color(0.90, 0.94, 0.98)
	instability_stack.add_child(instability_decay_value)

	instability_bonus_value = null
	instability_decay_fill = null

	_layout_right_combat_hud()

	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	upgrade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_panel.offset_left = -360.0
	upgrade_panel.offset_top = -220.0
	upgrade_panel.offset_right = 360.0
	upgrade_panel.offset_bottom = 220.0
	upgrade_panel.add_theme_stylebox_override("panel", _make_panel_style(0.96))
	ui_root.add_child(upgrade_panel)

	var upgrade_margin := MarginContainer.new()
	upgrade_margin.add_theme_constant_override("margin_left", 18)
	upgrade_margin.add_theme_constant_override("margin_top", 16)
	upgrade_margin.add_theme_constant_override("margin_right", 18)
	upgrade_margin.add_theme_constant_override("margin_bottom", 16)
	upgrade_panel.add_child(upgrade_margin)

	var upgrade_stack := VBoxContainer.new()
	upgrade_stack.add_theme_constant_override("separation", 10)
	upgrade_margin.add_child(upgrade_stack)

	upgrade_title = Label.new()
	upgrade_title.text = "Выбор улучшения"
	upgrade_title.add_theme_font_size_override("font_size", 28)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_title.modulate = Color(0.96, 0.98, 1.0)
	upgrade_stack.add_child(upgrade_title)

	upgrade_subtitle = Label.new()
	upgrade_subtitle.text = "U / Esc - закрыть, 1-9 - выбрать"
	upgrade_subtitle.add_theme_font_size_override("font_size", 15)
	upgrade_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_subtitle.modulate = Color(0.72, 0.78, 0.86)
	upgrade_stack.add_child(upgrade_subtitle)

	upgrade_options = VBoxContainer.new()
	upgrade_options.add_theme_constant_override("separation", 8)
	upgrade_stack.add_child(upgrade_options)

	_build_upgrade_menu_v2(ui_root)

	_rebuild_ability_hud()


func _build_upgrade_stage_root() -> void:
	upgrade_stage_root = get_node_or_null("UpgradeStageAvatars")
	if upgrade_stage_root != null:
		return

	upgrade_stage_root = Node2D.new()
	upgrade_stage_root.name = "UpgradeStageAvatars"
	add_child(upgrade_stage_root)


func _build_powerup_manager() -> void:
	if powerup_manager != null and is_instance_valid(powerup_manager):
		return

	powerup_manager = POWERUP_MANAGER_SCRIPT.new()
	powerup_manager.name = "PowerupManager"
	add_child(powerup_manager)
	if powerup_manager.has_method("setup"):
		powerup_manager.setup(self)


func _build_upgrade_menu_v2(ui_root: Node) -> void:
	if ui_root == null or upgrade_menu_root != null:
		return

	upgrade_menu_root = Control.new()
	upgrade_menu_root.visible = false
	upgrade_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(upgrade_menu_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_menu_root.add_child(dim)

	var center_holder := CenterContainer.new()
	center_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_menu_root.add_child(center_holder)

	var content_row := HBoxContainer.new()
	content_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content_row.add_theme_constant_override("separation", 22)
	center_holder.add_child(content_row)

	upgrade_title = Label.new()
	upgrade_title.text = ""
	upgrade_title.visible = false

	upgrade_subtitle = Label.new()
	upgrade_subtitle.text = ""
	upgrade_subtitle.visible = false

	upgrade_tree_header = Label.new()
	upgrade_tree_header.text = ""
	upgrade_tree_header.visible = false

	upgrade_options = VBoxContainer.new()
	upgrade_options.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_options.add_theme_constant_override("separation", 0)
	content_row.add_child(upgrade_options)

	upgrade_details_name_label = Label.new()
	upgrade_details_name_label.text = ""
	upgrade_details_name_label.visible = false

	upgrade_details_meta_label = Label.new()
	upgrade_details_meta_label.text = ""
	upgrade_details_meta_label.visible = false

	upgrade_details_cost_label = Label.new()
	upgrade_details_cost_label.text = ""
	upgrade_details_cost_label.visible = false

	upgrade_details_role_label = Label.new()
	upgrade_details_role_label.text = ""
	upgrade_details_role_label.visible = false

	upgrade_details_requirement_label = Label.new()
	upgrade_details_requirement_label.text = ""
	upgrade_details_requirement_label.visible = false

	upgrade_build_summary_label = Label.new()
	upgrade_build_summary_label.text = ""
	upgrade_build_summary_label.visible = false

	upgrade_skills_list = null


func notify_powerup_collected(pickup: Node, fighter: Node, powerup_id: String) -> void:
	if powerup_manager != null and is_instance_valid(powerup_manager) and powerup_manager.has_method("notify_pickup_collected"):
		powerup_manager.notify_pickup_collected(pickup)


func _make_panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, alpha)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.30, 0.45, 0.60, 0.75)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


func _make_hud_row(title_text: String, large_value: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.custom_minimum_size = Vector2(110.0, 0.0)
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.72, 0.78, 0.86)
	row.add_child(title)

	var value := Label.new()
	value.text = "-"
	value.add_theme_font_size_override("font_size", 28 if large_value else 20)
	value.modulate = Color(0.96, 0.98, 1.0)
	row.add_child(value)

	if title_text == "Осталось":
		hud_remaining_value = value
	elif title_text == "Раунд":
		hud_round_value = value
	elif title_text == "ОС":
		hud_os_value = value
	elif title_text == "Убийства":
		hud_kills_value = value
	else:
		hud_time_value = value

	return row


func _make_ability_card(
	ability_id: String,
	display_name: String,
	bind_text: String,
	accent: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(144.0, 114.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.12, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(accent.r * 0.72, accent.g * 0.72, accent.b * 0.72, 0.82)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.18)
	style.shadow_size = 11
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.04, 0.06, 0.09, 0.84)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(accent.r, accent.g, accent.b, 0.48)
	frame_style.corner_radius_top_left = 14
	frame_style.corner_radius_top_right = 14
	frame_style.corner_radius_bottom_right = 14
	frame_style.corner_radius_bottom_left = 14
	frame.add_theme_stylebox_override("panel", frame_style)
	margin.add_child(frame)

	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 6)
	frame_margin.add_theme_constant_override("margin_top", 5)
	frame_margin.add_theme_constant_override("margin_right", 6)
	frame_margin.add_theme_constant_override("margin_bottom", 5)
	frame.add_child(frame_margin)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 5)
	frame_margin.add_child(stack)

	var icon_holder := CenterContainer.new()
	icon_holder.custom_minimum_size = Vector2(0.0, 54.0)
	stack.add_child(icon_holder)

	var icon := ABILITY_ICON_SCRIPT.new()
	icon.set_ability(ability_id)
	icon.set_tint(accent)
	icon.custom_minimum_size = Vector2(108.0, 64.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_holder.add_child(icon)

	var title := Label.new()
	title.text = display_name
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.94, 0.97, 1.0)
	stack.add_child(title)

	var bind_pill := PanelContainer.new()
	var bind_style := StyleBoxFlat.new()
	bind_style.bg_color = Color(0.13, 0.15, 0.19, 0.96)
	bind_style.border_width_left = 2
	bind_style.border_width_top = 2
	bind_style.border_width_right = 2
	bind_style.border_width_bottom = 2
	bind_style.border_color = Color(accent.r, accent.g, accent.b, 0.42)
	bind_style.corner_radius_top_left = 11
	bind_style.corner_radius_top_right = 11
	bind_style.corner_radius_bottom_right = 11
	bind_style.corner_radius_bottom_left = 11
	bind_pill.add_theme_stylebox_override("panel", bind_style)
	bind_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(bind_pill)

	var bind_margin := MarginContainer.new()
	bind_margin.add_theme_constant_override("margin_left", 12)
	bind_margin.add_theme_constant_override("margin_top", 3)
	bind_margin.add_theme_constant_override("margin_right", 12)
	bind_margin.add_theme_constant_override("margin_bottom", 3)
	bind_pill.add_child(bind_margin)

	var bind := Label.new()
	bind.text = bind_text
	bind.add_theme_font_size_override("font_size", 14)
	bind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bind.modulate = accent
	bind_margin.add_child(bind)

	var status := Label.new()
	status.text = ""
	status.visible = false
	status.add_theme_font_size_override("font_size", 1)
	stack.add_child(status)

	ability_cards[ability_id] = {
		"panel": panel,
		"style": style,
		"frame_style": frame_style,
		"icon": icon,
		"title": title,
		"bind_panel": bind_pill,
		"bind_style": bind_style,
		"bind": bind,
		"status": status,
		"accent": accent
	}

	return panel


func _ensure_fighter_economy(fighter: Node) -> void:
	if fighter == null:
		return
	if fighter_economy.has(fighter):
		return

	fighter_economy[fighter] = {
		"os": starting_os,
		"passive_progress": 0.0
	}


func _update_fighter_economy(delta: float) -> void:
	if passive_os_interval <= 0.0:
		return

	for fighter in fighter_economy.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if not _is_fighter_alive(fighter):
			continue

		var economy: Dictionary = fighter_economy.get(fighter, {})
		var passive_progress: float = float(economy.get("passive_progress", 0.0)) + delta

		while passive_progress >= passive_os_interval:
			passive_progress -= passive_os_interval
			economy["os"] = int(economy.get("os", 0)) + passive_os_amount

		economy["passive_progress"] = passive_progress
		fighter_economy[fighter] = economy


func _award_os(fighter: Node, amount: int) -> void:
	if fighter == null or amount <= 0:
		return

	_ensure_fighter_economy(fighter)
	var economy: Dictionary = fighter_economy.get(fighter, {})
	economy["os"] = int(economy.get("os", 0)) + amount
	fighter_economy[fighter] = economy


func _spend_os(fighter: Node, amount: int) -> bool:
	if fighter == null or amount < 0:
		return false

	_ensure_fighter_economy(fighter)
	var economy: Dictionary = fighter_economy.get(fighter, {})
	var current_os: int = int(economy.get("os", 0))
	if current_os < amount:
		return false

	economy["os"] = current_os - amount
	fighter_economy[fighter] = economy
	return true


func _get_fighter_os(fighter: Node) -> int:
	if fighter == null:
		return 0

	_ensure_fighter_economy(fighter)
	var economy: Dictionary = fighter_economy.get(fighter, {})
	return int(economy.get("os", 0))


func _get_fighter_next_income_seconds(fighter: Node) -> float:
	if fighter == null:
		return passive_os_interval

	_ensure_fighter_economy(fighter)
	var economy: Dictionary = fighter_economy.get(fighter, {})
	var passive_progress: float = float(economy.get("passive_progress", 0.0))
	return maxf(0.0, passive_os_interval - passive_progress)


func _award_round_end_os() -> void:
	if round_end_os_stipend <= 0:
		return

	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		_award_os(fighter, round_end_os_stipend)


func _award_round_winner_bonus(winner: Node) -> void:
	if winner == null or not is_instance_valid(winner):
		return
	if round_winner_bonus_os <= 0:
		return

	_award_os(winner, round_winner_bonus_os)


func _get_upgrade_cost(tier: int) -> int:
	match tier:
		1:
			return tier_1_upgrade_cost
		2:
			return tier_2_upgrade_cost
		3:
			return tier_3_upgrade_cost
		_:
			return tier_3_upgrade_cost


func _reset_fighter_economy(fighter: Node) -> void:
	if fighter == null:
		return

	fighter_economy[fighter] = {
		"os": starting_os,
		"passive_progress": 0.0
	}


func _is_bot_fighter(fighter: Node) -> bool:
	if fighter == null or not is_instance_valid(fighter):
		return false
	if fighter.has_method("is_bot_controlled"):
		return fighter.is_bot_controlled()
	return false


func _ensure_bot_upgrade_state(fighter: Node) -> void:
	if not _is_bot_fighter(fighter):
		bot_upgrade_states.erase(fighter)
		return
	if bot_upgrade_states.has(fighter):
		return

	_reset_bot_upgrade_state(fighter)


func _reset_bot_upgrade_state(fighter: Node) -> void:
	if not _is_bot_fighter(fighter):
		bot_upgrade_states.erase(fighter)
		return

	var plan: Dictionary = _roll_bot_build_plan()
	var steps: Array = []
	var steps_value = plan.get("steps", [])
	if typeof(steps_value) == TYPE_ARRAY:
		steps = (steps_value as Array).duplicate(true)

	bot_upgrade_states[fighter] = {
		"plan_id": str(plan.get("id", "bot")),
		"plan_label_ru": str(plan.get("label_ru", "Бот")),
		"steps": steps,
		"next_step_index": 0,
		"decision_cooldown": _roll_bot_upgrade_delay()
	}


func _roll_bot_build_plan() -> Dictionary:
	if BOT_BUILD_PLANS.is_empty():
		return {}

	var index: int = bot_rng.randi_range(0, BOT_BUILD_PLANS.size() - 1)
	return (BOT_BUILD_PLANS[index] as Dictionary).duplicate(true)


func _roll_bot_upgrade_delay() -> float:
	var min_delay: float = maxf(0.05, bot_upgrade_think_interval_min)
	var max_delay: float = maxf(min_delay, bot_upgrade_think_interval_max)
	return bot_rng.randf_range(min_delay, max_delay)


func _update_bot_upgrade_ai(delta: float) -> void:
	if not bot_auto_upgrades_enabled:
		return

	for fighter in fighter_stats.keys():
		if not _is_bot_fighter(fighter):
			continue
		if fighter == null or not is_instance_valid(fighter):
			continue
		if not _is_fighter_alive(fighter):
			continue

		_ensure_bot_upgrade_state(fighter)
		var state: Dictionary = bot_upgrade_states.get(fighter, {})
		if state.is_empty():
			continue

		var cooldown_left: float = maxf(0.0, float(state.get("decision_cooldown", 0.0)) - delta)
		state["decision_cooldown"] = cooldown_left
		bot_upgrade_states[fighter] = state

		if cooldown_left > 0.0:
			continue

		var purchased: bool = _try_bot_purchase_upgrade(fighter)
		state = bot_upgrade_states.get(fighter, {})
		state["decision_cooldown"] = _roll_bot_upgrade_delay() if purchased else 0.35
		bot_upgrade_states[fighter] = state


func _try_bot_purchase_upgrade(fighter: Node) -> bool:
	if fighter == null or not is_instance_valid(fighter):
		return false
	if not fighter.has_method("get_available_upgrade_choices") or not fighter.has_method("grant_upgrade"):
		return false

	var current_os: int = _get_fighter_os(fighter)
	var available_choices_by_id: Dictionary = {}

	for choice_value in fighter.get_available_upgrade_choices():
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue

		var choice: Dictionary = (choice_value as Dictionary).duplicate(true)
		var upgrade_id := str(choice.get("upgrade_id", ""))
		if upgrade_id == "":
			continue

		choice["cost"] = _get_upgrade_cost(int(choice.get("tier", 0)))
		available_choices_by_id[upgrade_id] = choice

	if available_choices_by_id.is_empty():
		return false

	var state: Dictionary = bot_upgrade_states.get(fighter, {})
	var steps_value = state.get("steps", [])
	var steps: Array = steps_value if typeof(steps_value) == TYPE_ARRAY else []
	var step_index: int = clampi(int(state.get("next_step_index", 0)), 0, steps.size())

	for index in range(step_index, steps.size()):
		var upgrade_id := str(steps[index])
		if not available_choices_by_id.has(upgrade_id):
			continue

		var planned_choice: Dictionary = available_choices_by_id.get(upgrade_id, {})
		var planned_cost: int = int(planned_choice.get("cost", 0))
		state["next_step_index"] = index
		bot_upgrade_states[fighter] = state

		if current_os < planned_cost:
			return false

		if not _spend_os(fighter, planned_cost):
			return false

		if not fighter.grant_upgrade(upgrade_id):
			_award_os(fighter, planned_cost)
			return false

		if fighter.has_method("play_upgrade_animation"):
			fighter.play_upgrade_animation()
		_play_upgrade_stage_avatar_animation(fighter)
		state["next_step_index"] = index + 1
		bot_upgrade_states[fighter] = state
		return true

	var fallback_choices: Array = []
	for choice_value in available_choices_by_id.values():
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var fallback_choice: Dictionary = choice_value
		if current_os < int(fallback_choice.get("cost", 0)):
			continue
		fallback_choices.append(fallback_choice)

	if fallback_choices.is_empty():
		return false

	fallback_choices.sort_custom(func(a, b):
		var a_choice: Dictionary = a
		var b_choice: Dictionary = b
		if int(a_choice.get("tier", 0)) == int(b_choice.get("tier", 0)):
			return str(a_choice.get("upgrade_id", "")) < str(b_choice.get("upgrade_id", ""))
		return int(a_choice.get("tier", 0)) < int(b_choice.get("tier", 0))
	)

	var choice: Dictionary = fallback_choices[0]
	var cost: int = int(choice.get("cost", 0))
	var upgrade_id := str(choice.get("upgrade_id", ""))
	if upgrade_id == "":
		return false
	if not _spend_os(fighter, cost):
		return false
	if not fighter.grant_upgrade(upgrade_id):
		_award_os(fighter, cost)
		return false

	if fighter.has_method("play_upgrade_animation"):
		fighter.play_upgrade_animation()
	return true


func _refresh_hud() -> void:
	if (
		hud_remaining_value == null
		or hud_round_value == null
		or hud_os_value == null
		or hud_kills_value == null
		or hud_time_value == null
	):
		return

	hud_remaining_value.text = str(_active_fighter_count())
	hud_round_value.text = _get_round_label()
	hud_os_value.text = str(_get_fighter_os(local_player))
	hud_kills_value.text = str(_player_kills())
	hud_time_value.text = _format_time(round_time)
	_refresh_instability_hud()

	if hud_hint_label != null:
		if match_finished:
			hud_hint_label.text = "Tab - таблица | Матч завершён"
		elif round_active:
			var hint_parts := [
				"Tab - таблица",
				"+%d ОС через %ds" % [passive_os_amount, int(ceil(_get_fighter_next_income_seconds(local_player)))]
			]
			var final_save_hint := _get_final_save_hint_text()
			if final_save_hint != "":
				hint_parts.append(final_save_hint)
			hud_hint_label.text = " | ".join(hint_parts)
		elif upgrade_phase_active:
			var hint_parts := [
				"Tab - таблица",
				"Фаза прокачки: %ds" % int(ceil(upgrade_phase_time_left)),
				"U - улучшения"
			]
			var between_round_final_save := _get_final_save_hint_text()
			if between_round_final_save != "":
				hint_parts.append(between_round_final_save)
			hud_hint_label.text = " | ".join(hint_parts)
		else:
			var between_round_hint := "Tab - таблица | Между раундами"
			var between_round_final_save := _get_final_save_hint_text()
			if between_round_final_save != "":
				between_round_hint += " | %s" % between_round_final_save
			hud_hint_label.text = between_round_hint


func _refresh_instability_hud() -> void:
	if (
		instability_panel == null
		or instability_decay_value == null
		or instability_bar_fill == null
	):
		return

	if local_player == null or not is_instance_valid(local_player) or not local_player.has_method("get_instability_status"):
		instability_panel.visible = false
		return

	instability_panel.visible = true
	var status: Dictionary = local_player.get_instability_status()
	var bonus_ratio: float = clampf(float(status.get("bonus_ratio", 0.0)), 0.0, 1.0)
	var bonus_percent: int = int(status.get("bonus_percent", 0))
	var decay_seconds_left: float = maxf(0.0, float(status.get("decay_seconds_left", 0.0)))
	var display_color := _get_instability_display_color(bonus_ratio)

	instability_decay_value.text = "%.1fс" % decay_seconds_left
	instability_decay_value.modulate = display_color if bonus_percent > 0 else Color(0.72, 0.78, 0.86)

	var bonus_height: float = instability_bar_fill.get_parent().size.y * bonus_ratio
	instability_bar_fill.offset_top = -bonus_height
	instability_bar_fill.offset_bottom = 0.0
	instability_bar_fill.color = Color(display_color.r, display_color.g, display_color.b, 0.96)


func _get_instability_display_color(ratio: float) -> Color:
	var safe_color := Color(0.18, 0.92, 0.34, 0.98)
	var warning_color := Color(1.0, 0.82, 0.16, 0.98)
	var danger_color := Color(1.0, 0.20, 0.18, 0.98)
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	if clamped_ratio <= 0.5:
		return safe_color.lerp(warning_color, clamped_ratio / 0.5)
	return warning_color.lerp(danger_color, (clamped_ratio - 0.5) / 0.5)


func _refresh_ability_hud() -> void:
	if local_player == null or not is_instance_valid(local_player):
		_cache_local_player()
	var expected_layout_count: int = 0
	if local_player != null and is_instance_valid(local_player) and local_player.has_method("get_ability_layout"):
		expected_layout_count = (local_player.get_ability_layout() as Array).size()
	if ability_cards.is_empty() or ability_cards.size() != expected_layout_count:
		_rebuild_ability_hud()
		if ability_cards.is_empty():
			return

	var states: Dictionary = {}
	if local_player != null and is_instance_valid(local_player) and local_player.has_method("get_ability_states"):
		states = local_player.get_ability_states()

	for ability_id in ability_cards.keys():
		var card: Dictionary = ability_cards[ability_id]
		var icon := card.get("icon") as AbilityIcon
		var title := card["title"] as Label
		var bind := card["bind"] as Label
		var state: Dictionary = states.get(ability_id, {})

		if icon != null:
			icon.set_ability(str(state.get("id", ability_id)))
		if title != null:
			title.text = str(state.get("name", title.text))
		if bind != null:
			var raw_status := str(state.get("status", ""))
			var emphasis := str(state.get("emphasis", "disabled"))
			if raw_status.ends_with("s"):
				bind.text = raw_status.substr(0, raw_status.length() - 1)
			elif emphasis == "cooldown":
				bind.text = raw_status
			elif emphasis == "disabled":
				bind.text = "OUT"
			else:
				bind.text = str(state.get("bind", bind.text))

		_apply_ability_card_visual(card, str(state.get("emphasis", "disabled")))


func _apply_ability_card_visual(card: Dictionary, emphasis: String) -> void:
	var style := card["style"] as StyleBoxFlat
	var frame_style := card.get("frame_style") as StyleBoxFlat
	var icon := card.get("icon") as AbilityIcon
	var title := card["title"] as Label
	var bind_style := card.get("bind_style") as StyleBoxFlat
	var bind := card["bind"] as Label
	var status := card["status"] as Label
	var accent = card["accent"]

	if style == null or title == null or bind == null or status == null:
		return

	if emphasis == "ready":
		style.bg_color = Color(0.07, 0.09, 0.12, 0.96)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		if frame_style != null:
			frame_style.border_color = Color(accent.r, accent.g, accent.b, 0.40)
			frame_style.bg_color = Color(0.05, 0.07, 0.10, 0.76)
		if bind_style != null:
			bind_style.border_color = Color(accent.r, accent.g, accent.b, 0.38)
			bind_style.bg_color = Color(0.14, 0.16, 0.20, 0.92)
		title.modulate = Color(0.96, 0.98, 1.0)
		bind.modulate = accent
		status.modulate = accent.lerp(Color(0.96, 0.98, 1.0), 0.32)
		if icon != null:
			icon.set_tint(accent.lerp(Color(1.0, 0.98, 0.94), 0.18))
	elif emphasis == "active":
		style.bg_color = accent.lerp(Color(0.05, 0.06, 0.09, 0.98), 0.72)
		style.border_color = accent
		if frame_style != null:
			frame_style.border_color = accent
			frame_style.bg_color = Color(0.05, 0.07, 0.10, 0.82)
		if bind_style != null:
			bind_style.border_color = accent
			bind_style.bg_color = Color(0.18, 0.20, 0.24, 0.96)
		title.modulate = Color(0.98, 0.99, 1.0)
		bind.modulate = Color(0.98, 0.99, 1.0)
		status.modulate = Color(1.0, 1.0, 1.0)
		if icon != null:
			icon.set_tint(Color(0.98, 0.99, 1.0))
	elif emphasis == "cooldown":
		style.bg_color = Color(0.08, 0.10, 0.12, 0.94)
		style.border_color = Color(0.28, 0.33, 0.40, 0.85)
		if frame_style != null:
			frame_style.border_color = Color(accent.r, accent.g, accent.b, 0.24)
			frame_style.bg_color = Color(0.05, 0.07, 0.10, 0.56)
		if bind_style != null:
			bind_style.border_color = Color(0.28, 0.33, 0.40, 0.85)
			bind_style.bg_color = Color(0.12, 0.14, 0.18, 0.96)
		title.modulate = Color(0.78, 0.84, 0.92)
		bind.modulate = Color(0.90, 0.94, 0.98)
		status.modulate = Color(0.90, 0.94, 0.98)
		if icon != null:
			icon.set_tint(accent.lerp(Color(0.70, 0.76, 0.84), 0.45))
	else:
		style.bg_color = Color(0.07, 0.08, 0.10, 0.88)
		style.border_color = Color(0.20, 0.24, 0.29, 0.78)
		if frame_style != null:
			frame_style.border_color = Color(0.20, 0.24, 0.29, 0.56)
			frame_style.bg_color = Color(0.04, 0.05, 0.07, 0.52)
		if bind_style != null:
			bind_style.border_color = Color(0.20, 0.24, 0.29, 0.78)
			bind_style.bg_color = Color(0.10, 0.11, 0.14, 0.90)
		title.modulate = Color(0.58, 0.62, 0.70)
		bind.modulate = Color(0.70, 0.74, 0.80)
		status.modulate = Color(0.70, 0.74, 0.80)
		if icon != null:
			icon.set_tint(Color(0.42, 0.47, 0.54))


func _toggle_upgrade_panel() -> void:
	if upgrade_menu_open:
		_close_upgrade_panel()
	else:
		_open_upgrade_panel()


func _open_upgrade_panel() -> void:
	if not upgrade_phase_active:
		return
	if local_player == null or not is_instance_valid(local_player):
		_cache_local_player()
	if local_player == null or not is_instance_valid(local_player):
		return
	if not local_player.has_method("get_available_upgrade_choices"):
		return

	if draft_mode_enabled:
		_start_draft_upgrade_flow()
	else:
		upgrade_choice_entries = _get_local_upgrade_choices()
	upgrade_menu_open = true
	selected_upgrade_choice_index = 0
	if upgrade_panel != null:
		upgrade_panel.visible = false
	if upgrade_menu_root != null:
		upgrade_menu_root.visible = true
	_rebuild_upgrade_panel()


func _close_upgrade_panel(unlock_fighters: bool = true) -> void:
	upgrade_menu_open = false
	upgrade_choice_entries.clear()
	draft_choices.clear()
	if upgrade_panel != null:
		upgrade_panel.visible = false
	if upgrade_menu_root != null:
		upgrade_menu_root.visible = false

	if unlock_fighters and round_active:
		_set_all_fighters_locked(false)


func _refresh_upgrade_panel() -> void:
	if not upgrade_menu_open:
		return
	if local_player == null or not is_instance_valid(local_player):
		_close_upgrade_panel(false)
		return
	if not local_player.has_method("get_available_upgrade_choices"):
		_close_upgrade_panel(false)
		return

	if draft_mode_enabled:
		if draft_choices.is_empty() and _has_affordable_draft_options(local_player):
			_start_draft_upgrade_flow()
			_rebuild_upgrade_panel()
		return

	var refreshed_choices: Array = _get_local_upgrade_choices()
	if refreshed_choices != upgrade_choice_entries:
		upgrade_choice_entries = refreshed_choices
		_rebuild_upgrade_panel()


func _rebuild_upgrade_panel() -> void:
	if upgrade_options == null:
		return

	for child in upgrade_options.get_children():
		child.queue_free()
	if upgrade_skills_list != null:
		for child in upgrade_skills_list.get_children():
			child.queue_free()

	if upgrade_title != null:
		upgrade_title.text = "Прокачка между раундами" if upgrade_phase_active else "Выбор улучшения"

	if upgrade_subtitle != null:
		if draft_mode_enabled and draft_choices.is_empty():
			upgrade_subtitle.text = "Сейчас нет доступных улучшений"
		elif upgrade_choice_entries.is_empty() and not draft_mode_enabled:
			upgrade_subtitle.text = "Сейчас нет доступных улучшений"
		else:
			upgrade_subtitle.text = "ОС: %d  |  Осталось: %ds  |  Q/E - выбор  |  1-3 / Enter - купить" % [
				_get_fighter_os(local_player),
				int(ceil(upgrade_phase_time_left))
			]

	if draft_mode_enabled:
		_rebuild_draft_upgrade_panel()
		return

	if upgrade_choice_entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Доступных апгрейдов пока нет."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.modulate = Color(0.76, 0.82, 0.90)
		upgrade_options.add_child(empty_label)
		_refresh_upgrade_details({})
		_refresh_upgrade_skills_summary([])
		_refresh_upgrade_build_summary()
		return

	filtered_upgrade_choice_entries = _get_filtered_upgrade_choices_for_selected_skill(upgrade_choice_entries)
	if filtered_upgrade_choice_entries.is_empty():
		filtered_upgrade_choice_entries = upgrade_choice_entries.duplicate(true)

	selected_upgrade_choice_index = clampi(selected_upgrade_choice_index, 0, mini(8, filtered_upgrade_choice_entries.size()) - 1)
	var shown_count := mini(9, filtered_upgrade_choice_entries.size())
	for index in range(shown_count):
		var choice: Dictionary = filtered_upgrade_choice_entries[index]
		upgrade_options.add_child(_make_upgrade_option_card(index, choice))
	_refresh_upgrade_skills_summary(upgrade_choice_entries.slice(0, shown_count))
	_refresh_upgrade_details(filtered_upgrade_choice_entries[selected_upgrade_choice_index] if shown_count > 0 else {})
	_refresh_upgrade_build_summary()


func _rebuild_draft_upgrade_panel() -> void:
	if draft_choices.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Доступных улучшений пока нет."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.modulate = Color(0.76, 0.82, 0.90)
		upgrade_options.add_child(empty_label)
		_refresh_upgrade_details({})
		_refresh_upgrade_build_summary()
		return

	selected_upgrade_choice_index = clampi(selected_upgrade_choice_index, 0, draft_choices.size() - 1)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	upgrade_options.add_child(row)

	for index in range(draft_choices.size()):
		var choice: Dictionary = draft_choices[index]
		row.add_child(_make_draft_choice_card(index, choice, index == selected_upgrade_choice_index))

	_refresh_upgrade_details({})
	_refresh_upgrade_build_summary()


func _make_draft_choice_card(index: int, choice: Dictionary, is_selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(332.0, 280.0)
	panel.scale = Vector2(1.03, 1.03) if is_selected else Vector2.ONE

	var affordable: bool = bool(choice.get("affordable", false))
	var accent: Color = _get_draft_card_accent(choice, affordable, is_selected)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.13, 0.17, 0.98) if is_selected else Color(0.07, 0.09, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_size = 18 if is_selected else 8
	style.shadow_offset = Vector2.ZERO if is_selected else Vector2(0, 2)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.28) if is_selected else Color(0.0, 0.0, 0.0, 0.18)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "[ %d ]  %s" % [index + 1, _get_draft_tag_text(choice)]
	title.add_theme_font_size_override("font_size", 15)
	title.modulate = Color(0.86, 0.91, 0.96)
	stack.add_child(title)

	var upgrade_title := Label.new()
	upgrade_title.text = str(choice.get("name_ru", choice.get("name", "Улучшение")))
	upgrade_title.add_theme_font_size_override("font_size", 34)
	upgrade_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_title.modulate = Color(0.98, 1.0, 1.0)
	stack.add_child(upgrade_title)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 8)
	stack.add_child(meta_row)

	var branch_dot := ColorRect.new()
	branch_dot.color = _get_branch_marker_color(choice)
	branch_dot.custom_minimum_size = Vector2(10.0, 10.0)
	meta_row.add_child(branch_dot)

	var meta := Label.new()
	meta.text = "%s  •  L%d" % [str(choice.get("branch_name_ru", "Ветка")), int(choice.get("tier", 0))]
	meta.add_theme_font_size_override("font_size", 14)
	meta.modulate = Color(0.70, 0.77, 0.86)
	meta_row.add_child(meta)

	var cost := Label.new()
	cost.text = "Цена: %d ОС" % int(choice.get("cost", 0))
	cost.add_theme_font_size_override("font_size", 18)
	cost.modulate = Color(0.40, 0.95, 0.65) if affordable else Color(1.0, 0.55, 0.50)
	stack.add_child(cost)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 2.0)
	stack.add_child(spacer)

	var summary := Label.new()
	summary.text = _make_draft_short_summary(choice)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 17)
	summary.modulate = Color(0.72, 0.78, 0.86)
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(summary)

	return panel


func _make_upgrade_option_card(index: int, choice: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 92.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.12, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.33, 0.40, 0.85)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "%d. %s: %s" % [
		index + 1,
		str(choice.get("ability_name_ru", choice.get("ability_name", "Ability"))),
		str(choice.get("name_ru", choice.get("name", "Upgrade")))
	]
	title.add_theme_font_size_override("font_size", 19)
	title.modulate = Color(0.96, 0.98, 1.0)
	stack.add_child(title)

	var branch := Label.new()
	branch.text = "Уровень %d • %s" % [
		int(choice.get("tier", 0)),
		str(choice.get("branch_name_ru", "Ветка"))
	]
	branch.add_theme_font_size_override("font_size", 14)
	branch.modulate = Color(0.78, 0.84, 0.92)
	stack.add_child(branch)

	var cost := Label.new()
	var upgrade_cost: int = int(choice.get("cost", 0))
	var affordable: bool = bool(choice.get("affordable", false))
	cost.text = "Цена: %d ОС" % upgrade_cost
	cost.add_theme_font_size_override("font_size", 14)
	cost.modulate = Color(0.40, 0.95, 0.65) if affordable else Color(1.0, 0.55, 0.50)
	stack.add_child(cost)

	var summary := Label.new()
	summary.text = str(choice.get("summary_ru", ""))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 14)
	summary.modulate = Color(0.70, 0.76, 0.84) if affordable else Color(0.56, 0.60, 0.66)
	stack.add_child(summary)

	if not affordable:
		style.bg_color = Color(0.07, 0.08, 0.10, 0.88)
		style.border_color = Color(0.35, 0.20, 0.20, 0.72)
		title.modulate = Color(0.74, 0.78, 0.84)
		branch.modulate = Color(0.60, 0.64, 0.70)

	return panel


func _keycode_to_choice_index(keycode: int) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode - KEY_1)
	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return int(keycode - KEY_KP_1)
	return -1


func _select_upgrade_choice(choice_index: int) -> void:
	if local_player == null or not is_instance_valid(local_player):
		return
	if not local_player.has_method("grant_upgrade"):
		return
	var source_choices: Array = draft_choices if draft_mode_enabled else filtered_upgrade_choice_entries
	if choice_index < 0 or choice_index >= source_choices.size():
		return

	var choice: Dictionary = source_choices[choice_index]
	selected_upgrade_choice_index = choice_index
	var upgrade_id := str(choice.get("upgrade_id", ""))
	var upgrade_cost: int = int(choice.get("cost", 0))
	if upgrade_id == "":
		return
	if not bool(choice.get("affordable", false)):
		if upgrade_subtitle != null:
			upgrade_subtitle.text = "Недостаточно ОС: нужно %d, у тебя %d" % [upgrade_cost, _get_fighter_os(local_player)]
		return

	if not _spend_os(local_player, upgrade_cost):
		if upgrade_subtitle != null:
			upgrade_subtitle.text = "Недостаточно ОС: нужно %d, у тебя %d" % [upgrade_cost, _get_fighter_os(local_player)]
		return

	var applied: bool = local_player.grant_upgrade(upgrade_id)
	if not applied:
		_award_os(local_player, upgrade_cost)
		return

	if local_player.has_method("play_upgrade_animation"):
		local_player.play_upgrade_animation()
	_play_upgrade_stage_avatar_animation(local_player)
	_refresh_ability_hud()
	if draft_mode_enabled and upgrade_phase_active:
		if upgrade_id != "":
			draft_history_recent.append(upgrade_id)
			while draft_history_recent.size() > 8:
				draft_history_recent.remove_at(0)
		_advance_draft_after_purchase()
	elif upgrade_phase_active:
		upgrade_choice_entries = _get_local_upgrade_choices()
		_rebuild_upgrade_panel()
	else:
		_close_upgrade_panel()


func _refresh_upgrade_skills_summary(choice_list: Array) -> void:
	if upgrade_skills_list == null:
		return

	var skills_map: Dictionary = {}
	for choice_value in choice_list:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		var skill_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "Способность")))
		if not skills_map.has(skill_name):
			skills_map[skill_name] = {
				"count": 0,
				"available": false
			}
		var entry: Dictionary = skills_map[skill_name]
		entry["count"] = int(entry.get("count", 0)) + 1
		entry["available"] = bool(entry.get("available", false)) or bool(choice.get("affordable", false))
		skills_map[skill_name] = entry

	for skill_name in skills_map.keys():
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		var is_selected: bool = skill_name == selected_upgrade_skill_name
		style.bg_color = Color(0.10, 0.13, 0.18, 0.98) if is_selected else Color(0.08, 0.10, 0.12, 0.94)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.52, 0.72, 0.96, 0.88) if is_selected else Color(0.25, 0.31, 0.38, 0.72)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		row.add_theme_stylebox_override("panel", style)
		upgrade_skills_list.add_child(row)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		row.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		margin.add_child(hbox)

		var name_label := Label.new()
		name_label.text = skill_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.modulate = Color(0.98, 1.0, 1.0) if is_selected else Color(0.94, 0.97, 1.0)
		hbox.add_child(name_label)

		var count_label := Label.new()
		var entry: Dictionary = skills_map[skill_name]
		var available: bool = bool(entry.get("available", false))
		count_label.text = "%d" % int(entry.get("count", 0))
		count_label.add_theme_font_size_override("font_size", 15)
		count_label.modulate = Color(0.40, 0.95, 0.65) if available else Color(0.72, 0.76, 0.82)
		hbox.add_child(count_label)


func _refresh_upgrade_details(choice: Dictionary) -> void:
	if upgrade_details_name_label == null:
		return
	upgrade_details_name_label.text = ""
	upgrade_details_meta_label.text = ""
	upgrade_details_cost_label.text = ""
	upgrade_details_role_label.text = ""
	upgrade_details_requirement_label.text = ""
	if upgrade_tree_header != null:
		upgrade_tree_header.text = ""


func _refresh_upgrade_build_summary() -> void:
	if upgrade_build_summary_label == null:
		return
	upgrade_build_summary_label.text = ""


func _make_draft_short_summary(choice: Dictionary) -> String:
	var ability_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "")))
	var branch_name: String = str(choice.get("branch_name_ru", ""))
	var tier: int = int(choice.get("tier", 0))

	match ability_name:
		"Огненный шар":
			match branch_name:
				"Базовое усиление":
					return "Шар быстрее и чаще."
				"Точность":
					return "Летит дальше и попадает легче."
				"Сила":
					return "Сильнее выбивает с позиции."
		"Проломная мина":
			match branch_name:
				"Базовое усиление":
					return "Ставится быстрее и ловит шире."
				"Контроль":
					return "Жёстче наказывает за вход в зону."
				"Пролом":
					return "Сильнее ломает маршрут соперника."
		"Таранный рывок":
			match branch_name:
				"Базовое усиление":
					return "Рывок чаще и дальше."
				"Мобильность":
					return "Быстрее меняет позицию."
				"Таран":
					return "Сильнее врезается в цель."

	var summary: String = str(choice.get("summary_ru", "")).strip_edges()
	if summary == "":
		return "Улучшает ключевой эффект способности."
	if summary.length() > 56:
		summary = summary.substr(0, 53).strip_edges() + "..."
	return summary


func _get_draft_tag_text(choice: Dictionary) -> String:
	var ability_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "Способность")))
	match ability_name:
		"Огненный шар":
			return "FIREBALL"
		"Проломная мина":
			return "MINE"
		"Таранный рывок":
			return "DASH"
		_:
			return ability_name.to_upper()


func _get_draft_card_accent(choice: Dictionary, affordable: bool, is_selected: bool) -> Color:
	if is_selected:
		return Color(0.58, 0.78, 1.0, 0.92)
	if not affordable:
		return Color(0.52, 0.28, 0.28, 0.76)

	var ability_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "")))
	match ability_name:
		"Огненный шар":
			return Color(0.95, 0.55, 0.25, 0.82)
		"Проломная мина":
			return Color(0.96, 0.34, 0.34, 0.82)
		"Таранный рывок":
			return Color(0.67, 0.42, 1.0, 0.82)
		_:
			return Color(0.40, 0.95, 0.65, 0.70)


func _get_branch_marker_color(choice: Dictionary) -> Color:
	var branch_name: String = str(choice.get("branch_name_ru", ""))
	match branch_name:
		"Базовое усиление":
			return Color(0.45, 0.88, 0.70, 0.95)
		"Точность":
			return Color(0.42, 0.76, 1.0, 0.95)
		"Сила":
			return Color(1.0, 0.62, 0.30, 0.95)
		"Контроль":
			return Color(1.0, 0.42, 0.42, 0.95)
		"Пролом":
			return Color(0.96, 0.52, 0.36, 0.95)
		"Мобильность":
			return Color(0.68, 0.50, 1.0, 0.95)
		"Таран":
			return Color(0.88, 0.38, 0.90, 0.95)
		_:
			return Color(0.68, 0.74, 0.84, 0.95)


func _get_filtered_upgrade_choices_for_selected_skill(choice_list: Array) -> Array:
	var skill_names: Array[String] = []
	for choice_value in choice_list:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		var skill_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "Способность")))
		if not skill_names.has(skill_name):
			skill_names.append(skill_name)

	if skill_names.is_empty():
		selected_upgrade_skill_name = ""
		return []

	if selected_upgrade_skill_name == "" or not skill_names.has(selected_upgrade_skill_name):
		selected_upgrade_skill_name = skill_names[0]

	var result: Array = []
	for choice_value in choice_list:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		var skill_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "Способность")))
		if skill_name != selected_upgrade_skill_name:
			continue
		result.append(choice)

	return result


func _cycle_upgrade_skill_selection(direction: int) -> void:
	if upgrade_choice_entries.is_empty():
		return

	var skill_names: Array[String] = []
	for choice_value in upgrade_choice_entries:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		var skill_name: String = str(choice.get("ability_name_ru", choice.get("ability_name", "Способность")))
		if not skill_names.has(skill_name):
			skill_names.append(skill_name)

	if skill_names.is_empty():
		return

	var current_index: int = skill_names.find(selected_upgrade_skill_name)
	if current_index < 0:
		current_index = 0

	current_index = posmod(current_index + direction, skill_names.size())
	selected_upgrade_skill_name = skill_names[current_index]
	selected_upgrade_choice_index = 0
	_rebuild_upgrade_panel()


func _get_local_upgrade_choices() -> Array:
	var choices: Array = []
	if local_player == null or not is_instance_valid(local_player):
		return choices
	if not local_player.has_method("get_available_upgrade_choices"):
		return choices

	var current_os: int = _get_fighter_os(local_player)
	for choice_value in local_player.get_available_upgrade_choices():
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue

		var choice: Dictionary = choice_value.duplicate(true)
		var tier: int = int(choice.get("tier", 0))
		var cost: int = _get_upgrade_cost(tier)
		choice["cost"] = cost
		choice["affordable"] = current_os >= cost
		choices.append(choice)

	return choices


func _start_draft_upgrade_flow() -> void:
	upgrade_choice_entries = _get_local_upgrade_choices()
	draft_choices = _roll_draft_choices_for_fighter(local_player)
	selected_upgrade_choice_index = 0
	draft_roll_iteration += 1


func _has_affordable_draft_options(fighter: Node) -> bool:
	for choice_value in _get_local_upgrade_choices():
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		if bool(choice.get("affordable", false)):
			return true
	return false


func _advance_draft_after_purchase() -> void:
	if not upgrade_phase_active:
		_close_upgrade_panel()
		return

	if not _has_affordable_draft_options(local_player):
		upgrade_choice_entries = _get_local_upgrade_choices()
		draft_choices.clear()
		_rebuild_upgrade_panel()
		return

	_start_draft_upgrade_flow()
	_rebuild_upgrade_panel()


func _roll_draft_choices_for_fighter(fighter: Node) -> Array:
	var all_choices: Array = _get_local_upgrade_choices()
	if all_choices.is_empty():
		return []

	var affordable_choices: Array = []
	for choice_value in all_choices:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = (choice_value as Dictionary).duplicate(true)
		if not bool(choice.get("affordable", false)):
			continue
		choice["weight"] = _score_upgrade_choice(choice, fighter)
		affordable_choices.append(choice)

	if affordable_choices.is_empty():
		return []

	var synergy_pool: Array = []
	var sidegrade_pool: Array = []
	var power_pool: Array = []

	for choice_value in affordable_choices:
		var choice: Dictionary = choice_value
		var bucket: String = _categorize_upgrade_choice(choice, fighter)
		choice["source_bucket"] = bucket
		match bucket:
			"synergy":
				synergy_pool.append(choice)
			"power":
				power_pool.append(choice)
			_:
				sidegrade_pool.append(choice)

	var result: Array = []
	_try_add_weighted_choice(result, synergy_pool)
	_try_add_weighted_choice(result, sidegrade_pool)
	_try_add_weighted_choice(result, power_pool)

	var fallback_pool: Array = affordable_choices.duplicate(true)
	while result.size() < mini(3, affordable_choices.size()):
		if not _try_add_weighted_choice(result, fallback_pool):
			break

	return result


func _categorize_upgrade_choice(choice: Dictionary, fighter: Node) -> String:
	var owned_upgrades: Array = []
	if fighter != null and is_instance_valid(fighter) and fighter.has_method("get_owned_upgrade_ids"):
		var owned_value = fighter.get_owned_upgrade_ids()
		if typeof(owned_value) == TYPE_ARRAY:
			owned_upgrades = owned_value

	var ability_id: String = str(choice.get("ability_id", ""))
	var branch_id: String = str(choice.get("branch_id", ""))
	var tier: int = int(choice.get("tier", 0))

	for owned_value in owned_upgrades:
		var owned_id: String = str(owned_value)
		if owned_id.contains("%s_" % ability_id) and owned_id.contains("_%s" % branch_id):
			return "synergy"

	if tier >= 3:
		return "power"
	if tier == 2:
		return "synergy"
	return "sidegrade"


func _score_upgrade_choice(choice: Dictionary, fighter: Node) -> float:
	var weight: float = 1.0
	var bucket: String = _categorize_upgrade_choice(choice, fighter)
	match bucket:
		"synergy":
			weight = 1.0
		"power":
			weight = 0.72
		_:
			weight = 0.58

	var upgrade_id: String = str(choice.get("upgrade_id", ""))
	if draft_history_recent.has(upgrade_id):
		weight *= 0.35

	var tier: int = int(choice.get("tier", 0))
	if current_round_number >= 4 and tier >= 2:
		weight += 0.10

	return maxf(0.05, weight)


func _try_add_weighted_choice(result: Array, pool: Array) -> bool:
	var picked: Dictionary = _pick_weighted_choice(pool, result)
	if picked.is_empty():
		return false
	result.append(picked)
	return true


func _pick_weighted_choice(pool: Array, exclude_choices: Array) -> Dictionary:
	if pool.is_empty():
		return {}

	var excluded_ids: Array[String] = []
	for choice_value in exclude_choices:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		excluded_ids.append(str((choice_value as Dictionary).get("upgrade_id", "")))

	var total_weight: float = 0.0
	var candidates: Array = []
	for choice_value in pool:
		if typeof(choice_value) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choice_value
		var upgrade_id: String = str(choice.get("upgrade_id", ""))
		if excluded_ids.has(upgrade_id):
			continue
		var weight: float = float(choice.get("weight", 1.0))
		if weight <= 0.0:
			continue
		total_weight += weight
		candidates.append(choice)

	if candidates.is_empty():
		return {}
	if total_weight <= 0.0:
		return candidates[0]

	var roll: float = bot_rng.randf() * total_weight
	for choice_value in candidates:
		var choice: Dictionary = choice_value
		roll -= float(choice.get("weight", 1.0))
		if roll <= 0.0:
			return choice
	return candidates[candidates.size() - 1]


func _cycle_draft_choice_selection(direction: int) -> void:
	if draft_choices.is_empty():
		return
	selected_upgrade_choice_index = posmod(selected_upgrade_choice_index + direction, draft_choices.size())
	_rebuild_upgrade_panel()


func _refresh_scoreboard() -> void:
	if scoreboard_rows == null:
		return

	for child in scoreboard_rows.get_children():
		child.queue_free()

	scoreboard_rows.add_child(_make_score_header())

	for fighter in _sorted_fighters():
		scoreboard_rows.add_child(_make_score_row(fighter))


func _make_score_header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	row.add_child(_make_score_cell("Игрок", 170, true))
	row.add_child(_make_score_cell("W", 50, true))
	row.add_child(_make_score_cell("K", 50, true))
	row.add_child(_make_score_cell("D", 50, true))

	return row


func _make_score_row(fighter: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var stats: Dictionary = fighter_stats.get(fighter, {"kills": 0, "deaths": 0})
	var fighter_label := _fighter_name(fighter)
	if not _is_fighter_alive(fighter):
		fighter_label += " • OUT"
	row.add_child(_make_score_cell(fighter_label, 170, false))
	row.add_child(_make_score_cell(str(_get_fighter_round_wins(fighter)), 50, false))
	row.add_child(_make_score_cell(str(int(stats["kills"])), 50, false))
	row.add_child(_make_score_cell(str(int(stats["deaths"])), 50, false))

	return row


func _make_score_cell(text: String, width: float, is_header: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0.0)
	label.add_theme_font_size_override("font_size", 18 if is_header else 17)
	label.modulate = Color(0.76, 0.82, 0.90) if is_header else Color(0.96, 0.98, 1.0)
	return label


func _sorted_fighters() -> Array:
	var fighters: Array = []
	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		fighters.append(fighter)

	fighters.sort_custom(func(a, b):
		var rounds_a: int = _get_fighter_round_wins(a)
		var rounds_b: int = _get_fighter_round_wins(b)
		if rounds_a != rounds_b:
			return rounds_a > rounds_b

		var stats_a: Dictionary = fighter_stats[a]
		var stats_b: Dictionary = fighter_stats[b]
		if int(stats_a["kills"]) == int(stats_b["kills"]):
			if int(stats_a["deaths"]) == int(stats_b["deaths"]):
				return _fighter_name(a) < _fighter_name(b)
			return int(stats_a["deaths"]) < int(stats_b["deaths"])
		return int(stats_a["kills"]) > int(stats_b["kills"])
	)

	return fighters


func _active_fighter_count() -> int:
	var count := 0
	for fighter in fighter_stats.keys():
		if _is_fighter_alive(fighter):
			count += 1
	return count


func _update_duel_mode(delta: float) -> void:
	var should_be_active: bool = _active_fighter_count() <= 2
	if should_be_active:
		duel_elapsed_time += delta
	else:
		duel_elapsed_time = 0.0

	duel_mode_active = should_be_active


func _player_kills() -> int:
	if local_player == null or not is_instance_valid(local_player):
		return 0

	var local_stats_value = fighter_stats.get(local_player, {})
	if typeof(local_stats_value) != TYPE_DICTIONARY:
		return 0

	var local_stats: Dictionary = local_stats_value
	return int(local_stats.get("kills", 0))


func _fighter_name(fighter: Node) -> String:
	if fighter != null and fighter.has_method("get_fighter_name"):
		return fighter.get_fighter_name()
	if fighter != null:
		return fighter.name
	return "Unknown"


func _get_fighter_round_wins(fighter: Node) -> int:
	if fighter == null or not is_instance_valid(fighter):
		return 0
	return int(fighter_round_wins.get(fighter, 0))


func _get_round_label() -> String:
	if match_finished:
		return "END"
	return "%d/%d" % [current_round_number, match_total_rounds]


func _is_fighter_alive(fighter: Node) -> bool:
	if fighter == null or not is_instance_valid(fighter):
		return false
	if fighter.has_method("is_fighter_alive"):
		return fighter.is_fighter_alive()
	return true


func _finish_round() -> void:
	if not round_active:
		return

	_close_upgrade_panel(false)
	if powerup_manager != null and is_instance_valid(powerup_manager) and powerup_manager.has_method("clear_active_pickup"):
		powerup_manager.clear_active_pickup()
	round_active = false
	_award_round_end_os()
	var winner := _get_last_alive_fighter()
	if winner != null:
		_ensure_fighter_entry(winner)
		fighter_round_wins[winner] = _get_fighter_round_wins(winner) + 1
		_award_round_winner_bonus(winner)

	completed_rounds += 1
	match_finished = completed_rounds >= match_total_rounds
	if not match_finished:
		current_round_number = mini(match_total_rounds, completed_rounds + 1)
	_refresh_final_save_assignment()

	_show_result_panel()
	if match_finished:
		upgrade_phase_active = false
		upgrade_phase_time_left = 0.0
		restart_time_left = round_restart_delay
		_set_all_fighters_locked(true)
		_update_camera_target(true)
	else:
		_begin_upgrade_phase()
	_refresh_hud()
	_refresh_scoreboard()


func _show_result_panel() -> void:
	if result_panel == null:
		return

	if match_finished:
		var match_winner := _get_match_winner()
		if match_winner == null:
			result_title.text = "Матч завершён"
		else:
			result_title.text = "Матч: %s" % _fighter_name(match_winner)
	else:
		var winner := _get_last_alive_fighter()
		if winner == null:
			result_title.text = "Раунд %d: Ничья" % completed_rounds
		else:
			result_title.text = "Раунд %d: %s" % [completed_rounds, _fighter_name(winner)]

	result_panel.visible = true
	_refresh_result_panel()


func _refresh_result_panel() -> void:
	if result_panel == null or result_subtitle == null or not result_panel.visible:
		return

	if match_finished:
		var seconds_left := int(ceil(restart_time_left))
		seconds_left = maxi(0, seconds_left)
		result_subtitle.text = "Новый матч через %d   |   Space / Enter - сразу" % seconds_left
	elif upgrade_phase_active:
		var upgrade_seconds_left := maxi(0, int(ceil(upgrade_phase_time_left)))
		result_subtitle.text = "Прокачка перед раундом %d/%d: %d сек   |   U - панель   |   Space / Enter - начать" % [
			current_round_number,
			match_total_rounds,
			upgrade_seconds_left
		]
		var preview_text := _get_final_save_preview_text()
		if preview_text != "":
			result_subtitle.text += "   |   %s" % preview_text
	else:
		var seconds_left := int(ceil(restart_time_left))
		seconds_left = maxi(0, seconds_left)
		result_subtitle.text = "Раунд %d/%d через %d   |   Space / Enter - сразу" % [
			current_round_number,
			match_total_rounds,
			seconds_left
		]
		var preview_text := _get_final_save_preview_text()
		if preview_text != "":
			result_subtitle.text += "   |   %s" % preview_text


func _restart_round() -> void:
	_close_upgrade_panel(false)
	_clear_dynamic_layer("Projectiles")
	_clear_dynamic_layer("Mines")
	_clear_dynamic_layer("Arena")

	round_time = 0.0
	round_active = true
	upgrade_phase_active = false
	upgrade_phase_time_left = 0.0
	restart_time_left = 0.0
	match_finished = false

	var arena := get_node_or_null("Arena")
	if arena != null and arena.has_method("reset_round_state"):
		arena.reset_round_state(round_time)
	if powerup_manager != null and is_instance_valid(powerup_manager) and powerup_manager.has_method("reset_for_new_match"):
		powerup_manager.reset_for_new_match()

	_assign_edge_spawn_positions(false)

	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if fighter.has_method("reset_for_new_round"):
			fighter.reset_for_new_round()
		if fighter.has_method("set_round_locked"):
			fighter.set_round_locked(false)

	_restore_default_camera_parent()
	_refresh_hud()
	_refresh_scoreboard()

	if result_panel != null:
		result_panel.visible = false


func _restart_match() -> void:
	_close_upgrade_panel(false)
	_clear_dynamic_layer("Projectiles")
	_clear_dynamic_layer("Mines")
	_clear_dynamic_layer("Arena")

	round_time = 0.0
	round_active = true
	upgrade_phase_active = false
	upgrade_phase_time_left = 0.0
	restart_time_left = 0.0
	match_finished = false
	final_save_owner = null
	final_save_consumed = false
	completed_rounds = 0
	current_round_number = 1

	var arena := get_node_or_null("Arena")
	if arena != null and arena.has_method("reset_round_state"):
		arena.reset_round_state(round_time)
	if powerup_manager != null and is_instance_valid(powerup_manager) and powerup_manager.has_method("reset_for_new_match"):
		powerup_manager.reset_for_new_match()

	_assign_edge_spawn_positions(false)

	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		fighter_stats[fighter] = {
			"kills": 0,
			"deaths": 0
		}
		fighter_round_wins[fighter] = 0
		_reset_fighter_economy(fighter)
		_reset_bot_upgrade_state(fighter)
		if fighter.has_method("reset_upgrades"):
			fighter.reset_upgrades(true)
		if fighter.has_method("reset_for_new_round"):
			fighter.reset_for_new_round()
		if fighter.has_method("set_round_locked"):
			fighter.set_round_locked(false)

	_restore_default_camera_parent()
	_refresh_hud()
	_refresh_scoreboard()

	if result_panel != null:
		result_panel.visible = false


func _begin_upgrade_phase() -> void:
	upgrade_phase_active = true
	upgrade_phase_time_left = between_round_upgrade_duration
	restart_time_left = 0.0

	_clear_dynamic_layer("Projectiles")
	_clear_dynamic_layer("Mines")
	_clear_dynamic_layer("Arena")

	var arena := get_node_or_null("Arena")
	var upgrade_focus := Vector2.ZERO
	if arena != null and arena.has_method("get_arena_center"):
		upgrade_focus = arena.get_arena_center()
	if arena != null and arena.has_method("reset_round_state"):
		arena.reset_round_state(0.0)

	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if fighter.has_method("reset_for_new_round"):
			fighter.reset_for_new_round()
		if fighter.has_method("set_round_locked"):
			fighter.set_round_locked(true)

	_restore_default_camera_parent()
	_focus_camera_on_upgrade_stage(upgrade_focus)
	_assign_upgrade_stage_positions()
	_show_upgrade_stage_avatars()
	_open_upgrade_panel()
	_refresh_result_panel()


func _end_upgrade_phase_and_restart_round() -> void:
	if not upgrade_phase_active:
		return

	upgrade_phase_active = false
	upgrade_phase_time_left = 0.0
	_hide_upgrade_stage_avatars()
	_restart_round()


func _assign_upgrade_stage_positions() -> void:
	var fighters := _get_upgrade_stage_fighters()
	if fighters.is_empty():
		return

	var arena := get_node_or_null("Arena")
	var center := Vector2.ZERO
	if arena != null and arena.has_method("get_arena_center"):
		center = arena.get_arena_center()

	var line_x := center.x + _get_upgrade_stage_line_offset_x()
	var top_y := center.y - upgrade_stage_vertical_spacing * 0.5 * float(maxi(0, fighters.size() - 1))
	for index in range(fighters.size()):
		var fighter = fighters[index]
		var stage_position := Vector2(line_x, top_y + upgrade_stage_vertical_spacing * float(index))
		if fighter.has_method("snap_to_position"):
			fighter.snap_to_position(stage_position)
		else:
			fighter.global_position = stage_position


func _get_upgrade_stage_fighters() -> Array:
	var fighters: Array = []
	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if not _is_fighter_alive(fighter):
			continue
		fighters.append(fighter)

	fighters.sort_custom(func(a, b):
		if a == local_player:
			return true
		if b == local_player:
			return false
		return _fighter_name(a) < _fighter_name(b)
	)

	return fighters


func _show_upgrade_stage_avatars() -> void:
	if upgrade_stage_root == null or not is_instance_valid(upgrade_stage_root):
		return

	_clear_upgrade_stage_avatars()

	for fighter in _get_upgrade_stage_fighters():
		if fighter == null or not is_instance_valid(fighter):
			continue

		fighter.visible = false

		var avatar = UPGRADE_STAGE_AVATAR_SCRIPT.new()
		avatar.global_position = fighter.global_position
		if fighter.has_method("get_hit_radius"):
			avatar.body_radius = float(fighter.get_hit_radius())

		var fighter_color = fighter.get("body_color")
		if typeof(fighter_color) == TYPE_COLOR:
			avatar.body_color = fighter_color

		var fighter_aim = fighter.get("aim_direction")
		if typeof(fighter_aim) == TYPE_VECTOR2 and fighter_aim.length_squared() > 0.001:
			avatar.aim_direction = fighter_aim

		avatar.is_local_player = fighter == local_player
		upgrade_stage_root.add_child(avatar)
		upgrade_stage_avatars[fighter] = avatar


func _hide_upgrade_stage_avatars() -> void:
	_clear_upgrade_stage_avatars()
	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		fighter.visible = true


func _clear_upgrade_stage_avatars() -> void:
	for avatar in upgrade_stage_avatars.values():
		if avatar != null and is_instance_valid(avatar):
			avatar.queue_free()
	upgrade_stage_avatars.clear()

	if upgrade_stage_root == null or not is_instance_valid(upgrade_stage_root):
		return

	for child in upgrade_stage_root.get_children():
		child.queue_free()


func _play_upgrade_stage_avatar_animation(fighter: Node) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	if not upgrade_stage_avatars.has(fighter):
		return

	var avatar = upgrade_stage_avatars.get(fighter)
	if avatar == null or not is_instance_valid(avatar):
		return
	if avatar.has_method("play_upgrade_animation"):
		avatar.play_upgrade_animation()


func _get_upgrade_stage_line_offset_x() -> float:
	if upgrade_panel != null:
		var panel_width := upgrade_panel.size.x
		if panel_width <= 0.0:
			panel_width = upgrade_panel.offset_right - upgrade_panel.offset_left
		if panel_width > 0.0:
			return panel_width * 0.5 + upgrade_stage_panel_gap
	return 360.0 + upgrade_stage_panel_gap


func _focus_camera_on_upgrade_stage(focus_position: Vector2) -> void:
	if tracked_camera == null or not is_instance_valid(tracked_camera):
		return

	if tracked_camera.get_parent() != self:
		tracked_camera.reparent(self)
	tracked_camera.global_position = focus_position


func _get_match_winner() -> Node:
	var fighters := _sorted_fighters()
	if fighters.is_empty():
		return null
	return fighters[0]


func _refresh_final_save_assignment() -> void:
	final_save_owner = null
	final_save_consumed = false

	if not final_save_enabled:
		return
	if match_finished:
		return
	if current_round_number != match_total_rounds:
		return
	if completed_rounds < match_total_rounds - 1:
		return

	final_save_owner = _get_unique_round_leader()


func _get_unique_round_leader() -> Node:
	var leader: Node = null
	var leader_wins: int = -1
	var leader_tied := false

	for fighter in fighter_round_wins.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue

		var wins := _get_fighter_round_wins(fighter)
		if wins > leader_wins:
			leader = fighter
			leader_wins = wins
			leader_tied = false
		elif wins == leader_wins:
			leader_tied = true

	if leader == null or leader_tied:
		return null
	return leader


func _get_final_save_hint_text() -> String:
	if not final_save_enabled:
		return ""
	if current_round_number != match_total_rounds or match_finished:
		return ""
	if final_save_owner == null or not is_instance_valid(final_save_owner):
		return "Final Save: нет лидера"
	if final_save_consumed:
		if local_player != null and is_instance_valid(local_player) and final_save_owner == local_player:
			return "Final Save: потрачено"
		return "Final Save: %s потрачено" % _fighter_name(final_save_owner)
	if local_player != null and is_instance_valid(local_player) and final_save_owner == local_player:
		return "Final Save: у тебя 1 спасение"
	return "Final Save: %s" % _fighter_name(final_save_owner)


func _get_final_save_preview_text() -> String:
	if not final_save_enabled:
		return ""
	if current_round_number != match_total_rounds or match_finished:
		return ""
	if final_save_owner == null or not is_instance_valid(final_save_owner):
		return "Final Save не выдан"
	return "Final Save: %s" % _fighter_name(final_save_owner)


func try_consume_final_save_for(fighter: Node) -> bool:
	if fighter == null or not is_instance_valid(fighter):
		return false
	if not final_save_enabled or match_finished or not round_active:
		return false
	if current_round_number != match_total_rounds:
		return false
	if final_save_owner != fighter or final_save_consumed:
		return false
	if not fighter.has_method("trigger_final_save_rescue"):
		return false

	final_save_consumed = true
	fighter.trigger_final_save_rescue()
	_refresh_hud()
	_refresh_ability_hud()
	_refresh_scoreboard()
	return true


func _clear_dynamic_layer(node_name: String) -> void:
	var node := get_node_or_null(node_name)
	if node == null:
		return

	for child in node.get_children():
		child.queue_free()


func _set_all_fighters_locked(locked: bool) -> void:
	for fighter in fighter_stats.keys():
		if fighter == null or not is_instance_valid(fighter):
			continue
		if fighter.has_method("set_round_locked"):
			fighter.set_round_locked(locked)


func _get_last_alive_fighter() -> Node:
	for fighter in fighter_stats.keys():
		if _is_fighter_alive(fighter):
			return fighter
	return null


func _cache_camera() -> void:
	tracked_camera = get_node_or_null("Players/Player/Camera2D")
	if tracked_camera != null:
		default_camera_parent = tracked_camera.get_parent()


func _cache_local_player() -> void:
	local_player = get_node_or_null("Players/Player")
	if ability_row != null:
		_rebuild_ability_hud()


func _rebuild_ability_hud() -> void:
	if ability_row == null:
		return

	for child in ability_row.get_children():
		child.queue_free()
	ability_cards.clear()

	var ability_layout: Array = []
	if local_player != null and is_instance_valid(local_player) and local_player.has_method("get_ability_layout"):
		ability_layout = local_player.get_ability_layout()

	if ability_layout.is_empty():
		return

	var card_count: int = ability_layout.size()
	var card_height := 102.0
	var card_gap := 4.0
	var total_height := card_height * float(card_count) + card_gap * float(maxi(0, card_count - 1))
	ability_panel_height = total_height
	ability_panel.offset_left = -168.0
	ability_panel.offset_top = 184.0
	ability_panel.offset_right = -10.0
	ability_panel.offset_bottom = ability_panel.offset_top + total_height

	_layout_right_combat_hud()

	for entry in ability_layout:
		var ability_id := str(entry.get("id", ""))
		var ability_name := str(entry.get("name", "Ability"))
		var bind_text := str(entry.get("bind", ""))
		var accent := Color(0.90, 0.90, 0.95)
		if entry.has("accent"):
			accent = entry["accent"]
		ability_row.add_child(_make_ability_card(ability_id, ability_name, bind_text, accent))


func _layout_right_combat_hud() -> void:
	if ability_panel == null or instability_panel == null:
		return

	var top_margin := 94.0
	var rail_gap := 8.0
	var instability_height := 80.0
	ability_panel.offset_top = top_margin + instability_height + rail_gap
	ability_panel.offset_bottom = ability_panel.offset_top + ability_panel_height
	instability_panel.offset_left = ability_panel.offset_left
	instability_panel.offset_right = ability_panel.offset_right
	instability_panel.offset_top = top_margin
	instability_panel.offset_bottom = instability_panel.offset_top + instability_height


func _update_camera_target(force_follow_last_alive: bool = false) -> void:
	if tracked_camera == null or not is_instance_valid(tracked_camera):
		return

	var current_parent := tracked_camera.get_parent()
	if not force_follow_last_alive and current_parent != null and _is_fighter_alive(current_parent):
		return

	var fighter := _get_last_alive_fighter()
	if fighter == null:
		return

	if tracked_camera.get_parent() != fighter:
		tracked_camera.reparent(fighter)
		tracked_camera.position = Vector2.ZERO


func _restore_default_camera_parent() -> void:
	if tracked_camera == null or not is_instance_valid(tracked_camera):
		return
	if default_camera_parent == null or not is_instance_valid(default_camera_parent):
		return

	if tracked_camera.get_parent() != default_camera_parent:
		tracked_camera.reparent(default_camera_parent)
		tracked_camera.position = Vector2.ZERO


func _format_time(total_seconds: float) -> String:
	var seconds_total := int(total_seconds)
	var minutes := seconds_total / 60
	var seconds := seconds_total % 60
	return "%02d:%02d" % [minutes, seconds]
