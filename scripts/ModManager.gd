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


var installed: Array = [] setget , _get_installed
var available: Array = [] setget , _get_available


func _get_installed() -> Array:
	
	if installed == []:
		refresh_installed()
		
	return installed


func _get_available() -> Array:
	
	if available == []:
		refresh_available()
	
	return available


func parse_mods_dir(mods_dir: String) -> Array:
	
	if not Directory.new().dir_exists(mods_dir):
		return []
		
	var result = []
	
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
					
					result.append({
						"location": mods_dir + "/" + subdir,
						"modinfo": info
					})
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
	


func _sorting_comparison(a: Dictionary, b: Dictionary) -> bool:
	
	return (a["modinfo"]["name"].nocasecmp_to(b["modinfo"]["name"]) == -1)


func refresh_installed(sort_by_name = true):
	
	var gamedir = _workdir + "/" + _settings.read("game") + "/current"
	installed = []
	
	if Directory.new().dir_exists(gamedir + "/mods"):
		var non_stock = parse_mods_dir(gamedir + "/mods")
		for mod in non_stock:
			mod["is_stock"] = false
		installed.append_array(non_stock)
			
	var stock = parse_mods_dir(gamedir + "/data/mods")
	for mod in stock:
		mod["is_stock"] = true
	installed.append_array(stock)
		
	if sort_by_name:
		installed.sort_custom(self, "_sorting_comparison")


func refresh_available(sort_by_name = true):
	
	var mod_repo = _workdir + "/" + _settings.read("game") + "/mod_repo"
	available = parse_mods_dir(mod_repo)
	
	if sort_by_name:
		available.sort_custom(self, "_sorting_comparison")


func _delete_mod(mod_id: String) -> void:
	
	yield(get_tree().create_timer(0.05), "timeout")
	# Have to introduce an artificial delay, otherwise the engine becomes very
	# crash-happy when processing large numbers of mods.
	
	var mod = null
	for item in installed:
		if item["modinfo"]["id"] == mod_id:
			mod = item
			break
	
	if mod:
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
		_delete_mod(id)
		yield(self, "_done_deleting_mod")
	
	refresh_installed()
	emit_signal("mod_deletion_finished")


func _install_mod(mod_id: String) -> void:
	
	yield(get_tree().create_timer(0.05), "timeout")
	# For stability; see above.

	var mods_dir = _workdir + "/" + _settings.read("game") + "/current/mods"
	
	var mod = null
	for item in available:
		if item["modinfo"]["id"] == mod_id:
			mod = item
			break
	
	if mod:
		_fshelper.copy_dir(mod["location"], mods_dir)
		yield(_fshelper, "copy_dir_done")
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
