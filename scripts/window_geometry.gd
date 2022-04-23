extends Node

# This script makes it possible to set the correct size and position
# for the window before it is shown.

# Thanks to github.com/Lauson1ex for helping me figure this out.

var scale: float setget _set_scale
var min_base_size := Vector2(
		ProjectSettings.get("display/window/size/width"),
		ProjectSettings.get("display/window/size/height"))
var base_size := min_base_size

var decor_offset := Vector2.ZERO


func _set_scale(new_scale: float) -> void:
	
	scale = new_scale + 0.0004
	_apply_scale()


func _apply_scale() -> void:
	
	OS.min_window_size = min_base_size * scale
	OS.set_window_size(base_size * scale)


func calculate_scale_from_dpi() -> float:
	
	var ratio = OS.get_screen_dpi() / 96.0
	return stepify(ratio, 0.125)


func save_window_state() -> void:
	
	var state := {
		"size_x": base_size.x,
		"size_y": base_size.y,
		"position_x": OS.window_position.x,
		"position_y": OS.window_position.y,
		"decor_offset_x": decor_offset.x,
		"decor_offset_y": decor_offset.y,
		}
	Settings.store("window_state", state)


func recover_window_state() -> void:
	
	var state: Dictionary = Settings.read("window_state")
	
	if state.empty():
		OS.call_deferred("center_window")
		return
	
	base_size =  Vector2(state["size_x"] as float, state["size_y"] as float)
	var pos := Vector2(state["position_x"] as float, state["position_y"] as float)
	decor_offset = Vector2(state["decor_offset_x"] as float, state["decor_offset_y"] as float)
	pos += decor_offset
	OS.set_deferred("window_position", pos)
	
	# In some environments (e.g. KDE) switching a window from borderless to
	# normal results in it shifting down by the height of the window title.
	# The code below works around this by detecting when decorations actually
	# get added to the window (there is a measurable delay before that happens)
	# and storing the resulting offset for compensation on the next launch.
	
	while OS.window_size == OS.get_real_window_size():
		yield(get_tree(), "idle_frame")
	decor_offset = pos - OS.window_position


func _on_SceneTree_idle():
	
	yield(get_tree(), "idle_frame")
	ProjectSettings.call_deferred("set_setting", "display/window/per_pixel_transparency/allowed", false)
	OS.set_deferred("window_per_pixel_transparency_enabled", false)
	OS.set_deferred("window_borderless", false)
	OS.call_deferred("set_icon", load("res://icons/appicon.svg").get_data())
	recover_window_state()
	_apply_scale()


func _ready():
	
	if Settings.read("ui_scale_override_enabled"):
		_set_scale(Settings.read("ui_scale_override") as float)
	else:
		_set_scale(calculate_scale_from_dpi())

	_on_SceneTree_idle()


func _on_window_resized() -> void:
	
	base_size = OS.window_size / scale


func _exit_tree() -> void:
	
	save_window_state()
