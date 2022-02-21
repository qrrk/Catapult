extends WindowDialog


const _IMG1_RES := "res://images/font-sizes.png"
const _IMG2_RES := "res://images/font-rect.png"

const _IMG1_SZ := 200
const _IMG2_SZ := 450

onready var _geom := $"/root/WindowGeometry"
onready var _label := $Panel/Margin/VBox/Help


func open() -> void:
	
	var text := tr("dlg_font_config_help")
	var img1_size := int(_IMG1_SZ * _geom.scale)
	var img2_size := int(_IMG2_SZ * _geom.scale)
	text = text.replace("IMG_1", "[img=%s]%s[/img]" % [img1_size, _IMG1_RES])
	text = text.replace("IMG_2", "[img=%s]%s[/img]" % [img2_size, _IMG2_RES])
	_label.bbcode_text = text
	_label.scroll_to_line(0)
#
	rect_min_size = get_tree().root.size * Vector2(0.9, 0.9)
	set_as_minsize()
	popup_centered()


func _on_BtnOK_pressed() -> void:
	
	hide()
