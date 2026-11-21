extends Window
## Confirmation dialog asking whether to reinstall mods that are already present in the user directory.


signal response_yes
signal response_no

@onready var _label = $Panel/Margin/VBox/Label


## Opens the dialog with singular or plural prompt text for the given count of existing mods.
func open(num_mods: int) -> void:
	
	if num_mods == 1:
		_label.text = tr("dlg_mod_reinstall_text_single")
	else:
		_label.text = tr("dlg_mod_reinstall_text_multiple") % num_mods
	
	popup_centered()


func _on_BtnYes_pressed() -> void:
	
	response_yes.emit()
	hide()


func _on_BtnNo_pressed() -> void:
	
	response_no.emit()
	hide()
