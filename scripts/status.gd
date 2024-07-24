extends Node
# Singleton that simplifies posting of status messages from any place in the app.

const _STATUS_LBL_PATH := "/root/Catapult/Main/Log"

var rainbow_text := false

var _status_view: RichTextLabel = null
var _buffer := []  # Just in case there are any messages before the status label enters the scene.


func _ready() -> void:
	
	while true:
		_status_view = get_node(_STATUS_LBL_PATH)
		
		if _status_view:
			_flush_buffer()
			break
		else:
			await get_tree().create_timer(0.2).timeout


func post(msg: String, type: int = Enums.MSG_INFO) -> void:
	
	if (type == Enums.MSG_DEBUG) and (not Settings.read("debug_mode")):
		return
	
	var msg_data := _form_message(msg, type)
	
	if _status_view:
		_status_view.append_text(msg_data["bb_text"])
	else:
		print("saving message to buffer")
		_buffer.push_back(msg_data)
	
	if type == Enums.MSG_WARN:
		push_warning(msg)
	elif type == Enums.MSG_ERROR:
		push_error(msg)


func _datetime_with_msecs(utc = false) -> Dictionary:
	
	var datetime = Time.get_datetime_dict_from_system(utc)
	datetime["millisecond"] = Time.get_ticks_msec() % 1000
	return datetime


func _timestamp_with_msecs() -> String:
	
	var t = _datetime_with_msecs()
	var s = "[%02d:%02d:%02d.%03d]" % [t.hour, t.minute, t.second, t.millisecond]
	return s


func _form_message(msg: String, msg_type: int) -> Dictionary:
	
	var text = ""
	var bb_text = ""
		
	var time = _timestamp_with_msecs()
	text += time
	bb_text += "[color=#999999]%s[/color]" % time
	
	if rainbow_text:
		msg = "[rainbow freq=0.2 sat=5 val=1]%s[/rainbow]" % msg
	
	match msg_type:
		Enums.MSG_INFO:
			bb_text += " " + msg
		Enums.MSG_WARN:
			text += " [%s] %s" % [tr("tag_warning"), msg]
			bb_text += " [color=#ffd633][%s][/color] %s" % [tr("tag_warning"), msg]
		Enums.MSG_ERROR:
			text += " [%s] %s" % [tr("tag_error"), msg]
			bb_text += " [color=#ff3333][%s][/color] %s" % [tr("tag_error"), msg]
		Enums.MSG_DEBUG:
			bb_text += " [color=#999999][%s] %s[/color]" % [tr("tag_debug"), msg]
	
	bb_text += "\n"
	return {"type": msg_type, "text": text, "bb_text": bb_text}


func _flush_buffer() -> void:
	
	if _status_view:
		while _buffer.size() > 0:
			var msg = _buffer.pop_front()
			_status_view.append_text(msg["bb_text"])
