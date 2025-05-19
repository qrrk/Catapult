extends Node


onready var _debug_ui = $Main/Tabs/Debug
onready var _log = $Main/Log
onready var _game_info = $Main/GameInfo
onready var _game_desc = $Main/GameInfo/Description
onready var _mod_info = $Main/Tabs/Mods/ModInfo
onready var _tabs = $Main/Tabs
onready var _mods = $Mods  
onready var _releases = $Releases
onready var _installer = $ReleaseInstaller
onready var _btn_install = $Main/Tabs/Game/BtnInstall
onready var _btn_refresh = $Main/Tabs/Game/Builds/BtnRefresh
onready var _changelog = $Main/Tabs/Game/ChangelogDialog
onready var _lbl_changelog = $Main/Tabs/Game/Channel/HBox/ChangelogLink
onready var _btn_game_dir = $Main/Tabs/Game/ActiveInstall/Build/GameDir
onready var _btn_user_dir = $Main/Tabs/Game/ActiveInstall/Build/UserDir
onready var _btn_play = $Main/Tabs/Game/ActiveInstall/Launch/BtnPlay
onready var _btn_resume = $Main/Tabs/Game/ActiveInstall/Launch/BtnResume
onready var _btn_check = $Main/Tabs/Game/ActiveInstall/Update/BtnCheck
onready var _btn_update = $Main/Tabs/Game/ActiveInstall/Update/BtnUpdate
onready var _lst_builds = $Main/Tabs/Game/Builds/BuildsList
onready var _lst_games = $Main/GameChoice/GamesList
onready var _rbtn_stable = $Main/Tabs/Game/Channel/Group/RBtnStable
onready var _rbtn_exper = $Main/Tabs/Game/Channel/Group/RBtnExperimental
onready var _lbl_build = $Main/Tabs/Game/ActiveInstall/Build/Name
onready var _cb_update = $Main/Tabs/Game/UpdateCurrent
onready var _lst_installs = $Main/Tabs/Game/GameInstalls/HBox/InstallsList
onready var _btn_make_active = $Main/Tabs/Game/GameInstalls/HBox/VBox/btnMakeActive
onready var _btn_delete = $Main/Tabs/Game/GameInstalls/HBox/VBox/btnDelete
onready var _panel_installs = $Main/Tabs/Game/GameInstalls
onready var _btn_get_kenan = $Main/Tabs/Mods/HBox/Available/BtnDownloadKenan
onready var _version_check_request = HTTPRequest.new()

var _disable_savestate := {}
var _installs := {}

# For UI scaling on the fly
var _base_min_sizes := {}
var _base_icon_sizes := {}

var _easter_egg_counter := 0

const VERSION_CHECK_URL = "https://api.github.com/repos/Hihahahalol/Catapult_Dabdoob/releases/latest"
var _latest_version = ""
var _is_update_available = false
var _release_page_url = ""
var _download_urls = []


func _ready() -> void:
	
	# Add the HTTPRequest node for version checking
	add_child(_version_check_request)
	_version_check_request.connect("request_completed", self, "_on_version_check_completed")
	
	# Apply UI theme
	var theme_file = Settings.read("launcher_theme")
	load_ui_theme(theme_file)
	
	_save_control_min_sizes()
	_scale_control_min_sizes(Geom.scale)
	Geom.connect("scale_changed", self, "_on_ui_scale_changed")
	
	assign_localized_text()
	
	_btn_resume.grab_focus()
	
	var welcome_msg = tr("str_welcome")
	if Settings.read("print_tips_of_the_day"):
		welcome_msg += tr("str_tip_of_the_day") + TOTD.get_tip() + "\n"
	Status.post(welcome_msg)
	
	_unpack_utils()
	_setup_ui()
	
	# Connect the BtnCheck button signal
	_btn_check.connect("pressed", self, "_on_BtnCheck_pressed")
	# Connect the BtnUpdate button signal
	_btn_update.connect("pressed", self, "_on_BtnUpdate_pressed")


