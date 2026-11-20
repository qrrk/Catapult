extends Node


@export var lockable_controls: Array[Control] = []

# For UI scaling on the fly
var _base_min_sizes: Dictionary = {}
var _easter_egg_counter: int = 0


func _ready() -> void:
	
	Status.message_posted.connect(_on_status_message_posted)
	for bb_text in Status.consume_buffer():
		%LogText.append_text(bb_text)
	Settings.setting_changed.connect(_on_setting_changed)
	
	# Apply UI theme
	var theme_file: String = Settings.read("launcher_theme")
	load_ui_theme(theme_file)
	
	_save_control_min_sizes()
	_scale_control_min_sizes(Geom.scale)
	Geom.scale_changed.connect(_on_ui_scale_changed)
	
	assign_localized_text()
	
	var welcome_msg := tr("str_welcome")
	if Settings.read("print_tips_of_the_day"):
		welcome_msg += tr("str_tip_of_the_day") + TOTD.get_tip() + "\n"
	Status.post(welcome_msg)
	
	_setup_ui()


func _on_status_message_posted(bb_text: String) -> void:
	
	%LogText.append_text(bb_text)


func _on_setting_changed(key: String, value: Variant) -> void:
	
	match key:
		"launcher_locale":
			TranslationServer.set_locale(value as String)
			assign_localized_text()
		"launcher_theme":
			load_ui_theme(value as String)
		"show_game_desc":
			%GameInfoBox.visible = value as bool
		"debug_mode":
			_set_debug_tab_visible(value as bool)


func _set_debug_tab_visible(show_debug: bool) -> void:
	
	if show_debug:
		if %DebugArea.get_parent() != %TabbedLayout:
			%DebugArea.reparent(%TabbedLayout)
	elif %DebugArea.get_parent() == %TabbedLayout:
		%DebugArea.hide()
		%DebugArea.reparent(self)


func _save_control_min_sizes() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if ("custom_minimum_size" in node) and (node.custom_minimum_size != Vector2.ZERO):
			_base_min_sizes[node] = node.custom_minimum_size


func _scale_control_min_sizes(factor: float) -> void:
	
	for node in _base_min_sizes:
		node.custom_minimum_size = _base_min_sizes[node] * factor


func assign_localized_text() -> void:
	
	get_window().set_title(tr("window_title"))
	
	%TabbedLayout.set_tab_title(0, tr("tab_game"))
	%TabbedLayout.set_tab_title(1, tr("tab_mods"))
	%TabbedLayout.set_tab_title(2, tr("tab_soundpacks"))
	%TabbedLayout.set_tab_title(3, tr("tab_fonts"))
	%TabbedLayout.set_tab_title(4, tr("tab_backups"))
	%TabbedLayout.set_tab_title(5, tr("tab_settings"))
	
	var desc_key := GameRegistry.get_desc_key(Settings.read("game"))
	if not desc_key.is_empty():
		%GameDescText.text = tr(desc_key)


func load_ui_theme(theme_file: String) -> void:
	
	var ts := ThemeScaler.new()
	var proto = load("res://themes".path_join(theme_file))
	if proto is Theme:
		var new_theme: Theme = ts.make_scaled_theme(proto, Geom.scale)
		self.theme = new_theme
	else:
		Status.post(tr("msg_theme_load_error") % theme_file, Enums.MSG_ERROR)
		proto = ThemeDB.get_project_theme()
		self.theme = ts.make_scaled_theme(proto, Geom.scale)


func _setup_ui() -> void:
	
	%GamesList.clear()
	for game in GameRegistry.get_games():
		%GamesList.add_item(game["title"])
	
	%GameInfoBox.visible = Settings.read("show_game_desc")
	_set_debug_tab_visible(Settings.read("debug_mode"))
	
	var current_game: String = Settings.read("game")
	var game_idx := GameRegistry.index_of(current_game)
	if game_idx >= 0:
		%GamesList.select(game_idx)
	
	%GameArea.setup()


func _on_ui_scale_changed(new_scale: float) -> void:
	
	_scale_control_min_sizes(new_scale)
	load_ui_theme(Settings.read("launcher_theme"))


func _on_Tabs_tab_changed(tab: int) -> void:
	
	var active_tab: Control = %TabbedLayout.get_tab_control(tab)
	%LogText.visible = (active_tab != %SettingsArea)
	%GameArea.refresh_currently_installed()
	if active_tab and active_tab.has_method("on_tab_activated"):
		active_tab.call("on_tab_activated")


func _on_tab_unavailable() -> void:
	
	%TabbedLayout.set_deferred("current_tab", 0)


func _on_GamesList_item_selected(index: int) -> void:
	
	var game := GameRegistry.get_by_index(index)
	if game.is_empty():
		return
	Settings.store("game", game["id"])
	%GameDescText.text = tr(game["desc_key"])
	
	%TabbedLayout.current_tab = 0
	%GameArea.apply_game_choice()
	%GameArea.refresh_currently_installed()
	
	%ModsArea.refresh_data()


func _on_game_installs_changed(has_installs: bool) -> void:
	
	for i in [1, 2, 3, 4]:
		%TabbedLayout.set_individual_tab_disabled(i, not has_installs)


func _on_tab_operation_started() -> void:
	
	ControlLock.lock(lockable_controls)


func _on_tab_operation_finished() -> void:
	
	ControlLock.unlock(lockable_controls)


func _on_Description_meta_clicked(meta: Variant) -> void:
	
	OS.shell_open(str(meta))


func _on_Log_meta_clicked(meta: Variant) -> void:
	
	OS.shell_open(str(meta))


func _on_InfoIcon_gui_input(event: InputEvent) -> void:
	
	if (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_LEFT) and (event.is_pressed()):
		_easter_egg_counter += 1
		if _easter_egg_counter == 3:
			Status.post("[color=red]%s[/color]" % tr("msg_easter_egg_warning"))
		if _easter_egg_counter == 10:
			_activate_easter_egg()


func _activate_easter_egg() -> void:
	
	for node in Helpers.get_all_nodes_within(self):
		if node is Control:
			node.pivot_offset = node.size / 2.0
			node.rotation = (randf() * 2.0 - 1.0) * PI / 180.0
	
	Status.rainbow_text = true
	
	for i in range(20):
		Status.post(tr("msg_easter_egg_activated"))
		await get_tree().create_timer(0.1).timeout
