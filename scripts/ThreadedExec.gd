extends Node
# A simple wrapper for the OS.execute method that does the execution in another
# thread and collects the results.

signal execution_finished

#var _worker: Thread
var output := []
var last_exit_code := 0


#func _wrapper(path_and_args: Array) -> void:
	#pass # FIXME
	#exit_code = OS.execute(path_and_args[0], path_and_args[1], true, output, true)
	#emit_signal("process_exited")
	#_worker.call_deferred("wait_to_finish")

#func execute(path: String, args: PackedStringArray) -> void:
	#
	#pass # FIXME
	#_worker = Thread.new()
	#_worker.start(Callable(self, "_wrapper").bind([path, args]))


func execute(path: String, args: PackedStringArray) -> void:
	var thread := Thread.new()
	var exec_func := OS.execute.bind(path, args, output, true, true)
	thread.start(exec_func)
	while thread.is_alive():
		await get_tree().process_frame
	last_exit_code = thread.wait_to_finish()
	execution_finished.emit()
	
	
	
