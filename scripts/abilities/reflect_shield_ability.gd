extends "res://scripts/abilities/ability_base.gd"

var shield_config: Dictionary = {}


func _on_setup() -> void:
	ability_id = "reflect_shield"
	display_name = "Reflect"
	bind_text = "F"
	accent_color = Color(0.36, 0.92, 1.0)


func _on_refresh_from_owner() -> void:
	if owner == null or not owner.has_method("get_ability_config"):
		shield_config.clear()
		return

	shield_config = owner.get_ability_config("reflect_shield")
	cooldown_duration = float(shield_config.get("cooldown_sec", 0.0))


func _activate() -> bool:
	if owner == null or not owner.has_method("start_reflect_shield_from_ability"):
		return false

	var did_start: bool = owner.start_reflect_shield_from_ability(shield_config)
	if did_start:
		start_cooldown()
	return did_start


func _can_activate() -> bool:
	if float(shield_config.get("unlocks_ability", 0.0)) < 0.5:
		return false
	if owner.has_method("is_dash_active") and owner.is_dash_active():
		return false
	if owner.has_method("is_mine_placing_active") and owner.is_mine_placing_active():
		return false
	return true


func _is_active() -> bool:
	if owner != null and owner.has_method("is_reflect_shield_active"):
		return owner.is_reflect_shield_active()
	return false


func _get_active_text() -> String:
	return "ON"


func get_state() -> Dictionary:
	var state := get_descriptor()
	state["status"] = "READY"
	state["emphasis"] = "ready"

	if owner == null or not is_instance_valid(owner):
		state["status"] = "--"
		state["emphasis"] = "disabled"
		return state

	if owner.has_method("is_fighter_alive") and not owner.is_fighter_alive():
		state["status"] = "OUT"
		state["emphasis"] = "disabled"
		return state

	if float(shield_config.get("unlocks_ability", 0.0)) < 0.5:
		state["status"] = "LOCK"
		state["emphasis"] = "disabled"
		return state

	if owner.has_method("is_ability_input_locked") and owner.is_ability_input_locked():
		state["status"] = "WAIT"
		state["emphasis"] = "disabled"
		return state

	if _is_active():
		state["status"] = _get_active_text()
		state["emphasis"] = "active"
		return state

	if cooldown_left > 0.05:
		state["status"] = "%.1fs" % cooldown_left
		state["emphasis"] = "cooldown"
		return state

	return state
