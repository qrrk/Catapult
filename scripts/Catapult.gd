extends Node


var _disable_savestate := {}
var _installs := {}

# For UI scaling on the fly
var _base_min_sizes := {}

var _easter_egg_counter := 0


func _ready() -> void:
	
	# Apply UI theme
	var theme_file = Settings.read("launcher_theme")
	load_ui_theme(theme_file)
	
	_save_control_min_sizes()
	_scale_control_min_sizes(Geom.scale)
	Geom.scale_changed.connect(_on_ui_scale_changed)
	
	assign_localized_text()
	
	%QuickLoadBtn.grab_focus()
	
	var welcome_msg = tr("str_welcome")
	if Settings.read("print_tips_of_the_day"):
		welcome_msg += tr("str_tip_of_the_day") + TOTD.get_tip() + "\n"
	Status.post(welcome_msg)
	
	_unpack_utils()
	_setup_ui()


func _save_control_min_sizes() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if ("custom_minimum_size" in node) and (node.custom_minimum_size != Vector2.ZERO):
			_base_min_sizes[node] = node.custom_minimum_size


func _scale_control_min_sizes(factor: float) -> void:
	
	for node in _base_min_sizes:
		node.custom_minimum_size = _base_min_sizes[node] * factor


func assign_localized_text() -> void:
	
	get_window().set_title(tr("window_title"))	
	
	%TabbedLayout.set_tab_title(0, tr("tab_game"))
	%TabbedLayout.set_tab_title(1, tr("tab_mods"))
	%TabbedLayout.set_tab_title(2, tr("tab_soundpacks"))
	%TabbedLayout.set_tab_title(3, tr("tab_fonts"))
	%TabbedLayout.set_tab_title(4, tr("tab_backups"))
	%TabbedLayout.set_tab_title(5, tr("tab_settings"))
	
	%ChangelogLinkLabel.text = tr("lbl_changelog")
	
	var game = Settings.read("game")
	if game == "dda":
		%GameDescText.text = tr("desc_dda")
	elif game == "bn":
		%GameDescText.text = tr("desc_bn")
	elif game == "eod":
		%GameDescText.text = tr("desc_eod")
	elif game == "tish":
		%GameDescText.text = tr("desc_tish")
	elif game == "tlg":
		%GameDescText.text = tr("desc_tlg")


func load_ui_theme(theme_file: String) -> void:
	
	var ts := ThemeScaler.new()
	var proto = load("res://themes".path_join(theme_file))
	if proto is Theme:
		var new_theme: Theme = ts.make_scaled_theme(proto, Geom.scale)
		self.theme = new_theme
	else:
		Status.post(tr("msg_theme_load_error") % theme_file, Enums.MSG_ERROR)
		proto = ThemeDB.get_project_theme()
		self.theme = ts.make_scaled_theme(proto, Geom.scale)
		


func _unpack_utils() -> void:
	
	var unzip_exe = Paths.utils_dir.path_join("unzip.exe")
	if (OS.get_name() == "Windows") and (not FileAccess.file_exists(unzip_exe)):
		if not DirAccess.dir_exists_absolute(Paths.utils_dir):
			DirAccess.make_dir_absolute(Paths.utils_dir)
		Status.post(tr("msg_unpacking_unzip"))
		DirAccess.copy_absolute("res://utils/unzip.exe", unzip_exe)
	var zip_exe = Paths.utils_dir.path_join("zip.exe")
	if (OS.get_name() == "Windows") and (not FileAccess.file_exists(zip_exe)):
		if not DirAccess.dir_exists_absolute(Paths.utils_dir):
			DirAccess.make_dir_absolute(Paths.utils_dir)
		Status.post(tr("msg_unpacking_zip"))
		DirAccess.copy_absolute("res://utils/zip.exe", zip_exe)
	


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
	
	if tab == 5:
		%LogText.hide()
	else:
		%LogText.show()
	_refresh_currently_installed()


func _on_GamesList_item_selected(index: int) -> void:
	
	match index:
		0:
			Settings.store("game", "dda")
			%GameDescText.text = tr("desc_dda")
		1:
			Settings.store("game", "bn")
			%GameDescText.text = tr("desc_bn")
		2:
			Settings.store("game", "eod")
			%GameDescText.text = tr("desc_eod")
		3:
			Settings.store("game", "tish")
			%GameDescText.text = tr("desc_tish")
		4:
			Settings.store("game", "tlg")
			%GameDescText.text = tr("desc_tlg")
	
	%TabbedLayout.current_tab = 0
	apply_game_choice()
	_refresh_currently_installed()
	
	%ModManager.refresh_installed()
	%ModManager.refresh_available()


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
	if (Settings.read("game") == "eod") or (Settings.read("game") == "tish") or (Settings.read("game") == "tlg"):
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


func _on_ChangelogLink_meta_clicked(_meta) -> void:
	
	%ChangelogDialog.open()


