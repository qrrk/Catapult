extends Node
## Autoload singleton for timestamped, BBCode-formatted status log messages.


## Emitted whenever a formatted message is posted and at least one listener is connected.
signal message_posted(bb_text: String)

## When true, newly posted messages are wrapped in a rainbow BBCode tag (easter egg).
var rainbow_text := false

var _buffer: Array[String] = []  # Holds messages posted before a log view connects.


## Posts a message of the given severity level to the log (or buffers it until a view connects).
func post(msg: String, type: int = Enums.MSG_INFO) -> void:
	
	if (type == Enums.MSG_DEBUG) and (not Settings.read("debug_mode")):
		return
	
	var bb_text := _format_message(msg, type)
	
	if message_posted.get_connections().is_empty():
		_buffer.append(bb_text)
	else:
		message_posted.emit(bb_text)
	
	if type == Enums.MSG_WARN:
		push_warning(msg)
	elif type == Enums.MSG_ERROR:
		push_error(msg)


## Returns and clears any formatted messages buffered before a log view connected.
func consume_buffer() -> Array[String]:
	
	var pending: Array[String] = []
	pending.assign(_buffer)
	_buffer.clear()
	return pending


func _datetime_with_msecs(utc: bool = false) -> Dictionary:
	
	var datetime := Time.get_datetime_dict_from_system(utc)
	datetime["millisecond"] = Time.get_ticks_msec() % 1000
	return datetime


func _timestamp_with_msecs() -> String:
	
	var t := _datetime_with_msecs()
	return "[%02d:%02d:%02d.%03d]" % [t.hour, t.minute, t.second, t.millisecond]


func _format_message(msg: String, msg_type: int) -> String:
	
	var time := _timestamp_with_msecs()
	var bb_text := "[color=#999999]%s[/color]" % time
	
	if rainbow_text:
		msg = "[rainbow freq=0.2 sat=5 val=1]%s[/rainbow]" % msg
	
	match msg_type:
		Enums.MSG_INFO:
			bb_text += " " + msg
		Enums.MSG_WARN:
			bb_text += " [color=#ffd633][%s][/color] %s" % [tr("tag_warning"), msg]
		Enums.MSG_ERROR:
			bb_text += " [color=#ff3333][%s][/color] %s" % [tr("tag_error"), msg]
		Enums.MSG_DEBUG:
			bb_text += " [color=#999999][%s] %s[/color]" % [tr("tag_debug"), msg]
	
	return bb_text + "\n"
