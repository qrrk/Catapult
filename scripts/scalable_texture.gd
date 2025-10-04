class_name ScalableImageTexture
extends ImageTexture


@export var base_display_size: Vector2 = Vector2(16, 16)


func _init() -> void:
	
	Geom.connect("scale_changed", Callable(self, "_on_ui_scale_changed"))


func _on_ui_scale_changed(new_scale: float) -> void:
	
	self.set_size_override(base_display_size * new_scale)
