extends Node
# A simple wrapper for the OS.execute method that does the execution in another
# thread and collects the results.

signal execution_finished

var output := []
var last_exit_code := 0


func execute(path: String, args: PackedStringArray) -> void:
	var thread := Thread.new()
	var exec_func := OS.execute.bind(path, args, output, true, true)
	thread.start(exec_func)
	while thread.is_alive():
		await get_tree().process_frame
	last_exit_code = thread.wait_to_finish()
	execution_finished.emit()
