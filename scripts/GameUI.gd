extends VBoxContainer


signal installs_changed(has_installs: bool)
signal operation_started
signal operation_finished

var _installs: Dictionary = {}
var _release_lock: ControlLock
var _install_lock: ControlLock
var _fetching_releases: bool = false


func _ready() -> void:
	
	_release_lock = ControlLock.new([
		%StableSwitch,
		%ExperimentalSwitch,
		%ReleasesList,
		%RefreshReleasesBtn,
		%InstallReleaseBtn,
		%UpdateCurrentSwitch,
	])
	_install_lock = ControlLock.new([
		%LaunchGameBtn,
		%QuickLoadBtn,
		%GameInstallsList,
		%MakeInstallActiveBtn,
		%DeleteGameInstallBtn,
	])
	
	%ReleaseManager.started_fetching_releases.connect(_on_Releases_started_fetching_releases)
	%ReleaseManager.done_fetching_releases.connect(_on_Releases_done_fetching_releases)
	%ReleaseInstaller.operation_started.connect(_on_ReleaseInstaller_operation_started)
	%ReleaseInstaller.operation_finished.connect(_on_ReleaseInstaller_operation_finished)


func _notification(what: int) -> void:
	
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		update_localized_text()


func setup() -> void:
	
	update_localized_text()
	%UpdateCurrentSwitch.button_pressed = Settings.read("update_current_when_installing")
	apply_game_choice()
	%StableSwitch.toggled.connect(_on_RBtnStable_toggled)
	refresh_currently_installed()
	%QuickLoadBtn.grab_focus()


func update_localized_text() -> void:
	
	%ChangelogLinkLabel.text = tr("lbl_changelog")


func reload_builds_list() -> void:
	
	%ReleasesList.clear()
	for rec in %ReleaseManager.releases[_get_release_key()]:
		%ReleasesList.add_item(rec["name"])
	refresh_currently_installed()


func apply_game_choice() -> void:
	
	var game: String = Settings.read("game")
	_update_channel_controls(game)
	
	if len(%ReleaseManager.releases[_get_release_key()]) == 0:
		%ReleaseManager.fetch(_get_release_key())
	else:
		reload_builds_list()


func refresh_currently_installed() -> void:
	
	var releases: Array = %ReleaseManager.releases[_get_release_key()]
	
	%GameInstallsList.clear()
	var game: String = Settings.read("game")
	_installs = Paths.installs_summary
	var active_name: String = Settings.read("active_install_" + game)
	if game in _installs:
		for inst_name in _installs[game]:
			%GameInstallsList.add_item(inst_name)
			var curr_idx: int = %GameInstallsList.get_item_count() - 1
			%GameInstallsList.set_item_tooltip(curr_idx, tr("tooltip_installs_item") % _installs[game][inst_name])
	
	%ReleasesList.select(-1)
	%MakeInstallActiveBtn.disabled = true
	%DeleteGameInstallBtn.disabled = true
	
	var has_installs: bool = game in _installs
	if has_installs:
		%ActiveInstallNameLabel.text = active_name
		%LaunchGameBtn.disabled = false
		%QuickLoadBtn.disabled = not GameLauncher.has_last_world()
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
	
	%GameInstallsGroup.visible = (has_installs and _installs[game].size() > 1) \
			or (Settings.read("always_show_installs") == true)
	
	installs_changed.emit(has_installs)


func _update_channel_controls(game: String) -> void:
	
	var channel: String = Settings.read("channel")
	
	if %ReleaseManager.has_stable_releases(game):
		%ExperimentalSwitch.disabled = false
		%StableSwitch.disabled = false
		if channel == "stable":
			%ExperimentalSwitch.set_pressed_no_signal(false)
			%StableSwitch.set_pressed_no_signal(true)
			%RefreshReleasesBtn.disabled = not Settings.read("check_external_stable_release_source")
		else:
			%StableSwitch.set_pressed_no_signal(false)
			%ExperimentalSwitch.set_pressed_no_signal(true)
			%RefreshReleasesBtn.disabled = false
	else:
		if channel != "experimental":
			Settings.store("channel", "experimental")
		%StableSwitch.set_pressed_no_signal(false)
		%ExperimentalSwitch.set_pressed_no_signal(true)
		%ExperimentalSwitch.disabled = true
		%StableSwitch.disabled = true
		%RefreshReleasesBtn.disabled = false


func _get_release_key() -> String:
	
	var game: String = Settings.read("game")
	return game + "-" + Settings.read("channel")


func _confirm_game_safe_to_delete(release_name: String) -> bool:
	
	var misplaced_userdata: Array[String] = %ReleaseInstaller.check_game_dir_for_userdata(release_name)
	if not misplaced_userdata.is_empty():
		%UserDataDeletionDlg.open(misplaced_userdata)
		var delete_confirmed: bool = await %UserDataDeletionDlg.response_given
		return delete_confirmed
	return true


