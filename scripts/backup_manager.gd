extends Node
## Creates, lists, restores, and deletes zipped savegame backups for the currently selected game.


signal backup_creation_started
signal backup_creation_finished
signal backup_restoration_started
signal backup_restoration_finished
signal backup_deletion_started
signal backup_deletion_finished

## List of backup summary dictionaries (name, path, worlds), lazily populated on first access.
var available: Array:
	get:
		if not _available_backups:
			refresh_available()
		return _available_backups as Array

var _available_backups = null

## Creates a named backup of the current game's save directory, zipping each world folder.
func backup_current(backup_name: String) -> void:

	Status.post(tr("msg_backing_up_saves") % backup_name)
	backup_creation_started.emit()

	var dest_dir = Paths.save_backups.path_join(backup_name)
	
	if not DirAccess.dir_exists_absolute(dest_dir):
		DirAccess.make_dir_recursive_absolute(dest_dir)
		for item in FS.list_dir(Paths.savegames):
			var item_path = Paths.savegames.path_join(item)
			if DirAccess.dir_exists_absolute(item_path):
				FS.zip(Paths.savegames, item, dest_dir.path_join(item + ".zip"))
				await FS.zip_done
			elif FileAccess.file_exists(item_path):
				DirAccess.copy_absolute(item_path, dest_dir.path_join(item))
		
		Status.post(tr("msg_backup_created"))
	else:
		Status.post(tr("msg_backup_name_taken") % backup_name, Enums.MSG_ERROR)

	backup_creation_finished.emit()


## Returns a summary dictionary (name, path, worlds) for a save or backup directory.
func get_save_summary(path: String) -> Dictionary:
	
	if not DirAccess.dir_exists_absolute(path):
		return {}
	
	var summary = {
		"name": path.get_file(),
		"path": path,
		"worlds": [],
	}
	
	for world in FS.list_dir(path):
		summary["worlds"].append(world)
	
	return summary


## Rescans the save backups folder for the current game and updates [member available].
func refresh_available() -> void:

	_available_backups = []
	
	if not DirAccess.dir_exists_absolute(Paths.save_backups):
		return
	
	for backup in FS.list_dir(Paths.save_backups):
		var path = Paths.save_backups.path_join(backup)
		_available_backups.append(get_save_summary(path))


## Replaces the current game's save directory with the contents of the backup at backup_index.
func restore(backup_index: int) -> void:
	
	var backup_name: String = available[backup_index]["name"]
	Status.post(tr("msg_restoring_backup") % backup_name)
	
	var source_dir = available[backup_index]["path"]
	var dest_dir = Paths.savegames
	
	backup_restoration_started.emit()

	if DirAccess.dir_exists_absolute(source_dir):
		if DirAccess.dir_exists_absolute(dest_dir):
			FS.rm_dir(dest_dir)
			await FS.rm_dir_done
		
		DirAccess.make_dir_absolute(dest_dir)
		for item in FS.list_dir(source_dir):
			var source_item_path = source_dir.path_join(item)
			if item.to_lower().ends_with(".zip"):
				FS.extract(source_item_path, dest_dir)
				await FS.extract_done
			elif FileAccess.file_exists(source_item_path):
				DirAccess.copy_absolute(source_item_path, dest_dir.path_join(item))
		
		Status.post(tr("msg_backup_restored"))
	else:
		Status.post(tr("msg_backup_not_found") % backup_name, Enums.MSG_ERROR)
	
	backup_restoration_finished.emit()


## Deletes the named backup directory from disk.
func delete(backup_name: String) -> void:
	
	var target_dir = Paths.save_backups.path_join(backup_name)
	backup_deletion_started.emit()

	if DirAccess.dir_exists_absolute(target_dir):
		Status.post(tr("msg_deleting_backup") % backup_name)
	
		FS.rm_dir(target_dir)
		await FS.rm_dir_done
		Status.post(tr("msg_backup_deleted"))

	backup_deletion_finished.emit()
