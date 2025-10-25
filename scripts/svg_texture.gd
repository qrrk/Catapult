@tool
class_name SVGTexture
extends DPITexture

@export_multiline var svg_source: String:
	set(value):
		set_source(value)
	get():
		return get_source()


func _init() -> void:
	
	if not Engine.is_editor_hint():
		Geom.scale_changed.connect(func(new_scale):
			base_scale = new_scale
		)


func _validate_property(property: Dictionary) -> void:
	
	# Do not save the source text twice
	if property["name"] == "svg_source":
		property["usage"] &= ~PROPERTY_USAGE_STORAGE