func _on_Log_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)


func _on_BtnRefresh_pressed() -> void:
	
	%ReleaseManager.fetch(_get_release_key())


func _on_BuildsList_item_selected(index: int) -> void:
	
	var info = Paths.installs_summary
	var game = Settings.read("game")
	
	if (not Settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (%ReleaseManager.releases[_get_release_key()][index]["name"] in info[game]):
		%InstallReleaseBtn.disabled = true
		%UpdateCurrentSwitch.disabled = true
	else:
		%InstallReleaseBtn.disabled = false
		%UpdateCurrentSwitch.disabled = false


func _on_BtnInstall_pressed() -> void:
	
	var index = %ReleasesList.selected
	var release = %ReleaseManager.releases[_get_release_key()][index]
	var update_path := ""
	
	if Settings.read("update_current_when_installing"):
		var game = Settings.read("game")
		var active_name = Settings.read("active_install_" + game)
		if (game in _installs) and (active_name in _installs[game]):
			update_path = _installs[game][active_name]
		var safe_to_delete := await _confirm_game_safe_to_delete(active_name)
		if not safe_to_delete:
			return
	
	%ReleaseInstaller.install_release(release, update_path)


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
	if DirAccess.dir_exists_absolute(gamedir):
		OS.shell_open(gamedir)


func _on_UserDir_pressed() -> void:
	
	var userdir = Paths.userdata
	if DirAccess.dir_exists_absolute(userdir):
		OS.shell_open(userdir)


func _setup_ui() -> void:

	%GameInfoBox.visible = Settings.read("show_game_desc")
	if not Settings.read("debug_mode"):
		# %TabbedLayout.remove_child(%DebugArea)
		%DebugArea.hide()
		%DebugArea.reparent(self)
	
	%UpdateCurrentSwitch.button_pressed = Settings.read("update_current_when_installing")
	
	apply_game_choice()
	
	%GamesList.item_selected.connect(_on_GamesList_item_selected)
	%StableSwitch.toggled.connect(_on_RBtnStable_toggled)
	# Had to leave these signals unconnected in the editor and only connect
	# them now from code to avoid cyclic calls of apply_game_choice.
	
	_refresh_currently_installed()


func reload_builds_list() -> void:
	
	%ReleasesList.clear()
	for rec in %ReleaseManager.releases[_get_release_key()]:
			%ReleasesList.add_item(rec["name"])
	_refresh_currently_installed()


func apply_game_choice() -> void:
	
	# TODO: Turn this mess into a more elegant mess.

	var game = Settings.read("game")
	var channel = Settings.read("channel")
	
	if (game == "dda") or (game == "bn"):
		%ExperimentalSwitch.disabled = false
		%StableSwitch.disabled = false
		if channel == "stable":
			%StableSwitch.button_pressed = true
			%RefreshReleasesBtn.disabled = true
		else:
			%ExperimentalSwitch.button_pressed = true
			%RefreshReleasesBtn.disabled = false
	elif (game == "eod") or (game == "tish") or (game == "tlg"):
		%ExperimentalSwitch.button_pressed = true
		%ExperimentalSwitch.disabled = true
		%StableSwitch.disabled = true
		%RefreshReleasesBtn.disabled = false

	match game:
		"dda":
			%GamesList.select(0)
			%GameDescText.text = tr("desc_dda")
				
		"bn":
			%GamesList.select(1)
			%GameDescText.text = tr("desc_bn")

		"eod":
			%GamesList.select(2)
			%GameDescText.text = tr("desc_eod")

		"tish":
			%GamesList.select(3)
			%GameDescText.text = tr("desc_tish")
			
		"tlg":
			%GamesList.select(4)
			%GameDescText.text = tr("desc_tlg")
	
	if len(%ReleaseManager.releases[_get_release_key()]) == 0:
		%ReleaseManager.fetch(_get_release_key())
	else:
		reload_builds_list()


func _on_BtnPlay_pressed() -> void:
	
	_start_game()


func _on_BtnResume_pressed() -> void:
	
	var lastworld: String = Paths.config.path_join("lastworld.json")
	var info = Helpers.load_json_file(lastworld)
	if info:
		_start_game(info["world_name"])


func _start_game(world := "") -> void:
	
	match OS.get_name():
		"Linux":
			var params := ["--userdir", Paths.userdata + "/"]
			if world != "":
				params.append_array(["--world", world])
			OS.execute_with_pipe(Paths.game_dir.path_join("cataclysm-launcher"), params)
		"Windows":
			var world_str := ""
			if world != "":
				world_str = "--world \"%s\"" % world

			var exe_file = "cataclysm-tiles.exe"
			if Settings.read("game") == "bn" and FileAccess.file_exists(Paths.game_dir.path_join("cataclysm-bn-tiles.exe")):
				exe_file = "cataclysm-bn-tiles.exe"

			var command = "cd /d %s && start %s --userdir \"%s/\" %s" % [Paths.game_dir, exe_file, Paths.userdata, world_str]
			OS.execute_with_pipe("cmd", ["/C", command])
		_:
			return
	
	if not Settings.read("keep_open_after_starting_game"):
		get_tree().quit()


func _on_InstallsList_item_selected(index: int) -> void:
	
	var release_name = %GameInstallsList.get_item_text(index)
	%DeleteGameInstallBtn.disabled = false
	%MakeInstallActiveBtn.disabled = (release_name == Settings.read("active_install_" + Settings.read("game")))


func _on_InstallsList_item_activated(index: int) -> void:
	
	var release_name = %GameInstallsList.get_item_text(index)
	var path = _installs[Settings.read("game")][release_name]
	if DirAccess.dir_exists_absolute(path):
		OS.shell_open(path)


func _on_btnMakeActive_pressed() -> void:
	
	var release_name = %GameInstallsList.get_item_text(%GameInstallsList.get_selected_items()[0])
	Status.post(tr("msg_set_active") % release_name)
	Settings.store("active_install_" + Settings.read("game"), release_name)
	_refresh_currently_installed()
	print(%ReleaseInstaller.check_game_dir_for_userdata(release_name))


func _on_btnDelete_pressed() -> void:
	
	var release_name = %GameInstallsList.get_item_text(%GameInstallsList.get_selected_items()[0])
	var safe_to_delete := await _confirm_game_safe_to_delete(release_name)
	if safe_to_delete == true:
		%ReleaseInstaller.remove_release_by_name(release_name)


func _confirm_game_safe_to_delete(release_name: String) -> bool:
	
	var misplaced_userdata: Array[String] = %ReleaseInstaller.check_game_dir_for_userdata(release_name)
	if not misplaced_userdata.is_empty():
		%UserDataDeletionDlg.open(misplaced_userdata)
		var delete_confirmed: bool = await %UserDataDeletionDlg.response_given
		return delete_confirmed
	else:
		return true


func _refresh_currently_installed() -> void:
	
	var releases = %ReleaseManager.releases[_get_release_key()]

	%GameInstallsList.clear()
	var game = Settings.read("game")
	_installs = Paths.installs_summary
	var active_name = Settings.read("active_install_" + game)
	if game in _installs:
		for inst_name in _installs[game]:
			%GameInstallsList.add_item(inst_name)
			var curr_idx = %GameInstallsList.get_item_count() - 1
			%GameInstallsList.set_item_tooltip(curr_idx, tr("tooltip_installs_item") % _installs[game][inst_name])
	
	%ReleasesList.select(-1)
	%MakeInstallActiveBtn.disabled = true
	%DeleteGameInstallBtn.disabled = true
	
	if game in _installs:
		%ActiveInstallNameLabel.text = active_name
		%LaunchGameBtn.disabled = false
		%QuickLoadBtn.disabled = not (FileAccess.file_exists(Paths.config.path_join("lastworld.json")))
		%GameDirBtn.visible = true
		%UserDirBtn.visible = true
		if (%ReleasesList.selected != -1) and (%ReleasesList.selected < len(releases)):
				if not Settings.read("update_to_same_build_allowed"):
					%InstallReleaseBtn.disabled = (releases[%ReleasesList.selected]["name"] in _installs[game])
					%UpdateCurrentSwitch.disabled = %InstallReleaseBtn.disabled
		else:
			%InstallReleaseBtn.disabled = true

	else:
		%ActiveInstallNameLabel.text = tr("lbl_none")
		%InstallReleaseBtn.disabled = false
		%UpdateCurrentSwitch.disabled = true
		%LaunchGameBtn.disabled = true
		%QuickLoadBtn.disabled = true
		%GameDirBtn.visible = false
		%UserDirBtn.visible = false
	
	if (game in _installs and _installs[game].size() > 1) or \
			(Settings.read("always_show_installs") == true):
		%GameInstallsGroup.visible = true
	else:
		%GameInstallsGroup.visible = false

	for i in [1, 2, 3, 4]:
		%TabbedLayout.set_individual_tab_disabled(i, not game in _installs)


func _on_InfoIcon_gui_input(event: InputEvent) -> void:
	
	if (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_LEFT) and (event.is_pressed()):
		_easter_egg_counter += 1
		if _easter_egg_counter == 3:
			Status.post("[color=red]%s[/color]" % tr("msg_easter_egg_warning"))
		if _easter_egg_counter == 10:
			_activate_easter_egg()


func _activate_easter_egg() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if node is Control:
			node.pivot_offset = node.size / 2.0
			node.rotation = (randf() * 2.0 - 1.0) * PI / 180.0
	
	Status.rainbow_text = true
	
	for i in range(20):
		Status.post(tr("msg_easter_egg_activated"))
		await get_tree().create_timer(0.1).timeout
