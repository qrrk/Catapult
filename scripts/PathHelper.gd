extends Node
# This is a cetralized place for all path resolution logic.


signal status_message


onready var _settings := $"/root/SettingsManager"

var own_dir: String setget , _get_own_dir
var game_dir: String setget , _get_game_dir
var userdata: String setget , _get_userdata_dir
var config: String setget , _get_config_dir
var savegames: String setget , _get_savegame_dir
var mods_stock: String setget , _get_mods_dir_default
var mods_user: String setget , _get_mods_dir_user
var sound_stock: String setget , _get_sound_dir_default
var sound_user: String setget , _get_sound_dir_user
var gfx_default: String setget , _get_gfx_dir_default
var gfx_user: String setget , _get_gfx_dir_user
var font_user: String setget , _get_font_dir_user
var templates: String setget , _get_templates_dir
var memorial: String setget , _get_memorial_dir
var graveyard: String setget , _get_graveyard_dir
var mod_repo: String setget , _get_modrepo_dir
var tmp_dir: String setget , _get_tmp_dir
var utils_dir: String setget , _get_utils_dir
var save_backups: String setget , _get_save_backups_dir


func _get_own_dir() -> String:
	
	return OS.get_executable_path().get_base_dir()


func _get_game_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("current")


func _get_userdata_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("userdata")


func _get_config_dir() -> String:
	
	return _get_userdata_dir().plus_file("config")


func _get_savegame_dir() -> String:
	
	return _get_userdata_dir().plus_file("save")


func _get_mods_dir_default() -> String:
	
	return _get_game_dir().plus_file("data").plus_file("mods")


func _get_mods_dir_user() -> String:
	
	return _get_userdata_dir().plus_file("mods")


func _get_sound_dir_default() -> String:
	
	return _get_game_dir().plus_file("data").plus_file("sound")


func _get_sound_dir_user() -> String:
	
	return _get_userdata_dir().plus_file("sound")


func _get_gfx_dir_default() -> String:
	
	return _get_game_dir().plus_file("gfx")


func _get_gfx_dir_user() -> String:
	
	return _get_userdata_dir().plus_file("gfx")


func _get_font_dir_user() -> String:
	
	return _get_userdata_dir().plus_file("font")


func _get_templates_dir() -> String:
	
	return _get_userdata_dir().plus_file("templates")


func _get_memorial_dir() -> String:
	
	return _get_userdata_dir().plus_file("memorial")


func _get_graveyard_dir() -> String:
	
	return _get_userdata_dir().plus_file("graveyard")


func _get_modrepo_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("mod_repo")


func _get_tmp_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("tmp")


func _get_utils_dir() -> String:
	
	return _get_own_dir().plus_file("utils")


func _get_save_backups_dir() -> String:
	
	return _get_own_dir().plus_file(_settings.read("game")).plus_file("save_backups")