func _save_control_min_sizes() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if ("rect_min_size" in node) and (node.rect_min_size != Vector2.ZERO):
			_base_min_sizes[node] = node.rect_min_size


func _scale_control_min_sizes(factor: float) -> void:
	
	for node in _base_min_sizes:
		node.rect_min_size = _base_min_sizes[node] * factor


func _save_icon_sizes() -> void:
	
	var resources = load("res://")


func assign_localized_text() -> void:
	
	var version = Settings.read("version")
	OS.set_window_title(tr("window_title"))	
	
	_tabs.set_tab_title(0, tr("tab_game"))
	_tabs.set_tab_title(1, tr("tab_mods"))
	_tabs.set_tab_title(2, tr("tab_soundpacks"))
	_tabs.set_tab_title(3, tr("tab_fonts"))
	_tabs.set_tab_title(4, tr("tab_backups"))
	_tabs.set_tab_title(5, tr("tab_settings"))
	
	_lbl_changelog.bbcode_text = tr("lbl_changelog")
	
	var game = Settings.read("game")
	if game == "dda":
		_game_desc.bbcode_text = tr("desc_dda")
	elif game == "bn":
		_game_desc.bbcode_text = tr("desc_bn")
	elif game == "eod":
		_game_desc.bbcode_text = tr("desc_eod")
	elif game == "tish":
		_game_desc.bbcode_text = tr("desc_tish")
	elif game == "tlg":
		_game_desc.bbcode_text = tr("desc_tlg")


func load_ui_theme(theme_file: String) -> void:
	
	# Since we've got multiple themes that have some shared elements (like fonts),
	# we have to make sure old theme's *scaled* sizes don't become new theme's
	# *base* sizes. To avoid that, we have to reset the scale of the old theme
	# before replacing it, and we have to do that before we even attempt to load
	# the new theme.
	
	self.theme.apply_scale(1.0)
	var new_theme := load("res://themes".plus_file(theme_file)) as ScalableTheme
	
	if new_theme:
		new_theme.apply_scale(Geom.scale)
		self.theme = new_theme
	else:
		self.theme.apply_scale(Geom.scale)
		Status.post(tr("msg_theme_load_error") % theme_file, Enums.MSG_ERROR)


func _unpack_utils() -> void:
	
	var d = Directory.new()
	var unzip_exe = Paths.utils_dir.plus_file("unzip.exe")
	if (OS.get_name() == "Windows") and (not d.file_exists(unzip_exe)):
		if not d.dir_exists(Paths.utils_dir):
			d.make_dir(Paths.utils_dir)
		Status.post(tr("msg_unpacking_unzip"))
		d.copy("res://utils/unzip.exe", unzip_exe)
	var zip_exe = Paths.utils_dir.plus_file("zip.exe")
	if (OS.get_name() == "Windows") and (not d.file_exists(zip_exe)):
		if not d.dir_exists(Paths.utils_dir):
			d.make_dir(Paths.utils_dir)
		Status.post(tr("msg_unpacking_zip"))
		d.copy("res://utils/zip.exe", zip_exe)
	


func _smart_disable_controls(group_name: String) -> void:
	
	var nodes = get_tree().get_nodes_in_group(group_name)
	var state = {}
	
	for n in nodes:
		if "disabled" in n:
			state[n] = n.disabled
			n.disabled = true
			
	_disable_savestate[group_name] = state
	

func _smart_reenable_controls(group_name: String) -> void:
	
	if not group_name in _disable_savestate:
		return
	
	var state = _disable_savestate[group_name]
	for node in state:
		node.disabled = state[node]
		
	_disable_savestate.erase(group_name)


func _on_ui_scale_changed(new_scale: float) -> void:
	
	_scale_control_min_sizes(new_scale)


