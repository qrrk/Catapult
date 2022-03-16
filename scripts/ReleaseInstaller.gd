extends Node


signal installation_started
signal installation_finished

onready var _downloader := $"../Downloader"
onready var _fshelper := $"../FSHelper"
onready var _probe := $"../InstallProbe"


func install_release(release_info: Dictionary, game: String, update: bool = false) -> void:
	
	emit_signal("installation_started")
	
	if update:
		Status.post(tr("msg_updating_game") % release_info["name"])
	else:
		Status.post(tr("msg_installing_game") % release_info["name"])
	
	_downloader.download_file(release_info["url"], Paths.own_dir, release_info["filename"])
	yield(_downloader, "download_finished")
	
	var archive: String = Paths.own_dir.plus_file(release_info["filename"])
	if Directory.new().file_exists(archive):
		
		_fshelper.extract(archive, Paths.tmp_dir)
		yield(_fshelper, "extract_done")
		Directory.new().remove(archive)
		
		if _fshelper.last_extract_result == 0:
		
			var extracted_root
			match OS.get_name():
				"X11":
					extracted_root = Paths.tmp_dir.plus_file(_fshelper.list_dir(Paths.tmp_dir)[0])
				"Windows":
					extracted_root = Paths.tmp_dir
			
			_probe.create_info_file(extracted_root, release_info["name"])
			
			if update:
				_fshelper.rm_dir(Paths.game_dir)
				yield(_fshelper, "rm_dir_done")
			
			_fshelper.move_dir(extracted_root, Paths.game_dir)
			yield(_fshelper, "move_dir_done")
			
			if update:
				Status.post(tr("msg_game_updated"))
			else:
				Status.post(tr("msg_game_installed"))
	
	emit_signal("installation_finished")
