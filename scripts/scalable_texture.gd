class_name ScalableImageTexture
extends ImageTexture


var _base_size: Vector2


func _init() -> void:
	
	_base_size = self.get_size()
	Geom.connect("scale_changed", Callable(self, "_on_ui_scale_changed"))


func _on_ui_scale_changed(new_scale: float) -> void:
	
	self.size = _base_size * new_scale
