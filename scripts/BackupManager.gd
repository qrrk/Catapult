extends Node


signal status_message


const _BACKUPS_SUBDIR = "save_backups"

onready var _settings = $"/root/SettingsManager"
onready var _fshelper = $"../FSHelper"

onready var _workdir = OS.get_executable_path().get_base_dir()


func backup_current(backup_name: String) -> void:
	# Create a backup of the save dir for the current game.

	emit_signal("status_message", "Backing up current saves to %s..." % backup_name)

	var game_dir = _workdir.plus_file(_settings.read("game"))
	var temp_dir = _workdir.plus_file("tmp")
	var source_dir = game_dir.plus_file("current").plus_file("save")
	var dest_dir = game_dir.plus_file(_BACKUPS_SUBDIR).plus_file(backup_name)
	
	_fshelper.copy_dir(source_dir, temp_dir)
	yield(_fshelper, "copy_dir_done")

	_fshelper.move_dir(temp_dir.plus_file("save"), dest_dir)
	yield(_fshelper, "move_dir_done")
	
	emit_signal("status_message", "Backup complete.")
