extends Node


signal status_message
signal soundpack_installation_started
signal soundpack_installation_finished
signal soundpack_deletion_started
signal soundpack_deletion_finished


const SOUNDPACKS = [
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


onready var _settings = $"/root/SettingsManager"
onready var _fshelper = $"../FSHelper"
onready var _downloader = $"../Downloader"
onready var _workdir = OS.get_executable_path().get_base_dir()


func parse_sound_dir(sound_dir: String) -> Array:
	
	if not Directory.new().dir_exists(sound_dir):
		emit_signal("status_message", "Sound directory does not exist: %s" \
				% sound_dir, Enums.MSG_ERROR)
		return []
	
	var result = []
	
	for subdir in _fshelper.list_dir(sound_dir):
		var f = File.new()
		var info = sound_dir + "/" + subdir + "/soundpack.txt"
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
			item["location"] = sound_dir + "/" + subdir
			result.append(item)
			f.close()
		
	return result


func get_installed(include_stock = false) -> Array:
	
	var gamedir = _workdir + "/" + _settings.read("game") + "/current"
	var packs = []
	
	if Directory.new().dir_exists(gamedir + "/sound"):
		packs.append_array(parse_sound_dir(gamedir + "/sound"))
		for pack in packs:
			pack["is_stock"] = false
	
	if include_stock:
		var stock = parse_sound_dir(gamedir + "/data/sound")
		for pack in stock:
			pack["is_stock"] = true
		packs.append_array(stock)
		
	return packs


func delete_pack(name: String) -> void:
	
	for pack in get_installed():
		if pack["name"] == name:
			emit_signal("soundpack_deletion_started")
			emit_signal("status_message", "Deleting %s" % pack["location"])
			_fshelper.rm_dir(pack["location"])
			yield(_fshelper, "rm_dir_done")
			emit_signal("soundpack_deletion_finished")
			return
			
	emit_signal("status_message", "Could not find soundpack named \"%s\"" % name, Enums.MSG_ERROR)


func install_pack(soundpack_index: int, from_file = null, reinstall = false, keep_archive = false) -> void:
	
	var pack = SOUNDPACKS[soundpack_index]
	var game = _settings.read("game")
	var sound_dir = _workdir + "/" + game + "/current/sound"
	var tmp_dir = _workdir + "/" + game + "/tmp/" + pack["name"]
	var archive = ""
			
	emit_signal("soundpack_installation_started")
	
	if reinstall:
		emit_signal("status_message", "Reinstalling soundpack \"%s\"..." % pack["name"])
	else:
		emit_signal("status_message", "Installing soundpack \"%s\"..." % pack["name"])
	
	if from_file:
		archive = from_file
	else:
		_downloader.download_file(pack["url"], _workdir, pack["filename"])
		yield(_downloader, "download_finished")
		archive = _workdir + "/" + pack["filename"]
		if not Directory.new().file_exists(archive):
			emit_signal("status_message", "Could not download soundpack archive.", Enums.MSG_ERROR)
			emit_signal("soundpack_installation_finished")
			return
		
	if reinstall:
		_fshelper.rm_dir(sound_dir + "/" + pack["name"])
		yield(_fshelper, "rm_dir_done")
		
	_fshelper.extract(archive, tmp_dir)
	yield(_fshelper, "extract_done")
	if not keep_archive:
		Directory.new().remove(archive)
	_fshelper.move_dir(tmp_dir + "/" + pack["internal_path"], sound_dir + "/" + pack["name"])
	yield(_fshelper, "move_dir_done")
	_fshelper.rm_dir(tmp_dir)
	yield(_fshelper, "rm_dir_done")
	
	emit_signal("status_message", "Soundpack installed.")
	emit_signal("soundpack_installation_finished")
