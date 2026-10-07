extends Node


signal started_fetching_releases
signal done_fetching_releases

var _platform = ""


const _RELEASE_SOURCES_PATH = "res://data/release_sources.json"
const _STABLE_RELEASES_PATH = "res://data/stable_releases.json"

var _release_sources: Dictionary = {}
var _stable_releases: Dictionary = {}


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
	_load_sources()
	
	var p = OS.get_name()
	match p:
		"X11":
			_platform = "linux"
		"Linux":
			_platform = "linux"
		"Windows":
			_platform = "win"
		_:
			Status.post(tr("msg_unsupported_platform") % p, Enums.MSG_ERROR)


func _load_sources() -> void:
	var sources = Helpers.load_json_file(_RELEASE_SOURCES_PATH)
	if sources is Dictionary:
		_release_sources = sources
	else:
		_release_sources = {}
	
	var stables = Helpers.load_json_file(_STABLE_RELEASES_PATH)
	if stables is Dictionary:
		_stable_releases = stables
	else:
		_stable_releases = {}


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
			releases[release_key] = _stable_releases.get(release_key, {}).get(_platform, [])
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
