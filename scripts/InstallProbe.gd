extends Node


signal status_message


var _INFO_FILENAME = "catapult_install_info.json" if OS.get_name() != "OSX" else "Cataclysm.app/catapult_install_info.json"


var _workdir = ""


func _enter_tree() -> void:
	
	_workdir = OS.get_executable_path().get_base_dir()


func create_info_file(location: String, name: String) -> void:
	
	var info = {"name": name}
	var path = location + "/" + _INFO_FILENAME
	var f = File.new()
	if (f.open(path, File.WRITE) == 0):
		f.store_string(JSON.print(info, "    "))
		f.close()
	else:
		emit_signal("status_message", "Could not create install info file %s" % path, Enums.MSG_ERROR)


func _load_json(path: String) -> Dictionary:
	
	var f = File.new()
	var result: JSONParseResult
	
	f.open(path, File.READ)
	result = JSON.parse(f.get_as_text())
	f.close()
	
	if result.error:
		emit_signal("status_message", "Could not parse install info file %s" % path, Enums.MSG_ERROR)
		return {}
	
	return result.result
	


func probe_installed_games() -> Dictionary:
	
	var result = {}
	var d = Directory.new()
	
	
	var path_dda = _workdir + "/dda/current/" + _INFO_FILENAME
	if d.file_exists(path_dda):
		result["dda"] = _load_json(path_dda)
		
	var path_bn = _workdir + "/bn/current/" + _INFO_FILENAME
	if d.file_exists(path_bn):
		result["bn"] = _load_json(path_bn)
	
	return result
