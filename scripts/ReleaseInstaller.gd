extends Node


signal operation_started
signal operation_finished


func install_release(release_info: Dictionary, game: String, update_in: String = "") -> void:
	
	emit_signal("operation_started")
	
	if update_in:
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
			
			Helpers.create_info_file(extracted_root, release_info["name"])
			
			var target_dir: String
			if update_in:
				target_dir = update_in
				FS.rm_dir(target_dir)
				yield(FS, "rm_dir_done")
			else:
				target_dir = Paths.next_install_dir
			
			FS.move_dir(extracted_root, target_dir)
			yield(FS, "move_dir_done")
			
			if update_in:
				Settings.store("active_install_" + Settings.read("game"), release_info["name"])
				Status.post(tr("msg_game_updated"))
			else:
				Status.post(tr("msg_game_installed"))
	
	emit_signal("operation_finished")


func remove_release_by_name(name: String) -> void:
	
	emit_signal("operation_started")
	
	var installs := Paths.installs_summary
	var game = Settings.read("game")
	
	if (game in installs) and (name in installs[game]):
		Status.post("Removing %s..." % name)
		var location = installs[game][name]
		FS.rm_dir(location)
		yield(FS, "rm_dir_done")
		Status.post("Removal finished.")
	else:
		Status.post("Attempted to remove release \"%s\", but could not find it on disk." % name, Enums.MSG_ERROR)
	
	emit_signal("operation_finished")
