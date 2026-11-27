extends VBoxContainer
## UI controller for the Game tab: release channel selection, release installation/updates,
## multi-install management, and launching the active game.


## Emitted whenever the list of installations is refreshed, indicating whether any install exists.
signal installs_changed(has_installs: bool)
## Emitted when a release fetch or install/delete operation begins (locks shell controls).
signal operation_started
## Emitted when a release fetch or install/delete operation finishes (unlocks shell controls).
signal operation_finished

## Controls to lock while fetching release metadata from the network.
@export var lock_on_fetch: Array[Control] = []
## Controls to lock while installing, updating, or deleting a game release.
@export var lock_on_release_ops: Array[Control] = []

var _installs: Dictionary = {}
var _fetching_releases: bool = false


func _notification(what: int) -> void:
	
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		update_localized_text()


## Initializes tab state on startup, applies the saved game/channel selection.
func setup() -> void:
	
	update_localized_text()
	%UpdateCurrentSwitch.button_pressed = Settings.read("update_current_when_installing")
	apply_game_choice()
	refresh_currently_installed()
	%QuickLoadBtn.grab_focus()


## Updates localized rich-text labels inside the Game tab.
func update_localized_text() -> void:
	
	%ChangelogLinkLabel.text = tr("lbl_changelog")


## Repopulates the available releases dropdown from ReleaseManager, selects the newest build,
## and refreshes install state.
func reload_builds_list() -> void:
	
	%ReleasesList.clear()
	for rec in %ReleaseManager.releases[_get_release_key()]:
		%ReleasesList.add_item(rec["name"])
	if %ReleasesList.item_count > 0:
		%ReleasesList.select(0)
	refresh_currently_installed()


## Syncs channel controls for the currently selected game and fetches releases if not yet cached.
func apply_game_choice() -> void:
	
	var game: String = Settings.read("game")
	_update_channel_controls(game)
	
	if len(%ReleaseManager.releases[_get_release_key()]) == 0:
		%ReleasesList.clear()
		%ReleaseManager.fetch(_get_release_key())
	else:
		reload_builds_list()


## Scans installed versions of the selected game, updates launch/install buttons, and emits [signal installs_changed].
func refresh_currently_installed() -> void:
	
	%GameInstallsList.clear()
	var game: String = Settings.read("game")
	_installs = Paths.installs_summary
	var active_name: String = Settings.read("active_install_" + game)
	if game in _installs:
		for inst_name in _installs[game]:
			%GameInstallsList.add_item(inst_name)
			var curr_idx: int = %GameInstallsList.get_item_count() - 1
			%GameInstallsList.set_item_tooltip(curr_idx, tr("tooltip_installs_item") % _installs[game][inst_name])
	
	%MakeInstallActiveBtn.disabled = true
	%DeleteGameInstallBtn.disabled = true
	
	var has_installs: bool = game in _installs
	if has_installs:
		%ActiveInstallNameLabel.text = active_name
		%LaunchGameBtn.disabled = false
		%QuickLoadBtn.disabled = not %GameLauncher.has_last_world()
		%GameDirBtn.visible = true
		%UserDirBtn.visible = true
	else:
		%ActiveInstallNameLabel.text = tr("lbl_none")
		%LaunchGameBtn.disabled = true
		%QuickLoadBtn.disabled = true
		%GameDirBtn.visible = false
		%UserDirBtn.visible = false
	
	if not _fetching_releases:
		_update_install_controls()
	
	%GameInstallsGroup.visible = (has_installs and _installs[game].size() > 1) \
			or (Settings.read("always_show_installs") == true)
	
	installs_changed.emit(has_installs)


func _update_install_controls() -> void:
	
	var releases: Array = %ReleaseManager.releases[_get_release_key()]
	var selected_idx: int = %ReleasesList.selected
	var has_valid_selection: bool = (selected_idx >= 0) and (selected_idx < releases.size())
	var game: String = Settings.read("game")
	var has_installs: bool = game in _installs
	
	if not has_valid_selection:
		%InstallReleaseBtn.disabled = true
		%UpdateCurrentSwitch.disabled = true
	elif not has_installs:
		%InstallReleaseBtn.disabled = false
		%UpdateCurrentSwitch.disabled = true
	else:
		var same_build_blocked: bool = (not Settings.read("update_to_same_build_allowed")) \
				and (releases[selected_idx]["name"] in _installs[game])
		%InstallReleaseBtn.disabled = same_build_blocked
		%UpdateCurrentSwitch.disabled = same_build_blocked


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
		ControlLock.lock(lock_on_fetch)
		operation_started.emit()


func _on_Releases_done_fetching_releases() -> void:
	
	if _fetching_releases:
		_fetching_releases = false
		ControlLock.unlock(lock_on_fetch)
		operation_finished.emit()
	if not ControlLock.is_any_locked(lock_on_release_ops):
		_update_channel_controls(Settings.read("game"))
		reload_builds_list()


func _on_ReleaseInstaller_operation_started() -> void:
	
	ControlLock.lock(lock_on_release_ops)
	operation_started.emit()


func _on_ReleaseInstaller_operation_finished() -> void:
	
	ControlLock.unlock(lock_on_release_ops)
	operation_finished.emit()
	refresh_currently_installed()


func _on_ChangelogLink_meta_clicked(_meta: Variant) -> void:
	
	%ChangelogDialog.open()


func _on_BtnRefresh_pressed() -> void:
	
	%ReleaseManager.fetch(_get_release_key())


func _on_BuildsList_item_selected(_index: int) -> void:
	
	_installs = Paths.installs_summary
	_update_install_controls()


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
	
	if %GameLauncher.launch() and not Settings.read("keep_open_after_starting_game"):
		get_tree().quit()


func _on_BtnResume_pressed() -> void:
	
	if %GameLauncher.resume_last_world() and not Settings.read("keep_open_after_starting_game"):
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
