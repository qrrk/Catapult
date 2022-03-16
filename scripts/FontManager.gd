extends Node


const _DEFAULT_FONTS = ["data/font/Terminus.ttf", "data/font/unifont.ttf"]

onready var _path := $"../PathHelper"

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
	
	Status.post(tr("msg_game_option_not_found_get") % name, Enums.MSG_ERROR)


func set_game_option(name: String, value: String):
	
	for item in _game_options:
		if item["name"] == name:
			item["value"] = value
			return
	
	Status.post(tr("msg_game_option_not_found_set") % name, Enums.MSG_ERROR)


func load_available_fonts() -> void:
	
	var f := File.new()
	var error := f.open("res://fonts/ingame/font_info.json", File.READ)
	
	if error:
		Status.post(tr("msg_failed_to_open_font_info"), Enums.MSG_ERROR)
		return
	
	var json_result := JSON.parse(f.get_as_text())
	
	if json_result.error:
		Status.post(tr("msg_could_not_parse_font_info"), Enums.MSG_ERROR)
		Status.post(tr("msg_font_info_error_details")
				% [json_result.error, json_result.error_line, json_result.error_string], Enums.MSG_DEBUG)
		return
		
	available_fonts = json_result.result


func font_config_file_exists() -> bool:
	
	var config_file: String = _path.config.plus_file("fonts.json")
			
	return Directory.new().file_exists(config_file)


func load_font_config() -> void:
	
	var result: Dictionary = {}
	var config_file: String = _path.config.plus_file("fonts.json")
	
	if Directory.new().file_exists(config_file):
		var f := File.new()
		var err = f.open(config_file, File.READ)
		if err == 0:
			var parse_result := JSON.parse(f.get_as_text())
			if parse_result.error == 0:
				result = parse_result.result
			else:
				Status.post(tr("msg_could_not_parse_font_config") % config_file, Enums.MSG_ERROR)
				Status.post(tr("msg_font_config_error_details")
						% [parse_result.error, parse_result.error_line, parse_result.error_string], Enums.MSG_DEBUG)
		else:
			Status.post(tr("msg_failed_to_open_font_config") % [config_file, err], Enums.MSG_ERROR)
	else:
		Status.post(tr("msg_font_config_not_found") % config_file, Enums.MSG_ERROR)
	
	font_config = result


func options_file_exists() -> bool:
	
	var options_file: String = _path.config.plus_file("options.json")
		
	return Directory.new().file_exists(options_file)


func load_game_options() -> void:
	
	var options_file: String = _path.config.plus_file("options.json")

	if Directory.new().file_exists(options_file):
		var f := File.new()
		var err = f.open(options_file, File.READ)
		if err == 0:
			var parse_result := JSON.parse(f.get_as_text())
			if parse_result.error == 0:
				_game_options = parse_result.result
			else:
				Status.post(tr("msg_could_not_parse_game_options") % options_file, Enums.MSG_ERROR)
				Status.post(tr("msg_game_options_error_details")
						% [parse_result.error, parse_result.error_line, parse_result.error_string], Enums.MSG_DEBUG)
		else:
			Status.post(tr("msg_could_not_open_game_options") % [options_file, err], Enums.MSG_ERROR)
	else:
		Status.post(tr("msg_game_options_not_found") % options_file, Enums.MSG_ERROR)


func _write_font_config() -> void:
	
	var config_file: String = _path.config.plus_file("fonts.json")
	
	var f = File.new()
	var err = f.open(config_file, File.WRITE)
	if err == 0:
		var json = JSON.print(font_config, "    ")
		f.store_string(json)
		f.close()
	else:
		Status.post(tr("msg_font_config_not_writable") % config_file, Enums.MSG_ERROR)


func write_game_options() -> void:
	
	var options_file: String = _path.config.plus_file("options.json")
	
	var f = File.new()
	var err = f.open(options_file, File.WRITE)
	if err == 0:
		var json = JSON.print(_game_options, "    ")
		f.store_string(json)
		f.close()
		Status.post(tr("msg_game_options_saved"))
	else:
		Status.post(tr("msg_game_options_not_writable") % options_file, Enums.MSG_ERROR)


func _install_font(font_index: int) -> bool:
	
	var d := Directory.new()
	var font_file = available_fonts[font_index]["file"]
	var source := "res://fonts/ingame".plus_file(font_file)
	var dest: String = _path.font_user.plus_file(font_file)
	var err = d.copy(source, dest)
	
	if err:
		Status.post(tr("msg_could_not_install_font") % [font_file, err], Enums.MSG_ERROR)
		Status.post(tr("msg_font_install_details") % [source, dest], Enums.MSG_DEBUG)
		return false
	else:
		return true


func set_font(font_index: int, ui: bool, map: bool, overmap: bool) -> void:
	
	if (font_index < 0) or (font_index >= len(available_fonts)):
		Status.post(tr("msg_invalid_font_index_passed") % font_index, Enums.MSG_ERROR)
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
			Status.post(tr("msg_font_config_field_missing") % field, Enums.MSG_ERROR)
	
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
