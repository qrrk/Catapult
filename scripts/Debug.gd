extends VBoxContainer


@onready var _mods = $"../../../Mods"
@onready var _sound = $"../../../Sound"


func _on_Button_pressed() -> void:
	
	# Test modinfo parsing.
	
	var message = "Found mods:"
	var mods_dir = Paths.mods_stock
	
	Status.post("Looking for mods in %s" % mods_dir)
	
	for mod in _mods.parse_mods_dir(mods_dir):
		message += "\n" + mod["modinfo"]["name"]
		message += "\n(%s)" % mod["location"]
	
	Status.post(message)


func _on_Button2_pressed() -> void:
	
	# Test soundpack parsing.
	
	var message = "Found soundpacks:"
	var sound_dir = Paths.sound_user
	
	Status.post("Looking for soundpacks in %s" % sound_dir)
	
	for pack in _sound.parse_sound_dir(sound_dir):
		message += "\nName: %s" % pack["name"]
		message += "\nDescription: %s" % pack["description"]
		message += "\nLocation: %s" % pack["location"]
	
	Status.post(message)


func _on_Button3_pressed():
	
	var dir = Paths.own_dir.path_join("testdir")
	DirAccess.make_dir_absolute(dir)
	
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
	
	Status.post("Command data: " + str(command))
	await get_tree().create_timer(2).timeout
	
	var oew = OSExecWrapper.new()
	oew.execute(command["name"], command["args"])
	await oew.process_exited

	Status.post("Command exited with code %s. Output:\n%s" % [oew.exit_code, oew.output[0]])


func _on_Button4_pressed() -> void:
	
	Status.post("Testing status messages:\n")
	await get_tree().create_timer(0.05).timeout
	Status.post("This is a normal (info) message.", Enums.MSG_INFO)
	await get_tree().create_timer(0.05).timeout
	Status.post("This is a warning message.", Enums.MSG_WARN)
	await get_tree().create_timer(0.05).timeout
	Status.post("This is an error message.", Enums.MSG_ERROR)
	await get_tree().create_timer(0.05).timeout
	Status.post("This is a debug message.\n", Enums.MSG_DEBUG)


func _on_Button5_pressed() -> void:
	
	var path = Paths.own_dir
	Status.post("Listing directory %s..." % path, Enums.MSG_DEBUG)
	await get_tree().create_timer(0.1).timeout
	
	var listing_msg = "\n"
	for p in FS.list_dir(path, true):
		listing_msg += p + "\n"
		
	Status.post(listing_msg, Enums.MSG_DEBUG)


func _on_Button6_pressed() -> void:
	
	Status.post("Random tip of the day (debug):\n%s\n" % TOTD.get_tip())


func _on_Button7_pressed() -> void:
	
	var msg = "PathHelper properties:"
	
	for prop in Paths.get_property_list():
		var name = prop["name"]
		if (prop["type"] == 4):
			msg += "\n%s: %s" % [name, Paths.get(name)]
	
	Status.post(msg, Enums.MSG_DEBUG)


func _on_Button8_pressed() -> void:
	
	var locales = TranslationServer.get_loaded_locales()
	var curr_locale = TranslationServer.get_locale()
	Status.post("Loaded locales: " + str(locales), Enums.MSG_DEBUG)
	Status.post("Current locale: " + curr_locale, Enums.MSG_DEBUG)
	for locale in locales:
		TranslationServer.set_locale(locale)
		Status.post(tr("debug_test"), Enums.MSG_DEBUG)
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
	DisplayServer.get_screen_count(),
	get_window().current_screen,
	DisplayServer.screen_get_position(),
	DisplayServer.screen_get_size(),
	get_window().position,
	get_window().size,
	get_window().get_size_with_decorations()]
	
	Status.post(msg, Enums.MSG_DEBUG)
