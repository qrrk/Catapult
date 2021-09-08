extends Node


signal status_message
signal copy_dir_done
signal rm_dir_done
signal move_dir_done
signal extract_done


var _platform = ""


func _enter_tree() -> void:
	
	_platform = OS.get_name()


func get_own_dir() -> String:
	# Returns the absolute path to the directory with the executable.
	
	return OS.get_executable_path().get_base_dir()


func list_dir(path: String, recursive := false) -> Array:
	# Lists the files and subdirectories within a directory.
	
	var d = Directory.new()
	d.open(path)
	d.list_dir_begin(true)
	var result = []
	
	while true:
		var name = d.get_next()
		if name:
			result.append(name)
			if recursive and d.current_is_dir():
				var subdir = list_dir(path.plus_file(name), true)
				for child in subdir:
					result.append(name.plus_file(child))
		else:
			break
	
	return result


func _copy_dir_internal(data: Array) -> void:
	
	var abs_path: String = data[0]
	var dest_dir: String = data[1]
	var update_only: bool = data[2]
	
	var dir = abs_path.get_file()
	var d = Directory.new()
	d.make_dir_recursive(dest_dir.plus_file(dir))
	
	for item in list_dir(abs_path):
		var path = abs_path.plus_file(item)
		if d.file_exists(path):
			d.copy(path, dest_dir.plus_file(dir).plus_file(item))
		elif d.dir_exists(path):
			_copy_dir_internal([path, dest_dir.plus_file(dir), update_only])


func copy_dir(abs_path: String, dest_dir: String, update_only := false) -> void:
	# Recursively copies a directory *into* a new location.
	
	var tfe = ThreadedFuncExecutor.new()
	tfe.execute(self, "_copy_dir_internal", [abs_path, dest_dir, update_only])
	yield(tfe, "func_returned")
	tfe.collect()
	emit_signal("copy_dir_done")


func _rm_dir_internal(data: Array) -> void:
	
	var abs_path = data[0]
	var d = Directory.new()
	for item in list_dir(abs_path):
		var path = abs_path.plus_file(item)
		if d.file_exists(path):
			d.remove(path)
		elif d.dir_exists(path):
			_rm_dir_internal([path])
	
	d.remove(abs_path)


func rm_dir(abs_path: String) -> void:
	# Recursively removes a directory.
	
	var tfe = ThreadedFuncExecutor.new()
	tfe.execute(self, "_rm_dir_internal", [abs_path])
	yield(tfe, "func_returned")
	tfe.collect()
	emit_signal("rm_dir_done")


func _move_dir_internal(data: Array) -> void:
	
	var abs_path: String = data[0]
	var abs_dest: String = data[1]
	
	var d = Directory.new()
	d.make_dir_recursive(abs_dest)
	
	for item in list_dir(abs_path):
		var path = abs_path.plus_file(item)
		if d.file_exists(path):
			d.rename(path, abs_dest.plus_file(item))
		elif d.dir_exists(path):
			_move_dir_internal([path, abs_dest.plus_file(item)])
	
	d.remove(abs_path)


func move_dir(abs_path: String, abs_dest: String) -> void:
	# Moves the specified directory (this is move with rename, so the last
	# part of dest is the new name for the directory).
	
	var tfe = ThreadedFuncExecutor.new()
	tfe.execute(self, "_move_dir_internal", [abs_path, abs_dest])
	yield(tfe, "func_returned")
	tfe.collect()
	emit_signal("move_dir_done")


func extract(path: String, dest_dir: String) -> void:
	# Extracts a .zip or .tar.gz archive using the system utilities.
	
	var command_linux_zip = {
		"name": "unzip",
		"args": ["-o", "\"\"%s\"\"" % path, "-d", "\"\"%s\"\"" % dest_dir]
	}
	var command_linux_gz = {
		"name": "tar",
		"args": ["-xzf", "\"\"%s\"\"" % path, "-C", "\"\"%s\"\"" % dest_dir,
				"--exclude=*doc/CONTRIBUTING.md", "--exclude=*doc/JSON_LOADING_ORDER.md"]
				# Godot can't operate on symlinks just yet, so we have to avoid them.
	}
	var command_windows = {
		"name": "powershell",
		"args": ["-NoP", "-NonI", "-Command",
				 "\"Expand-Archive -Force '%s' '%s'\"" % [path, dest_dir]]
	}
	var command
	
	if (_platform == "X11") and (path.to_lower().ends_with(".tar.gz")):
		command = command_linux_gz
	elif (_platform == "X11") and (path.to_lower().ends_with(".zip")):
		command = command_linux_zip
	elif (_platform == "Windows") and (path.to_lower().ends_with(".zip")):
		command = command_windows
	else:
		emit_signal("status_message", "Unsupported platform or archive format (file: %s)" % path.get_file(), Enums.MSG_ERROR)
		emit_signal("extract_done")
		return
		
	var d = Directory.new()
	if not d.dir_exists(dest_dir):
		d.make_dir_recursive(dest_dir)
		
	emit_signal("status_message", "Extracting %s..." % path.get_file())
		
	var oew = OSExecWrapper.new()
	oew.execute(command["name"], command["args"])
	yield(oew, "process_exited")
	if oew.exit_code:
		emit_signal("status_message", "extract: Command exited with an error (exit code: %s)" % oew.exit_code, Enums.MSG_ERROR)
		emit_signal("status_message", "Failed command: " + str(command), Enums.MSG_DEBUG)
		emit_signal("status_message", "Output: " + oew.output[0], Enums.MSG_DEBUG)
	emit_signal("extract_done")

# if you're on Windows 7 or 10 with powershell you can use: powershell.exe -NoP -NonI -Command "Expand-Archive '.\file.zip' '.\unziped\'" – AK_ Mar 17 '18 at 21:11
# powershell -NoP -NonI -Command "Expand-Archive -Force 'test.zip' 'asdf'"

