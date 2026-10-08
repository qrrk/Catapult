extends Node


signal started_fetching_releases
signal done_fetching_releases

var _platform = ""


const _RELEASE_SOURCES_PATH = "res://data/release_sources.json"
const _STABLE_RELEASES_PATH = "res://data/stable_releases.json"
const _STABLE_CACHE_FILENAME = "release_info_cache.json"

var _release_sources: Dictionary = {}
var _stable_releases: Dictionary = {}
var _builtin_stables: Dictionary = {}

var _http_stable: HTTPRequest
var _checking_external_stables: bool = false


var releases = {
	"dda-stable": [],
	"dda-experimental": [],
	"bn-stable": [],
	"bn-experimental": [],
	"eod-stable": [],
	"eod-experimental": [],
	"tish-stable": [],
	"tish-experimental": [],
	"tlg-stable": [],
	"tlg-experimental": [],
}


func _ready() -> void:
	_http_stable = HTTPRequest.new()
	add_child(_http_stable)
	_http_stable.request_completed.connect(_on_request_completed_stable)
	
	_load_sources()
	
	var p = OS.get_name()
	match p:
		"X11", "Linux":
			_platform = "linux"
		"Windows":
			_platform = "win"
		_:
			Status.post(tr("msg_unsupported_platform") % p, Enums.MSG_ERROR)
	
	if Settings.read("check_external_stable_release_source"):
		check_external_stable_releases(true)


func _load_sources() -> void:
	var sources = Helpers.load_json_file(_RELEASE_SOURCES_PATH)
	if sources is Dictionary:
		_release_sources = sources
	else:
		_release_sources = {}
	
	var stables = Helpers.load_json_file(_STABLE_RELEASES_PATH)
	if stables is Dictionary:
		_builtin_stables = stables
	else:
		_builtin_stables = {}
	
	var cache_path = Paths.own_dir.path_join(_STABLE_CACHE_FILENAME)
	if FileAccess.file_exists(cache_path):
		var cached = Helpers.load_json_file(cache_path)
		if cached is Dictionary:
			_stable_releases = _merge_stable_releases(cached, _builtin_stables)
		else:
			_stable_releases = _builtin_stables.duplicate(true)
	else:
		_stable_releases = _builtin_stables.duplicate(true)
	
	_update_stable_releases_arrays()


func _update_stable_releases_arrays() -> void:
	releases["dda-stable"] = _stable_releases.get("dda-stable", {}).get(_platform, [])
	releases["bn-stable"] = _stable_releases.get("bn-stable", {}).get(_platform, [])


func _merge_stable_releases(higher_priority: Dictionary, lower_priority: Dictionary) -> Dictionary:
	var result := {}
	
	var all_channels := {}
	for ch in higher_priority.keys():
		all_channels[ch] = true
	for ch in lower_priority.keys():
		all_channels[ch] = true
	
	for channel in all_channels.keys():
		result[channel] = {}
		var hi_ch = higher_priority.get(channel, {})
		var lo_ch = lower_priority.get(channel, {})
		if not (hi_ch is Dictionary):
			hi_ch = {}
		if not (lo_ch is Dictionary):
			lo_ch = {}
		
		var all_platforms := {}
		for p in hi_ch.keys():
			all_platforms[p] = true
		for p in lo_ch.keys():
			all_platforms[p] = true
		
		for platform in all_platforms.keys():
			var hi_list = hi_ch.get(platform, [])
			var lo_list = lo_ch.get(platform, [])
			if not (hi_list is Array):
				hi_list = []
			if not (lo_list is Array):
				lo_list = []
			
			var merged_list: Array = []
			var seen_names := {}
			
			for item in hi_list:
				if item is Dictionary and "name" in item:
					var item_name: String = str(item["name"])
					if not item_name in seen_names:
						seen_names[item_name] = true
						merged_list.append(item.duplicate(true))
			
			for item in lo_list:
				if item is Dictionary and "name" in item:
					var item_name: String = str(item["name"])
					if not item_name in seen_names:
						seen_names[item_name] = true
						merged_list.append(item.duplicate(true))
			
			result[channel][platform] = merged_list
	
	return result


