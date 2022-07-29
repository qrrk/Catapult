extends ItemList


var disabled: bool setget _set_disabled, _get_disabled


func _set_disabled(value: bool) -> void:
	
	for i in get_item_count():
		set_item_disabled(i, value)
	
	if value == true:
		unselect_all()
	
	disabled = value


func _get_disabled() -> bool:
	
	return disabled
