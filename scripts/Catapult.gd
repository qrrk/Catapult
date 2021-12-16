extends Node


const _GAME_DESC = {
	"dda":
		"[b]Cataclysm: Dark Days Ahead[/b] is a turn-based survival game set in a post-apocalyptic world. Scavenge, explore, craft, build, farm, repair and modify vehicles, install bionics, mutate, defend against [color=#009900]zombies[/color] and countless other monstrosities — all in a limitless, procedurally generated world!",
	"bn":
		"[b]Cataclysm: Bright Nights[/b]. Reject pedantry, embrace [color=#ff3300]!!fun!![/color]. This fork takes the game back to its sci-fi roguelike roots and reverts many controversial changes by the DDA team (pockets, proficiencies, freezing, and [color=#3b93f7][url=https://github.com/cataclysmbnteam/Cataclysm-BN/wiki/Changes-so-far]more[/url][/color]). Special attention is paid to combat, game balance and pacing.",
}

onready var _settings = $"/root/SettingsManager"
onready var _geom = $"/root/WindowGeometry"
onready var _self = $"."
onready var _debug_ui = $Main/Tabs/Debug
onready var _log = $Main/Log
onready var _totd = $TOTD
onready var _game_info = $Main/GameInfo
onready var _game_desc = $Main/GameInfo/Description
onready var _mod_info = $Main/Tabs/Mods/ModInfo
onready var _inst_probe = $InstallProbe
onready var _tabs = $Main/Tabs
onready var _mods = $Mods
onready var _releases = $Releases
onready var _fshelper = $FSHelper
onready var _installer = $ReleaseInstaller
onready var _btn_install = $Main/Tabs/Game/BtnInstall
onready var _btn_refresh = $Main/Tabs/Game/Builds/BtnRefresh
onready var _btn_changelog = $Main/Tabs/Game/BtnChangelog
onready var _btn_game_dir = $Main/Tabs/Game/CurrentInstall/Build/GameDir
onready var _btn_play = $Main/Tabs/Game/CurrentInstall/BtnPlay
onready var _lst_builds = $Main/Tabs/Game/Builds/BuildsList
onready var _lst_games = $Main/GameChoice/GamesList
onready var _rbtn_stable = $Main/Tabs/Game/Channel/Group/RBtnStable
onready var _rbtn_exper = $Main/Tabs/Game/Channel/Group/RBtnExperimental
onready var _lbl_build = $Main/Tabs/Game/CurrentInstall/Build/Name
onready var _changelogger = $ChangelogPopup/Changelogger

var _disable_savestate = {}
var _ui_staring_sizes = {}  # For UI scaling on the fly


func _ready() -> void:
	
	OS.set_window_title("Catapult — a launcher for Cataclysm: DDA and BN")
	_log.text = ""
	
	var welcome_msg = "Welcome to Catapult!"
	if _settings.read("print_tips_of_the_day"):
		welcome_msg += "\n\n[u]Tip of the day:[/u]\n" + _totd.get_tip() + "\n"
	print_msg(welcome_msg)
	
	_unpack_utils()
	setup_ui()


func _unpack_utils() -> void:
	
	var d = Directory.new()
	var utils_dir = _fshelper.get_own_dir().plus_file("utils")
	var unzip_exe = utils_dir.plus_file("unzip.exe")
	if (OS.get_name() == "Windows") and (not d.file_exists(unzip_exe)):
		if not d.dir_exists(utils_dir):
			d.make_dir(utils_dir)
		print_msg("Unpacking unzip.exe...")
		d.copy("res://utils/unzip.exe", unzip_exe)


func apply_ui_scale() -> void:
	# Scale all kinds of fixed sizes with DPI.
	
	_self.get_font("DynamicFont").size = 14.0 * _geom.scale
	
	for node in [_game_desc, _log, _mod_info]:
		for font_prop in [
			"custom_fonts/normal_font",
			"custom_fonts/italics_font",
			"custom_fonts/bold_font",
			"custom_fonts/bold_italics_font"
			]:
			node.get(font_prop).size = 14.0 * _geom.scale
	
	for node in _get_all_nodes($"/root"):
		for property in [
				"custom_constants/separation",
				"rect_min_size",
				]:
			_try_scale_property(node, property, _geom.scale)
			
	var theme = _self.theme
	for node_type in ["CheckButton", "CheckBox", "SpinBox"]:
		for icon in theme.get_icon_list(node_type):
			_try_scale_property(theme.get_icon(icon, node_type), "size", _geom.scale)


