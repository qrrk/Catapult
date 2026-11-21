extends Node
## Autoload singleton managing persistent launcher settings (catapult_settings.json)
## with fallback defaults loaded from res://data/default_settings.json.


## Emitted whenever a setting's value changes.
signal setting_changed(key: String, value: Variant)

const _SETTINGS_FILENAME = "catapult_settings.json"
const _DEFAULTS_FILENAME = "res://data/default_settings.json"

var _defaults: Dictionary = {}
var _settings_file: String = ""
var _current: Dictionary = {}


func _exit_tree() -> void:
	_write_to_file(_current, _settings_file)


func _load() -> void:
	
	if _defaults.is_empty():
		_defaults = Helpers.load_json_file(_DEFAULTS_FILENAME)
		if _defaults == null:
			_defaults = {}
	
	_settings_file = Paths.own_dir.path_join(_SETTINGS_FILENAME)
	
	if FileAccess.file_exists(_settings_file):
		_current = _read_from_file(_settings_file)
		
	else:
		_current = _defaults.duplicate(true)
		Status.post(tr("msg_creating_settings") % _SETTINGS_FILENAME)
		_write_to_file(_defaults, _settings_file)


func _read_from_file(path: String) -> Dictionary:
	
	if not FileAccess.file_exists(path):
		Status.post(tr("msg_nonexistent_attempt") % path, Enums.MSG_ERROR)
		return {}
		
	Status.post(tr("msg_loading_settings") % _SETTINGS_FILENAME)
		
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(f.get_as_text())
	
	if error:
		Status.post(tr("msg_settings_parse_error") % [json.get_error_line(), json.get_error_message()], Enums.MSG_ERROR)
		return {}
	else:
		return json.data


func _write_to_file(data: Dictionary, path: String) -> void:
	
	var content = JSON.stringify(data, "    ")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)
	f.close()


## Returns the value of a setting, lazily loading settings and falling back to defaults if absent.
func read(setting_name: String) -> Variant:
	
	if len(_current) == 0:
		_load()
	
	if not setting_name in _current:
		if _defaults.is_empty():
			_defaults = Helpers.load_json_file(_DEFAULTS_FILENAME)
			if _defaults == null:
				_defaults = {}
		if setting_name in _defaults:
			_current[setting_name] = _defaults[setting_name]
		else:
			Status.post(tr("msg_nonexisting_setting") % setting_name, Enums.MSG_ERROR)
			return null
	
	return _current[setting_name]


## Stores a setting value and emits [signal setting_changed] if it changed.
func store(setting_name: String, setting_value: Variant) -> void:
	
	if _current.is_empty():
		_load()
	
	var changed := not _current.has(setting_name)
	if not changed:
		var prev: Variant = _current[setting_name]
		changed = typeof(prev) != typeof(setting_value) or prev != setting_value
	
	_current[setting_name] = setting_value
	if changed:
		setting_changed.emit(setting_name, setting_value)
