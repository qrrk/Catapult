extends VBoxContainer


onready var _backups = $"/root/Catapult/Backups"
onready var _edit_name = $Current/HBox/EditName
onready var _btn_create = $Current/BtnCreate
onready var _list_backups = $Available/BackupsList
onready var _btn_refresh = $Available/Buttons/BtnRefresh
onready var _btn_restore = $Available/Buttons/BtnRestore
onready var _btn_delete = $Available/Buttons/BtnDelete


func _refresh_available() -> void:
	
	_list_backups.clear()
	_btn_restore.disabled = true
	_btn_delete.disabled = true

	for item in _backups.get_available():
		_list_backups.add_item(item["name"])


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 4:
		return
	
	_refresh_available()


func _on_BtnCreate_pressed():

	var target_file = _edit_name.text
	if target_file.is_valid_filename():
		_backups.backup_current(target_file)
		yield(_backups, "backup_creation_finished")
		_refresh_available()


func _on_EditName_text_entered(new_text):
	
	_on_BtnCreate_pressed()


func _on_BtnRefresh_pressed():

	_refresh_available()


func _on_BtnRestore_pressed():

	if not _list_backups.is_anything_selected():
		return
	
	var selection = _list_backups.get_item_text(_list_backups.get_selected_items()[0])
	if selection != "":
		_backups.restore(selection)


func _on_BtnDelete_pressed():
	
	if not _list_backups.is_anything_selected():
		return
	
	var selection = _list_backups.get_item_text(_list_backups.get_selected_items()[0])

	if selection != "":
		_backups.delete(selection)
		yield(_backups, "backup_deletion_finished")
		_refresh_available()


func _on_EditName_text_changed(new_text: String):
	
	# This disallows Windows' invalid characters as well as text that is empty or has leading or
	# trailing whitespace. These rules are used regardless of the active OS.
	_btn_create.disabled = not new_text.is_valid_filename()
	
	# Keep normal color if text is empty to avoid red placeholder text.
	if new_text == "" or new_text.is_valid_filename():
		_edit_name.add_color_override("font_color", get_color("font_color", "LineEdit"))
	else:
		_edit_name.add_color_override("font_color", Color.red)


func _on_BackupsList_item_selected(index):
	
	_btn_restore.disabled = false
	_btn_delete.disabled = false
