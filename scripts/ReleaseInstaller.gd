extends Node


signal status_message
signal installation_started
signal installation_finished
signal _migration_finished


onready var _downloader = $"../Downloader"
onready var _fshelper = $"../FSHelper"
onready var _probe = $"../InstallProbe"
onready var _settings = $"/root/SettingsManager"
onready var _workdir = _fshelper.get_own_dir()


func install_release(release_info: Dictionary, game: String, update: bool = false) -> void:
	
	emit_signal("installation_started")
	
	if update:
		emit_signal("status_message", "Updating to %s..." % release_info["name"])
	else:
		emit_signal("status_message", "Installing %s..." % release_info["name"])
	
	var gamedir = _workdir + "/" + game + "/current"
	var tmpdir = _workdir + "/" + game + "/tmp"

	var basegamedir = gamedir
	
	if OS.get_name() == "OSX":
		gamedir += "/Cataclysm.app"
	
	
	_downloader.download_file(release_info["url"], _workdir, release_info["filename"])
	yield(_downloader, "download_finished")
	
	if Directory.new().file_exists(_workdir.plus_file(release_info["filename"])):
		
		_fshelper.extract(_workdir + "/" + release_info["filename"], tmpdir)
		yield(_fshelper, "extract_done")
		Directory.new().remove(_workdir + "/" + release_info["filename"])
		
		print(_fshelper.last_extract_result)
		if _fshelper.last_extract_result == 0:
		
			var extracted_root
			match OS.get_name():
				"X11":
					extracted_root = tmpdir + "/" + _fshelper.list_dir(tmpdir)[0]
				"Windows":
					extracted_root = tmpdir
				"OSX":
					extracted_root = tmpdir + "/Cataclysm.app"
					
			
			if update:
				if len(_settings.read("game_data_to_migrate")) > 0:
					_migrate_game_data(gamedir, extracted_root)
					yield(self, "_migration_finished")
				_fshelper.rm_dir(gamedir)
				yield(_fshelper, "rm_dir_done")
			
			if OS.get_name() != "OSX":
				_fshelper.move_dir(extracted_root, gamedir)
				yield(_fshelper, "move_dir_done")				
			else:
				var output = []
				var args = ["-i", "-c", 'chmod -R u+w "%s" "%s"; mkdir -p "%s"; cp -r "%s" "%s"' % [gamedir, basegamedir, extracted_root, extracted_root, gamedir]]
				OS.execute("zsh", args, true, output, true)
			
			_probe.create_info_file(basegamedir, release_info["name"])
			
			if update:
				emit_signal("status_message", "Update finished.")
			else:
				emit_signal("status_message", "Installation finished.")
	
	emit_signal("installation_finished")


func _migrate_game_data(from_dir: String, to_dir: String) -> void:

	emit_signal("status_message", "Migrating game data. This may take a while.")
	
	var datatypes = _settings.read("game_data_to_migrate")
	
	if "savegames" in datatypes:
		emit_signal("status_message", "Copying savegames...")
		_fshelper.copy_dir(from_dir + "/save", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "settings" in datatypes:
		emit_signal("status_message", "Copying game settings...")
		_fshelper.copy_dir(from_dir + "/config", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "mods" in datatypes:
		emit_signal("status_message", "Copying mods...")
		_fshelper.copy_dir(from_dir + "/mods", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "fonts" in datatypes:
		emit_signal("status_message", "Copying user fonts...")
		_fshelper.copy_dir(from_dir + "/font", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "tilesets" in datatypes:
		emit_signal("status_message", "Copying tilesets...")
		_fshelper.copy_dir(from_dir + "/gfx", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "soundpacks" in datatypes:
		emit_signal("status_message", "Copying soundpacks...")
		_fshelper.copy_dir(from_dir + "/sound", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "templates" in datatypes:
		emit_signal("status_message", "Copying character templates...")
		_fshelper.copy_dir(from_dir + "/templates", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "memorial" in datatypes:
		emit_signal("status_message", "Copying memorial...")
		_fshelper.copy_dir(from_dir + "/memorial", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "graveyard" in datatypes:
		emit_signal("status_message", "Copying graveyard...")
		_fshelper.copy_dir(from_dir + "/graveyard", to_dir)
		yield(_fshelper, "copy_dir_done")
	
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("_migration_finished")

