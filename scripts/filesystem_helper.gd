extends Node


signal copy_dir_done
signal rm_dir_done
signal move_dir_done
signal extract_done
signal zip_done


var _platform: String = ""

var last_extract_result: int = 0: get = _get_last_extract_result
# Stores the exit code of the last extract operation (0 if successful).
var last_zip_result: int = 0: get = _get_last_zip_result
# Stores the exit code of the last zip operation (0 if successful).


func _enter_tree() -> void:
	
	_platform = OS.get_name()


func _get_last_extract_result() -> int:
	
	return last_extract_result


func _get_last_zip_result() -> int:
	return last_zip_result
	

func list_dir(path: String, recursive := false) -> Array:
	# Lists the files and subdirectories within a directory.
	
	var result := []
	var dir := DirAccess.open(path)
	dir.include_hidden = true
	var error := DirAccess.get_open_error()
	if error != OK:
		Status.post(tr("msg_list_dir_failed") % [path, error], Enums.MSG_ERROR)
		return result
	
	error = dir.list_dir_begin()
	if error != OK:
		Status.post(tr("msg_list_dir_failed") % [path, error], Enums.MSG_ERROR)
		return result
	
	while true:
		var item = dir.get_next()
		if item:
			result.append(item)
			if recursive and dir.current_is_dir():
				var subdir = list_dir(path.path_join(item), true)
				for child in subdir:
					result.append(item.path_join(child))
		else:
			break
	
	return result


func _copy_dir_internal(abs_path: String, dest_dir: String) -> void:

	var dir = abs_path.get_file()
	
	var error = DirAccess.make_dir_recursive_absolute(dest_dir.path_join(dir))
	if error:
		Status.post(tr("msg_cannot_create_target_dir") % [dest_dir.path_join(dir), error], Enums.MSG_ERROR)
		return
	
	for item in list_dir(abs_path):
		var path = abs_path.path_join(item)
		if FileAccess.file_exists(path):
			error = DirAccess.copy_absolute(path, dest_dir.path_join(dir).path_join(item))
			if error:
				Status.post(tr("msg_copy_file_failed") % [item, error], Enums.MSG_ERROR)
				Status.post(tr("msg_copy_file_failed_details") % [path, dest_dir.path_join(dir).path_join(item)])
		elif DirAccess.dir_exists_absolute(path):
			_copy_dir_internal(path, dest_dir.path_join(dir))
			


func copy_dir(abs_path: String, dest_dir: String) -> void:
	# Recursively copies a directory *into* a new location.
	
	var thread := Thread.new()
	thread.start(_copy_dir_internal.bind(abs_path, dest_dir))
	while thread.is_alive():
		await get_tree().process_frame
	thread.wait_to_finish()
	emit_signal("copy_dir_done")


func _rm_dir_internal(abs_path: String) -> void:
	
	var error
	for item in list_dir(abs_path):
		var path = abs_path.path_join(item)
		if FileAccess.file_exists(path):
			error = DirAccess.remove_absolute(path)
			if error:
				Status.post(tr("msg_remove_file_failed") % [item, error], Enums.MSG_ERROR)
				Status.post(tr("msg_remove_file_failed_details") % path, Enums.MSG_DEBUG)
		elif DirAccess.dir_exists_absolute(path):
			_rm_dir_internal(path)
	
	error = DirAccess.remove_absolute(abs_path)
	if error:
		Status.post(tr("msg_rm_dir_failed") % [abs_path, error], Enums.MSG_ERROR)


func rm_dir(abs_path: String) -> void:
	# Recursively removes a directory.
	
	var thread := Thread.new()
	thread.start(_rm_dir_internal.bind(abs_path))
	while thread.is_alive():
		await get_tree().process_frame
	thread.wait_to_finish()
	emit_signal("rm_dir_done")


func _move_dir_internal(abs_path: String, abs_dest: String) -> void:
	
	var error = DirAccess.make_dir_recursive_absolute(abs_dest)
	if error:
		Status.post(tr("msg_create_dir_failed") % [abs_dest, error], Enums.MSG_ERROR)
		return
	
	for item in list_dir(abs_path):
		var path = abs_path.path_join(item)
		var dest = abs_dest.path_join(item)
		if FileAccess.file_exists(path):
			error = DirAccess.rename_absolute(path, abs_dest.path_join(item))
			if error:
				Status.post(tr("msg_move_file_failed") % [item, error], Enums.MSG_ERROR)
				Status.post(tr("msg_move_file_failed_details") % [path, dest])
		elif DirAccess.dir_exists_absolute(path):
			_move_dir_internal(path, abs_dest.path_join(item))
	
	error = DirAccess.remove_absolute(abs_path)
	if error:
		Status.post(tr("msg_move_rmdir_failed") % [abs_path, error], Enums.MSG_ERROR)