func _save_stable_cache(data: Dictionary) -> void:
	var cache_path = Paths.own_dir.path_join(_STABLE_CACHE_FILENAME)
	var content = JSON.stringify(data, "    ")
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f != null:
		f.store_string(content)
		f.close()


func _count_stable_releases(stables: Dictionary) -> int:
	var total := 0
	for ch in stables.values():
		if ch is Dictionary:
			for p in ch.values():
				if p is Array:
					total += p.size()
	return total


func check_external_stable_releases(silent: bool = false) -> void:
	if _checking_external_stables:
		return
	
	var raw_address = Settings.read("external_stable_release_source")
	if raw_address == null:
		return
	var source_address: String = str(raw_address).strip_edges()
	if source_address.is_empty():
		return
	
	if source_address.begins_with("http://") or source_address.begins_with("https://"):
		_checking_external_stables = true
		if not silent:
			emit_signal("started_fetching_releases")
			Status.post(tr("msg_fetching_releases_stable"))
		_update_proxy(_http_stable)
		var err := _http_stable.request(source_address)
		if err != OK:
			_checking_external_stables = false
			Status.post(tr("msg_check_stables_failed"), Enums.MSG_WARN)
			if not silent:
				emit_signal("done_fetching_releases")
		return
	
	# Local file path
	var file_path: String = source_address
	if not file_path.is_absolute_path():
		file_path = Paths.own_dir.path_join(source_address)
	
	if not FileAccess.file_exists(file_path):
		Status.post(tr("msg_check_stables_failed") + " (%s)" % file_path, Enums.MSG_WARN)
		return
	
	var data = Helpers.load_json_file(file_path)
	if data is Dictionary:
		_process_and_merge_stables(data, silent)
	else:
		Status.post(tr("msg_check_stables_failed"), Enums.MSG_WARN)


