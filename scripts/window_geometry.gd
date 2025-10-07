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


func _set_scale(new_scale: float) -> void:
	
	scale = new_scale + 0.0004
	_apply_scale()
	emit_signal("scale_changed", scale)


func _apply_scale() -> void:
	
	get_window().min_size = min_base_size * scale
	get_window().size = base_size * scale


func calculate_scale_from_dpi() -> float:
	
	var ratio = DisplayServer.screen_get_dpi() / 96.0
	return snapped(ratio, 0.125)


func save_window_state() -> void:
	
	var state := {
		"size_x": base_size.x,
		"size_y": base_size.y,
		"position_x": get_window().position.x,
		"position_y": get_window().position.y,
		}
	Settings.store("window_state", state)


func recover_window_state() -> void:

	var state: Dictionary = Settings.read("window_state")
	var pos: Vector2i
	
	if not state.is_empty():
		base_size =  Vector2i(state["size_x"], state["size_y"])
		pos = Vector2i(state["position_x"], state["position_y"])
	else:
		var screen_center := DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		pos = screen_center - Vector2i(base_size * scale / 2)
	
	get_window().set_deferred("position", pos)
	
	# Counteract shifting of the window when decorations are added to it
	# (this happens in KDE and possibly other environments).
	while get_window().size == get_window().get_size_with_decorations():
		await  get_tree().process_frame
	if get_window().position != pos:
		get_window().position = pos


func _on_SceneTree_idle():
	
	await get_tree().process_frame
	get_window().set_deferred("borderless", false)
	get_window().set_deferred("transparent", false)
	recover_window_state()
	_apply_scale()
	get_window().size_changed.connect(self._on_window_resized)


func _ready():
	
	if Settings.read("ui_scale_override_enabled"):
		_set_scale(Settings.read("ui_scale_override") as float)
	else:
		_set_scale(calculate_scale_from_dpi())

	_on_SceneTree_idle()


func _on_window_resized() -> void:
	
	base_size = get_window().get_size_with_decorations() / scale


func _exit_tree() -> void:
	
	save_window_state()
