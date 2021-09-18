extends Node


signal status_message


const _DEFAULT_FONTS = ["data/font/Terminus.ttf", "data/font/unifont.ttf"]

onready var _settings = $"/root/SettingsManager"
onready var _workdir := OS.get_executable_path().get_base_dir()

var _game_options: Array = []

var available_fonts: Array = [] setget , _get_available_fonts
var font_config: Dictionary = {} setget , _get_font_config


func _get_available_fonts() -> Array:
	
	return available_fonts


func _get_font_config() -> Dictionary:
	
	return font_config


func get_game_option(name: String):
	
	for item in _game_options:
		if item["name"] == name:
			return item["value"]
	
	emit_signal("status_message", "Tried to get game option \"%s\", but it wasn't found."
			% name, Enums.MSG_ERROR)


func set_game_option(name: String, value: String):
	
	for item in _game_options:
		if item["name"] == name:
			item["value"] = value
			return
	
	emit_signal("status_message", "Tried to set game option \"%s\", but it wasn't found."
			% name, Enums.MSG_ERROR)


func load_available_fonts() -> void:
	
	var f := File.new()
	var error := f.open("res://fonts/ingame/font_info.json", File.READ)
	
	if error:
		emit_signal("status_message", "Failed to open bundled font info.", Enums.MSG_ERROR)
		return
	
	var json_result := JSON.parse(f.get_as_text())
	
	if json_result.error:
		emit_signal("status_message", "Could not parse bundled font info.", Enums.MSG_ERROR)
		emit_signal("status_message", "Error code: %s. Error line: %s. Error message: %s"
				% [json_result.error, json_result.error_line, json_result.error_string], Enums.MSG_DEBUG)
		return
		
	available_fonts = json_result.result


func font_config_file_exists() -> bool:
	
	var config_file: String = _workdir.plus_file(_settings.read("game")).\
			plus_file("current").plus_file("config").plus_file("fonts.json")
			
	return Directory.new().file_exists(config_file)


func load_font_config() -> void:
	
	var result: Dictionary = {}
	var config_file: String = _workdir.plus_file(_settings.read("game")).\
			plus_file("current").plus_file("config").plus_file("fonts.json")
	
	if Directory.new().file_exists(config_file):
		var f := File.new()
		var err = f.open(config_file, File.READ)
		if err == 0:
			var parse_result := JSON.parse(f.get_as_text())
			if parse_result.error == 0:
				result = parse_result.result
			else:
				emit_signal("status_message", "Could not parse font config file %s." % config_file, Enums.MSG_ERROR)
				emit_signal("status_message", "Error code: %s. Error line: %s. Error message: %s"
						% [parse_result.error, parse_result.error_line, parse_result.error_string], Enums.MSG_DEBUG)
		else:
			emit_signal("status_message", "Could not open font config file %s (error code: %s)."
					% [config_file, err], Enums.MSG_ERROR)
	else:
		emit_signal("status_message", "Font config file %s is not found!" % config_file, Enums.MSG_ERROR)
	
	font_config = result


func options_file_exists() -> bool:
	
	var options_file: String = _workdir.plus_file(_settings.read("game")).\
		plus_file("current").plus_file("config").plus_file("options.json")
		
	return Directory.new().file_exists(options_file)


func load_game_options() -> void:
	
	var options_file: String = _workdir.plus_file(_settings.read("game")).\
			plus_file("current").plus_file("config").plus_file("options.json")

	if Directory.new().file_exists(options_file):
		var f := File.new()
		var err = f.open(options_file, File.READ)
		if err == 0:
			var parse_result := JSON.parse(f.get_as_text())
			if parse_result.error == 0:
				_game_options = parse_result.result
			else:
				emit_signal("status_message", "Could not parse game options file %s." % options_file, Enums.MSG_ERROR)
				emit_signal("status_message", "Error code: %s. Error line: %s. Error message: %s"
						% [parse_result.error, parse_result.error_line, parse_result.error_string], Enums.MSG_DEBUG)
		else:
			emit_signal("status_message", "Could not open game options file %s (error code: %s)."
					% [options_file, err], Enums.MSG_ERROR)
	else:
		emit_signal("status_message", "Game options file %s is not found!" % options_file, Enums.MSG_ERROR)