func _try_scale_property(obj: Object, prop: String, multiplier: float) -> void:
	
	var value = obj.get(prop)
	if (value) and (typeof(value) in [TYPE_INT, TYPE_REAL, TYPE_VECTOR2, TYPE_RECT2]):
		if [obj, prop] in _ui_staring_sizes:
			obj.set(prop, _ui_staring_sizes[[obj, prop]] * multiplier)
		else:
			obj.set(prop, value * multiplier)
			_ui_staring_sizes[[obj, prop]] = value
#		print("Node: %s, property: %s, new value: %s" % [obj.name, prop, obj.get(prop)])


func _get_all_nodes(within: Node) -> Array:
	
	var result = []
	for node in within.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(_get_all_nodes(node))
	return result


func datetime_with_msecs(utc = false) -> Dictionary:
	
	var datetime = OS.get_datetime(utc)
	datetime["millisecond"] = OS.get_system_time_msecs() % 1000
	return datetime


func timestamp_with_msecs() -> String:
	
	var t = datetime_with_msecs()
	var s = "[%02d:%02d:%02d.%03d]" % [t.hour, t.minute, t.second, t.millisecond]
	return s


func print_msg(msg: String, msg_type = Enums.MSG_INFO) -> void:
	
	var text = ""
	var bb_text = ""
		
	var time = timestamp_with_msecs()
	text += time
	bb_text += "[color=#999999]%s[/color]" % time
	
	match msg_type:
		Enums.MSG_INFO:
			bb_text += " " + msg
		Enums.MSG_WARN:
			text += " [warning] " + msg
			bb_text += " [color=#ffd633][warning][/color] " + msg
			push_warning(text)
		Enums.MSG_ERROR:
			text += " [error] " + msg
			bb_text += " [color=#ff3333][error][/color] " + msg
			push_error(text)
		Enums.MSG_DEBUG:
			if not _settings.read("debug_mode"):
				return
			bb_text += " [color=#999999][debug] %s[/color]" % msg
	
	bb_text += "\n"
	
	if _log:
		_log.append_bbcode(bb_text)


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


func _is_selected_game_installed() -> bool:
	
	var info = _inst_probe.probe_installed_games()
	var game = _settings.read("game")
	return (game in info)


func _on_Tabs_tab_changed(tab: int) -> void:
	
	_refresh_currently_installed()


func _on_GamesList_item_selected(index: int) -> void:
	
	match index:
		0:
			_settings.store("game", "dda")
			_game_desc.bbcode_text = _GAME_DESC["dda"]
		1:
			_settings.store("game", "bn")
			_game_desc.bbcode_text = _GAME_DESC["bn"]
	
	_tabs.current_tab = 0
	apply_game_choice()
	_refresh_currently_installed()
	
	_mods.refresh_installed()
	_mods.refresh_available()


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
	
	if _settings.read("game") == "bn":
		return
	
	if button_pressed:
		_settings.store("channel", "stable")
	else:
		_settings.store("channel", "experimental")
		
	apply_game_choice()


func _on_Releases_started_fetching_releases() -> void:
	
	_smart_disable_controls("disable_while_fetching_releases")


func _on_Releases_done_fetching_releases() -> void:
	
	_smart_reenable_controls("disable_while_fetching_releases")
	reload_builds_list()
	_refresh_currently_installed()


func _on_ReleaseInstaller_installation_started() -> void:
	
	_smart_disable_controls("disable_while_installing_game")


func _on_ReleaseInstaller_installation_finished() -> void:
	
	_smart_reenable_controls("disable_while_installing_game")
	_refresh_currently_installed()


func _on_mod_operation_started() -> void:
	
	_smart_disable_controls("disable_during_mod_operations")


func _on_mod_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_mod_operations")


func _on_soundpack_operation_started() -> void:
	
	_smart_disable_controls("disable_during_soundpack_operations")


func _on_soundpack_operation_finished() -> void:
	
	_smart_reenable_controls("disable_during_soundpack_operations")


func _on_Description_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)


