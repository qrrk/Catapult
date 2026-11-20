@tool
extends TextureButton

@export var hovered_scale := 1.1
@export_tool_button("Reserve Space for Hovered Size") var reserve := func():
	custom_minimum_size = ceil(texture_normal.get_size() * hovered_scale)


func _on_mouse_entered() -> void:
	
	if texture_normal is DPITexture:
		texture_normal.base_scale *= hovered_scale


func _on_mouse_exited() -> void:
	
	if texture_normal is DPITexture:
		texture_normal.base_scale = Geom.scale
