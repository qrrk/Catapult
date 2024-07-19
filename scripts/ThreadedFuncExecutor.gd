class_name ThreadedFuncExecutor
extends Object

signal func_returned

var _worker: Thread
var _result = null


func _wrapper(data: Array) -> void:
	
	if data[2]:  # So you can execute functions that take no arguments.
		_result = data[0].call(data[1], data[2])
	else:
		_result = data[0].call(data[1])
		
	call_deferred("emit_signal", "func_returned")


func execute(instance: Object, method: String, userdata = null,
		priority = Thread.PRIORITY_NORMAL) -> void:
	
	_worker = Thread.new()
	_result = null
	var data = [instance, method, userdata]
	_worker.start(Callable(self, "_wrapper").bind(data), priority)
	

func collect():
	
	if _worker.is_active():
		_worker.wait_to_finish()
		return _result
