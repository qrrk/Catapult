extends Node


signal status_message


onready var _settings := $"/root/SettingsManager"

var own_dir: String setget , _get_own_dir
var game_dir: String setget , _get_game_dir
var config_dir: String setget , _get_config_dir
var mods_dir_stock: String setget , _get_mods_dir_default
var mods_dir_user: String setget , _get_mods_dir_user
var sound_dir_stock: String setget , _get_sound_dir_default
var sound_dir_user: String setget , _get_sound_dir_user
var gfx_dir_default: String setget , _get_gfx_dir_default
var gfx_dir_user: String setget , _get_gfx_dir_user
var font_dir_user: String setget , _get_font_dir_user
var templates_dir: String setget , _get_templates_dir
var memorial_dir: String setget , _get_memorial_dir
var graveyard_dir: String setget , _get_graveyard_dir
var modrepo_dir: String setget , _get_modrepo_dir
var tmp_dir: String setget , _get_tmp_dir
var utils_dir: String setget , _get_utils_dir


func _get_own_dir() -> String:
	
	return OS.get_executable_path().get_base_dir()


func _get_game_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("current")


func _get_config_dir() -> String:
	
	return _get_game_dir().plus_file("config")


func _get_mods_dir_default() -> String:
	
	return _get_game_dir().plus_file("data").plus_file("mods")


func _get_mods_dir_user() -> String:
	
	return _get_game_dir().plus_file("mods")


func _get_sound_dir_default() -> String:
	
	return _get_game_dir().plus_file("data").plus_file("sound")


func _get_sound_dir_user() -> String:
	
	return _get_game_dir().plus_file("sound")


func _get_gfx_dir_default() -> String:
	
	return _get_game_dir().plus_file("gfx")


func _get_gfx_dir_user() -> String:
	
	return _get_game_dir().plus_file("gfx")  # Will not be the same in the future.


func _get_font_dir_user() -> String:
	
	return _get_game_dir().plus_file("font")


func _get_templates_dir() -> String:
	
	return _get_game_dir().plus_file("templates")


func _get_memorial_dir() -> String:
	
	return _get_game_dir().plus_file("memorial")


func _get_graveyard_dir() -> String:
	
	return _get_game_dir().plus_file("graveyard")


func _get_modrepo_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("mod_repo")


func _get_tmp_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("tmp")


func _get_utils_dir() -> String:
	
	return _get_own_dir().plus_file("utils")
