extends Window


@onready var _label := $Panel/Margin/VBox/Help


func open() -> void:
	
	var text := tr("dlg_font_config_help")
	text = text.replace("[IMG_1]", "[img=%d]res://images/font-sizes.png[/img]" % (180 * Geom.scale))
	text = text.replace("[IMG_2]", "[img=%d]res://images/font-rect.png[/img]" % (400 * Geom.scale))
	_label.text = text
	_label.scroll_to_line(0)
#
	popup_centered_ratio(0.9)


func _on_BtnOK_pressed() -> void:
	
	hide()
