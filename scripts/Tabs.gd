extends TabContainer
# A simple extension for TabContainer that allows it to be disabled as a whole
# and in a way independent of its individual tabs being disabled or re-enabled.


var _manually_disabled = []

export var disabled: bool = false setget _set_disabled


func _set_disabled(value: bool) -> void:
	
	for i in get_tab_count():
		if (value == true) and (i == current_tab):
			# https://github.com/godotengine/godot/issues/52290
			continue
		if not i in _manually_disabled:
			.set_tab_disabled(i, value)
	
	disabled = value


func set_tab_disabled(index: int, value: bool) -> void:
	
	if (value == true) and (not index in _manually_disabled):
		_manually_disabled.append(index)
	elif index in _manually_disabled:
		_manually_disabled.erase(index)
	
	if not disabled:
		.set_tab_disabled(index, value)
