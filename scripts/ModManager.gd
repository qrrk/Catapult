extends Node


signal status_message
signal mod_installation_started
signal mod_installation_finished
signal mod_deletion_started
signal mod_deletion_finished
signal modpack_retrieval_started
signal modpack_retrieval_finished

signal _done_installing_mod
signal _done_deleting_mod


const _MODPACKS = {
	"kenan-dda": {
		"name": "CDDA Kenan Modpack",
		"url": "https://github.com/Kenan2000/CDDA-Kenan-Modpack/archive/refs/heads/master.zip",
		"filename": "CDDA-Kenan-Modpack-master.zip",
		"internal_path": "CDDA-Kenan-Modpack-master/Kenan-Modpack"
	},
	"kenan-bn": {
		"name": "BN Kenan Modpack",
		"url": "https://github.com/Kenan2000/Bright-Nights-Kenan-Mod-Pack/archive/refs/heads/master.zip",
		"filename": "Bright-Nights-Kenan-Mod-Pack-master.zip",
		"internal_path": "Bright-Nights-Kenan-Mod-Pack-master/Kenan-BrightNights-Modpack"
	}
}

onready var _settings = $"/root/SettingsManager"
onready var _fshelper = $"../FSHelper"
onready var _downloader = $"../Downloader"
onready var _workdir = OS.get_executable_path().get_base_dir()


var installed: Dictionary = {} setget , _get_installed
var available: Dictionary = {} setget , _get_available


func _get_installed() -> Dictionary:
	
	if len(installed) == 0:
		refresh_installed()
		
	return installed


func _get_available() -> Dictionary:
	
	if len(available) == 0:
		refresh_available()
	
	return available


func parse_mods_dir(mods_dir: String) -> Dictionary:
	
	if not Directory.new().dir_exists(mods_dir):
		return {}
		
	var result = {}
	
	for subdir in _fshelper.list_dir(mods_dir):
		var f = File.new()
		var modinfo = mods_dir + "/" + subdir + "/modinfo.json"
		
		if f.file_exists(modinfo):
			
			f.open(modinfo, File.READ)
			var json = JSON.parse(f.get_as_text())
			if json.error != OK:
				emit_signal("status_message", "Could not parse %s" % modinfo, Enums.MSG_ERROR)
				continue
			
			var json_result = json.result
			if typeof(json_result) == TYPE_DICTIONARY:
				json_result = [json_result]
			
			for item in json_result:
				if ("type" in item) and (item["type"] == "MOD_INFO"):
					
					var info = item
					info["name"] = _strip_html_tags(info["name"])
					if "description" in info:
						info["description"] = _strip_html_tags(info["description"])
					if not "id" in info:  # Since not all mods have IDs, apparently!
						if "ident" in info:
							info["id"] = info["ident"]
						else:
							info["id"] = info["name"]
					
					result[info["id"]] = {
						"location": mods_dir + "/" + subdir,
						"modinfo": info
					}
					break
					
			f.close()
	
	return result


func _strip_html_tags(text: String) -> String:
	
	var s = text
	var regex = RegEx.new()
	regex.compile("<[^<>]+>")
	
	var matches = regex.search_all(s)
	for match_ in matches:
		var m: RegExMatch = match_
		s = s.replace(m.get_string(), "")
		
	return s


func mod_status(id: String) -> int:
	
	# Returns mod installed status:
	# 0 - not installed;
	# 1 - installed;
	# 2 - stock mod;
	# 3 - stock mod but obsolete;
	# 4 - installed with modified ID.
	
	if id + "__" in installed:
		return 4
	elif id in installed:
		if installed[id]["is_stock"]:
			if installed[id]["is_obsolete"]:
				return 3
			else:
				return 2
		else:
			return 1
	else:
		return 0


func refresh_installed():
	
	var gamedir = _workdir + "/" + _settings.read("game") + "/current"
	
	if OS.get_name() == "OSX":
		gamedir += "/Cataclysm.app/Contents/Resources"
	
	installed = {}
	
	var non_stock := {}
	if Directory.new().dir_exists(gamedir + "/mods"):
		non_stock = parse_mods_dir(gamedir + "/mods")
		for id in non_stock:
			non_stock[id]["is_stock"] = false
			
	var stock := parse_mods_dir(gamedir + "/data/mods")
	for id in stock:
		stock[id]["is_stock"] = true
		if ("obsolete" in stock[id]["modinfo"]) and (stock[id]["modinfo"]["obsolete"] == true):
			stock[id]["is_obsolete"] = true
		else:
			stock[id]["is_obsolete"] = false
			
	# In OSX, mods should place in /data/mods folder.
	# It's no difference between stock and non_stock.
	# for temporarily fix, assign stock -> non_stock when OSX.
	if OS.get_name() == "OSX":
		non_stock = stock
		stock = {}
	
	
	for id in non_stock:
		installed[id] = non_stock[id]
		installed[id]["is_stock"] = false
		installed[id]["is_obsolete"] = false
		
	for id in stock:
		installed[id] = stock[id]


