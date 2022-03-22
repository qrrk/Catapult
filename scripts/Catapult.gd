extends Node


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
onready var _changelog = $Main/Tabs/Game/ChangelogDialog
onready var _lbl_changelog = $Main/Tabs/Game/Channel/HBox/ChangelogLink
onready var _btn_game_dir = $Main/Tabs/Game/CurrentInstall/Build/GameDir
onready var _btn_user_dir = $Main/Tabs/Game/CurrentInstall/Build/UserDir
onready var _btn_play = $Main/Tabs/Game/CurrentInstall/Launch/BtnPlay
onready var _btn_resume = $Main/Tabs/Game/CurrentInstall/Launch/BtnResume
onready var _lst_builds = $Main/Tabs/Game/Builds/BuildsList
onready var _lst_games = $Main/GameChoice/GamesList
onready var _rbtn_stable = $Main/Tabs/Game/Channel/Group/RBtnStable
onready var _rbtn_exper = $Main/Tabs/Game/Channel/Group/RBtnExperimental
onready var _lbl_build = $Main/Tabs/Game/CurrentInstall/Build/Name

var _disable_savestate := {}
var _ui_staring_sizes := {}  # For UI scaling on the fly
var _easter_egg_counter := 0


func _ready() -> void:
	
	# Apply UI theme
	var theme_file = Settings.read("launcher_theme")
	load_ui_theme(theme_file)
	
	OS.set_window_title(tr("window_title"))
	
	# Apply translation to tab titles.
	_tabs.set_tab_title(0, tr("tab_game"))
	_tabs.set_tab_title(1, tr("tab_mods"))
	_tabs.set_tab_title(2, tr("tab_soundpacks"))
	_tabs.set_tab_title(3, tr("tab_fonts"))
	_tabs.set_tab_title(4, tr("tab_backups"))
	_tabs.set_tab_title(5, tr("tab_settings"))
	
	_lbl_changelog.bbcode_text = tr("lbl_changelog")
	
	var welcome_msg = tr("str_welcome")
	if Settings.read("print_tips_of_the_day"):
		welcome_msg += tr("str_tip_of_the_day") + _totd.get_tip() + "\n"
	Status.post(welcome_msg)
	
	_unpack_utils()
	setup_ui()


func load_ui_theme(theme_file: String) -> void:
	
	var theme := load("res://themes".plus_file(theme_file)) as Theme
	if theme:
		self.theme = theme
	else:
		Status.post(tr("msg_theme_load_error") % theme_file, Enums.MSG_ERROR)


func _unpack_utils() -> void:
	
	var d = Directory.new()
	var unzip_exe = Paths.utils_dir.plus_file("unzip.exe")
	if (OS.get_name() == "Windows") and (not d.file_exists(unzip_exe)):
		if not d.dir_exists(Paths.utils_dir):
			d.make_dir(Paths.utils_dir)
		Status.post(tr("msg_unpacking_unzip"))
		d.copy("res://utils/unzip.exe", unzip_exe)


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
	var game = Settings.read("game")
	return (game in info)


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
	
	_tabs.current_tab = 0
	apply_game_choice()
	_refresh_currently_installed()
	
	_mods.refresh_installed()
	_mods.refresh_available()


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
	
	if Settings.read("game") == "bn":
		return
	
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
	
	var info = _inst_probe.probe_installed_games()
	var game = Settings.read("game")
	
	if (not Settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (info[game]["name"] == _releases.releases[_get_release_key()][index]["name"]):
		_btn_install.disabled = true
	else:
		_btn_install.disabled = false


func _on_BtnInstall_pressed() -> void:
	
	var index = _lst_builds.selected
	var release = _releases.releases[_get_release_key()][index]
	var update = Settings.read("game") in _inst_probe.probe_installed_games()
	_installer.install_release(release, Settings.read("game"), update)


func _get_release_key() -> String:
	# Compiles a string looking like "dda-stable" or "bn-experimental"
	# from settings.
	
	var game = Settings.read("game")
	var key
	
	if game == "dda":
		key = game + "-" + Settings.read("channel")
	else:
		key = "bn-experimental"
	
	return key


func _on_GameDir_pressed() -> void:
	
	var gamedir = Paths.game_dir
	if Directory.new().dir_exists(gamedir):
		OS.shell_open(gamedir)


func _on_UserDir_pressed() -> void:
	
	var userdir = Paths.userdata
	if Directory.new().dir_exists(userdir):
		OS.shell_open(userdir)


func setup_ui() -> void:

	_game_info.visible = Settings.read("show_game_desc")
	if not Settings.read("debug_mode"):
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

	var game = Settings.read("game")
	var channel = Settings.read("channel")

	match game:
		"dda":
			_lst_games.select(0)
			_rbtn_exper.disabled = false
			_rbtn_stable.disabled = false
			if channel == "stable":
				_rbtn_stable.pressed = true
				_btn_refresh.disabled = true
			else:
				_btn_refresh.disabled = false
			_game_desc.bbcode_text = tr("desc_dda")
				
		"bn":
			_lst_games.select(1)
			_rbtn_exper.pressed = true
			_rbtn_exper.disabled = true
			_rbtn_stable.disabled = true
			_btn_refresh.disabled = false
			_game_desc.bbcode_text = tr("desc_bn")
	
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
			var command = "cd /d %s && start cataclysm-tiles.exe --userdir %s %s" % [Paths.game_dir, Paths.userdata, world_str]
			OS.execute("cmd", ["/C", command], false)


func _refresh_currently_installed() -> void:
	
	var info = _inst_probe.probe_installed_games()
	var game = Settings.read("game")
	var releases = _releases.releases[_get_release_key()]
	
	if _is_selected_game_installed():
		_lbl_build.text = info[game]["name"]
		_btn_install.text = tr("btn_update")
		_btn_play.disabled = false
		_btn_resume.disabled = not (Directory.new().file_exists(Paths.config.plus_file("lastworld.json")))
		_btn_game_dir.visible = true
		_btn_user_dir.visible = true
		if (_lst_builds.selected != -1) and (_lst_builds.selected < len(releases)):
				if not Settings.read("update_to_same_build_allowed"):
					_btn_install.disabled = (releases[_lst_builds.selected]["name"] == info[game]["name"])
		else:
			_btn_install.disabled = true
		
	else:
		_lbl_build.text = tr("lbl_none")
		_btn_install.text = tr("btn_install")
		_btn_install.disabled = false
		_btn_play.disabled = true
		_btn_resume.disabled = true
		_btn_game_dir.visible = false
		_btn_user_dir.visible = false
		
	for i in [1, 2, 3, 4]:
		_tabs.set_tab_disabled(i, not _is_selected_game_installed())


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
