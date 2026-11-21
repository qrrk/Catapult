extends Node
## Autoload singleton managing DPI-aware UI scaling and window size/position persistence.
## Configures window geometry on startup before decorations are shown to avoid visible resize flicker.
# Thanks to github.com/Lauson1ex for helping figure out the borderless startup sequence.


## Emitted whenever the active UI scale factor changes.
signal scale_changed(new_scale: float)

## Active UI scale factor. Assigning updates window size/min_size and emits [signal scale_changed].
var scale: float:
	set(new_scale):
		scale = new_scale + 0.0004
		_apply_scale()
		scale_changed.emit(scale)

var min_base_size := Vector2(
		ProjectSettings.get("display/window/size/viewport_width"),
		ProjectSettings.get("display/window/size/viewport_height"))
var base_size := min_base_size


func _apply_scale() -> void:
	
	get_window().min_size = min_base_size * scale
	get_window().size = base_size * scale


## Computes an automatic UI scale factor from the current screen DPI, snapped to increments of 0.125.
func calculate_scale_from_dpi() -> float:
	
	var ratio = DisplayServer.screen_get_dpi() / 96.0
	return snapped(ratio, 0.125)


## Persists the current unscaled window size and screen position to Settings.
func save_window_state() -> void:
	
	var state := {
		"size_x": base_size.x,
		"size_y": base_size.y,
		"position_x": get_window().position.x,
		"position_y": get_window().position.y,
		}
	Settings.store("window_state", state)


## Restores saved window size and position, clamping back on-screen and resetting auto-scale if it overflows.
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
	
	# Failsafe in case window ends up off-screen after display config changes, etc.
	var screen_rect := Rect2i(DisplayServer.screen_get_position(), DisplayServer.screen_get_size())
	var window_rect := Rect2i(get_window().position, get_window().get_size_with_decorations())
	if not screen_rect.encloses(window_rect):
		# Reset both size and position, to be safe
		get_window().size = get_window().min_size
		get_window().move_to_center()
	
	# If after that the window is still larger than the screen, check if auto-scale is reasonable.
	if (Settings.read("ui_scale_override_enabled") == false) and (scale > 1.0):
		var screen_size := DisplayServer.screen_get_size()
		if (get_window().min_size.y > screen_size.y) or (get_window().min_size.x > screen_size.x):
			Status.post(tr("msg_auto_scale_failsafe_triggered") % snapped(scale, 0.01), Enums.MSG_WARN)
			Settings.store("ui_scale_override_enabled", true)
			Settings.store("ui_scale_override", 1.0)
			scale = 1.0
			get_window().move_to_center.call_deferred()

func _on_SceneTree_idle() -> void:
	
	await get_tree().process_frame
	get_window().set_deferred("borderless", false)
	get_window().set_deferred("transparent", false)
	recover_window_state()
	_apply_scale()
	get_window().size_changed.connect(self._on_window_resized)


func _ready() -> void:
	
	if Settings.read("ui_scale_override_enabled"):
		scale = Settings.read("ui_scale_override") as float
	else:
		scale = calculate_scale_from_dpi()

	_on_SceneTree_idle()


func _on_window_resized() -> void:
	
	base_size = get_window().get_size_with_decorations() / scale


func _exit_tree() -> void:
	
	save_window_state()
