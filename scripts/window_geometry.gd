extends Node

# This script makes it possible to set the correct size and position
# for the window before it is shown.

# Thanks to github.com/Lauson1ex for helping me figure this out.

var scale: float setget _set_scale
var min_base_size := Vector2(
	ProjectSettings.get("display/window/size/width"),
	ProjectSettings.get("display/window/size/height"))
var base_size := min_base_size

onready var _settings := $"/root/SettingsManager"
onready var _viewport := get_tree().get_root()


func _set_scale(new_scale: float) -> void:
	
	scale = new_scale
	_apply_scale()


func _apply_scale() -> void:
	
	var final_scale := scale if fmod(scale, 1.0) == 0 else scale + 0.002
	# This is a workaround for weird font aliasing that shows up when the scale
	# is a simple rational fraction, like 125% (5/4) or 150% (3/2).
	
	OS.min_window_size = min_base_size * final_scale
	OS.set_window_size(base_size * final_scale)



func calculate_scale_from_dpi() -> float:
	
	var ratio = OS.get_screen_dpi() / 96.0
	return stepify(ratio, 0.125)


func _on_SceneTree_idle():
	
	yield(get_tree(), "idle_frame")
	ProjectSettings.call_deferred("set_setting", "display/window/per_pixel_transparency/allowed", false)
	OS.set_deferred("window_per_pixel_transparency_enabled", false)
	OS.set_deferred("window_borderless", false)
	OS.call_deferred("set_icon", load("res://icons/appicon.svg").get_data())
	
	# Workaround for an issue with KWin that produces a glitchy bottom border
	# when changing the window from borderless to normal.
	if (OS.get_name() == "X11") and (OS.execute("pgrep", ["kwin"]) == 0):
		OS.call_deferred("set", "window_position", OS.window_position + Vector2(0, 1))


func _ready():
	
	if _settings.read("ui_scale_override_enabled"):
		scale = _settings.read("ui_scale_override") as float
	else:
		scale = calculate_scale_from_dpi()
	
	_apply_scale()
	OS.center_window()
	_viewport.connect("size_changed", self, "_on_window_resized")
	_on_SceneTree_idle()


func _on_window_resized() -> void:
	
	var new_size := OS.window_size / scale
	_viewport.set_size_override(true, new_size)
	base_size = new_size
