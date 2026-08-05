class_name AbilityTreeData
extends RefCounted

const DEFAULT_PATH := "res://ability_tree_v1.json"

static var _cached_tree: Dictionary = {}


static func get_tree_data(path: String = DEFAULT_PATH) -> Dictionary:
	if not _cached_tree.is_empty():
		return _cached_tree

	if not FileAccess.file_exists(path):
		printerr("Ability tree JSON not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Failed to open ability tree JSON: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("Ability tree JSON root must be a Dictionary: %s" % path)
		return {}

	_cached_tree = parsed
	_build_indexes(_cached_tree)
	return _cached_tree


static func get_ability_spec(ability_id: String, path: String = DEFAULT_PATH) -> Dictionary:
	var tree := get_tree_data(path)
	var ability_index_value = tree.get("ability_index", {})
	if typeof(ability_index_value) != TYPE_DICTIONARY:
		return {}
	return ability_index_value.get(ability_id, {})


static func get_upgrade_entry(upgrade_id: String, path: String = DEFAULT_PATH) -> Dictionary:
	var tree := get_tree_data(path)
	var upgrade_index_value = tree.get("upgrade_index", {})
	if typeof(upgrade_index_value) != TYPE_DICTIONARY:
		return {}
	return upgrade_index_value.get(upgrade_id, {})


static func _build_indexes(tree: Dictionary) -> void:
	if tree.has("ability_index") and tree.has("upgrade_index"):
		return

	var ability_index: Dictionary = {}
	var upgrade_index: Dictionary = {}
	var abilities_value = tree.get("abilities", [])

	if typeof(abilities_value) != TYPE_ARRAY:
		tree["ability_index"] = ability_index
		tree["upgrade_index"] = upgrade_index
		return

	for ability_value in abilities_value:
		if typeof(ability_value) != TYPE_DICTIONARY:
			continue

		var ability: Dictionary = ability_value
		var ability_id := str(ability.get("id", ""))
		if ability_id == "":
			continue

		ability_index[ability_id] = ability

		var upgrade_nodes_value = ability.get("upgrade_nodes", [])
		if typeof(upgrade_nodes_value) != TYPE_ARRAY:
			continue

		for node_value in upgrade_nodes_value:
			if typeof(node_value) != TYPE_DICTIONARY:
				continue

			var node: Dictionary = node_value
			var node_id := str(node.get("id", ""))
			if node_id == "":
				continue

			upgrade_index[node_id] = {
				"ability_id": ability_id,
				"node": node
			}

	tree["ability_index"] = ability_index
	tree["upgrade_index"] = upgrade_index
