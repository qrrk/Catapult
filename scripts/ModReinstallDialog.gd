extends Window


signal response_yes
signal response_no

@onready var _label = $Panel/Margin/VBox/Label


func open(num_mods: int) -> void:
	
	if num_mods == 1:
		_label.text = tr("dlg_mod_reinstall_text_single")
	else:
		_label.text = tr("dlg_mod_reinstall_text_multiple") % num_mods
	
	size = Vector2(400, 150)
	popup_centered()


func _on_BtnYes_pressed() -> void:
	
	emit_signal("response_yes")
	hide()


func _on_BtnNo_pressed() -> void:
	
	emit_signal("response_no")
	hide()


func _on_BtnCancel_pressed() -> void:
	
	hide()
