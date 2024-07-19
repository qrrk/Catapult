extends VBoxContainer


@onready var _backups = $"/root/Catapult/Backups"
@onready var _edit_name = $Current/HBox/EditName
@onready var _btn_create = $Current/HBox/BtnCreate
@onready var _list_backups = $Available/HBox/BackupsList
@onready var _btn_refresh = $Available/Buttons/BtnRefresh
@onready var _btn_restore = $Available/Buttons/BtnRestore
@onready var _btn_delete = $Available/Buttons/BtnDelete
@onready var _lbl_info = $Available/HBox/BackupInfo


func _refresh_available() -> void:
	
	_list_backups.clear()
	_btn_restore.disabled = true
	_btn_delete.disabled = true
	_lbl_info.text = tr("lbl_backup_info_placeholder")
	_backups.refresh_available()

	for item in _backups.available:
		_list_backups.add_item(item["name"])


func _populate_default_new_name() -> void:
	
	var datetime = Time.get_datetime_dict_from_system()
	_edit_name.text = "Manual_%02d-%02d-%02d_%02d-%02d" % [
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

	var target_file = _edit_name.text
	if target_file.is_valid_filename():
		_backups.backup_current(target_file)
		await _backups.backup_creation_finished
		_refresh_available()


func _on_EditName_text_entered(new_text):
	
	_on_BtnCreate_pressed()


func _on_BtnRefresh_pressed():

	_refresh_available()


func _on_BtnRestore_pressed():

	if not _list_backups.is_anything_selected():
		return
	
	var idx = _list_backups.get_selected_items()[0]
	_backups.restore(idx)


func _on_BtnDelete_pressed():
	
	if not _list_backups.is_anything_selected():
		return
	
	var selection = _list_backups.get_item_text(_list_backups.get_selected_items()[0])

	if selection != "":
		_backups.delete(selection)
		await _backups.backup_deletion_finished
		_refresh_available()


func _on_EditName_text_changed(new_text: String):
	
	# This disallows Windows' invalid characters as well as text that is empty or has leading or
	# trailing whitespace. These rules are used regardless of the active OS.
	_btn_create.disabled = not new_text.is_valid_filename()
	
	# Keep normal color if text is empty to avoid red placeholder text.
	if (new_text == "") or (new_text.is_valid_filename()):
		_edit_name.add_theme_color_override("font_color", get_theme_color("font_color", "LineEdit"))
	else:
		_edit_name.add_theme_color_override("font_color", Color.RED)


func _on_BackupsList_item_selected(index):
	
	_btn_restore.disabled = false
	_btn_delete.disabled = false
	_lbl_info.text = _make_backup_info_string(index)


func _make_backup_info_string(index: int) -> String:
	
	var text := ""
	var info: Dictionary = _backups.available[index]
	
	var worlds_str := ""
	for world in info["worlds"]:
		worlds_str += world + ", "
	worlds_str = worlds_str.substr(0, len(worlds_str) - 2)
	
	text += "[u]%s[/u]\n[color=#3b93f7][url=%s]%s[/url][/color]\n\n" % [tr("backup_info_location"), info["path"], info["path"]]
	text += "[u]%s[/u]\n%s" % [tr("backup_info_worlds"), worlds_str]
	
	return text


func _on_BackupInfo_meta_clicked(meta) -> void:
	
	OS.shell_open(meta)
