extends VBoxContainer


signal status_message


onready var _settings = $"/root/SettingsManager"
onready var _fshelper = $"/root/Catapult/FSHelper"
onready var _path = $"/root/Catapult/PathHelper"
onready var _mods = $"../../../Mods"
onready var _sound = $"../../../Sound"
onready var _totd = $"/root/Catapult/TOTD"
onready var _workdir = OS.get_executable_path().get_base_dir()


func _on_Button_pressed() -> void:
	
	# Test modinfo parsing.
	
	var message = "Found mods:"
	var mods_dir = _workdir + "/" + _settings.read("game") + "/current/data/mods"
	
	emit_signal("status_message", "Looking for mods in %s" % mods_dir)	
	
	for mod in _mods.parse_mods_dir(mods_dir):
		message += "\n" + mod["modinfo"]["name"]
		message += "\n(%s)" % mod["location"]
	
	emit_signal("status_message", message)


func _on_Button2_pressed() -> void:
	
	# Test soundpack parsing.
	
	var message = "Found soundpacks:"
	var sound_dir = _workdir + "/" + _settings.read("game") + "/current/sound"
	
	emit_signal("status_message", "Looking for soundpacks in %s" % sound_dir)
	
	for pack in _sound.parse_sound_dir(sound_dir):
		message += "\nName: %s" % pack["name"]
		message += "\nDescription: %s" % pack["description"]
		message += "\nLocation: %s" % pack["location"]
	
	emit_signal("status_message", message)


func _on_Button3_pressed():
	
	var workdir = OS.get_executable_path().get_base_dir()
	var d = Directory.new()
	var dir = workdir.plus_file("testdir")
	d.make_dir(dir)
	
	var command_linux = {
		"name": "sh",
		"args": ["-c", "echo", "Lorem ipsum"]
	}
	var command_windows = {
		"name": "cmd",
		"args": ["/S", "/C", "rmdir \"%s\"" % dir]
	}
	
	var command
	match OS.get_name():
		"X11":
			command = command_linux
		"Windows":
			command = command_windows
	
	emit_signal("status_message", "Command data: " + str(command))
	yield(get_tree().create_timer(2), "timeout")
	
	var oew = OSExecWrapper.new()
	oew.execute(command["name"], command["args"])
	yield(oew, "process_exited")

	emit_signal("status_message", "Command exited with code %s. Output:\n%s" % \
			[oew.exit_code, oew.output[0]])


func _on_Button4_pressed() -> void:
	
	emit_signal("status_message", "Testing status messages:\n")
	yield(get_tree().create_timer(0.05), "timeout")
	emit_signal("status_message", "This is a normal (info) message.", Enums.MSG_INFO)
	yield(get_tree().create_timer(0.05), "timeout")
	emit_signal("status_message", "This is a warning message.", Enums.MSG_WARN)
	yield(get_tree().create_timer(0.05), "timeout")
	emit_signal("status_message", "This is an error message.", Enums.MSG_ERROR)
	yield(get_tree().create_timer(0.05), "timeout")
	emit_signal("status_message", "This is a debug message.\n", Enums.MSG_DEBUG)


func _on_Button5_pressed() -> void:
	
	var path = _workdir
	emit_signal("status_message", "Listing directory %s..." % path, Enums.MSG_DEBUG)
	yield(get_tree().create_timer(0.1), "timeout")
	
	var listing_msg = "\n"
	for p in _fshelper.list_dir(path, true):
		listing_msg += p + "\n"
		
	emit_signal("status_message", listing_msg, Enums.MSG_DEBUG)


func _on_Button6_pressed() -> void:
	
	emit_signal("status_message", "Random tip of the day (debug):\n%s\n" % _totd.get_tip())


func _on_Button7_pressed() -> void:
	
	var msg = "Paths provided by PathHelper:"
	
	for prop in _path.get_property_list():
		var name = prop["name"]
		if (prop["type"] == 4) and ("dir" in name):
			msg += "\n%s: %s" % [name, _path.get(name)]
	
	emit_signal("status_message", msg, Enums.MSG_DEBUG)


func _on_Button8_pressed() -> void:
	
	var locales = TranslationServer.get_loaded_locales()
	var curr_locale = TranslationServer.get_locale()
	emit_signal("status_message", "Loaded locales: " + str(locales), Enums.MSG_DEBUG)
	emit_signal("status_message", "Current locale: " + curr_locale, Enums.MSG_DEBUG)
	for locale in locales:
		TranslationServer.set_locale(locale)
		emit_signal("status_message", tr("debug_test"), Enums.MSG_DEBUG)
	TranslationServer.set_locale(curr_locale)


func _on_Button9_pressed() -> void:
	
	var msg := """Screen information:
	Screen count: %s
	Current screen: %s
	Screen position: %s
	Screen size: %s
	Window position: %s
	Window size: %s
	Real window size: %s\n""" % [ \
	OS.get_screen_count(),
	OS.current_screen,
	OS.get_screen_position(),
	OS.get_screen_size(),
	OS.window_position,
	OS.window_size,
	OS.get_real_window_size()]
	
	emit_signal("status_message", msg, Enums.MSG_DEBUG)
