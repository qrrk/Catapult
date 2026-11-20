extends ItemList
# A small extension that adds the "disabled" propertry to ItemList.


@export var disabled: bool = false: set = _set_disabled


func _set_disabled(value: bool) -> void:
	
	for i in get_item_count():
		set_item_disabled(i, value)
	
	set_process_input(not value)
	disabled = value
