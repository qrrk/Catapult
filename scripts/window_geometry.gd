extends Node

# This script makes it possible to set the correct size and position
# for the window before it is shown.

# Thanks to github.com/Lauson1ex for helping me figure this out.

signal scale_changed

var scale: float: set = _set_scale
var min_base_size := Vector2(
		ProjectSettings.get("display/window/size/viewport_width"),
		ProjectSettings.get("display/window/size/viewport_height"))
var base_size := min_base_size

var decor_offset := Vector2i.ZERO


func _set_scale(new_scale: float) -> void:
	
	scale = new_scale + 0.0004
	_apply_scale()
	emit_signal("scale_changed", scale)


func _apply_scale() -> void:
	
	get_window().min_size = min_base_size * scale
	get_window().set_size(base_size * scale)


func calculate_scale_from_dpi() -> float:
	
	var ratio = DisplayServer.screen_get_dpi() / 96.0
	return snapped(ratio, 0.125)


func save_window_state() -> void:
	
	var state := {
		"size_x": base_size.x,
		"size_y": base_size.y,
		"position_x": get_window().position.x,
		"position_y": get_window().position.y,
		"decor_offset_x": decor_offset.x,
		"decor_offset_y": decor_offset.y,
		}
	Settings.store("window_state", state)


func recover_window_state() -> void:
	
	var state: Dictionary = Settings.read("window_state")
	
	if state.is_empty():
		OS.call_deferred("center_window")
		return
	
	base_size =  Vector2i(state["size_x"] as int, state["size_y"] as int)
	var pos := Vector2i(state["position_x"] as int, state["position_y"] as int)
	decor_offset = Vector2i(state["decor_offset_x"] as int, state["decor_offset_y"] as int)
	pos += decor_offset
	OS.set_deferred("window_position", pos)
	
	# In some environments (e.g. KDE) switching a window from borderless to
	# normal results in it shifting down by the height of the window title.
	# The code below works around this by detecting when decorations actually
	# get added to the window (there is a measurable delay before that happens)
	# and storing the resulting offset for compensation on the next launch.
	
	while get_window().size == get_window().get_size_with_decorations():
		await get_tree().process_frame
	decor_offset = pos - get_window().position


func _on_SceneTree_idle():
	
	await get_tree().process_frame
	ProjectSettings.call_deferred("set_setting", "display/window/per_pixel_transparency/allowed", false)
	OS.set_deferred("window_per_pixel_transparency_enabled", false)
	OS.set_deferred("window_borderless", false)
	recover_window_state()
	_apply_scale()


func _ready():
	
	if Settings.read("ui_scale_override_enabled"):
		_set_scale(Settings.read("ui_scale_override") as float)
	else:
		_set_scale(calculate_scale_from_dpi())

	_on_SceneTree_idle()


func _on_window_resized() -> void:
	
	base_size = get_window().size / scale


func _exit_tree() -> void:
	
	save_window_state()
