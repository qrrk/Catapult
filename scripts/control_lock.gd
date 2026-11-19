class_name ControlLock
extends RefCounted
## Ref-counted static helper that disables a set of controls during async operations
## and restores their pre-lock disabled states when all locks on each control are released.
## Lock state is stored in each control's metadata so overlapping lock sets compose safely.

const _META_LOCK_COUNT := &"control_lock_count"
const _META_RESTORE_DISABLED := &"restore_disabled_to"


static func lock(controls: Array[Control]) -> void:
	for control in controls:
		if not is_instance_valid(control) or not ("disabled" in control):
			continue
		var count: int = control.get_meta(_META_LOCK_COUNT, 0)
		if count == 0:
			control.set_meta(_META_RESTORE_DISABLED, control.get("disabled"))
			control.set("disabled", true)
		control.set_meta(_META_LOCK_COUNT, count + 1)


static func unlock(controls: Array[Control]) -> void:
	for control in controls:
		if not is_instance_valid(control):
			continue
		var count: int = control.get_meta(_META_LOCK_COUNT, 0)
		if count <= 0:
			continue
		count -= 1
		if count == 0:
			control.set("disabled", control.get_meta(_META_RESTORE_DISABLED, false))
			control.remove_meta(_META_LOCK_COUNT)
			control.remove_meta(_META_RESTORE_DISABLED)
		else:
			control.set_meta(_META_LOCK_COUNT, count)


static func is_any_locked(controls: Array[Control]) -> bool:
	for control in controls:
		if is_instance_valid(control) and control.get_meta(_META_LOCK_COUNT, 0) > 0:
			return true
	return false
