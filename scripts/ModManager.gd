extends Node


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
		"internal_paths": [
			"CDDA-Structured-Kenan-Modpack-master/Kenan-Structured-Modpack/High-Maintenance-Huge-Mods",
			],
		"archived_path": "CDDA-Structured-Kenan-Modpack-master/Kenan-Structured-Modpack/Archived-Mods",
	},
	"kenan-bn": {
		"name": "BN Kenan Modpack",
		"url": "https://github.com/Kenan2000/Bright-Nights-Kenan-Mod-Pack/archive/refs/heads/master.zip",
		"filename": "Bright-Nights-Kenan-Mod-Pack-master.zip",
		"internal_paths": [
			"BrightNights-Structured-Kenan-Modpack-master/Kenan-BrightNights-Structured-Modpack/High-Maintenance-Huge-Mods",
			"BrightNights-Structured-Kenan-Modpack-master/Kenan-BrightNights-Structured-Modpack/Medium-Maintenance-Small-Mods",
			],
		"archived_path": "BrightNights-Structured-Kenan-Modpack-master/Kenan-BrightNights-Structured-Modpack/Archived-Mods",
	}
}


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
	
	for subdir in FS.list_dir(mods_dir):
		var f = File.new()
		var modinfo = mods_dir.plus_file(subdir).plus_file("/modinfo.json")
		
		if f.file_exists(modinfo):
			
			f.open(modinfo, File.READ)
			var json = JSON.parse(f.get_as_text())
			if json.error != OK:
				Status.post(tr("msg_mod_json_parsing_failed") % modinfo, Enums.MSG_ERROR)
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
	
	installed = {}
	
	var non_stock := {}
	if Directory.new().dir_exists(Paths.mods_user):
		non_stock = parse_mods_dir(Paths.mods_user)
		for id in non_stock:
			non_stock[id]["is_stock"] = false
			
	var stock := parse_mods_dir(Paths.mods_stock)
	for id in stock:
		stock[id]["is_stock"] = true
		if ("obsolete" in stock[id]["modinfo"]) and (stock[id]["modinfo"]["obsolete"] == true):
			stock[id]["is_obsolete"] = true
		else:
			stock[id]["is_obsolete"] = false
			
	for id in non_stock:
		installed[id] = non_stock[id]
		installed[id]["is_stock"] = false
		installed[id]["is_obsolete"] = false
		
	for id in stock:
		installed[id] = stock[id]


func refresh_available():
	
	available = parse_mods_dir(Paths.mod_repo)


func _delete_mod(mod_id: String) -> void:
	
	yield(get_tree().create_timer(0.05), "timeout")
	# Have to introduce an artificial delay, otherwise the engine becomes very
	# crash-happy when processing large numbers of mods.
	
	if mod_id in installed:
		var mod = installed[mod_id]
		FS.rm_dir(mod["location"])
		yield(FS, "rm_dir_done")
		Status.post(tr("msg_mod_deleted") % mod["modinfo"]["name"])
	else:
		Status.post(tr("msg_mod_not_found") % mod_id, Enums.MSG_ERROR)
	
	emit_signal("_done_deleting_mod")


func delete_mods(mod_ids: Array) -> void:
	
	if len(mod_ids) == 0:
		return
	
	if len(mod_ids) > 1:
		Status.post(tr("msg_deleting_n_mods") % len(mod_ids))
	
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

	var mods_dir = Paths.mods_user
	
	if mod_id in available:
		var mod = available[mod_id]
		
		FS.copy_dir(mod["location"], mods_dir)
		yield(FS, "copy_dir_done")
		
		if (mod_id in installed) and (installed[mod_id]["is_obsolete"] == true):
			Status.post(tr("msg_obsolete_mod_collision") % [mod_id, mod["modinfo"]["name"]])
			var modinfo = mod["modinfo"].duplicate()
			modinfo["id"] += "__"
			modinfo["name"] += "*"
			var f = File.new()
			f.open(mods_dir.plus_file(mod["location"].get_file()).plus_file("modinfo.json"), File.WRITE)
			f.store_string(JSON.print(modinfo, "    "))
					
		Status.post(tr("msg_mod_installed") % mod["modinfo"]["name"])
	else:
		Status.post(tr("msg_mod_not_found") % mod_id, Enums.MSG_ERROR)
	
	emit_signal("_done_installing_mod")


func install_mods(mod_ids: Array) -> void:
	
	if len(mod_ids) == 0:
		return
	
	if len(mod_ids) > 1:
		Status.post(tr("msg_installing_n_mods") % len(mod_ids))
	
	emit_signal("mod_installation_started")
	
	for id in mod_ids:
		_install_mod(id)
		yield(self, "_done_installing_mod")
	
	refresh_installed()
	emit_signal("mod_installation_finished")


func retrieve_kenan_pack() -> void:
	
	var game = Settings.read("game")
	var pack = _MODPACKS["kenan-" + game]
	
	emit_signal("modpack_retrieval_started")
	Status.post(tr("msg_getting_kenan_pack") % game.to_upper())
	
	Downloader.download_file(pack["url"], Paths.own_dir, pack["filename"])
	yield(Downloader, "download_finished")
	
	var archive = Paths.own_dir.plus_file(pack["filename"])
	if Directory.new().file_exists(archive):
		FS.extract(archive, Paths.tmp_dir)
		yield(FS, "extract_done")
		Directory.new().remove(archive)
		
		Status.post(tr("msg_wiping_mod_repo"))
		if (Directory.new().dir_exists(Paths.mod_repo)):
			FS.rm_dir(Paths.mod_repo)
			yield(FS, "rm_dir_done")
		
		Status.post(tr("msg_unpacking_kenan_mods"))
		for int_path in pack["internal_paths"]:
			FS.move_dir(Paths.tmp_dir.plus_file(int_path), Paths.mod_repo)
			yield(FS, "move_dir_done")
		
		if Settings.read("install_archived_mods"):
			Status.post(tr("msg_unpacking_archived_mods"))
			FS.move_dir(Paths.tmp_dir.plus_file(pack["archived_path"]), Paths.mod_repo)
			yield(FS, "move_dir_done")
		
		Status.post(tr("msg_kenan_install_cleanup"))
		FS.rm_dir(Paths.tmp_dir.plus_file(pack["internal_paths"][0].split("/")[0]))
		yield(FS, "rm_dir_done")
		
		Status.post(tr("msg_kenan_install_done"))
	
	refresh_available()
	emit_signal("modpack_retrieval_finished")
