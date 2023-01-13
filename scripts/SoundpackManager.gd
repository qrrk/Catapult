extends Node


signal soundpack_installation_started
signal soundpack_installation_finished
signal soundpack_deletion_started
signal soundpack_deletion_finished


const SOUNDPACKS = [
	{
		"name": "CC-Sounds",
		"url": "https://github.com/Fris0uman/CDDA-Soundpacks/releases/download/2022-08-23/CC-Sounds.zip",
		"filename": "CC-Sounds.zip",
		"internal_path": "CC-Sounds",
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
		"url": "http://chezzo.com/cdda/ChestHoleSoundSet.zip",
		"filename": "chesthole-soundpack.zip",
		"internal_path": "ChestHole",
	},
	{
		"name": "ChestHoleCC",
		"url": "http://chezzo.com/cdda/ChestHoleCCSoundset.zip",
		"filename": "chesthole-cc-soundpack.zip",
		"internal_path": "ChestHoleCC",
	},
	{
		"name": "ChestOldTimey",
		"url": "http://chezzo.com/cdda/ChestOldTimeyLessismore.zip",
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
		"name": "RRFSounds",
		"url": "https://www.dropbox.com/s/d8dfmb2facvkdh6/RRFSounds.zip",
		"filename": "rrfsounds.zip",
		"internal_path": "data/sound/RRFSounds",
		"manual_download": true,
	},
]


func parse_sound_dir(sound_dir: String) -> Array:
	
	if not Directory.new().dir_exists(sound_dir):
		Status.post(tr("msg_no_sound_dir") % sound_dir, Enums.MSG_ERROR)
		return []
	
	var result = []
	
	for subdir in FS.list_dir(sound_dir):
		var f = File.new()
		var info = sound_dir.plus_file(subdir).plus_file("soundpack.txt")
		if f.file_exists(info):
			f.open(info, File.READ)
			var lines = f.get_as_text().split("\n", false)
			var name = ""
			var desc = ""
			for line in lines:
				if line.begins_with("VIEW: "):
					name = line.trim_prefix("VIEW: ")
				elif line.begins_with("DESCRIPTION: "):
					desc = line.trim_prefix("DESCRIPTION: ")
			var item = {}
			item["name"] = name
			item["description"] = desc
			item["location"] = sound_dir.plus_file(subdir)
			result.append(item)
			f.close()
		
	return result


func get_installed(include_stock = false) -> Array:
	
	var packs = []
	
	if Directory.new().dir_exists(Paths.sound_user):
		packs.append_array(parse_sound_dir(Paths.sound_user))
		for pack in packs:
			pack["is_stock"] = false
	
	if include_stock:
		var stock = parse_sound_dir(Paths.sound_stock)
		for pack in stock:
			pack["is_stock"] = true
		packs.append_array(stock)
		
	return packs


func delete_pack(name: String) -> void:
	
	for pack in get_installed():
		if pack["name"] == name:
			emit_signal("soundpack_deletion_started")
			Status.post(tr("msg_deleting_sound") % pack["location"])
			FS.rm_dir(pack["location"])
			yield(FS, "rm_dir_done")
			emit_signal("soundpack_deletion_finished")
			return
			
	Status.post(tr("msg_soundpack_not_found") % name, Enums.MSG_ERROR)


func install_pack(soundpack_index: int, from_file = null, reinstall = false, keep_archive = false) -> void:
	
	var pack = SOUNDPACKS[soundpack_index]
	var game = Settings.read("game")
	var sound_dir = Paths.sound_user
	var tmp_dir = Paths.tmp_dir.plus_file(pack["name"])
	var archive = ""
	
	emit_signal("soundpack_installation_started")
	
	if reinstall:
		Status.post(tr("msg_reinstalling_sound") % pack["name"])
	else:
		Status.post(tr("msg_installing_sound") % pack["name"])
	
	if from_file:
		archive = from_file
	else:
		Downloader.download_file(pack["url"], Paths.own_dir, pack["filename"])
		yield(Downloader, "download_finished")
		archive = Paths.own_dir.plus_file(pack["filename"])
		if not Directory.new().file_exists(archive):
			Status.post(tr("msg_sound_download_failed"), Enums.MSG_ERROR)
			emit_signal("soundpack_installation_finished")
			return
		
	if reinstall:
		FS.rm_dir(sound_dir + "/" + pack["name"])
		yield(FS, "rm_dir_done")
		
	FS.extract(archive, tmp_dir)
	yield(FS, "extract_done")
	if not keep_archive:
		Directory.new().remove(archive)
	FS.move_dir(tmp_dir + "/" + pack["internal_path"], sound_dir + "/" + pack["name"])
	yield(FS, "move_dir_done")
	FS.rm_dir(tmp_dir)
	yield(FS, "rm_dir_done")
	
	Status.post(tr("msg_sound_installed"))
	emit_signal("soundpack_installation_finished")
