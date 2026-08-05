class_name AbilityBase
extends RefCounted

var owner = null
var ability_id: String = ""
var display_name: String = ""
var bind_text: String = ""
var accent_color: Color = Color(0.90, 0.90, 0.95)
var cooldown_duration: float = 0.0
var cooldown_left: float = 0.0


func setup(new_owner) -> void:
	owner = new_owner
	_on_setup()
	refresh_from_owner()


func refresh_from_owner() -> void:
	if owner == null or not is_instance_valid(owner):
		return
	_on_refresh_from_owner()


func physics_update(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(0.0, cooldown_left - delta)
	_on_physics_update(delta)


func try_activate() -> bool:
	if not can_activate():
		return false
	return _activate()


func can_activate() -> bool:
	if owner == null or not is_instance_valid(owner):
		return false
	if owner.has_method("is_fighter_alive") and not owner.is_fighter_alive():
		return false
	if owner.has_method("is_ability_input_locked") and owner.is_ability_input_locked():
		return false
	if cooldown_left > 0.0:
		return false
	return _can_activate()


func start_cooldown() -> void:
	cooldown_left = cooldown_duration


func interrupt() -> void:
	_on_interrupt()


func reset_state() -> void:
	cooldown_left = 0.0
	_on_reset()


func get_descriptor() -> Dictionary:
	return {
		"id": ability_id,
		"name": display_name,
		"bind": bind_text,
		"accent": accent_color
	}


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


func _on_setup() -> void:
	pass


func _on_refresh_from_owner() -> void:
	pass


func _on_physics_update(_delta: float) -> void:
	pass


func _can_activate() -> bool:
	return true


func _activate() -> bool:
	return false


func _is_active() -> bool:
	return false


func _get_active_text() -> String:
	return "ACTIVE"


func _on_interrupt() -> void:
	pass


func _on_reset() -> void:
	pass