func _on_Tabs_tab_changed(tab: int) -> void:
	
	_refresh_currently_installed()


func _on_GamesList_item_selected(index: int) -> void:
	
	match index:
		0:
			Settings.store("game", "dda")
			_game_desc.bbcode_text = tr("desc_dda")
		1:
			Settings.store("game", "bn")
			_game_desc.bbcode_text = tr("desc_bn")
		2:
			Settings.store("game", "eod")
			_game_desc.bbcode_text = tr("desc_eod")
		3:
			Settings.store("game", "tish")
			_game_desc.bbcode_text = tr("desc_tish")
		4:
			Settings.store("game", "tlg")
			_game_desc.bbcode_text = tr("desc_tlg")
	
	_tabs.current_tab = 0
	apply_game_choice()
	_refresh_currently_installed()
	
	_mods.refresh_installed()
	_mods.refresh_available()


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
	if (Settings.read("game") == "eod") or (Settings.read("game") == "tish"):
		Settings.store("channel", "experimental")


	if button_pressed:
		Settings.store("channel", "stable")
	else:
		Settings.store("channel", "experimental")
		
	apply_game_choice()


func _on_Releases_started_fetching_releases() -> void:
	
	_smart_disable_controls("disable_while_fetching_releases")


func _on_Releases_done_fetching_releases() -> void:
	
	_smart_reenable_controls("disable_while_fetching_releases")
	reload_builds_list()
	_refresh_currently_installed()


func _on_ReleaseInstaller_operation_started() -> void:
	
	_smart_disable_controls("disable_during_release_operations")


func _on_ReleaseInstaller_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_release_operations")
	_refresh_currently_installed()


func _on_mod_operation_started() -> void:
	
	_smart_disable_controls("disable_during_mod_operations")


func _on_mod_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_mod_operations")


func _on_soundpack_operation_started() -> void:
	
	_smart_disable_controls("disable_during_soundpack_operations")


func _on_soundpack_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_soundpack_operations")


func _on_backup_operation_started() -> void:
	
	_smart_disable_controls("disable_during_backup_operations")


func _on_backup_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_backup_operations")


func _on_Description_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)


func _on_ChangelogLink_meta_clicked(meta) -> void:
	
	_changelog.open()


func _on_Log_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)


func _on_BtnRefresh_pressed() -> void:
	
	_releases.fetch(_get_release_key())


