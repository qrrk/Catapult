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

var _disable_savestate := {}
var _installs := {}

# For UI scaling on the fly
var _base_min_sizes := {}
var _base_icon_sizes := {}

var _easter_egg_counter := 0


func _ready() -> void:
	
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
		Status.post(tr("msg_unpacking_unzip"))
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
		if channel == "stable":
			_rbtn_stable.pressed = true
			_btn_refresh.disabled = true
		else:
			_btn_refresh.disabled = false
	elif (game == "eod") or (game == "tish"):
		_rbtn_exper.pressed = true
		_rbtn_exper.disabled = true
		_rbtn_stable.disabled = true
		_btn_refresh.disabled = false

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
			var command = "cd /d %s && start cataclysm-tiles.exe --userdir \"%s/\" %s" % [Paths.game_dir, Paths.userdata, world_str]
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
