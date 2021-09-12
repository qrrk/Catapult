extends TextureButton


export(float, 1.0, 1.5) var _scale_when_hovered = 1.1

var _normal_position := Vector2()


func _on_mouse_entered() -> void:
	
	_normal_position = rect_position
	rect_size = rect_min_size * _scale_when_hovered
	var offset := (rect_size - rect_min_size) / 2.0
	rect_position -= offset


func _on_mouse_exited() -> void:
	
	rect_size = rect_min_size
	rect_position = _normal_position
