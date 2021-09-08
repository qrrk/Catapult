class_name OSExecWrapper
extends Object


signal process_exited

var _worker: Thread
var output = []
var exit_code = null


func _wrapper(path_and_args: Array) -> void:
	
	exit_code = OS.execute(path_and_args[0], path_and_args[1], true, output, true)
	emit_signal("process_exited")
	_worker.call_deferred("wait_to_finish")

func execute(path: String, args: PoolStringArray) -> void:
	
	_worker = Thread.new()
	_worker.start(self, "_wrapper", [path, args])

