extends Node


signal operation_started
signal operation_finished


func install_release(release_info: Dictionary, update_in: String = "") -> void:
	
	emit_signal("operation_started")
	
	if update_in:
		Status.post(tr("msg_updating_game") % release_info["name"])
	else:
		Status.post(tr("msg_installing_game") % release_info["name"])
	
	var archive: String = Paths.cache_dir.path_join(release_info["filename"])
	
	if Settings.read("ignore_cache") or not FileAccess.file_exists(archive):
		Downloader.download_file(release_info["url"], Paths.cache_dir, release_info["filename"])
		await Downloader.download_finished
	
	if FileAccess.file_exists(archive):
		
		FS.extract(archive, Paths.tmp_dir)
		await FS.extract_done
		if not Settings.read("keep_cache"):
			DirAccess.remove_absolute(archive)
		
		if FS.last_extract_result == 0:
		
			var extracted_root
			match OS.get_name():
				"X11":
					extracted_root = Paths.tmp_dir.path_join(FS.list_dir(Paths.tmp_dir)[0])
				"Linux":
					extracted_root = Paths.tmp_dir.path_join(FS.list_dir(Paths.tmp_dir)[0])
				"Windows":
					extracted_root = Paths.tmp_dir
			
			Helpers.create_info_file(extracted_root, release_info["name"])
			
			var target_dir: String
			if update_in:
				target_dir = update_in
				FS.rm_dir(target_dir)
				await FS.rm_dir_done
			else:
				target_dir = Paths.next_install_dir
			
			FS.move_dir(extracted_root, target_dir)
			await FS.move_dir_done
			
			if update_in:
				Settings.store("active_install_" + Settings.read("game"), release_info["name"])
				Status.post(tr("msg_game_updated"))
			else:
				Status.post(tr("msg_game_installed"))
	
	emit_signal("operation_finished")


func remove_release_by_name(release_name: String) -> void:
	
	emit_signal("operation_started")
	
	var installs := Paths.installs_summary
	var game = Settings.read("game")
	
	if (game in installs) and (release_name in installs[game]):
		Status.post(tr("msg_deleting_game") % release_name)
		var location = installs[game][release_name]
		FS.rm_dir(location)
		await FS.rm_dir_done
		Status.post(tr("msg_game_deleted"))
	else:
		Status.post(tr("msg_delete_not_found") % release_name, Enums.MSG_ERROR)
	
	emit_signal("operation_finished")
