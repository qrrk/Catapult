@tool
extends TextureButton
## Inline DPI-aware icon button that enlarges slightly on mouse hover.

## Scale multiplier applied to the icon's base scale while hovered.
@export var hovered_scale := 1.1
@export_tool_button("Reserve Space for Hovered Size") var reserve := func():
	custom_minimum_size = ceil(texture_normal.get_size() * hovered_scale)


func _on_mouse_entered() -> void:
	
	if texture_normal is DPITexture:
		texture_normal.base_scale *= hovered_scale


func _on_mouse_exited() -> void:
	
	if texture_normal is DPITexture:
		texture_normal.base_scale = Geom.scale
