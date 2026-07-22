extends Node


signal soundpack_installation_started
signal soundpack_installation_finished
signal soundpack_deletion_started
signal soundpack_deletion_finished


const SOUNDPACKS = [
	{
		"name": "CC-Sounds",
		"url": "https://github.com/Fris0uman/CDDA-Soundpacks/releases/latest/download/CC-Sounds.zip",
		"filename": "CC-Sounds.zip",
		"internal_path": "CC-Sounds",
	},
	{
		"name": "CC-Sounds-sfx-only",
		"url": "https://github.com/Fris0uman/CDDA-Soundpacks/releases/latest/download/CC-Sounds-sfx-only.zip",
		"filename": "CC-Sounds-sfx-only.zip",
		"internal_path": "CC-Sounds-sfx-only",
	},
	{
		"name": "CO.AG-music-only",
		"url": "https://github.com/Fris0uman/CDDA-Soundpacks/releases/latest/download/CO.AG-music-only.zip",
		"filename": "CO.AG-music-only.zip",
		"internal_path": "CO.AG-music-only",
	},
	{
		"name": "BeepBoopBip",
		"url": "https://github.com/Golfavel/CDDA-Soundpacks_BeepBoop/archive/refs/heads/master.zip",
		"filename": "BeepBoopBip.zip",
		"internal_path": "CDDA-Soundpacks_BeepBoop-master/sound/BeepBoopBip",
	},
	{
		"name": "@'s soundpack",
		"url": "https://github.com/damalsk/damalsksoundpack/archive/refs/heads/master.zip",
		"filename": "ats-soundpack.zip",
		"internal_path": "damalsksoundpack-master",
	},
	{
		"name": "CDDA-Soundpack",
		"url": "https://github.com/budg3/CDDA-Soundpack/archive/master.zip",
		"filename": "cdda-soundpack.zip",
		"internal_path": "CDDA-Soundpack-master/CDDA-Soundpack",
	},
	{
		"name": "ChestHole",
		"url": "https://web.archive.org/web/20240122133501if_/https://chezzo.com/cdda/ChestHoleSoundSet.zip",
		"filename": "chesthole-soundpack.zip",
		"internal_path": "ChestHole",
	},
	{
		"name": "ChestHoleCC",
		"url": "https://web.archive.org/web/20210401095201if_/http://chezzo.com/cdda/ChestHoleCCSoundset.zip",
		"filename": "chesthole-cc-soundpack.zip",
		"internal_path": "ChestHoleCC",
	},
	{
		"name": "ChestOldTimey",
		"url": "https://web.archive.org/web/20210401095200if_/http://chezzo.com/cdda/ChestOldTimeyLessismore.zip",
		"filename": "chest-old-timey-soundpack.zip",
		"internal_path": "ChestHoleOldTimey",
	},
	{
		"name": "Otopack",
		"url": "https://github.com/Kenan2000/Otopack-Mods-Updates/archive/master.zip",
		"filename": "otopack.zip",
		"internal_path": "Otopack-Mods-Updates-master/Otopack+ModsUpdates",
	},
	{
		"name": "Otopack-BN-Mk-2",
		"url": "https://github.com/NarandBD/Otopack-BN-Mk-2/archive/main.zip",
		"filename": "otopack-bn-mk2.zip",
		"internal_path": "Otopack-BN-Mk-2-main/Otopack+ModsUpdates BN",
	},
	{
		"name": "RRFSounds",
		"url": "https://dl.dropboxusercontent.com/s/d8dfmb2facvkdh6/RRFSounds.zip",
		"filename": "rrfsounds.zip",
		"internal_path": "data/sound/RRFSounds",
	},
]


func parse_sound_dir(sound_dir: String) -> Array:
	
	if not DirAccess.dir_exists_absolute(sound_dir):
		Status.post(tr("msg_no_sound_dir") % sound_dir, Enums.MSG_ERROR)
		return []
	
	var result = []
	
	for subdir in FS.list_dir(sound_dir):
		var info = sound_dir.path_join(subdir).path_join("soundpack.txt")
		if FileAccess.file_exists(info):
			var f := FileAccess.open(info, FileAccess.READ)
			var lines = f.get_as_text().split("\n", false)
			var pack_name = ""
			var pack_desc = ""
			for line in lines:
				if line.begins_with("VIEW: "):
					pack_name = line.trim_prefix("VIEW: ")
				elif line.begins_with("DESCRIPTION: "):
					pack_desc = line.trim_prefix("DESCRIPTION: ")
			var item = {}
			item["name"] = pack_name
			item["description"] = pack_desc
			item["location"] = sound_dir.path_join(subdir)
			result.append(item)
			f.close()
		
	return result


func get_installed(include_stock = false) -> Array:
	
	var packs = []
	
	if DirAccess.dir_exists_absolute(Paths.sound_user):
		packs.append_array(parse_sound_dir(Paths.sound_user))
		for pack in packs:
			pack["is_stock"] = false
	
	if include_stock:
		var stock = parse_sound_dir(Paths.sound_stock)
		for pack in stock:
			pack["is_stock"] = true
		packs.append_array(stock)
		
	return packs


func delete_pack(pack_name: String) -> void:
	
	for pack in get_installed():
		if pack["name"] == pack_name:
			emit_signal("soundpack_deletion_started")
			Status.post(tr("msg_deleting_sound") % pack["location"])
			FS.rm_dir(pack["location"])
			await FS.rm_dir_done
			emit_signal("soundpack_deletion_finished")
			return
			
	Status.post(tr("msg_soundpack_not_found") % pack_name, Enums.MSG_ERROR)


func install_pack(soundpack_index: int, from_file = null, reinstall = false, keep_archive = false) -> void:
	
	var pack = SOUNDPACKS[soundpack_index]
	var sound_dir = Paths.sound_user
	var tmp_dir = Paths.tmp_dir.path_join(pack["name"])
	var archive = ""
	
	emit_signal("soundpack_installation_started")
	
	if reinstall:
		Status.post(tr("msg_reinstalling_sound") % pack["name"])
	else:
		Status.post(tr("msg_installing_sound") % pack["name"])
	
	if from_file:
		archive = from_file
	else:
		archive = Paths.cache_dir.path_join(pack["filename"])
		if Settings.read("ignore_cache") or not FileAccess.file_exists(archive):
			Downloader.download_file(pack["url"], Paths.cache_dir, pack["filename"])
			await Downloader.download_finished
		if not FileAccess.file_exists(archive):
			Status.post(tr("msg_sound_download_failed"), Enums.MSG_ERROR)
			emit_signal("soundpack_installation_finished")
			return
		
	if reinstall:
		FS.rm_dir(sound_dir + "/" + pack["name"])
		await FS.rm_dir_done
		
	FS.extract(archive, tmp_dir)
	await FS.extract_done
	if not keep_archive and not Settings.read("keep_cache"):
		DirAccess.remove_absolute(archive)
	FS.move_dir(tmp_dir + "/" + pack["internal_path"], sound_dir + "/" + pack["name"])
	await FS.move_dir_done
	FS.rm_dir(tmp_dir)
	await FS.rm_dir_done
	
	Status.post(tr("msg_sound_installed"))
	emit_signal("soundpack_installation_finished")
