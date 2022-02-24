extends WindowDialog


onready var _label := $Panel/Margin/VBox/Help


func open() -> void:
	
	_label.bbcode_text = tr("dlg_font_config_help")
	_label.scroll_to_line(0)
#
	popup_centered_ratio(0.9)


func _on_BtnOK_pressed() -> void:
	
	hide()
