extends VBoxContainer


var _langs := ["en", "fr", "ru", "zh", "cs", "es", "pl", "tr", "pt"]

var _themes := [
	"Godot_3.res",
	"Light.res",
	"Grey.res",
	"Solarized_Dark.res",
	"Solarized_Light.res",
]

onready var _root = $"/root/Catapult"
onready var _tabs = $"/root/Catapult/Main/Tabs"
onready var _debug_ui = $"/root/Catapult/Main/Tabs/Debug"


func _ready() -> void:
	
	# On the first launch, automatically set UI to system language, if available.
	var sys_locale := TranslationServer.get_locale().substr(0, 2)
	if (Settings.read("launcher_locale") == "") and (sys_locale in TranslationServer.get_loaded_locales()):
		Settings.store("launcher_locale", sys_locale)
	
	var locale = Settings.read("launcher_locale")
	TranslationServer.set_locale(locale)
	var lang_idx := _langs.find(locale)
	if lang_idx >= 0:
		$LauncherLanguage/obtnLanguage.selected = lang_idx
	
	var theme_idx := _themes.find(Settings.read("launcher_theme"))
	if theme_idx >= 0:
		$LauncherTheme/obtnTheme.selected = theme_idx
	
	$ShowGameDesc.pressed = Settings.read("show_game_desc")
	$KeepLauncherOpen.pressed = Settings.read("keep_open_after_starting_game")
	$PrintTips.pressed = Settings.read("print_tips_of_the_day")
	$UpdateToSame.pressed = Settings.read("update_to_same_build_allowed")
	$ShortenNames.pressed = Settings.read("shorten_release_names")
	$AlwaysShowInstalls.pressed = Settings.read("always_show_installs")
	$ShowObsoleteMods.pressed = Settings.read("show_obsolete_mods")
	$InstallArchivedMods.pressed = Settings.read("install_archived_mods")
	$ShowDebug.pressed = Settings.read("debug_mode")
	$NumReleases/sbNumReleases.value = Settings.read("num_releases_to_request") as int
	$NumPrs/sbNumPRs.value = Settings.read("num_prs_to_request") as int
	
	$ScaleOverride/cbScaleOverrideEnable.pressed = Settings.read("ui_scale_override_enabled")
	$ScaleOverride/sbScaleOverride.editable = Settings.read("ui_scale_override_enabled")
	$ScaleOverride/sbScaleOverride.value = (Settings.read("ui_scale_override") as float) * 100.0


func _on_obtnLanguage_item_selected(index: int) -> void:
	
	var locale = _langs[index]
	Settings.store("launcher_locale", locale)
	TranslationServer.set_locale(locale)
	_root.assign_localized_text()


func _on_obtnTheme_item_selected(index: int) -> void:
	
	Settings.store("launcher_theme", _themes[index])
	_root.load_ui_theme(_themes[index])


func _on_ShowGameDesc_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_game_desc", button_pressed)
	$"../../GameInfo".visible = button_pressed


func _on_KeepLauncherOpen_toggled(button_pressed: bool) -> void:
	
	Settings.store("keep_open_after_starting_game", button_pressed)


func _on_PrintTips_toggled(button_pressed: bool) -> void:
	
	Settings.store("print_tips_of_the_day", button_pressed)


func _on_UpdateToSame_toggled(button_pressed: bool) -> void:
	
	Settings.store("update_to_same_build_allowed", button_pressed)


func _on_ShortenNames_toggled(button_pressed: bool) -> void:
	
	Settings.store("shorten_release_names", button_pressed)


func _on_AlwaysShowInstalls_toggled(button_pressed: bool) -> void:
	
	Settings.store("always_show_installs", button_pressed)


func _on_ShowObsoleteMods_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_obsolete_mods", button_pressed)

func _on_InstallArchivedMods_toggled(button_pressed: bool) -> void:
	
	Settings.store("install_archived_mods", button_pressed)

func _on_ShowDebug_toggled(button_pressed: bool) -> void:
	
	Settings.store("debug_mode", button_pressed)
	
	if button_pressed:
		if _debug_ui.get_parent() != _tabs:
			_tabs.call_deferred("add_child", _debug_ui)
	elif _debug_ui.get_parent() == _tabs:
		_tabs.call_deferred("remove_child", _debug_ui)


func _on_sbNumReleases_value_changed(value: float) -> void:
	
	Settings.store("num_releases_to_request", str(value))

func _on_sbNumPRs_value_changed(value: float) -> void:
	
	Settings.store("num_prs_to_request", str(value))


func _on_cbScaleOverrideEnable_toggled(button_pressed: bool) -> void:
	
	Settings.store("ui_scale_override_enabled", button_pressed)
	$ScaleOverride/sbScaleOverride.editable = button_pressed
	
	if button_pressed:
		Geom.scale = Settings.read("ui_scale_override")
	else:
		Geom.scale = Geom.calculate_scale_from_dpi()
	
	_root.theme.apply_scale(Geom.scale)


func _on_sbScaleOverride_value_changed(value: float) -> void:
	
	if Settings.read("ui_scale_override_enabled"):
		Settings.store("ui_scale_override", value / 100.0)
		Geom.scale = value / 100.0
		_root.theme.apply_scale(Geom.scale)
