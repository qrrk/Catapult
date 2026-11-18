class_name GameRegistry
extends RefCounted
## Central registry of supported Cataclysm games loaded from res://data/games.json.

const _GAMES_PATH := "res://data/games.json"

static var _games: Array[Dictionary] = []
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	
	var f := FileAccess.open(_GAMES_PATH, FileAccess.READ)
	if f == null:
		push_error("Failed to open %s (error %d)" % [_GAMES_PATH, FileAccess.get_open_error()])
		return
	
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK or not (json.data is Array):
		push_error("Failed to parse %s: %s" % [_GAMES_PATH, json.get_error_message()])
		return
	
	for entry in json.data:
		if entry is Dictionary and "id" in entry:
			_games.append(entry)


static func get_games() -> Array[Dictionary]:
	_ensure_loaded()
	return _games


static func get_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for game in _games:
		ids.append(game["id"] as String)
	return ids


static func has_game(game_id: String) -> bool:
	return index_of(game_id) >= 0


static func get_game(game_id: String) -> Dictionary:
	_ensure_loaded()
	for game in _games:
		if game["id"] == game_id:
			return game
	return {}


static func get_by_index(index: int) -> Dictionary:
	_ensure_loaded()
	if index >= 0 and index < _games.size():
		return _games[index]
	return {}


static func index_of(game_id: String) -> int:
	_ensure_loaded()
	for i in _games.size():
		if _games[i]["id"] == game_id:
			return i
	return -1


static func get_title(game_id: String) -> String:
	var game := get_game(game_id)
	return game.get("title", "{BUG!!}") as String


static func get_desc_key(game_id: String) -> String:
	var game := get_game(game_id)
	return game.get("desc_key", "") as String


static func get_fetch_msg_key(game_id: String) -> String:
	var game := get_game(game_id)
	return game.get("fetch_msg_key", "") as String


static func get_all_release_keys() -> Array[String]:
	var keys: Array[String] = []
	for game_id in get_ids():
		keys.append(game_id + "-stable")
		keys.append(game_id + "-experimental")
	return keys
