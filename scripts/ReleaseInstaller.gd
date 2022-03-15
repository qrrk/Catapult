extends Node


signal status_message
signal installation_started
signal installation_finished
signal _migration_finished


onready var _downloader := $"../Downloader"
onready var _fshelper := $"../FSHelper"
onready var _probe := $"../InstallProbe"
onready var _settings := $"/root/SettingsManager"
onready var _path := $"../PathHelper"


func install_release(release_info: Dictionary, game: String, update: bool = false) -> void:
	
	emit_signal("installation_started")
	
	if update:
		emit_signal("status_message", tr("msg_updating_game") % release_info["name"])
	else:
		emit_signal("status_message", tr("msg_installing_game") % release_info["name"])
	
	_downloader.download_file(release_info["url"], _path.own_dir, release_info["filename"])
	yield(_downloader, "download_finished")
	
	var archive: String = _path.own_dir.plus_file(release_info["filename"])
	if Directory.new().file_exists(archive):
		
		_fshelper.extract(archive, _path.tmp_dir)
		yield(_fshelper, "extract_done")
		Directory.new().remove(archive)
		
		if _fshelper.last_extract_result == 0:
		
			var extracted_root
			match OS.get_name():
				"X11":
					extracted_root = _path.tmp_dir.plus_file(_fshelper.list_dir(_path.tmp_dir)[0])
				"Windows":
					extracted_root = _path.tmp_dir
			
			_probe.create_info_file(extracted_root, release_info["name"])
			
			if update:
				if len(_settings.read("game_data_to_migrate")) > 0:
					_migrate_game_data(_path.game_dir, extracted_root)
					yield(self, "_migration_finished")
				_fshelper.rm_dir(_path.game_dir)
				yield(_fshelper, "rm_dir_done")
			
			_fshelper.move_dir(extracted_root, _path.game_dir)
			yield(_fshelper, "move_dir_done")
			
			if update:
				emit_signal("status_message", tr("msg_game_updated"))
			else:
				emit_signal("status_message", tr("msg_game_installed"))
	
	emit_signal("installation_finished")


func _migrate_game_data(from_dir: String, to_dir: String) -> void:

	emit_signal("status_message", tr("msg_migrating_game_data"))
	
	var datatypes = _settings.read("game_data_to_migrate")
	
	if "savegames" in datatypes:
		emit_signal("status_message", tr("msg_migrating_saves"))
		_fshelper.copy_dir(from_dir + "/save", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "settings" in datatypes:
		emit_signal("status_message", tr("msg_migrating_config"))
		_fshelper.copy_dir(from_dir + "/config", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "mods" in datatypes:
		emit_signal("status_message", tr("msg_migrating_mods"))
		_fshelper.copy_dir(from_dir + "/mods", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "fonts" in datatypes:
		emit_signal("status_message", tr("msg_migrating_fonts"))
		_fshelper.copy_dir(from_dir + "/font", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "tilesets" in datatypes:
		emit_signal("status_message", tr("msg_migrating_gfx"))
		_fshelper.copy_dir(from_dir + "/gfx", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "soundpacks" in datatypes:
		emit_signal("status_message", tr("msg_migrating_sound"))
		_fshelper.copy_dir(from_dir + "/sound", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "templates" in datatypes:
		emit_signal("status_message", tr("msg_migrating_templates"))
		_fshelper.copy_dir(from_dir + "/templates", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "memorial" in datatypes:
		emit_signal("status_message", tr("msg_migrating_memorial"))
		_fshelper.copy_dir(from_dir + "/memorial", to_dir)
		yield(_fshelper, "copy_dir_done")
		
	if "graveyard" in datatypes:
		emit_signal("status_message", tr("msg_migrating_graveyard"))
		_fshelper.copy_dir(from_dir + "/graveyard", to_dir)
		yield(_fshelper, "copy_dir_done")
	
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("_migration_finished")

