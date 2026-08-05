extends "res://scripts/abilities/ability_base.gd"

var place_time: float = 0.3
var placing_left: float = 0.0
var placing: bool = false
var mine_config: Dictionary = {}


func _on_setup() -> void:
	ability_id = "mine"
	display_name = "Mine"
	bind_text = "E"
	accent_color = Color(1.0, 0.30, 0.24)


func _on_refresh_from_owner() -> void:
	if owner == null or not owner.has_method("get_ability_config"):
		mine_config.clear()
		return

	mine_config = owner.get_ability_config("mine")
	cooldown_duration = float(mine_config.get("cooldown_sec", 0.0))
	place_time = float(mine_config.get("place_time_sec", 0.0))


func _on_physics_update(delta: float) -> void:
	if not placing:
		return

	placing_left = maxf(0.0, placing_left - delta)
	if placing_left > 0.0:
		return

	placing = false
	if owner != null and is_instance_valid(owner) and owner.has_method("place_mine_from_ability"):
		if owner.place_mine_from_ability(mine_config):
			start_cooldown()


func _can_activate() -> bool:
	if placing:
		return false
	if owner.has_method("is_dash_active") and owner.is_dash_active():
		return false
	return true


func _activate() -> bool:
	placing = true
	placing_left = place_time
	return true


func _is_active() -> bool:
	return placing


func _get_active_text() -> String:
	return "PLANT"


func is_placing() -> bool:
	return placing


func _on_interrupt() -> void:
	placing = false
	placing_left = 0.0


func _on_reset() -> void:
	placing = false
	placing_left = 0.0
