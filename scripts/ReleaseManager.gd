extends Node


signal status_message
signal started_fetching_releases
signal done_fetching_releases


onready var _settings = $"/root/SettingsManager"

var _platform = ""


const _RELEASE_URLS = {
	"dda-experimental":
		"https://api.github.com/repos/CleverRaven/Cataclysm-DDA/releases",
	"bn-experimental":
		"https://api.github.com/repos/cataclysmbnteam/Cataclysm-BN/releases",
}

const _ASSET_FILTERS = {
	"dda-experimental-linux": {
		"field": "name",
		"substring": "cdda-linux-tiles-x64",
	},
	"dda-experimental-win": {
		"field": "name",
		"substring": "cdda-windows-tiles-x64",
	},
	"bn-experimental-linux": {
		"field": "name",
		"substring": "cbn-linux-tiles-x64",
	},
	"bn-experimental-win": {
		"field": "name",
		"substring": "cbn-windows-tiles-x64",
	},
}

const _DDA_STABLE_LINUX = [
	{
		"name": "0.F-2 Frank-2",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F-2/cataclysmdda-0.F-Linux_x64-Tiles-0.F-2.tar.gz",
		"filename": "cataclysmdda-0.F-Linux_x64-Tiles-0.F-2.tar.gz"
	},
	{
		"name": "0.F-1 Frank-1",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F-1/cataclysmdda-0.F-Linux_x64-Tiles-0.F-1.tar.gz",
		"filename": "cataclysmdda-0.F-Linux_x64-Tiles-0.F-1.tar.gz"
	},
	{
		"name": "0.F Frank",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F/cdda-linux-tiles-x64-2021-07-03-0512.tar.gz",
		"filename": "cdda-linux-tiles-x64-2021-07-03-0512.tar.gz"
	},
	{
		"name": "0.E-3 Ellison-3",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-3/cataclysmdda-0.E-Linux_x64-Tiles-0.E-3.tar.gz",
		"filename": "cataclysmdda-0.E-Linux_x64-Tiles-0.E-3.tar.gz"
	},
	{
		"name": "0.E-2 Ellison-2",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-2/cataclysmdda-0.E-Linux_x64-Tiles-0.E-2.tar.gz",
		"filename": "cataclysmdda-0.E-Linux_x64-Tiles-0.E-2.tar.gz"
	},
	{
		"name": "0.E-1 Ellison-1",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-1/cataclysmdda-0.E-Linux_x64-Tiles-0.E-1.tar.gz",
		"filename": "cataclysmdda-0.E-Linux_x64-Tiles-0.E-1.tar.gz"
	},
	{
		"name": "0.E Ellison",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E/cataclysmdda-0.E-Linux_x64-Tiles-10478.tar.gz",
		"filename": "cataclysmdda-0.E-Linux_x64-Tiles-10478.tar.gz"
	},
	{
		"name": "0.D Danny",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.D/cataclysmdda-0.D-8574-Linux-Tiles.tar.gz",
		"filename": "cataclysmdda-0.D-8574-Linux-Tiles.tar.gz"
	},
]

const _DDA_STABLE_WIN = [
	{
		"name": "0.F-2 Frank-2",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F-2/cataclysmdda-0.F-Windows_x64-Tiles-0.F-2.zip",
		"filename": "cataclysmdda-0.F-Windows_x64-Tiles-0.F-2.zip"
	},
	{
		"name": "0.F-1 Frank-1",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F-1/cataclysmdda-0.F-Windows_x64-Tiles-0.F-1.zip",
		"filename": "cataclysmdda-0.F-Windows_x64-Tiles-0.F-1.zip"
	},
	{
		"name": "0.F Frank",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.F/cdda-windows-tiles-x64-2021-07-03-0512.zip",
		"filename": "cdda-windows-tiles-x64-2021-07-03-0512.zip"
	},
	{
		"name": "0.E-3 Ellison-3",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-3/cataclysmdda-0.E-Windows_x64-Tiles-0.E-3.zip",
		"filename": "cataclysmdda-0.E-Windows_x64-Tiles-0.E-3.zip"
	},
	{
		"name": "0.E-2 Ellison-2",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-2/cataclysmdda-0.E-Windows_x64-Tiles-0.E-2.zip",
		"filename": "cataclysmdda-0.E-Windows_x64-Tiles-0.E-2.zip"
	},
	{
		"name": "0.E-1 Ellison-1",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E-1/cataclysmdda-0.E-Windows_x64-Tiles-0.E-1.zip",
		"filename": "cataclysmdda-0.E-Windows_x64-Tiles-0.E-1.zip"
	},
	{
		"name": "0.E Ellison",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.E/cataclysmdda-0.E-Windows_x64-Tiles-10478.zip",
		"filename": "cataclysmdda-0.E-Windows_x64-Tiles-10478.zip"
	},
	{
		"name": "0.D Danny",
		"url": "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.D/cataclysmdda-0.D-8574-Win64-Tiles.zip",
		"filename": "cataclysmdda-0.D-8574-Win64-Tiles.zip"
	},
]

