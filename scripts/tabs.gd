extends TabContainer
## TabContainer extension that supports disabling the entire tab bar via [member disabled]
## independently of individually disabled tabs (e.g. tabs disabled when no game is installed).


var _manually_disabled: Array[int] = []

## Disables or re-enables all non-current tabs while preserving individually disabled tabs.
@export var disabled: bool = false: set = _set_disabled


func _set_disabled(value: bool) -> void:
	
	for i in get_tab_count():
		if (value == true) and (i == current_tab):
			# https://github.com/godotengine/godot/issues/52290
			continue
		if not i in _manually_disabled:
			super.set_tab_disabled(i, value)
	
	disabled = value

## Marks a tab as individually disabled or enabled, respecting the global lock state.
func set_individual_tab_disabled(index: int, value: bool) -> void:
	
	if (value == true) and (not index in _manually_disabled):
		_manually_disabled.append(index)
	elif index in _manually_disabled:
		_manually_disabled.erase(index)
	
	if not disabled:
		super.set_tab_disabled(index, value)
