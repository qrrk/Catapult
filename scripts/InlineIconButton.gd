extends TextureButton


@export var _scale_when_hovered = 1.1 # (float, 1.0, 1.5)

var _normal_position := Vector2()


func _on_mouse_entered() -> void:
	
	_normal_position = position
	size = custom_minimum_size * _scale_when_hovered
	var offset := (size - custom_minimum_size) / 2.0
	position -= offset


func _on_mouse_exited() -> void:
	
	size = custom_minimum_size
	position = _normal_position
