@tool
class_name SVGTexture
extends DPITexture
## DPITexture subclass exposing editable inline SVG source in the Inspector and
## automatically re-scaling its base scale when the UI scale changes at runtime.

## Inline SVG markup forwarded to DPITexture.set_source() (not duplicated in .tres storage).
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
