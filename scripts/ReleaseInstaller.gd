extends Node


signal installation_started
signal installation_finished

onready var _probe := $"../InstallProbe"


func install_release(release_info: Dictionary, game: String, update: bool = false) -> void:
	
	emit_signal("installation_started")
	
	if update:
		Status.post(tr("msg_updating_game") % release_info["name"])
	else:
		Status.post(tr("msg_installing_game") % release_info["name"])
	
	Downloader.download_file(release_info["url"], Paths.own_dir, release_info["filename"])
	yield(Downloader, "download_finished")
	
	var archive: String = Paths.own_dir.plus_file(release_info["filename"])
	if Directory.new().file_exists(archive):
		
		FS.extract(archive, Paths.tmp_dir)
		yield(FS, "extract_done")
		Directory.new().remove(archive)
		
		if FS.last_extract_result == 0:
		
			var extracted_root
			match OS.get_name():
				"X11":
					extracted_root = Paths.tmp_dir.plus_file(FS.list_dir(Paths.tmp_dir)[0])
				"Windows":
					extracted_root = Paths.tmp_dir
			
			_probe.create_info_file(extracted_root, release_info["name"])
			
			if update:
				FS.rm_dir(Paths.game_dir)
				yield(FS, "rm_dir_done")
			
			FS.move_dir(extracted_root, Paths.game_dir)
			yield(FS, "move_dir_done")
			
			if update:
				Status.post(tr("msg_game_updated"))
			else:
				Status.post(tr("msg_game_installed"))
	
	emit_signal("installation_finished")