func _on_request_completed_stable(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking_external_stables = false
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		Status.post(tr("msg_check_stables_failed"), Enums.MSG_WARN)
		emit_signal("done_fetching_releases")
		return
	
	var json_conv := JSON.new()
	var parse_err := json_conv.parse(body.get_string_from_utf8())
	if parse_err != OK or not (json_conv.data is Dictionary):
		Status.post(tr("msg_check_stables_failed"), Enums.MSG_WARN)
		emit_signal("done_fetching_releases")
		return
	
	_process_and_merge_stables(json_conv.data, false)


func _process_and_merge_stables(incoming: Dictionary, silent: bool = false) -> void:
	var prev_total := _count_stable_releases(_stable_releases)
	_stable_releases = _merge_stable_releases(incoming, _stable_releases)
	var new_total := _count_stable_releases(_stable_releases)
	
	_save_stable_cache(_stable_releases)
	_update_stable_releases_arrays()
	
	if not silent:
		if new_total > prev_total:
			Status.post(tr("msg_got_n_new_stables") % (new_total - prev_total))
		else:
			Status.post(tr("msg_no_new_stables"))
	
	emit_signal("done_fetching_releases")


func _get_asset_filter(release_type: String) -> Dictionary:
	if _release_sources.is_empty():
		_load_sources()
	return _release_sources.get("asset_filters", {}).get(release_type + "-" + _platform, {})


func _get_query_string() -> String:
	
	var num_per_page = Settings.read("num_releases_to_request")
	return "?per_page=%s" % int(num_per_page)


func _update_proxy(http: HTTPRequest) -> void:
	if Settings.read("proxy_option") == "on":
		var host = Settings.read("proxy_host")
		var port = Settings.read("proxy_port") as int
		http.set_http_proxy(host, port)
		http.set_https_proxy(host, port)
	else:
		http.set_http_proxy("", -1)
		http.set_https_proxy("", -1)

func _request_releases(http: HTTPRequest, release: String) -> void:
	if _release_sources.is_empty():
		_load_sources()
	emit_signal("started_fetching_releases")
	_update_proxy(http)
	var urls = _release_sources.get("urls", {})
	http.request(urls[release] + _get_query_string())


func _on_request_completed_dda(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		Status.post(tr("msg_releases_request_failed"), Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["dda-experimental"], _get_asset_filter("dda-experimental"))
	
	emit_signal("done_fetching_releases")


func _on_request_completed_bn(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		Status.post(tr("msg_releases_request_failed"), Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["bn-experimental"], _get_asset_filter("bn-experimental"))
	
	emit_signal("done_fetching_releases")

func _on_request_completed_eod(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		Status.post(tr("msg_releases_request_failed"), Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["eod-experimental"], _get_asset_filter("eod-experimental"))
	
	emit_signal("done_fetching_releases")

func _on_request_completed_tish(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		Status.post(tr("msg_releases_request_failed"), Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["tish-experimental"], _get_asset_filter("tish-experimental"))
	
	emit_signal("done_fetching_releases")

func _on_request_completed_tlg(result: int, response_code: int,
		headers: PackedStringArray, body: PackedByteArray) -> void:
	
	Status.post(tr("msg_http_request_info") %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		Status.post(tr("msg_releases_request_failed"), Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["tlg-experimental"], _get_asset_filter("tlg-experimental"))
	
	emit_signal("done_fetching_releases")

func _parse_builds(data: PackedByteArray, write_to: Array, filter: Dictionary) -> void:
	
	var json_conv := JSON.new()
	json_conv.parse(data.get_string_from_utf8())
	var json = json_conv.data
	
	# Check if API rate limit is exceeded
	if "message" in json:
		print(tr("msg_releases_api_failure") % json["message"])
		return
		
	var tmp_arr = []

	for rec in json:
		var build = {}
		build["name"] = rec["name"]
		if Settings.read("shorten_release_names"):
			build["name"] = build["name"].split(" ")[-1]
		build["url"] = ""
		
		for asset in rec["assets"]:
			if filter["substring"] in asset[filter["field"]]:
				build["url"] = asset["browser_download_url"]
				build["filename"] = asset["name"]
		
		if build["url"] != "":
			tmp_arr.append(build)
	
	if len(tmp_arr) > 0:
		write_to.clear()
		write_to.append_array(tmp_arr)
		Status.post(tr("msg_got_n_releases") % len(tmp_arr))


func fetch(release_key: String) -> void:
	if _stable_releases.is_empty():
		_load_sources()
	
	match release_key:
		"dda-stable", "bn-stable":
			if Settings.read("check_external_stable_release_source"):
				check_external_stable_releases(false)
			else:
				_update_stable_releases_arrays()
				emit_signal("done_fetching_releases")
		"dda-experimental":
			Status.post(tr("msg_fetching_releases_dda"))
			_request_releases($HTTPRequest_DDA, "dda-experimental")
		"bn-experimental":
			Status.post(tr("msg_fetching_releases_bn"))
			_request_releases($HTTPRequest_BN, "bn-experimental")
		"eod-experimental":
			Status.post(tr("msg_fetching_releases_eod"))
			_request_releases($HTTPRequest_EOD, "eod-experimental")
		"tish-experimental":
			Status.post(tr("msg_fetching_releases_tish"))
			_request_releases($HTTPRequest_TISH, "tish-experimental")
		"tlg-experimental":
			Status.post(tr("msg_fetching_releases_tlg"))
			_request_releases($HTTPRequest_TLG, "tlg-experimental")
		_:
			Status.post(tr("msg_invalid_fetch_func_param") % release_key, Enums.MSG_ERROR)
