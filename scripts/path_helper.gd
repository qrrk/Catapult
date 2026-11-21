extends Node
## Autoload singleton (Paths) resolving all launcher, game-installation, and userdata paths
## dynamically for the currently selected game and active installation.

## Directory containing the Catapult executable.
var own_dir: String:
	get:
		return OS.get_executable_path().get_base_dir()

## Nested dictionary mapping game IDs to installation names and absolute paths.
var installs_summary: Dictionary:
	get:
		return _get_installs_summary()

## Download archive cache directory.
var cache_dir: String:
	get:
		return own_dir.path_join("cache")

## Root directory of the currently active installation for the selected game.
var game_dir: String:
	get:
		return _get_game_dir()

## Next unused [code]gameN[/code] installation directory path for the selected game.
var next_install_dir: String:
	get:
		return _get_next_install_dir()

## Shared userdata root directory for the selected game.
var userdata: String:
	get:
		return own_dir.path_join(Settings.read("game")).path_join("userdata")

var config: String:
	get:
		return userdata.path_join("config")

var savegames: String:
	get:
		return userdata.path_join("save")

var mods_stock: String:
	get:
		return game_dir.path_join("data").path_join("mods")

var mods_user: String:
	get:
		return userdata.path_join("mods")

var sound_stock: String:
	get:
		return game_dir.path_join("data").path_join("sound")

var sound_user: String:
	get:
		return userdata.path_join("sound")

var gfx_default: String:
	get:
		return game_dir.path_join("gfx")

var gfx_user: String:
	get:
		return userdata.path_join("gfx")

var font_user: String:
	get:
		return userdata.path_join("font")

var templates: String:
	get:
		return userdata.path_join("templates")

var memorial: String:
	get:
		return userdata.path_join("memorial")

var graveyard: String:
	get:
		return userdata.path_join("graveyard")

var mod_repo: String:
	get:
		return own_dir.path_join(Settings.read("game")).path_join("mod_repo")

var tmp_dir: String:
	get:
		return own_dir.path_join(Settings.read("game")).path_join("tmp")

var utils_dir: String:
	get:
		return own_dir.path_join("utils")

var save_backups: String:
	get:
		return own_dir.path_join(Settings.read("game")).path_join("save_backups")

var _last_active_install_name := ""
var _last_active_install_dir := ""


func _get_installs_summary() -> Dictionary:
	
	var result = {}
	
	for game in GameRegistry.get_ids():
		var installs = {}
		var base_dir = own_dir.path_join(game)
		if not DirAccess.dir_exists_absolute(base_dir):
			continue
			
		for subdir in FS.list_dir(base_dir):
			var info_file = base_dir.path_join(subdir).path_join(Helpers.INFO_FILENAME)
			if FileAccess.file_exists(info_file):
				var info = Helpers.load_json_file(info_file)
				installs[info["name"]] = base_dir.path_join(subdir)
		if not installs.is_empty():
			result[game] = installs
	
	# Ensure that some installation of the game is set as active
	var game = Settings.read("game")
	var active_name = Settings.read("active_install_" + game)
	if game in result:
		if (active_name == "") or (not active_name in result[game]):
			Settings.store("active_install_" + game, result[game].keys()[0])
	
	return result


func _get_game_dir() -> String:

	var active_name = Settings.read("active_install_" + Settings.read("game"))
	
	if active_name == "":
		return next_install_dir
	elif active_name == _last_active_install_name:
		return _last_active_install_dir
	else:
		return _find_active_game_dir()


func _find_active_game_dir() -> String:
	
	var base_dir = own_dir.path_join(Settings.read("game"))
	for subdir in FS.list_dir(base_dir):
		var curr_dir = base_dir.path_join(subdir)
		var info_file = curr_dir.path_join("catapult_install_info.json")
		if FileAccess.file_exists(info_file):
			var info = Helpers.load_json_file(info_file)
			if ("name" in info) and (info["name"] == Settings.read("active_install_" + Settings.read("game"))):
				_last_active_install_dir = curr_dir
				return curr_dir
	
	return ""


func _get_next_install_dir() -> String:
	# Finds a suitable directory name for a new game installation in the
	# multi-install system. The names follow the pattern "game0, game1, ..."
	
	var base_dir := own_dir.path_join(Settings.read("game"))
	var dir_number := 0
	while DirAccess.dir_exists_absolute(base_dir.path_join("game" + str(dir_number))):
		dir_number += 1
	return base_dir.path_join("game" + str(dir_number))
