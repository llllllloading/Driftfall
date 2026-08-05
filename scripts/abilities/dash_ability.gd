extends "res://scripts/abilities/ability_base.gd"

var dash_config: Dictionary = {}

func _on_setup() -> void:
	ability_id = "dash"
	display_name = "Dash"
	bind_text = "R"
	accent_color = Color(0.66, 0.38, 1.0)


func _on_refresh_from_owner() -> void:
	if owner == null or not owner.has_method("get_ability_config"):
		dash_config.clear()
		return

	dash_config = owner.get_ability_config("dash")
	cooldown_duration = float(dash_config.get("cooldown_sec", 0.0))


func _can_activate() -> bool:
	if owner.has_method("is_dash_active") and owner.is_dash_active():
		return false
	if owner.has_method("is_mine_placing_active") and owner.is_mine_placing_active():
		return false
	return true


func _activate() -> bool:
	if not owner.has_method("start_dash_from_ability"):
		return false

	var did_start: bool = owner.start_dash_from_ability()
	if did_start:
		start_cooldown()
	return did_start


func _is_active() -> bool:
	if owner != null and owner.has_method("is_dash_active"):
		return owner.is_dash_active()
	return false


func _get_active_text() -> String:
	return "DASH"
