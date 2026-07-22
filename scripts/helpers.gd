extends Node


const INFO_FILENAME := "catapult_install_info.json"


func create_info_file(location: String, install_name: String) -> void:
	
	var info = {"name": install_name}
	var path = location + "/" + INFO_FILENAME
	var info_file := FileAccess.open(path, FileAccess.WRITE)
	if info_file:
		info_file.store_string(JSON.stringify(info, "    "))
		info_file.close()
	else:
		Status.post(tr("msg_cannot_create_install_info") % path, Enums.MSG_ERROR)


func get_all_nodes_within(n: Node) -> Array:
	
	var result = []
	for node in n.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(get_all_nodes_within(node))
	return result


func load_json_file(file: String) -> Variant:
	
	var f := FileAccess.open(file, FileAccess.READ)
	
	if f == null:
		Status.post(tr("msg_file_read_fail") % [file.get_file(), FileAccess.get_open_error()], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return null
	
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	var data = json.get_data()
	f.close()
	
	if err:
		Status.post(tr("msg_json_parse_fail") % file.get_file(), Enums.MSG_ERROR)
		Status.post(tr("msg_debug_json_result") % [err, json.get_error_message(), json.get_error_line()], Enums.MSG_DEBUG)
		return null
	
	return data


func save_to_json_file(data, file: String) -> bool:
	
	var f := FileAccess.open(file, FileAccess.WRITE)
	
	if f == null:
		Status.post(tr("msg_file_write_fail") % [file.get_file(), FileAccess.get_open_error()], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return false
	
	var text := JSON.stringify(data, "    ")
	f.store_string(text)
	f.close()
	
	return true


func sanitize_filename(name: String) -> String:
	# Reduces a network/user-supplied filename to a safe subset so it can
	# never break out of shell quoting or traverse directories.
	var allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
	var out := ""
	for c in name:
		if allowed.contains(c):
			out += c
	if out == "" or out == "." or out == "..":
		out = "download"
	out = out.replace("..", "_")
	return out


func safe_shell_open(url: String) -> void:
	# Only launch http(s) / mailto links and local absolute paths.
	# Blocks javascript:, file:, cmd:, data: and other dangerous schemes.
	var u := url.strip_edges()
	if u.begins_with("http://") or u.begins_with("https://") or u.begins_with("mailto:"):
		OS.shell_open(u)
		return
	if u.begins_with("/") or u.begins_with("\\\\") or (u.length() > 2 and u[1] == ":"):
		# Local absolute filesystem path (folder/file) -- safe to open.
		OS.shell_open(u)
		return
	Status.post("Blocked potentially unsafe link: " + u, Enums.MSG_WARN)


func shell_quote(path: String) -> String:
	# Wraps a path in single quotes for safe interpolation into a /bin/bash -c
	# string. Single quotes inside the path are escaped as '\''.
	return "'" + path.replace("'", "'\\''") + "'"


func is_valid_archive(path: String) -> bool:
	# Rejects anything that is not a zip or gzip/tar.gz before extraction,
	# mitigating download tampering (a swapped-in executable won't pass).
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var header := f.get_buffer(4)
	f.close()
	if header.size() >= 2 and header[0] == 0x1F and header[1] == 0x8B:
		return true  # gzip (tar.gz)
	if header.size() >= 4 and header[0] == 0x50 and header[1] == 0x4B \
			and (header[2] == 0x03 or header[2] == 0x05) \
			and (header[3] == 0x04 or header[3] == 0x06 or header[3] == 0x08):
		return true  # zip
	return false


func verify_sha256(file_path: String, expected: String) -> bool:
	# Returns true when expected is empty (verification skipped) or the file's
	# SHA-256 matches expected (case-insensitive).
	if expected == "":
		return true
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return false
	while not f.eof_reached():
		ctx.update(f.get_buffer(65536))
	f.close()
	var got := ctx.finish().hex_encode().to_lower()
	return got == expected.to_lower()
