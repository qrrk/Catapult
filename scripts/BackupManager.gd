extends Node


signal backup_creation_started
signal backup_creation_finished
signal backup_restoration_started
signal backup_restoration_finished
signal backup_deletion_started
signal backup_deletion_finished

var available = null: get = _get_available


func backup_current(backup_name: String) -> void:
	# Create a backup of the save dir for the current game.

	Status.post(tr("msg_backing_up_saves") % backup_name)
	emit_signal("backup_creation_started")

	var dest_dir = Paths.save_backups.path_join(backup_name)
	
	if not DirAccess.dir_exists_absolute(dest_dir):
		DirAccess.make_dir_recursive_absolute(dest_dir)
		for world in FS.list_dir(Paths.savegames):
			FS.zip(Paths.savegames, world, dest_dir.path_join(world + ".zip"))
			await FS.zip_done
		
		Status.post(tr("msg_backup_created"))
	else:
		Status.post(tr("msg_backup_name_taken") % backup_name, Enums.MSG_ERROR)

	emit_signal("backup_creation_finished")


func get_save_summary(path: String) -> Dictionary:
	# Get information about a game save directory (any directory containing one or more game worlds)
	
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


func _get_available() -> Array:
	
	if not available:
		refresh_available()
	
	return available


func refresh_available():

	available = []
	
	if not DirAccess.dir_exists_absolute(Paths.save_backups):
		return
	
	for backup in FS.list_dir(Paths.save_backups):
		var path = Paths.save_backups.path_join(backup)
		available.append(get_save_summary(path))


func restore(backup_index: int) -> void:
	# Replace the save dir in the current game with the named backup
	
	var backup_name: String = available[backup_index]["name"]
	Status.post(tr("msg_restoring_backup") % backup_name)
	
	var source_dir = available[backup_index]["path"]
	var dest_dir = Paths.savegames
	
	emit_signal("backup_restoration_started")

	if DirAccess.dir_exists_absolute(source_dir):
		if DirAccess.dir_exists_absolute(dest_dir):
			FS.rm_dir(dest_dir)
			await FS.rm_dir_done
		
		DirAccess.make_dir_absolute(dest_dir)
		for world_zip in FS.list_dir(source_dir):
			FS.extract(source_dir.path_join(world_zip), dest_dir)
			await FS.extract_done
		
		Status.post(tr("msg_backup_restored"))
	else:
		Status.post(tr("msg_backup_not_found") % backup_name, Enums.MSG_ERROR)
	
	emit_signal("backup_restoration_finished")


func delete(backup_name: String) -> void:
	# Delete a backup.
	
	var target_dir = Paths.save_backups.path_join(backup_name)
	emit_signal("backup_deletion_started")

	if DirAccess.dir_exists_absolute(target_dir):
		Status.post(tr("msg_deleting_backup") % backup_name)
	
		FS.rm_dir(target_dir)
		await FS.rm_dir_done
		Status.post(tr("msg_backup_deleted"))

	emit_signal("backup_deletion_finished")
