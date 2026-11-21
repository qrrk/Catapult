class_name Helpers
extends RefCounted
## Stateless file, JSON, and node-tree utility functions.


const INFO_FILENAME := "catapult_install_info.json"


## Writes catapult_install_info.json inside an extracted game directory to record its release name.
static func create_info_file(location: String, install_name: String) -> void:
	
	var info := {"name": install_name}
	var path := location + "/" + INFO_FILENAME
	var info_file := FileAccess.open(path, FileAccess.WRITE)
	if info_file:
		info_file.store_string(JSON.stringify(info, "    "))
		info_file.close()
	else:
		Status.post(TranslationServer.translate("msg_cannot_create_install_info") % path, Enums.MSG_ERROR)


## Returns a flat depth-first list of all descendant nodes under the given node.
static func get_all_nodes_within(n: Node) -> Array[Node]:
	
	var result: Array[Node] = []
	for node in n.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(get_all_nodes_within(node))
	return result


## Reads and parses a JSON file, logging errors to Status and returning null on failure.
static func load_json_file(file: String) -> Variant:
	
	var f := FileAccess.open(file, FileAccess.READ)
	
	if f == null:
		Status.post(TranslationServer.translate("msg_file_read_fail") % [file.get_file(), FileAccess.get_open_error()], Enums.MSG_ERROR)
		Status.post(TranslationServer.translate("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return null
	
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	var data: Variant = json.get_data()
	f.close()
	
	if err:
		Status.post(TranslationServer.translate("msg_json_parse_fail") % file.get_file(), Enums.MSG_ERROR)
		Status.post(TranslationServer.translate("msg_debug_json_result") % [err, json.get_error_message(), json.get_error_line()], Enums.MSG_DEBUG)
		return null
	
	return data


## Serializes data as pretty-printed JSON to a file, returning true on success.
static func save_to_json_file(data: Variant, file: String) -> bool:
	
	var f := FileAccess.open(file, FileAccess.WRITE)
	
	if f == null:
		Status.post(TranslationServer.translate("msg_file_write_fail") % [file.get_file(), FileAccess.get_open_error()], Enums.MSG_ERROR)
		Status.post(TranslationServer.translate("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return false
	
	var text := JSON.stringify(data, "    ")
	f.store_string(text)
	f.close()
	
	return true
