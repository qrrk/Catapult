class_name GameLauncher
extends RefCounted
## Launches the active Cataclysm installation (new game or resume last world).


static func has_last_world() -> bool:
	return FileAccess.file_exists(Paths.config.path_join("lastworld.json"))


static func resume_last_world() -> bool:
	var lastworld: String = Paths.config.path_join("lastworld.json")
	var info: Variant = Helpers.load_json_file(lastworld)
	if info is Dictionary and info.get("world_name") is String:
		return launch(info["world_name"] as String)
	return false


static func launch(world: String = "") -> bool:
	match OS.get_name():
		"Linux":
			var params := ["--userdir", Paths.userdata + "/"]
			if not world.is_empty():
				params.append_array(["--world", world])
			OS.create_process(Paths.game_dir.path_join("cataclysm-launcher"), params, false)
			return true
		"Windows":
			var world_str := ""
			if not world.is_empty():
				world_str = "--world \"%s\"" % world
			
			var matches := FS.list_dir(Paths.game_dir, false, "(?i).*cataclysm.*\\.exe$")
			Status.post(str(matches), Enums.MSG_DEBUG)
			if matches.is_empty():
				return false
			var exe_file: String = matches[0]
			
			var command := "cd /d %s && start %s --userdir \"%s/\" %s" % [Paths.game_dir, exe_file, Paths.userdata, world_str]
			OS.execute_with_pipe("cmd", ["/C", command])
			return true
		_:
			return false
