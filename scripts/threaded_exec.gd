extends Node
## Autoload singleton wrapping OS.execute() on a background thread so external commands
## do not freeze the UI thread.


## Emitted when the background command completes and results are populated.
signal execution_finished

## Captured stdout/stderr from the most recent execution.
var output := []
## Process exit code returned by the most recent execution.
var last_exit_code := 0


## Runs an external command on a background thread, then emits [signal execution_finished].
func execute(path: String, args: PackedStringArray) -> void:
	var thread := Thread.new()
	var exec_func := OS.execute.bind(path, args, output, true, true)
	thread.start(exec_func)
	while thread.is_alive():
		await get_tree().process_frame
	last_exit_code = thread.wait_to_finish()
	execution_finished.emit()
