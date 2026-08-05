extends "res://scripts/player.gd"

const BOT_COLORS := [
	Color(0.96, 0.73, 0.28, 1.0),
	Color(0.34, 0.83, 0.88, 1.0),
	Color(0.95, 0.42, 0.69, 1.0),
	Color(0.62, 0.86, 0.33, 1.0)
]


func _ready() -> void:
	control_mode = 2
	use_mouse_aim = false
	use_mouse_fire = false
	move_left_action = ""
	move_right_action = ""
	move_up_action = ""
	move_down_action = ""
	fireball_action = ""
	mine_action = ""
	dash_action = ""
	reflect_shield_action = ""
	if fighter_name == "":
		fighter_name = "Bot %d" % (_get_bot_index() + 1)
	if body_color == Color(0.92, 0.95, 1.0):
		body_color = BOT_COLORS[_get_bot_index() % BOT_COLORS.size()]
	var bot_index: int = _get_bot_index()
	move_speed = 205.0
	dash_speed = 980.0
	bot_action_interval = 1.05
	match bot_index % 4:
		0:
			bot_distance_bias = 0.92
			bot_commit_bias = 1.08
			bot_side_bias = -1.0
			bot_duel_break_interval = 2.4
			bot_preferred_distance = 285.0
			bot_dash_commit_range = 210.0
			bot_fireball_preferred_range = 650.0
			bot_strafe_interval = 1.0
		1:
			bot_distance_bias = 1.08
			bot_commit_bias = 0.94
			bot_side_bias = 1.0
			bot_duel_break_interval = 3.2
			bot_preferred_distance = 325.0
			bot_dash_commit_range = 180.0
			bot_fireball_preferred_range = 720.0
			bot_strafe_interval = 1.28
		2:
			bot_distance_bias = 0.97
			bot_commit_bias = 1.02
			bot_side_bias = -1.0
			bot_duel_break_interval = 2.7
			bot_preferred_distance = 300.0
			bot_dash_commit_range = 200.0
			bot_fireball_preferred_range = 690.0
			bot_strafe_interval = 1.12
		_:
			bot_distance_bias = 1.12
			bot_commit_bias = 0.9
			bot_side_bias = 1.0
			bot_duel_break_interval = 3.5
			bot_preferred_distance = 340.0
			bot_dash_commit_range = 170.0
			bot_fireball_preferred_range = 760.0
			bot_strafe_interval = 1.36
	super()
	bot_strafe_sign = -1.0 if bot_side_bias < 0.0 else 1.0
	bot_action_timer = bot_action_interval * (0.7 + 0.1 * float(bot_index % 3))
	bot_strafe_timer = bot_strafe_interval * (0.55 + 0.12 * float(bot_index % 4))
	bot_duel_break_left = bot_duel_break_interval * (0.55 + 0.1 * float(bot_index % 4))


func _get_bot_index() -> int:
	var parent := get_parent()
	if parent == null:
		return 0

	var index := 0
	for child in parent.get_children():
		if child == self:
			return index
		if child.get_script() == get_script():
			index += 1

	return index
