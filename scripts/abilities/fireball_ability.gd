extends "res://scripts/abilities/ability_base.gd"

var projectile_config: Dictionary = {}


func _on_setup() -> void:
	ability_id = "fireball"
	display_name = "Fireball"
	bind_text = "LMB"
	accent_color = Color(1.0, 0.48, 0.22)


func _on_refresh_from_owner() -> void:
	if owner == null or not owner.has_method("get_ability_config"):
		projectile_config.clear()
		return

	projectile_config = owner.get_ability_config("fireball")
	cooldown_duration = float(projectile_config.get("cooldown_sec", 0.0))


func _can_activate() -> bool:
	if owner.has_method("is_dash_active") and owner.is_dash_active():
		return false
	return true


func _activate() -> bool:
	if not owner.has_method("spawn_fireball_from_ability"):
		return false

	var did_spawn: bool = owner.spawn_fireball_from_ability(projectile_config)
	if did_spawn:
		start_cooldown()
	return did_spawn
