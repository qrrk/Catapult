class_name GameLauncher
extends Node
## Launches the active Cataclysm installation (new game or resume last world)
## and polls spawned game processes until they exit.


var _running_pids: Array[int] = []

@onready var _poll_timer: Timer = $PollTimer


## Returns true if lastworld.json exists in the active game's config directory.
func has_last_world() -> bool:
	return FileAccess.file_exists(Paths.config.path_join("lastworld.json"))


## Reads lastworld.json and launches directly into the last played world, returning true if started.
func resume_last_world() -> bool:
	var lastworld: String = Paths.config.path_join("lastworld.json")
	var info: Variant = Helpers.load_json_file(lastworld)
	if info is Dictionary and info.get("world_name") is String:
		return launch(info["world_name"] as String)
	return false


## Spawns the active game executable with [code]--userdir[/code] (and optional [code]--world[/code]),
## returning true if the process was started.
func launch(world: String = "") -> bool:
	var params := ["--userdir", Paths.userdata + "/"]
	if not world.is_empty():
		params.append_array(["--world", world])
	
	var exe_path := ""
	match OS.get_name():
		"Linux":
			exe_path = Paths.game_dir.path_join("cataclysm-launcher")
		"Windows":
			var matches := FS.list_dir(Paths.game_dir, false, "(?i).*cataclysm.*\\.exe$")
			Status.post(str(matches), Enums.MSG_DEBUG)
			if matches.is_empty():
				return false
			exe_path = Paths.game_dir.path_join(matches[0])
			params.append_array(["--basepath", Paths.game_dir + "/"])
		_:
			return false
	
	var pid := OS.create_process(exe_path, params, false)
	if pid == -1:
		return false
	_track_pid(pid)
	return true


func _track_pid(pid: int) -> void:
	_running_pids.append(pid)
	if _poll_timer.is_stopped():
		_poll_timer.start()


func _on_poll_timer_timeout() -> void:
	var still_running: Array[int] = []
	for pid in _running_pids:
		if OS.is_process_running(pid):
			still_running.append(pid)
	_running_pids = still_running
	if _running_pids.is_empty():
		_poll_timer.stop()