func _write_font_config() -> void:
	
	var config_file: String = _workdir.plus_file(_settings.read("game")).\
			plus_file("current").plus_file("config").plus_file("fonts.json")
	
	var f = File.new()
	var err = f.open(config_file, File.WRITE)
	if err == 0:
		var json = JSON.print(font_config, "    ")
		f.store_string(json)
		f.close()
	else:
		emit_signal("status_message", "Could not open font config file %s for writing."
				% config_file, Enums.MSG_ERROR)


func write_game_options() -> void:
	
	var options_file: String = _workdir.plus_file(_settings.read("game")).\
			plus_file("current").plus_file("config").plus_file("options.json")
	
	var f = File.new()
	var err = f.open(options_file, File.WRITE)
	if err == 0:
		var json = JSON.print(_game_options, "    ")
		f.store_string(json)
		f.close()
		emit_signal("status_message", "Saved game options to [i]options.json[/i].")
	else:
		emit_signal("status_message", "Could not open game options file %s for writing."
				% options_file, Enums.MSG_ERROR)


func _install_font(font_index: int) -> bool:
	
	var d := Directory.new()
	var font_file = available_fonts[font_index]["file"]
	var source := "res://fonts/ingame".plus_file(font_file)
	var dest := _workdir.plus_file(_settings.read("game")).plus_file("current")\
			.plus_file("font").plus_file(font_file)
	var err = d.copy(source, dest)
	
	if err:
		emit_signal("status_message", "Could not install font file %s (error code: %s)."
				% [font_file, err], Enums.MSG_ERROR)
		emit_signal("status_message", "Font source: %s. Destination: %s."
				% [source, dest], Enums.MSG_DEBUG)
		return false
	else:
		return true


func set_font(font_index: int, ui: bool, map: bool, overmap: bool) -> void:
	
	if (font_index < 0) or (font_index >= len(available_fonts)):
		emit_signal("status_message", "set_font was passed invalid font index %s."
				% font_index, Enums.MSG_ERROR)
		return
		
	if not _install_font(font_index):
		return
	
	var fields = []
	if ui:
		fields.append("typeface")
	if map:
		fields.append("map_typeface")
	if overmap:
		fields.append("overmap_typeface")
	
	for field in fields:
		if field in font_config:
			if len(font_config[field]) <= 2:
				font_config[field].push_front(available_fonts[font_index]["file"])
			else:
				font_config[field][0] = available_fonts[font_index]["file"]
		else:
			emit_signal("status_message", "Font config does not have field \"%s\"."
					% field, Enums.MSG_ERROR)
	
	_write_font_config()


func reset_font() -> void:
	
	for field in ["typeface", "map_typeface", "overmap_typeface"]:
		font_config[field] = _DEFAULT_FONTS.duplicate()
	
	_write_font_config()


func _get_current_font_indices() -> Dictionary:
	# Finds out which bundled fonts from available_fonts are currently
	# set in fonts.json (if any).
	
	var result := {}
	
	for field in ["typeface", "map_typeface", "overmap_typeface"]:
		var file: String = font_config[field][0]
		var index := -1
		for i in len(available_fonts):
			if available_fonts[i]["file"] == file:
				index = i
				break
		result[field] = index
	
	return result


func set_font_sizes(ui: int, map: int, overmap: int) -> void:
	
	var current_indices := _get_current_font_indices()
	var height_ratio: float
	var width_ratio: float
	
	var index: int = current_indices["typeface"]
	if index >= 0:
		height_ratio = available_fonts[index]["height"]
		width_ratio = available_fonts[index]["width"]
	else:
		height_ratio = 1.0
		width_ratio = 0.5
	set_game_option("FONT_SIZE", str(ui))
	set_game_option("FONT_HEIGHT", str(int(ui * height_ratio)))
	set_game_option("FONT_WIDTH", str(int(ui * width_ratio)))
	
	index = current_indices["map_typeface"]
	if index >= 0:
		height_ratio = available_fonts[index]["height"]
	else:
		height_ratio = 1.0
	set_game_option("MAP_FONT_SIZE", str(map))
	set_game_option("MAP_FONT_HEIGHT", str(int(map * height_ratio)))
	set_game_option("MAP_FONT_WIDTH", str(int(map * height_ratio)))
	
	index = current_indices["overmap_typeface"]
	if index >= 0:
		height_ratio = available_fonts[index]["height"]
	else:
		height_ratio = 1.0
	set_game_option("OVERMAP_FONT_SIZE", str(overmap))
	set_game_option("OVERMAP_FONT_HEIGHT", str(int(overmap * height_ratio)))
	set_game_option("OVERMAP_FONT_WIDTH", str(int(overmap * height_ratio)))