var releases = {
	"dda-stable": [],
	"dda-experimental": [],
	"bn-experimental": [],
}


func _ready() -> void:
	
	var p = OS.get_name()
	match p:
		"X11":
			_platform = "linux"
		"Windows":
			_platform = "win"
		_:
			emit_signal("status_message", "Unsupported platform: \"%s\"" % p, Enums.MSG_ERROR)


func _get_query_string() -> String:
	
	var num_per_page = _settings.read("num_releases_to_request")
	return "?per_page=%s" % num_per_page


func _request_dda() -> void:
	emit_signal("started_fetching_releases")
	$HTTPRequest_DDA.request(_RELEASE_URLS["dda-experimental"] + _get_query_string())


func _request_bn() -> void:
	emit_signal("started_fetching_releases")
	$HTTPRequest_BN.request(_RELEASE_URLS["bn-experimental"] + _get_query_string())


func _on_request_completed_dda(result: int, response_code: int,
		headers: PoolStringArray, body: PoolByteArray) -> void:
	
	emit_signal("status_message", "[b]HTTPRequest info:[/b]\n[u]Result:[/u] %s\n[u]Response code:[/u] %s\n[u]Headers:[/u] %s" %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		emit_signal("status_message", "Request failed. Do you have internet connection?", Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["dda-experimental"], _ASSET_FILTERS["dda-experimental-" + _platform])
	
	emit_signal("done_fetching_releases")


func _on_request_completed_bn(result: int, response_code: int,
		headers: PoolStringArray, body: PoolByteArray) -> void:
	
	emit_signal("status_message", "[b]HTTPRequest info:[/b]\n[u]Result:[/u] %s\n[u]Response code:[/u] %s\n[u]Headers:[/u] %s" %
			[result, response_code, headers], Enums.MSG_DEBUG)
	
	if result:
		emit_signal("status_message", "Request failed. Do you have internet connection?", Enums.MSG_WARN)
	else:
		_parse_builds(body, releases["bn-experimental"], _ASSET_FILTERS["bn-experimental-" + _platform])
	
	emit_signal("done_fetching_releases")


func _parse_builds(data: PoolByteArray, write_to: Array, filter: Dictionary) -> void:
	
	var json = JSON.parse(data.get_string_from_utf8()).result
	
	# Check if API rate limit is exceeded
	if "message" in json:
		print("Could not get the builds list. GitHub says: " + json["message"])
		return
		
	var tmp_arr = []

	for rec in json:
		var build = {}
		build["name"] = rec["name"]
		if _settings.read("shorten_release_names"):
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
		emit_signal("status_message", "Got %s releases." % len(tmp_arr))


func fetch(release_key: String) -> void:
	
	match release_key:
		"dda-stable":
			match _platform:
				"linux":
					releases["dda-stable"] = _DDA_STABLE_LINUX
				"win":
					releases["dda-stable"] = _DDA_STABLE_WIN
			emit_signal("done_fetching_releases")
		"dda-experimental":
			emit_signal("status_message", "Fetching releases for DDA Experimental...")
			_request_dda()
		"bn-experimental":
			emit_signal("status_message", "Fetching releases for BN Experimental...")
			_request_bn()
		_:
			emit_signal("status_message", "ReleaseManager.fetch() was passed %s" % release_key, Enums.MSG_ERROR)

