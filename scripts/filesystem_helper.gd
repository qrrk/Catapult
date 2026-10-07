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
	

func list_dir(path: String, recursive := false, filter_pattern: String = "") -> Array:
	# Lists the files and subdirectories within a directory.
	# Optionally filters results using a regex pattern string matched against full relative paths.
	
	var result := []
	var filter_regex: RegEx = null
	
	if filter_pattern != "":
		filter_regex = RegEx.new()
		var compile_error = filter_regex.compile(filter_pattern)
		if compile_error != OK:
			Status.post(tr("msg_list_dir_failed") % [path, compile_error], Enums.MSG_ERROR)
			return result
	
	var stack: Array[String]
	stack.append("")
	
	while stack.size() > 0:
		var current_rel: String = stack.pop_back()
		var current_abs: String = path.path_join(current_rel) if current_rel != "" else path
		
		var dir := DirAccess.open(current_abs)
		if dir == null:
			var open_error := DirAccess.get_open_error()
			Status.post(tr("msg_list_dir_failed") % [current_abs, open_error], Enums.MSG_ERROR)
			continue
		
		dir.include_hidden = true
		var error := dir.list_dir_begin()
		if error != OK:
			Status.post(tr("msg_list_dir_failed") % [current_abs, error], Enums.MSG_ERROR)
			continue
		
		while true:
			var item: String = dir.get_next()
			if item == "":
				break
			
			var item_rel_path = current_rel.path_join(item) if current_rel != "" else item

			if (filter_regex == null) or (filter_regex.search(item_rel_path) != null):
				result.append(item_rel_path)
			
			if recursive and dir.current_is_dir():
				stack.append(item_rel_path)
		
		dir.list_dir_end()
	
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


func _extract_zip_internal(archive_path: String, dest_dir: String) -> int:
	var reader := ZIPReader.new()
	var err := reader.open(archive_path)
	if err != OK:
		return err
	
	var files := reader.get_files()
	for file_path in files:
		var norm_path: String = (file_path as String).replace("\\", "/")
		if norm_path.ends_with("/"):
			var dir_err = DirAccess.make_dir_recursive_absolute(dest_dir.path_join(norm_path))
			if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
				reader.close()
				return dir_err
		else:
			var target_file_path := dest_dir.path_join(norm_path)
			var dir_err = DirAccess.make_dir_recursive_absolute(target_file_path.get_base_dir())
			if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
				reader.close()
				return dir_err
			
			var buffer := reader.read_file(file_path)
			var fa := FileAccess.open(target_file_path, FileAccess.WRITE)
			if fa == null:
				var open_err = FileAccess.get_open_error()
				reader.close()
				return open_err
			fa.store_buffer(buffer)
			fa.close()
	
	reader.close()
	return OK


func extract(path: String, dest_dir: String) -> void:
	# Extracts a .zip archive natively using Godot's ZIPReader,
	# or a .tar.gz archive using system tar on Linux.
	
	if not DirAccess.dir_exists_absolute(dest_dir):
		DirAccess.make_dir_recursive_absolute(dest_dir)
	
	if (_platform == "X11" || _platform == "Linux") and (path.to_lower().ends_with(".tar.gz")):
		var command_linux_gz = {
			"item": "/bin/bash",
			"args": ["-c", "tar -xzf \"%s\" -C \"%s\" && find \"%s\" -type l -delete" % [path, dest_dir, dest_dir]]
			# Godot can't operate on symlinks, so we have to clean them up with find.
		}
		Status.post(tr("msg_extracting_file") % path.get_file())
		ThreadedExec.execute(command_linux_gz["item"], command_linux_gz["args"])
		await ThreadedExec.execution_finished
		last_extract_result = ThreadedExec.last_exit_code
		if last_extract_result != 0:
			Status.post(tr("msg_extract_error") % last_extract_result, Enums.MSG_ERROR)
			Status.post(tr("msg_extract_failed_cmd") % str(command_linux_gz), Enums.MSG_DEBUG)
			Status.post(tr("msg_extract_fail_output") % ThreadedExec.output[0], Enums.MSG_DEBUG)
		emit_signal("extract_done")
		return
	
	if path.to_lower().ends_with(".zip"):
		Status.post(tr("msg_extracting_file") % path.get_file())
		var thread := Thread.new()
		thread.start(_extract_zip_internal.bind(path, dest_dir))
		while thread.is_alive():
			await get_tree().process_frame
		last_extract_result = thread.wait_to_finish()
		if last_extract_result != OK:
			Status.post(tr("msg_extract_error") % last_extract_result, Enums.MSG_ERROR)
		emit_signal("extract_done")
		return
	
	Status.post(tr("msg_extract_unsupported") % path.get_file(), Enums.MSG_ERROR)
	last_extract_result = ERR_FILE_UNRECOGNIZED
	emit_signal("extract_done")


func _zip_dir_internal(parent: String, dir_to_zip: String, dest_zip: String) -> int:
	var packer := ZIPPacker.new()
	var err := packer.open(dest_zip)
	if err != OK:
		return err
	
	var source_root := parent.path_join(dir_to_zip)
	
	packer.start_file(dir_to_zip.replace("\\", "/") + "/")
	packer.close_file()
	
	for rel_path in list_dir(source_root, true):
		var abs_path: String = source_root.path_join(rel_path)
		var norm_rel: String = (rel_path as String).replace("\\", "/")
		var entry_name: String = dir_to_zip.replace("\\", "/").path_join(norm_rel)
		
		if DirAccess.dir_exists_absolute(abs_path):
			packer.start_file(entry_name + "/")
			packer.close_file()
		elif FileAccess.file_exists(abs_path):
			var fa := FileAccess.open(abs_path, FileAccess.READ)
			if fa == null:
				packer.close()
				return FileAccess.get_open_error()
			var data := fa.get_buffer(fa.get_length())
			fa.close()
			packer.start_file(entry_name)
			packer.write_file(data)
			packer.close_file()
	
	packer.close()
	return OK


func zip(parent: String, dir_to_zip: String, dest_zip: String) -> void:
	# Creates a .zip archive natively using Godot's ZIPPacker.
	# parent: directory that contains dir_to_zip (e.g. Paths.savegames)
	# dir_to_zip: relative folder to zip up (e.g. world_name)
	# dest_zip: full path to destination zip file
	
	if not dest_zip.to_lower().ends_with(".zip"):
		Status.post(tr("msg_extract_unsupported") % dest_zip.get_file(), Enums.MSG_ERROR)
		last_zip_result = ERR_FILE_UNRECOGNIZED
		emit_signal("zip_done")
		return
	
	var dest_parent := dest_zip.get_base_dir()
	if not DirAccess.dir_exists_absolute(dest_parent):
		DirAccess.make_dir_recursive_absolute(dest_parent)
	
	Status.post(tr("msg_zipping_file") % dest_zip.get_file())
	
	var thread := Thread.new()
	thread.start(_zip_dir_internal.bind(parent, dir_to_zip, dest_zip))
	while thread.is_alive():
		await get_tree().process_frame
	last_zip_result = thread.wait_to_finish()
	if last_zip_result != OK:
		Status.post(tr("msg_zip_error") % last_zip_result, Enums.MSG_ERROR)
	emit_signal("zip_done")
	
