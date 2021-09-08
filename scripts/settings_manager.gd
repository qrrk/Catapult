extends Node


signal status_message


const _SETTINGS_FILENAME = "catapult_settings.json"

const _HARDCODED_DEFAULTS = {
	"game": "dda",
	"channel": "stable",  # Currently used only for DDA.
	"print_tips_of_the_day": true,
	"update_to_same_build_allowed": false,
	"shorten_release_names": false,
	"num_releases_to_request": 10,
	"ui_scale_override": 1.0,
	"ui_scale_override_enabled": false,
	"show_stock_mods": false,
	"show_installed_mods_in_available": false,
	"show_stock_sound": false,
	"show_game_desc": true,
	"debug_mode": false,
	"game_data_to_migrate": [
		"savegames", "settings", "mods", "fonts", "tilesets",
		"soundpacks", "templates", "memorial", "graveyard"],
}


var _settings_file = ""

var _current = {}


func _enter_tree() -> void:
	connect("status_message", $"/root/Catapult", "_on_status_message")


func _exit_tree() -> void:
	_write_to_file(_current, _settings_file)


func _load() -> void:
	
	_settings_file = OS.get_executable_path().get_base_dir() + "/" + _SETTINGS_FILENAME
	
	if File.new().file_exists(_settings_file):
		_current = _read_from_file(_settings_file)
		
	else:
		_current = _HARDCODED_DEFAULTS
		emit_signal("status_message", "Creating settings file %s." % _SETTINGS_FILENAME)
		_write_to_file(_HARDCODED_DEFAULTS, _settings_file)


func _read_from_file(path: String) -> Dictionary:
	
	var f = File.new()
	
	if not f.file_exists(path):
		emit_signal("status_message", "Attempted to load settings from nonexistent file " + path, Enums.MSG_ERROR)
		return {}
		
	emit_signal("status_message", "Loading settings from %s." % _SETTINGS_FILENAME)
		
	f.open(path, File.READ)
	var s = f.get_as_text()
	var result: JSONParseResult = JSON.parse(s)
	
	if result.error:
		emit_signal("status_message", "Error parsing settings from JSON, line %s, message: %s" %
				[result.error_line, result.error_string], Enums.MSG_ERROR)
		return {}
	else:
		return result.result


func _write_to_file(data: Dictionary, path: String) -> void:
	
	var f = File.new()
	var content = JSON.print(data, "    ")
	f.open(path, File.WRITE)
	f.store_string(content)
	f.close()


func read(setting_name: String):
	
	if len(_current) == 0:
		_load()
	
	if not setting_name in _current:
		if setting_name in _HARDCODED_DEFAULTS:
			_current[setting_name] = _HARDCODED_DEFAULTS[setting_name]
		else:
			emit_signal("status_message", "Attempted to read nonexistent setting \"%s\"" \
					% setting_name, Enums.MSG_ERROR)
			return null
	
	return _current[setting_name]


func store(setting_name: String, setting_value) -> void:
	
	_current[setting_name] = setting_value
