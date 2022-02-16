extends VBoxContainer


onready var _backups = $"/root/Catapult/Backups"
onready var _edit_name = $Current/HBox/EditName
onready var _btn_create = $Current/BtnCreate
onready var _list_backups = $Available/BackupsList
onready var _btn_refresh = $Available/Buttons/BtnRefresh
onready var _btn_restore = $Available/Buttons/BtnRestore


func _refresh_available() -> void:
	
	_list_backups.clear()
	for item in _backups.get_available():
		_list_backups.add_item(item)


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 4:
		return
	
	_refresh_available()


func _on_BtnCreate_pressed():

	var target_file = _edit_name.text
	if target_file != "":
		_backups.backup_current(target_file)
		yield(_backups, "backup_creation_finished")
		_refresh_available()


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
