extends Node


const _GAME_DESC = {
	"dda":
		"[b]Cataclysm: Dark Days Ahead[/b] is a turn-based survival game set in a post-apocalyptic world. Scavenge, explore, craft, build, farm, repair and modify vehicles, install bionics, mutate, defend against [color=#009900]zombies[/color] and countless other monstrosities — all in a limitless, procedurally generated world!",
	"bn":
		"[b]Cataclysm: Bright Nights[/b]. Reject pedantry, embrace [color=#ff3300]!!fun!![/color]. This fork takes the game back to its sci-fi rougelike roots and reverts many controversial changes by the DDA team (pockets, proficiencies, freezing, and [color=#3b93f7][url=https://github.com/cataclysmbnteam/Cataclysm-BN/wiki/Changes-so-far]more[/url][/color]). Special attention is paid to combat, game balance and pacing.",
}


onready var _settings = $"/root/SettingsManager"
onready var _geom = $"/root/WindowGeometry"

var _debug_mode: bool = false

var _disable_savestate = {}
var _ui_staring_sizes = {}  # For UI scaling on the fly


func _ready() -> void:
	
	OS.set_window_title("Catapult — a launcher for Cataclysm: DDA and BN")
	
	$Main/Log.text = ""
	var welcome_msg = "Welcome to Catapult!"
	if _settings.read("print_tips_of_the_day"):
		welcome_msg += "\n\n[u]Tip of the day:[/u]\n" + $TOTD.get_tip() + "\n"
	print_msg(welcome_msg)
	_debug_mode = _settings.read("debug_mode")
	setup_ui()


func apply_ui_scale() -> void:
	# Scale all kinds of fixed sizes with DPI.
	
	$".".get_font("DynamicFont").size = 14.0 * _geom.scale
	
	for node in [$Main/GameInfo/Description, $Main/Log, $Main/Tabs/Mods/ModInfo]:
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
			
	var theme = $".".theme
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
			if not _debug_mode:
				return
			bb_text += " [color=#999999][debug] %s[/color]" % msg
	
	bb_text += "\n"
	$Main/Log.append_bbcode(bb_text)


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
	
	var info = $InstallProbe.probe_installed_games()
	var game = _settings.read("game")
	return (game in info)


func _on_GamesList_item_selected(index: int) -> void:
	
	match index:
		0:
			_settings.store("game", "dda")
			$Main/GameInfo/Description.bbcode_text = _GAME_DESC["dda"]
		1:
			_settings.store("game", "bn")
			$Main/GameInfo/Description.bbcode_text = _GAME_DESC["bn"]
	
	$Main/Tabs.current_tab = 0
	apply_game_choice()
	_refresh_currently_installed()
	
	$Mods.refresh_installed()
	$Mods.refresh_available()


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
	
	$Releases.fetch(_get_release_key())


func _on_BuildsList_item_selected(index: int) -> void:
	
	var info = $InstallProbe.probe_installed_games()
	var game = _settings.read("game")
	var btn = $Main/Tabs/Game/BtnInstall
	
	if (not _settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (info[game]["name"] == $Releases.releases[_get_release_key()][index]["name"]):
		btn.disabled = true
	else:
		btn.disabled = false


func _on_status_message(msg: String, msg_type: int = Enums.MSG_INFO) -> void:
	
	print_msg(msg, msg_type)


func _on_BtnInstall_pressed() -> void:
	
	var index = $Main/Tabs/Game/Builds/BuildsList.selected
	var release = $Releases.releases[_get_release_key()][index]
	var update = _settings.read("game") in $InstallProbe.probe_installed_games()
	$ReleaseInstaller.install_release(release, _settings.read("game"), update)


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


func setup_ui() -> void:

	$Main/GameInfo.visible = _settings.read("show_game_desc")
	
	if not _settings.read("debug_mode"):
		$Main/Tabs/Debug.queue_free()
	
	apply_game_choice()
	
	$Main/GameChoice/GamesList.connect("item_selected", self, "_on_GamesList_item_selected")
	$Main/Tabs/Game/Channel/Group/RBtnStable.connect("toggled", self, "_on_RBtnStable_toggled")
	# Had to leave these signals unconnected in the editor and only connect
	# them now from code to avoid cyclic calls of apply_game_choice.
	
	_refresh_currently_installed()


func reload_builds_list() -> void:
	
	var list = $Main/Tabs/Game/Builds/BuildsList
	list.clear()
	for rec in $Releases.releases[_get_release_key()]:
			list.add_item(rec["name"])
	_refresh_currently_installed()


func apply_game_choice() -> void:
	
	# TODO: Turn this mess into a more elegant mess.

	var game = _settings.read("game")
	var channel = _settings.read("channel")

	match game:
		"dda":
			$Main/GameChoice/GamesList.select(0)
			$Main/Tabs/Game/Channel/Group/RBtnExperimental.disabled = false
			$Main/Tabs/Game/Channel/Group/RBtnStable.disabled = false
			if channel == "stable":
				$Main/Tabs/Game/Channel/Group/RBtnStable.pressed = true
				$Main/Tabs/Game/Builds/BtnRefresh.disabled = true
			else:
				$Main/Tabs/Game/Builds/BtnRefresh.disabled = false
		"bn":
			$Main/GameChoice/GamesList.select(1)
			$Main/Tabs/Game/Channel/Group/RBtnExperimental.pressed = true
			$Main/Tabs/Game/Channel/Group/RBtnExperimental.disabled = true
			$Main/Tabs/Game/Channel/Group/RBtnStable.disabled = true
			$Main/Tabs/Game/Builds/BtnRefresh.disabled = false
			
	$Main/GameInfo/Description.bbcode_text = _GAME_DESC[game]
	
	if len($Releases.releases[_get_release_key()]) == 0:
		$Releases.fetch(_get_release_key())
	else:
		reload_builds_list()


func _on_BtnPlay_pressed() -> void:
	
	var exec_path = $FSHelper.get_own_dir().plus_file(_settings.read("game")).plus_file("current")
	match OS.get_name():
		"X11":
			OS.execute(exec_path.plus_file("cataclysm-launcher"), [], false)
		"Windows":
			var command = "cd /d %s && start cataclysm-tiles.exe" % exec_path
			OS.execute("cmd", ["/C", command], false)


func _refresh_currently_installed() -> void:
	
	var info = $InstallProbe.probe_installed_games()
	var game = _settings.read("game")
	var list = $Main/Tabs/Game/Builds/BuildsList
	var label = $Main/Tabs/Game/CurrentInstall/Build
	var btn_install = $Main/Tabs/Game/BtnInstall
	var btn_play = $Main/Tabs/Game/CurrentInstall/BtnPlay
	var releases = $Releases.releases[_get_release_key()]
	
	if _is_selected_game_installed():
		label.text = info[game]["name"]
		btn_install.text = "Update to Selected"
		btn_play.disabled = false
		if (list.selected != -1) and (list.selected < len(releases)):
			btn_install.disabled = (releases[list.selected]["name"] == info[game]["name"])
		else:
			btn_install.disabled = true
		
	else:
		label.text = "None"
		btn_install.text = "Install Selected"
		btn_install.disabled = false
		btn_play.disabled = true
		
	for i in [1, 2]:
		$Main/Tabs.set_tab_disabled(i, not _is_selected_game_installed())
