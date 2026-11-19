class_name ControlLock
extends RefCounted
## Ref-counted helper that disables a set of controls during async operations
## and restores their exact pre-lock disabled states when all locks are released.

var _controls: Array[Control] = []
var _lock_count: int = 0
var _saved_disabled: Dictionary = {}


func _init(controls: Array[Control] = []) -> void:
	_controls = controls


func lock() -> void:
	_lock_count += 1
	if _lock_count > 1:
		return
	
	_saved_disabled.clear()
	for control in _controls:
		if is_instance_valid(control) and ("disabled" in control):
			_saved_disabled[control] = control.get("disabled")
			control.set("disabled", true)


func unlock() -> void:
	if _lock_count <= 0:
		return
	
	_lock_count -= 1
	if _lock_count > 0:
		return
	
	for control in _saved_disabled:
		if is_instance_valid(control):
			control.set("disabled", _saved_disabled[control])
	_saved_disabled.clear()


func is_locked() -> bool:
	return _lock_count > 0
