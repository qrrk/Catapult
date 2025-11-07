extends VBoxContainer


func _refresh_available() -> void:
	
	%BackupsList.clear()
	%RestoreBackupBtn.disabled = true
	%DeleteBackupBtn.disabled = true
	%BackupInfo.text = tr("lbl_backup_info_placeholder")
	%BackupManager.refresh_available()

	for item in %BackupManager.available:
		%BackupsList.add_item(item["name"])


func _populate_default_new_name() -> void:
	
	var datetime = Time.get_datetime_dict_from_system()
	%BackupNameField.text = "Manual_%02d-%02d-%02d_%02d-%02d" % [
		datetime["year"] % 100,
		datetime["month"],
		datetime["day"],
		datetime["hour"],
		datetime["minute"],
	]


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 4:
		return
	
	_refresh_available()
	_populate_default_new_name()


## Update the default backup filename when the app gains focus.
func _notification(what: int) -> void:

	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		_populate_default_new_name()


func _on_BtnCreate_pressed():

	var target_file = %BackupNameField.text
	if target_file.is_valid_filename():
		%BackupManager.backup_current(target_file)
		await %BackupManager.backup_creation_finished
		_refresh_available()


func _on_EditName_text_entered():
	
	_on_BtnCreate_pressed()


func _on_BtnRefresh_pressed():

	_refresh_available()


func _on_BtnRestore_pressed():

	if not %BackupsList.is_anything_selected():
		return
	
	var idx = %BackupsList.get_selected_items()[0]
	%BackupManager.restore(idx)


func _on_BtnDelete_pressed():
	
	if not %BackupsList.is_anything_selected():
		return
	
	var selection = %BackupsList.get_item_text(%BackupsList.get_selected_items()[0])

	if selection != "":
		%BackupManager.delete(selection)
		await %BackupManager.backup_deletion_finished
		_refresh_available()


func _on_EditName_text_changed(new_text: String):
	
	# This disallows Windows' invalid characters as well as text that is empty or has leading or
	# trailing whitespace. These rules are used regardless of the active OS.
	%CreateBackupBtn.disabled = not new_text.is_valid_filename()
	
	# Keep normal color if text is empty to avoid red placeholder text.
	if (new_text == "") or (new_text.is_valid_filename()):
		%BackupNameField.add_theme_color_override("font_color", get_theme_color("font_color", "LineEdit"))
	else:
		%BackupNameField.add_theme_color_override("font_color", Color.RED)


func _on_BackupsList_item_selected(index):
	
	%RestoreBackupBtn.disabled = false
	%DeleteBackupBtn.disabled = false
	%BackupInfo.text = _make_backup_info_string(index)


func _make_backup_info_string(index: int) -> String:
	
	var text := ""
	var info: Dictionary = %BackupManager.available[index]
	
	var worlds_str := ""
	for world in info["worlds"]:
		worlds_str += world + ", "
	worlds_str = worlds_str.substr(0, len(worlds_str) - 2)
	
	text += "[u]%s[/u]\n[color=#3b93f7][url=%s]%s[/url][/color]\n\n" % [tr("backup_info_location"), info["path"], info["path"]]
	text += "[u]%s[/u]\n%s" % [tr("backup_info_worlds"), worlds_str]
	
	return text


func _on_BackupInfo_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)
