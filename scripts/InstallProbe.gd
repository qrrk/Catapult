extends Node


const _INFO_FILENAME = "catapult_install_info.json"

onready var _path := $"../PathHelper"


func create_info_file(location: String, name: String) -> void:
	
	var info = {"name": name}
	var path = location + "/" + _INFO_FILENAME
	var f = File.new()
	if (f.open(path, File.WRITE) == 0):
		f.store_string(JSON.print(info, "    "))
		f.close()
	else:
		Status.post(tr("msg_cannot_create_install_info") % path, Enums.MSG_ERROR)


func _load_json(path: String) -> Dictionary:
	
	var f = File.new()
	var result: JSONParseResult
	
	f.open(path, File.READ)
	result = JSON.parse(f.get_as_text())
	f.close()
	
	if result.error:
		Status.post(tr("msg_cannot_parse_install_info") % path, Enums.MSG_ERROR)
		return {}
	
	return result.result
	


func probe_installed_games() -> Dictionary:
	
	var result = {}
	var d = Directory.new()
	
	var path_dda = _path.own_dir + "/dda/current/" + _INFO_FILENAME
	if d.file_exists(path_dda):
		result["dda"] = _load_json(path_dda)
		
	var path_bn = _path.own_dir + "/bn/current/" + _INFO_FILENAME
	if d.file_exists(path_bn):
		result["bn"] = _load_json(path_bn)
	
	return result
