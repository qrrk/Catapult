extends Node


const INFO_FILENAME := "catapult_install_info.json"


func create_info_file(location: String, name: String) -> void:
	
	var info = {"name": name}
	var path = location + "/" + INFO_FILENAME
	var f = File.new()
	if (f.open(path, File.WRITE) == 0):
		f.store_string(JSON.print(info, "    "))
		f.close()
	else:
		Status.post(tr("msg_cannot_create_install_info") % path, Enums.MSG_ERROR)


func get_all_nodes_within(n: Node) -> Array:
	
	var result = []
	for node in n.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(get_all_nodes_within(node))
	return result


func load_json_file(file: String):
	
	var f := File.new()
	var err := f.open(file, File.READ)
	
	if err:
		Status.post(tr("msg_file_read_fail") % [file.get_file(), err], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return null
	
	var r := JSON.parse(f.get_as_text())
	f.close()
	
	if r.error:
		Status.post(tr("msg_json_parse_fail") % file.get_file(), Enums.MSG_ERROR)
		Status.post(tr("msg_debug_json_result") % [r.error, r.error_string, r.error_line], Enums.MSG_DEBUG)
		return null
	
	return r.result


func save_to_json_file(data, file: String) -> bool:
	
	var f := File.new()
	var err := f.open(file, File.WRITE)
	
	if err:
		Status.post(tr("msg_file_write_fail") % [file.get_file(), err], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return false
	
	var text := JSON.print(data, "    ")
	f.store_string(text)
	f.close()
	
	return true