func _on_BuildsList_item_selected(index: int) -> void:
	
	var info = Paths.installs_summary
	var game = Settings.read("game")
	
	if (not Settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (_releases.releases[_get_release_key()][index]["name"] in info[game]):
		_btn_install.disabled = true
		_cb_update.disabled = true
	else:
		_btn_install.disabled = false
		_cb_update.disabled = false


func _on_BtnInstall_pressed() -> void:
	
	var index = _lst_builds.selected
	var release = _releases.releases[_get_release_key()][index]
	var update_path := ""
	if Settings.read("update_current_when_installing"):
		var game = Settings.read("game")
		var active_name = Settings.read("active_install_" + game)
		if (game in _installs) and (active_name in _installs[game]):
			update_path = _installs[game][active_name]
	_installer.install_release(release, Settings.read("game"), update_path)


func _on_cbUpdateCurrent_toggled(button_pressed: bool) -> void:
	
	Settings.store("update_current_when_installing", button_pressed)


func _get_release_key() -> String:
	# Compiles a string looking like "dda-stable" or "bn-experimental"
	# from settings.
	
	var game = Settings.read("game")
	var key = game + "-" + Settings.read("channel")
	
	return key


func _on_GameDir_pressed() -> void:
	
	var gamedir = Paths.game_dir
	if Directory.new().dir_exists(gamedir):
		OS.shell_open(gamedir)


func _on_UserDir_pressed() -> void:
	
	var userdir = Paths.userdata
	if Directory.new().dir_exists(userdir):
		OS.shell_open(userdir)


func _setup_ui() -> void:

	_game_info.visible = Settings.read("show_game_desc")
	if not Settings.read("debug_mode"):
		_tabs.remove_child(_debug_ui)
	
	_cb_update.pressed = Settings.read("update_current_when_installing")
	
	apply_game_choice()
	
	_lst_games.connect("item_selected", self, "_on_GamesList_item_selected")
	_rbtn_stable.connect("toggled", self, "_on_RBtnStable_toggled")
	# Had to leave these signals unconnected in the editor and only connect
	# them now from code to avoid cyclic calls of apply_game_choice.
	
	_refresh_currently_installed()


func reload_builds_list() -> void:
	
	_lst_builds.clear()
	for rec in _releases.releases[_get_release_key()]:
			_lst_builds.add_item(rec["name"])
	_refresh_currently_installed()


func apply_game_choice() -> void:
	
	# TODO: Turn this mess into a more elegant mess.

	var game = Settings.read("game")
	var channel = Settings.read("channel")
	
	if (game == "dda") or (game == "bn"):
		_rbtn_exper.disabled = false
		_rbtn_stable.disabled = false
		# Thes Forks do have the Kenan Modpack
		_btn_get_kenan.disabled = false
		_btn_get_kenan.hint_tooltip = tr("tooltip_get_kenan_pack")
		if channel == "stable":
			_rbtn_stable.pressed = true
			_btn_refresh.disabled = true
		else:
			_btn_refresh.disabled = false
	elif game in ["eod", "tish", "tlg"]:
		# These Forks do not have a stable channel
		_rbtn_exper.pressed = true
		_rbtn_exper.disabled = true
		_rbtn_stable.disabled = true
		_btn_refresh.disabled = false
		# These Forks do not have the Kenan Modpack
		_btn_get_kenan.disabled = true
		_btn_get_kenan.hint_tooltip = tr("tooltip_no_kenan_pack")

	match game:
		"dda":
			_lst_games.select(0)
			_game_desc.bbcode_text = tr("desc_dda")
				
		"bn":
			_lst_games.select(1)
			_game_desc.bbcode_text = tr("desc_bn")

		"eod":
			_lst_games.select(2)
			_game_desc.bbcode_text = tr("desc_eod")

		"tish":
			_lst_games.select(3)
			_game_desc.bbcode_text = tr("desc_tish")

		"tlg":
			_lst_games.select(4)
			_game_desc.bbcode_text = tr("desc_tlg")
	
	if len(_releases.releases[_get_release_key()]) == 0:
		_releases.fetch(_get_release_key())
	else:
		reload_builds_list()


func _on_BtnPlay_pressed() -> void:
	
	_start_game()


func _on_BtnResume_pressed() -> void:
	
	var lastworld: String = Paths.config.plus_file("lastworld.json")
	var info = Helpers.load_json_file(lastworld)
	if info:
		_start_game(info["world_name"])


func _start_game(world := "") -> void:
	
	match OS.get_name():
		"X11":
			var params := ["--userdir", Paths.userdata + "/"]
			if world != "":
				params.append_array(["--world", world])
			OS.execute(Paths.game_dir.plus_file("cataclysm-launcher"), params, false)
		"Windows":
			var world_str := ""
			if world != "":
				world_str = "--world \"%s\"" % world

			var exe_file = "cataclysm-tiles.exe"
			if Settings.read("game") == "bn" and Directory.new().file_exists(Paths.game_dir.plus_file("cataclysm-bn-tiles.exe")):
				exe_file = "cataclysm-bn-tiles.exe"
			if Settings.read("game") == "tlg" and Directory.new().file_exists(Paths.game_dir.plus_file("cataclysm-tlg-tiles.exe")):
				exe_file = "cataclysm-tlg-tiles.exe"

			var command = "cd /d %s && start %s --userdir \"%s/\" %s" % [Paths.game_dir, exe_file, Paths.userdata, world_str]
			OS.execute("cmd", ["/C", command], false)
		_:
			return
	
	if not Settings.read("keep_open_after_starting_game"):
		get_tree().quit()


func _on_InstallsList_item_selected(index: int) -> void:
	
	var name = _lst_installs.get_item_text(index)
	_btn_delete.disabled = false
	_btn_make_active.disabled = (name == Settings.read("active_install_" + Settings.read("game")))


func _on_InstallsList_item_activated(index: int) -> void:
	
	var name = _lst_installs.get_item_text(index)
	var path = _installs[Settings.read("game")][name]
	if Directory.new().dir_exists(path):
		OS.shell_open(path)


func _on_btnMakeActive_pressed() -> void:
	
	var name = _lst_installs.get_item_text(_lst_installs.get_selected_items()[0])
	Status.post(tr("msg_set_active") % name)
	Settings.store("active_install_" + Settings.read("game"), name)
	_refresh_currently_installed()


func _on_btnDelete_pressed() -> void:
	
	var name = _lst_installs.get_item_text(_lst_installs.get_selected_items()[0])
	_installer.remove_release_by_name(name)


func _refresh_currently_installed() -> void:
	
	var releases = _releases.releases[_get_release_key()]

	_lst_installs.clear()
	var game = Settings.read("game")
	_installs = Paths.installs_summary
	var active_name = Settings.read("active_install_" + game)
	if game in _installs:
		for name in _installs[game]:
			_lst_installs.add_item(name)
			var curr_idx = _lst_installs.get_item_count() - 1
			_lst_installs.set_item_tooltip(curr_idx, tr("tooltip_installs_item") % _installs[game][name])
#			if name == active_name:
#				_lst_installs.set_item_custom_fg_color(curr_idx, Color(0, 0.8, 0))
	
	_lst_builds.select(-1)
	_btn_make_active.disabled = true
	_btn_delete.disabled = true
	
	if game in _installs:
		_lbl_build.text = active_name
		_btn_play.disabled = false
		_btn_resume.disabled = not (Directory.new().file_exists(Paths.config.plus_file("lastworld.json")))
		_btn_game_dir.visible = true
		_btn_user_dir.visible = true
		if (_lst_builds.selected != -1) and (_lst_builds.selected < len(releases)):
				if not Settings.read("update_to_same_build_allowed"):
					_btn_install.disabled = (releases[_lst_builds.selected]["name"] in _installs[game])
					_cb_update.disabled = _btn_install.disabled
		else:
			_btn_install.disabled = true

	else:
		_lbl_build.text = tr("lbl_none")
		_btn_install.disabled = false
		_cb_update.disabled = true
		_btn_play.disabled = true
		_btn_resume.disabled = true
		_btn_game_dir.visible = false
		_btn_user_dir.visible = false
	
	if (game in _installs and _installs[game].size() > 1) or \
			(Settings.read("always_show_installs") == true):
		_panel_installs.visible = true
	else:
		_panel_installs.visible = false

	for i in [1, 2, 3, 4]:
		_tabs.set_tab_disabled(i, not game in _installs)


func _on_InfoIcon_gui_input(event: InputEvent) -> void:
	
	if (event is InputEventMouseButton) and (event.button_index == BUTTON_LEFT) and (event.is_pressed()):
		_easter_egg_counter += 1
		if _easter_egg_counter == 3:
			Status.post("[color=red]%s[/color]" % tr("msg_easter_egg_warning"))
		if _easter_egg_counter == 10:
			_activate_easter_egg()


func _activate_easter_egg() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if node is Control:
			node.rect_pivot_offset = node.rect_size / 2.0
			node.rect_rotation = randf() * 2.0 - 1.0
	
	Status.rainbow_text = true
	
	for i in range(20):
		Status.post(tr("msg_easter_egg_activated"))
		yield(get_tree().create_timer(0.1), "timeout")


func _on_BtnCheck_pressed() -> void:
	var current_version = Settings.read("version")
	Status.post(tr("Checking for updates... Current version: v%s") % current_version)
	
	# Disable the button while checking
	_btn_check.disabled = true
	_btn_update.disabled = true
	
	# Make the HTTP request to GitHub
	var error = _version_check_request.request(VERSION_CHECK_URL)
	if error != OK:
		Status.post(tr("Error making HTTP request"), Enums.MSG_ERROR)
		_btn_check.disabled = false

func _on_version_check_completed(result, response_code, headers, body):
	_btn_check.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		Status.post(tr("Failed to connect to update server"), Enums.MSG_ERROR)
		return
		
	if response_code != 200:
		Status.post(tr("Error response from update server: %d") % response_code, Enums.MSG_ERROR)
		return
	
	# Parse the JSON response
	var json = JSON.parse(body.get_string_from_utf8())
	if json.error != OK:
		Status.post(tr("Error parsing response from server"), Enums.MSG_ERROR)
		return
	
	var response = json.result
	if typeof(response) != TYPE_DICTIONARY:
		Status.post(tr("Invalid response format from server"), Enums.MSG_ERROR)
		return
	
	if "name" in response:
		_latest_version = response["name"]
		var current_version = Settings.read("version")
		
		Status.post(tr("Latest version available: v%s") % _latest_version)
		
		# Store the browser download URL from the API response
		if "html_url" in response:
			_release_page_url = response["html_url"]
		else:
			_release_page_url = "https://github.com/Hihahahalol/Catapult_Dabdoob/releases/latest"
		
		# Find downloadable assets in the response
		_download_urls = []
		if "assets" in response and response["assets"] is Array and response["assets"].size() > 0:
			for asset in response["assets"]:
				if "browser_download_url" in asset:
					_download_urls.append({
						"name": asset.get("name", "unknown"),
						"size": asset.get("size", 0),
						"url": asset["browser_download_url"]
					})
		
		# Simple version comparison
		if _is_newer_version(_latest_version, current_version):
			Status.post(tr("A new version is available! You can update to v%s") % _latest_version, Enums.MSG_SUCCESS)
			_btn_update.disabled = false
			_is_update_available = true
		else:
			Status.post(tr("You have the latest version!"), Enums.MSG_SUCCESS)
			_btn_update.disabled = true
			_is_update_available = false
	else:
		Status.post(tr("Could not determine latest version"), Enums.MSG_ERROR)

func _is_newer_version(latest: String, current: String) -> bool:
	# Split version strings and convert to integers
	var latest_parts = latest.split(".")
	var current_parts = current.split(".")
	
	# Compare major version first
	if latest_parts.size() > 0 and current_parts.size() > 0:
		var latest_major = int(latest_parts[0])
		var current_major = int(current_parts[0])
		
		if latest_major > current_major:
			return true
		elif latest_major < current_major:
			return false
	
	# If major versions are equal, compare minor version
	if latest_parts.size() > 1 and current_parts.size() > 1:
		var latest_minor = int(latest_parts[1])
		var current_minor = int(current_parts[1])
		
		if latest_minor > current_minor:
			return true
	
	return false

func _on_BtnUpdate_pressed() -> void:
	if _is_update_available:
		Status.post(tr("Starting update to version v%s...") % _latest_version)
		_perform_update()
	else:
		Status.post(tr("No update available"))

func _perform_update() -> void:
	# Check if we have download URLs available
	if _download_urls.empty():
		Status.post(tr("No download URLs found. Opening release page in browser..."))
		OS.shell_open(_release_page_url)
		return
	
	# Disable buttons during update
	_btn_check.disabled = true
	_btn_update.disabled = true
	
	# Create a temporary directory for the download
	var temp_dir = OS.get_user_data_dir().plus_file("update_temp")
	var dir = Directory.new()
	if dir.dir_exists(temp_dir):
		_remove_directory_recursive(temp_dir)
	dir.make_dir(temp_dir)
	
	# Show update progress to user
	Status.post(tr("Downloading update from GitHub..."))
	
	# Find the appropriate asset for the current OS
	var download_url = ""
	var asset_name = ""
	var os_name = OS.get_name()
	
	# Log all available assets for debugging
	Status.post(tr("Available assets:"))
	for asset in _download_urls:
		Status.post("- " + asset["name"])
	
	for asset in _download_urls:
		var name = asset["name"].to_lower()
		
		# Check for Windows assets
		if os_name == "Windows" and (name.find("win") >= 0 or name.find("windows") >= 0 or name.ends_with(".exe")):
			download_url = asset["url"]
			asset_name = asset["name"]
			Status.post(tr("Selected Windows asset: %s") % asset_name)
			break
		
		# Check for Linux assets
		elif os_name == "X11" and (name.find("linux") >= 0 or name.find("x86_64") >= 0 or name.ends_with(".x86_64")):
			download_url = asset["url"]
			asset_name = asset["name"]
			Status.post(tr("Selected Linux asset: %s") % asset_name)
			break
	
	# If no matching asset was found, use the first one as a fallback
	if download_url.empty():
		Status.post(tr("No OS-specific asset found for %s, using first available") % os_name)
		download_url = _download_urls[0]["url"]
		asset_name = _download_urls[0]["name"]
		
	Status.post(tr("Downloading %s...") % asset_name)
	
	# Set up the downloader
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_update_download_completed", [temp_dir, asset_name])
	
	# Start the download
	var error = http_request.request(download_url)
	if error != OK:
		Status.post(tr("Error starting download: %s") % error, Enums.MSG_ERROR)
		_cleanup_update(http_request, temp_dir)

func _on_update_download_completed(result, response_code, headers, body, temp_dir, asset_name):
	var http_request = get_node_or_null("HTTPRequest")
	if http_request:
		remove_child(http_request)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS:
		Status.post(tr("Download failed with error code: %s") % result, Enums.MSG_ERROR)
		_cleanup_update(null, temp_dir)
		return
		
	if response_code != 200:
		Status.post(tr("Server returned error code: %s") % response_code, Enums.MSG_ERROR)
		_cleanup_update(null, temp_dir)
		return
	
	# Save the downloaded file
	var downloaded_file = temp_dir.plus_file(asset_name)
	var file = File.new()
	var error = file.open(downloaded_file, File.WRITE)
	if error != OK:
		Status.post(tr("Failed to create temporary file: %s") % error, Enums.MSG_ERROR)
		_cleanup_update(null, temp_dir)
		return
		
	file.store_buffer(body)
	file.close()
	
	Status.post(tr("Download complete. Preparing update..."))
	
	# Create a PowerShell script to handle the update
	_create_powershell_updater(downloaded_file)

func _create_powershell_updater(downloaded_file):
	var current_exe = OS.get_executable_path()
	
	# Create a much simpler PowerShell script for updating just the executable
	var ps_script = """
# Dabdoob Update Script - Single Executable Updater
$ErrorActionPreference = "Stop"

# Log function
function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath "$env:USERPROFILE\\AppData\\Roaming\\Godot\\app_userdata\\Dabdoob\\update_log.txt" -Append
}

# Clear previous log and start a new one
if (Test-Path "$env:USERPROFILE\\AppData\\Roaming\\Godot\\app_userdata\\Dabdoob\\update_log.txt") {
    Remove-Item -Path "$env:USERPROFILE\\AppData\\Roaming\\Godot\\app_userdata\\Dabdoob\\update_log.txt" -Force
}

Log-Message "Starting update process"
Log-Message "Downloaded file: %s"
Log-Message "Target executable: %s"

try {
    # Wait for main process to exit
    Log-Message "Waiting for application to close..."
    Start-Sleep -Seconds 5
    
    $processName = [System.IO.Path]::GetFileNameWithoutExtension("%s")
    Log-Message "Process name: $processName"
    
    # Check if process is still running
    $running = Get-Process -Name $processName -ErrorAction SilentlyContinue
    
    if ($running) {
        Log-Message "Process still running, waiting another 5 seconds..."
        Start-Sleep -Seconds 5
        
        # Try to forcefully terminate if still running
        $running = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($running) {
            Log-Message "Terminating process..."
            Stop-Process -Name $processName -Force
            Start-Sleep -Seconds 2
        }
    }
    
    # Check if source and target files exist
    if (-not (Test-Path "%s")) {
        throw "Source file not found: %s"
    }
    
    Log-Message "Source file exists and has size: $((Get-Item -Path "%s").Length) bytes"
    
    if (Test-Path "%s") {
        Log-Message "Target file exists and has size: $((Get-Item -Path "%s").Length) bytes"
    } else {
        Log-Message "Target file does not exist yet"
    }
    
    # Copy the executable
    Log-Message "Copying executable file..."
    Copy-Item -Path "%s" -Destination "%s" -Force
    
    # Verify the copy worked
    if (Test-Path "%s") {
        Log-Message "Verified: Target file now exists with size: $((Get-Item -Path "%s").Length) bytes"
    } else {
        throw "Failed to create target file"
    }
    
    # Start the updated application
    Log-Message "Update complete, starting application..."
    Start-Process -FilePath "%s"
    
    # Clean up
    Log-Message "Cleaning up..."
    Start-Sleep -Seconds 2
    Remove-Item -Path "%s" -Force -ErrorAction SilentlyContinue
    
    Log-Message "Update completed successfully"
} catch {
    Log-Message "Error during update: $_"
    Log-Message "Stack trace: $($_.ScriptStackTrace)"
}
""" % [
	downloaded_file.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	current_exe.get_file(),
	downloaded_file.replace("/", "\\"),
	downloaded_file.replace("/", "\\"),
	downloaded_file.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	downloaded_file.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	current_exe.replace("/", "\\"),
	downloaded_file.replace("/", "\\")
]
	
	var ps_path = OS.get_user_data_dir().plus_file("update.ps1")
	var file = File.new()
	file.open(ps_path, File.WRITE)
	file.store_string(ps_script)
	file.close()
	
	# Create a simple batch file to launch PowerShell with elevated privileges
	var bat_script = """
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%s"
""" % ps_path.replace("/", "\\")
	
	var bat_path = OS.get_user_data_dir().plus_file("update_launcher.bat")
	file = File.new()
	file.open(bat_path, File.WRITE)
	file.store_string(bat_script)
	file.close()
	
	# Log
	Status.post(tr("Update ready! Dabdoob will restart to complete the update."))
	Status.post(tr("Update logs will be saved to: %s") % OS.get_user_data_dir().plus_file("update_log.txt"))
	
	# Execute the batch file and exit
	if OS.get_name() == "Windows":
		# Run the PowerShell script without showing a window
		OS.execute("cmd.exe", ["/c", "start", "/b", bat_path], false)
		yield(get_tree().create_timer(2.0), "timeout")
		get_tree().quit()
	else:
		Status.post(tr("Automatic updates are only supported on Windows. Please update manually."))
		OS.shell_open(_release_page_url)
		_cleanup_update(null, OS.get_user_data_dir().plus_file("update_temp"))

func _cleanup_update(http_request, temp_dir):
	if http_request:
		remove_child(http_request)
		http_request.queue_free()
	
	# Re-enable buttons
	_btn_check.disabled = false
	_btn_update.disabled = false
	
	# Clean up temporary directory
	if temp_dir:
		_remove_directory_recursive(temp_dir)
		
func _remove_directory_recursive(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_remove_directory_recursive(path.plus_file(file_name))
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		dir.change_dir("..")
		dir.remove(path)