func refresh_available():
	
	var mod_repo = _workdir + "/" + _settings.read("game") + "/mod_repo"
	available = parse_mods_dir(mod_repo)


func _delete_mod(mod_id: String) -> void:
	
	yield(get_tree().create_timer(0.05), "timeout")
	# Have to introduce an artificial delay, otherwise the engine becomes very
	# crash-happy when processing large numbers of mods.
	
	if mod_id in installed:
		var mod = installed[mod_id]
		_fshelper.rm_dir(mod["location"])
		yield(_fshelper, "rm_dir_done")
		emit_signal("status_message", "Deleted %s" % mod["modinfo"]["name"])
	else:
		emit_signal("status_message", "Could not find mod with ID \"%s\"" % mod_id, Enums.MSG_ERROR)
	
	emit_signal("_done_deleting_mod")


func delete_mods(mod_ids: Array) -> void:
	
	if len(mod_ids) == 0:
		return
	
	if len(mod_ids) > 1:
		emit_signal("status_message", "Deleting %s mods..." % len(mod_ids))
	
	emit_signal("mod_deletion_started")
	
	for id in mod_ids:
		if mod_status(id) == 4:
			_delete_mod(id + "__")
		else:
			_delete_mod(id)
		yield(self, "_done_deleting_mod")
	
	refresh_installed()
	emit_signal("mod_deletion_finished")


func _install_mod(mod_id: String) -> void:
	
	yield(get_tree().create_timer(0.05), "timeout")
	# For stability; see above.

	var mods_dir = _workdir + "/" + _settings.read("game") + "/current"
	
	if OS.get_name() == "OSX":
		mods_dir += "/Cataclysm.app/Contents/Resources/data"
	
	mods_dir += "/mods"
	
	if mod_id in available:
		var mod = available[mod_id]
		
		_fshelper.copy_dir(mod["location"], mods_dir)
		yield(_fshelper, "copy_dir_done")
		
		if (mod_id in installed) and (installed[mod_id]["is_obsolete"] == true):
			emit_signal("status_message", "There is already an obsoleted mod with ID %s. [i]%s[/i] will be installed with modified ID and name to avoid collisions."
					% [mod_id, mod["modinfo"]["name"]])
			var modinfo = mod["modinfo"].duplicate()
			modinfo["id"] += "__"
			modinfo["name"] += "*"
			var f = File.new()
			f.open(mods_dir.plus_file(mod["location"].get_file()).plus_file("modinfo.json"), File.WRITE)
			f.store_string(JSON.print(modinfo, "    "))
					
		emit_signal("status_message", "Installed %s" % mod["modinfo"]["name"])
	else:
		emit_signal("status_message", "Could not find mod with ID \"%s\"" % mod_id, Enums.MSG_ERROR)
	
	emit_signal("_done_installing_mod")


func install_mods(mod_ids: Array) -> void:
	
	if len(mod_ids) == 0:
		return
	
	if len(mod_ids) > 1:
		emit_signal("status_message", "Installing %s mods..." % len(mod_ids))
	
	emit_signal("mod_installation_started")
	
	for id in mod_ids:
		_install_mod(id)
		yield(self, "_done_installing_mod")
	
	refresh_installed()
	emit_signal("mod_installation_finished")


func retrieve_kenan_pack() -> void:
	
	var game = _settings.read("game")
	var pack = _MODPACKS["kenan-" + game]
	var _tmp_dir = _workdir + "/" + game + "/tmp"
	var _modrepo_dir = _workdir + "/" + game + "/mod_repo"
	
	emit_signal("modpack_retrieval_started")
	emit_signal("status_message", "Retrieving Kenan Modpack for %s..." % game.to_upper())
	
	_downloader.download_file(pack["url"], _workdir, pack["filename"])
	yield(_downloader, "download_finished")
	
	var archive = _workdir + "/" + pack["filename"]
	if Directory.new().file_exists(archive):
		_fshelper.extract(archive, _tmp_dir)
		yield(_fshelper, "extract_done")
		Directory.new().remove(archive)
		emit_signal("status_message", "Wiping the repository...")
		if (Directory.new().dir_exists(_modrepo_dir)):
			_fshelper.rm_dir(_modrepo_dir)
			yield(_fshelper, "rm_dir_done")
		emit_signal("status_message", "Adding mods from the pack to repository...")
		_fshelper.move_dir(_tmp_dir + "/" + pack["internal_path"], _modrepo_dir)
		yield(_fshelper, "move_dir_done")
		_fshelper.rm_dir(_tmp_dir + "/" + pack["internal_path"].split("/")[0])
		yield(_fshelper, "rm_dir_done")
		emit_signal("status_message", "All finished.")
	
	refresh_available()
	emit_signal("modpack_retrieval_finished")
