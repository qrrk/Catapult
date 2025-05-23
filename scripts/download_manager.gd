extends Node


signal download_started
signal download_finished

# Give progress update after this time or this amount downloaded,
# whichever comes first.
const _PROGRESS_AFTER_MSECS := 2000
const _PROGRESS_AFTER_BYTES := 1024 * 1024 * 5

var _current_filename := ""
var _current_file_path := ""
var _download_ongoing := false

@onready var _http: HTTPRequest


func _enter_tree() -> void:
	
	_http = HTTPRequest.new()
	_http.use_threads = true
	self.add_child(_http)
	_http.connect("request_completed", Callable(self, "_on_HTTPRequest_request_completed"))

func set_proxy(host: String, port: int) -> void:
	
	_http.set_http_proxy(host, port)
	_http.set_https_proxy(host, port)

func download_file(url: String, target_dir: String, target_filename: String) -> void:
	
	if Settings.read("proxy_option") == "on" or Settings.read("proxy_option") == "download":
		var host = Settings.read("proxy_host")
		var port = Settings.read("proxy_port") as int
		Status.post(tr("msg_using_proxy") % [host, port])
		set_proxy(host, port)
	else:
		set_proxy("", -1)
	
	if not DirAccess.dir_exists_absolute(target_dir):
		var err := DirAccess.make_dir_recursive_absolute(target_dir)
		if err:
			Status.post(tr("msg_download_failed") % target_filename, Enums.MSG_ERROR)
			emit_signal("download_finished")
			return
	
	Status.post(tr("msg_downloading_file") % target_filename)
	emit_signal("download_started")
	_current_filename = target_filename
	_current_file_path = target_dir.path_join(target_filename)
	_http.download_file = target_dir + "/" + target_filename
	_http.request(url)
	_download_ongoing = true
	var last_progress_time = Time.get_ticks_msec()
	var last_progress_bytes = 0
	
	while _download_ongoing:
		
		var downloaded = _http.get_downloaded_bytes()
		var total = _http.get_body_size()
		
		if downloaded < 1:
			await get_tree().process_frame
			continue
		
		var delta_time = Time.get_ticks_msec() - last_progress_time
		var delta_bytes = downloaded - last_progress_bytes
		
		if (delta_time >= _PROGRESS_AFTER_MSECS) or (delta_bytes >= _PROGRESS_AFTER_BYTES):
			Status.post(_get_progress_string(downloaded, total, delta_time, delta_bytes))
			last_progress_time = Time.get_ticks_msec()
			last_progress_bytes = downloaded
		
		await get_tree().process_frame


func _get_progress_string(downloaded: int, total: int,
		delta_time: int, delta_bytes: int) -> String:
	
	var amount_str = ""
	if (downloaded > 1024*1024):
		amount_str = "%.1f %s" % [(downloaded / 1048576.0), tr("unit_mb")]
	else:
		# warning-ignore:integer_division
		amount_str = "%s %s" % [(downloaded / 1024), tr("unit_kb")]
		
	var percent_str = ""
	if total > 0:
		percent_str = " (%.1f%%)" % ((float(downloaded) / total) * 100)
		
	var speed_str = " %s " % tr("str_dl_speed_at")
	var speed_bps = delta_bytes / float(delta_time) * 1000.0
	if speed_bps > 1048576.0:
		speed_str += "%.1f %s" % [(speed_bps / 1048576.0), tr("unit_mbps")]
	else:
		speed_str += "%d %s" % [(speed_bps / 1024.0), tr("unit_kbps")]
		
	var result = "%s %s%s%s" % [tr("msg_download_progress"), amount_str, percent_str, speed_str]
	return result


func _on_HTTPRequest_request_completed(_result: int, _response_code: int,
		_headers: PackedStringArray, _body: PackedByteArray) -> void:
	
	_download_ongoing = false
	Status.post(tr("msg_http_request_info") % [_result, _response_code, _headers], Enums.MSG_DEBUG)
	
	if FileAccess.file_exists(_current_file_path):
		Status.post(tr("msg_download_finished") % _current_filename)
	else:
		Status.post(tr("msg_download_failed") % _current_filename, Enums.MSG_ERROR)
	
	emit_signal("download_finished")
