extends VBoxContainer


onready var _geom = $"/root/WindowGeometry"
onready var _settings = $"/root/SettingsManager"
onready var _root = $"/root/Catapult"
onready var _tabs = $"/root/Catapult/Main/Tabs"
onready var _debug_ui = $"/root/Catapult/Main/Tabs/Debug"

onready var _migration = {
	"savegames": $Migration/Grid/Savegames,
	"fonts": $Migration/Grid/Fonts,
	"templates": $Migration/Grid/Templates,
	"settings": $Migration/Grid/Settings,
	"tilesets": $Migration/Grid/Tilesets,
	"memorial": $Migration/Grid/Memorial,
	"mods": $Migration/Grid/Mods,
	"soundpacks": $Migration/Grid/Soundpacks,
	"graveyard": $Migration/Grid/Graveyard,
}


func _ready() -> void:
	
	$ShowGameDesc.pressed = _settings.read("show_game_desc")
	$PrintTips.pressed = _settings.read("print_tips_of_the_day")
	$UpdateToSame.pressed = _settings.read("update_to_same_build_allowed")
	$ShortenNames.pressed = _settings.read("shorten_release_names")
	$ShowObsoleteMods.pressed = _settings.read("show_obsolete_mods")
	$ShowDebug.pressed = _settings.read("debug_mode")
	$NumReleases/sbNumReleases.value = _settings.read("num_releases_to_request") as int
	
	$ScaleOverride/cbScaleOverrideEnable.pressed = _settings.read("ui_scale_override_enabled")
	$ScaleOverride/sbScaleOverride.editable = _settings.read("ui_scale_override_enabled")
	$ScaleOverride/sbScaleOverride.value = (_settings.read("ui_scale_override") as float) * 100.0
	
	var data_types = _settings.read("game_data_to_migrate")
	for type in _migration:
		if type in data_types:
			_migration[type].pressed = true
		else:
			_migration[type].pressed = false


func _on_ShowGameDesc_toggled(button_pressed: bool) -> void:
	
	_settings.store("show_game_desc", button_pressed)
	$"../../GameInfo".visible = button_pressed


func _on_PrintTips_toggled(button_pressed: bool) -> void:
	
	_settings.store("print_tips_of_the_day", button_pressed)


func _on_UpdateToSame_toggled(button_pressed: bool) -> void:
	
	_settings.store("update_to_same_build_allowed", button_pressed)


func _on_ShortenNames_toggled(button_pressed: bool) -> void:
	
	_settings.store("shorten_release_names", button_pressed)


func _on_ShowObsoleteMods_toggled(button_pressed: bool) -> void:
	
	_settings.store("show_obsolete_mods", button_pressed)


func _on_ShowDebug_toggled(button_pressed: bool) -> void:
	
	_settings.store("debug_mode", button_pressed)
	
	if button_pressed:
		if _debug_ui.get_parent() != _tabs:
			_tabs.call_deferred("add_child", _debug_ui)
	elif _debug_ui.get_parent() == _tabs:
		_tabs.call_deferred("remove_child", _debug_ui)


func _on_sbNumReleases_value_changed(value: float) -> void:
	
	_settings.store("num_releases_to_request", str(value))


func _on_cbScaleOverrideEnable_toggled(button_pressed: bool) -> void:
	
	_settings.store("ui_scale_override_enabled", button_pressed)
	$ScaleOverride/sbScaleOverride.editable = button_pressed
	
	if button_pressed:
		_geom.scale = _settings.read("ui_scale_override")
	else:
		_geom.scale = _geom.calculate_scale_from_dpi()


func _on_sbScaleOverride_value_changed(value: float) -> void:
	
	if _settings.read("ui_scale_override_enabled"):
		_settings.store("ui_scale_override", value / 100.0)
		_geom.scale = value / 100.0


func _on_any_migration_checkbox_toggled(_asdf: bool) -> void:
	# To cut down on the amount of code, let's treat all these checkboxes
	# as one control and poll all of them every time.
	
	var data_types = []
	for type in _migration:
		if _migration[type].pressed:
			data_types.append(type)
	
	_settings.store("game_data_to_migrate", data_types)
