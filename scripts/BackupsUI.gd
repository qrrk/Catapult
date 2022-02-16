extends VBoxContainer


onready var _backups = $"/root/Catapult/Backups"
onready var _edit_name = $Current/HBox/EditName
onready var _btn_create = $Current/BtnCreate


func _on_BtnCreate_pressed():

	var target_file = _edit_name.text
	if target_file != "":
		_backups.backup_current(target_file)