func _on_RBtnStable_toggled(button_pressed: bool) -> void:
	
	if not %ReleaseManager.has_stable_releases(Settings.read("game")):
		Settings.store("channel", "experimental")
	elif button_pressed:
		Settings.store("channel", "stable")
	else:
		Settings.store("channel", "experimental")
	
	apply_game_choice()


func _on_Releases_started_fetching_releases() -> void:
	
	if not _fetching_releases:
		_fetching_releases = true
		_release_lock.lock()
		operation_started.emit()


func _on_Releases_done_fetching_releases() -> void:
	
	if _fetching_releases:
		_fetching_releases = false
		_release_lock.unlock()
		operation_finished.emit()
	if not _release_lock.is_locked() and not _install_lock.is_locked():
		_update_channel_controls(Settings.read("game"))
		reload_builds_list()


func _on_ReleaseInstaller_operation_started() -> void:
	
	_release_lock.lock()
	_install_lock.lock()
	operation_started.emit()


func _on_ReleaseInstaller_operation_finished() -> void:
	
	_install_lock.unlock()
	_release_lock.unlock()
	operation_finished.emit()
	refresh_currently_installed()


func _on_ChangelogLink_meta_clicked(_meta: Variant) -> void:
	
	%ChangelogDialog.open()


func _on_BtnRefresh_pressed() -> void:
	
	%ReleaseManager.fetch(_get_release_key())


func _on_BuildsList_item_selected(index: int) -> void:
	
	var info := Paths.installs_summary
	var game: String = Settings.read("game")
	
	if (not Settings.read("update_to_same_build_allowed")) \
			and (game in info) \
			and (%ReleaseManager.releases[_get_release_key()][index]["name"] in info[game]):
		%InstallReleaseBtn.disabled = true
		%UpdateCurrentSwitch.disabled = true
	else:
		%InstallReleaseBtn.disabled = false
		%UpdateCurrentSwitch.disabled = false


func _on_BtnInstall_pressed() -> void:
	
	var index: int = %ReleasesList.selected
	var release: Dictionary = %ReleaseManager.releases[_get_release_key()][index]
	var update_path := ""
	
	if Settings.read("update_current_when_installing"):
		var game: String = Settings.read("game")
		var active_name: String = Settings.read("active_install_" + game)
		if (game in _installs) and (active_name in _installs[game]):
			update_path = _installs[game][active_name]
		var safe_to_delete := await _confirm_game_safe_to_delete(active_name)
		if not safe_to_delete:
			return
	
	%ReleaseInstaller.install_release(release, update_path)


func _on_cbUpdateCurrent_toggled(button_pressed: bool) -> void:
	
	Settings.store("update_current_when_installing", button_pressed)


func _on_GameDir_pressed() -> void:
	
	var gamedir := Paths.game_dir
	if DirAccess.dir_exists_absolute(gamedir):
		OS.shell_open(gamedir)


func _on_UserDir_pressed() -> void:
	
	var userdir := Paths.userdata
	if DirAccess.dir_exists_absolute(userdir):
		OS.shell_open(userdir)


func _on_BtnPlay_pressed() -> void:
	
	if GameLauncher.launch() and not Settings.read("keep_open_after_starting_game"):
		get_tree().quit()


func _on_BtnResume_pressed() -> void:
	
	if GameLauncher.resume_last_world() and not Settings.read("keep_open_after_starting_game"):
		get_tree().quit()


func _on_InstallsList_item_selected(index: int) -> void:
	
	var release_name: String = %GameInstallsList.get_item_text(index)
	%DeleteGameInstallBtn.disabled = false
	%MakeInstallActiveBtn.disabled = (release_name == Settings.read("active_install_" + Settings.read("game")))


func _on_InstallsList_item_activated(index: int) -> void:
	
	var release_name: String = %GameInstallsList.get_item_text(index)
	var path: String = _installs[Settings.read("game")][release_name]
	if DirAccess.dir_exists_absolute(path):
		OS.shell_open(path)


func _on_btnMakeActive_pressed() -> void:
	
	var release_name: String = %GameInstallsList.get_item_text(%GameInstallsList.get_selected_items()[0])
	Status.post(tr("msg_set_active") % release_name)
	Settings.store("active_install_" + Settings.read("game"), release_name)
	refresh_currently_installed()


func _on_btnDelete_pressed() -> void:
	
	var release_name: String = %GameInstallsList.get_item_text(%GameInstallsList.get_selected_items()[0])
	var safe_to_delete := await _confirm_game_safe_to_delete(release_name)
	if safe_to_delete:
		%ReleaseInstaller.remove_release_by_name(release_name)