func move_dir(abs_path: String, abs_dest: String) -> void:
	# Moves the specified directory (this is move with rename, so the last
	# part of dest is the new item for the directory).
	
	var thread := Thread.new()
	thread.start(_move_dir_internal.bind(abs_path, abs_dest))
	while thread.is_alive():
		await get_tree().process_frame
	thread.wait_to_finish()
	emit_signal("move_dir_done")


func extract(path: String, dest_dir: String) -> void:
	# Extracts a .zip or .tar.gz archive using the system utilities on Linux
	# and bundled unzip.exe from InfoZip on Windows.
	
	var unzip_exe = Paths.utils_dir.path_join("unzip.exe")
	
	var command_linux_zip = {
		"item": "unzip",
		"args": ["-o", "%s" % path, "-d", "%s" % dest_dir]
	}
	var command_linux_gz = {
		"item": "/bin/bash",
		"args": ["-c", "tar -xzf \"%s\" -C \"%s\" && find \"%s\" -type l -delete" % [path, dest_dir, dest_dir]]
		# Godot can't operate on symlinks, so we have to clean them up with find.
	}
	var command_windows = {
		"item": "cmd",
		"args": ["/C", "\"%s\" -o \"%s\" -d \"%s\"" % [unzip_exe, path, dest_dir]]
	}
	var command
	
	if (_platform == "X11" || _platform == "Linux") and (path.to_lower().ends_with(".tar.gz")):
		command = command_linux_gz
	elif (_platform == "X11" || _platform == "Linux") and (path.to_lower().ends_with(".zip")):
		command = command_linux_zip
	elif (_platform == "Windows") and (path.to_lower().ends_with(".zip")):
		command = command_windows
	else:
		Status.post(tr("msg_extract_unsupported") % path.get_file(), Enums.MSG_ERROR)
		emit_signal("extract_done")
		return
		
	if not DirAccess.dir_exists_absolute(dest_dir):
		DirAccess.make_dir_recursive_absolute(dest_dir)
		
	Status.post(tr("msg_extracting_file") % path.get_file())
	
	ThreadedExec.execute(command["item"], command["args"])
	await ThreadedExec.execution_finished
	if ThreadedExec.last_exit_code != 0:
		Status.post(tr("msg_extract_error") % ThreadedExec.last_exit_code, Enums.MSG_ERROR)
		Status.post(tr("msg_extract_failed_cmd") % str(command), Enums.MSG_DEBUG)
		Status.post(tr("msg_extract_fail_output") % ThreadedExec.output[0], Enums.MSG_DEBUG)
	emit_signal("extract_done")


func zip(parent: String, dir_to_zip: String, dest_zip: String) -> void:
	# Creates a .zip using the system utilities on Linux
	# and bundled zip.exe from InfoZip on Windows.
	# parent: directory that zip command is run from  (Path.savegames)
	# dir_to_zip: relative folder to zip up  (world_name)
	# dest_zip: zip item   (world_name.zip)
	# 
	# runs a command like:
	# cd <userdata/save> && zip -r MyWorld.zip MyWorld
	
	var zip_exe = Paths.utils_dir.path_join("zip.exe")
	
	var command_linux_zip = {
		"item": "/bin/bash",
		"args": ["-c", "cd '%s' && zip -b '%s' -r '%s' '%s'" % [parent, Paths.tmp_dir, dest_zip, dir_to_zip]]
	}
	var command_windows = {
		"item": "cmd",
		"args": ["/C", "cd /d \"%s\" && \"%s\" -b \"%s\" -r \"%s\" \"%s\"" % [parent, zip_exe, Paths.tmp_dir, dest_zip, dir_to_zip]]
	}
	var command
	
	if (_platform == "X11" || _platform == "Linux") and (dest_zip.to_lower().ends_with(".zip")):
		command = command_linux_zip
	elif (_platform == "Windows") and (dest_zip.to_lower().ends_with(".zip")):
		command = command_windows
	else:
		Status.post(tr("msg_extract_unsupported") % dest_zip.get_file(), Enums.MSG_ERROR)
		emit_signal("zip_done")
		return
		
	if not DirAccess.dir_exists_absolute(Paths.tmp_dir):
		DirAccess.make_dir_recursive_absolute(Paths.tmp_dir)
	
	Status.post(tr("msg_zipping_file") % dest_zip.get_file())
	
	ThreadedExec.execute(command["item"], command["args"])
	await ThreadedExec.execution_finished
	if ThreadedExec.last_exit_code != 0:
		Status.post(tr("msg_zip_error") % ThreadedExec.last_exit_code, Enums.MSG_ERROR)
		Status.post(tr("msg_extract_failed_cmd") % str(command), Enums.MSG_DEBUG)
		Status.post(tr("msg_extract_fail_output") % ThreadedExec.last_exit_code, Enums.MSG_DEBUG)
	emit_signal("zip_done")
	
