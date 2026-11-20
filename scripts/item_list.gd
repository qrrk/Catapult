extends ItemList
## A small extension that adds a disabled property to ItemList.


## Disables or re-enables all items and input handling on this list.
@export var disabled: bool = false: set = _set_disabled
## When true, clears any active selection whenever the list is disabled.
@export var deselect_on_disable: bool = false


func _set_disabled(value: bool) -> void:
	
	for i in get_item_count():
		set_item_disabled(i, value)
	
	if value and deselect_on_disable:
		deselect_all()
	
	set_process_input(not value)
	disabled = value