func _on_BtnRefresh_pressed() -> void:
	
	_releases.fetch(_get_release_key())


func _on_BuildsList_item_selected(index: int) -> void:
	
	var info = _inst_probe.probe_installed_games()
	var game = _settings.read("game")
	
	if (not _settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (info[game]["name"] == _releases.releases[_get_release_key()][index]["name"]):
		_btn_install.disabled = true
	else:
		_btn_install.disabled = false


func _on_status_message(msg: String, msg_type: int = Enums.MSG_INFO) -> void:
	
	print_msg(msg, msg_type)


func _on_BtnInstall_pressed() -> void:
	
	var index = _lst_builds.selected
	var release = _releases.releases[_get_release_key()][index]
	var update = _settings.read("game") in _inst_probe.probe_installed_games()
	_installer.install_release(release, _settings.read("game"), update)

func _on_BtnChangelog_pressed() -> void:
	$ChangelogPopup.rect_min_size = get_tree().root.size * Vector2(0.9, 0.9)
	$ChangelogPopup.set_as_minsize()
	$ChangelogPopup.popup_centered()
	_changelogger.download_pull_requests()
	
func _on_BtnCloseChangelog_pressed():
	$ChangelogPopup.hide()

func _get_release_key() -> String:
	# Compiles a string looking like "dda-stable" or "bn-experimental"
	# from settings.
	
	var game = _settings.read("game")
	var key
	
	if game == "dda":
		key = game + "-" + _settings.read("channel")
	else:
		key = "bn-experimental"
	
	return key


func _on_GameDir_pressed() -> void:
	
	var gamedir = _fshelper.get_own_dir().plus_file(_settings.read("game")).plus_file("current")
	if Directory.new().dir_exists(gamedir):
		OS.shell_open(gamedir)


func setup_ui() -> void:

	_game_info.visible = _settings.read("show_game_desc")
	if not _settings.read("debug_mode"):
		_tabs.remove_child(_debug_ui)
	
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

	var game = _settings.read("game")
	var channel = _settings.read("channel")

	match game:
		"dda":
			_lst_games.select(0)
			_rbtn_exper.disabled = false
			_rbtn_stable.disabled = false
			if channel == "stable":
				_rbtn_stable.pressed = true
				_btn_refresh.disabled = true
				_btn_changelog.disabled = true
			else:
				_btn_refresh.disabled = false
				_btn_changelog.disabled = false
				
		"bn":
			_lst_games.select(1)
			_rbtn_exper.pressed = true
			_rbtn_exper.disabled = true
			_rbtn_stable.disabled = true
			_btn_refresh.disabled = false
			
	_game_desc.bbcode_text = _GAME_DESC[game]
	
	if len(_releases.releases[_get_release_key()]) == 0:
		_releases.fetch(_get_release_key())
	else:
		reload_builds_list()


func _on_BtnPlay_pressed() -> void:
	
	var exec_path = _fshelper.get_own_dir().plus_file(_settings.read("game")).plus_file("current")
	match OS.get_name():
		"X11":
			OS.execute(exec_path.plus_file("cataclysm-launcher"), [], false)
		"Windows":
			var command = "cd /d %s && start cataclysm-tiles.exe" % exec_path
			OS.execute("cmd", ["/C", command], false)


func _refresh_currently_installed() -> void:
	
	var info = _inst_probe.probe_installed_games()
	var game = _settings.read("game")
	var releases = _releases.releases[_get_release_key()]
	
	if _is_selected_game_installed():
		_lbl_build.text = info[game]["name"]
		_btn_install.text = "Update to Selected"
		_btn_play.disabled = false
		_btn_game_dir.visible = true
		if (_lst_builds.selected != -1) and (_lst_builds.selected < len(releases)):
				if not _settings.read("update_to_same_build_allowed"):
					_btn_install.disabled = (releases[_lst_builds.selected]["name"] == info[game]["name"])
		else:
			_btn_install.disabled = true
		
	else:
		_lbl_build.text = "None"
		_btn_install.text = "Install Selected"
		_btn_install.disabled = false
		_btn_play.disabled = true
		_btn_game_dir.visible = false
		
	for i in [1, 2, 3]:
		_tabs.set_tab_disabled(i, not _is_selected_game_installed())
