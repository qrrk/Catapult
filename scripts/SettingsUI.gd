extends VBoxContainer


var _langs := ["en", "fr", "ru", "zh", "cs", "es", "pl", "tr", "pt", "ko"]

var _themes := [
	"Godot_4.tres",
	"Light.tres",
	"Gray.tres",
	"Solarized_Dark.tres",
	"Solarized_Light.tres",
]

var _proxy_options := ["off", "on", "download"]

@onready var _root = $"/root/Catapult"


func _ready() -> void:
	
	# On the first launch, automatically set UI to system language, if available.
	var sys_locale := TranslationServer.get_locale().substr(0, 2)
	if (Settings.read("launcher_locale") == "") and (sys_locale in TranslationServer.get_loaded_locales()):
		Settings.store("launcher_locale", sys_locale)
	
	var locale = Settings.read("launcher_locale")
	TranslationServer.set_locale(locale)
	var lang_idx := _langs.find(locale)
	if lang_idx >= 0:
		%LauncherLanguageList.selected = lang_idx
	
	var theme_idx := _themes.find(Settings.read("launcher_theme"))
	if theme_idx >= 0:
		%LauncherThemeList.selected = theme_idx
	
	%ShowGameDescSwitch.button_pressed = Settings.read("show_game_desc")
	%KeepLauncherOpenSwitch.button_pressed = Settings.read("keep_open_after_starting_game")
	%PrintTipsSwitch.button_pressed = Settings.read("print_tips_of_the_day")
	%UpdateToSameVerSwitch.button_pressed = Settings.read("update_to_same_build_allowed")
	%ShortenNamesSwitch.button_pressed = Settings.read("shorten_release_names")
	%AlwaysShowInstallsSwitch.button_pressed = Settings.read("always_show_installs")
	%ShowObsoleteModsSwitch.button_pressed = Settings.read("show_obsolete_mods")
	%InstallArchivedModsSwitch.button_pressed = Settings.read("install_archived_mods")
	%KeepDownloadCacheSwitch.button_pressed = Settings.read("keep_cache")
	%IgnoreDownloadCacheSwitch.button_pressed = Settings.read("ignore_cache")
	%DebugModeSwitch.button_pressed = Settings.read("debug_mode")
	%NumReleasesField.value = Settings.read("num_releases_to_request") as int
	%NumPrsField.value = Settings.read("num_prs_to_request") as int
	
	var proxy_option_idx := _proxy_options.find(Settings.read("proxy_option"))
	if proxy_option_idx >= 0:
		%ProxyOptionList.selected = proxy_option_idx
	else:
		%ProxyOptionList.selected = 0
	%ProxyHostField.text = Settings.read("proxy_host")
	%ProxyPortField.value = Settings.read("proxy_port") as int
	
	%CustomScaleEnableSwitch.button_pressed = Settings.read("ui_scale_override_enabled")
	%CustomScaleValueField.editable = Settings.read("ui_scale_override_enabled")
	%CustomScaleValueField.value = (Settings.read("ui_scale_override") as float) * 100.0


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
	%GameInfoBox.visible = button_pressed


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

func _on_KeepCache_toggled(button_pressed: bool) -> void:
	
	Settings.store("keep_cache", button_pressed)

func _on_IgnoreCache_toggled(button_pressed: bool) -> void:
	
	Settings.store("ignore_cache", button_pressed)

func _on_ShowDebug_toggled(button_pressed: bool) -> void:
	
	Settings.store("debug_mode", button_pressed)
	
	if button_pressed:
		%DebugArea.reparent(%TabbedLayout)
	elif %DebugArea.get_parent() == %TabbedLayout:
		%DebugArea.hide()
		%DebugArea.reparent(_root)


func _on_sbNumReleases_value_changed(value: float) -> void:
	
	Settings.store("num_releases_to_request", str(value))

func _on_sbNumPRs_value_changed(value: float) -> void:
	
	Settings.store("num_prs_to_request", str(value))


func _on_obtnProxyOption_item_selected(index):
	Settings.store("proxy_option", _proxy_options[index])

func _on_leProxyHost_text_changed(new_text):
	Settings.store("proxy_host", new_text)

func _on_sbProxyPort_value_changed(value):
	Settings.store("proxy_port", value)


func _on_cbScaleOverrideEnable_toggled(button_pressed: bool) -> void:
	
	Settings.store("ui_scale_override_enabled", button_pressed)
	%CustomScaleValueField.editable = button_pressed
	
	if button_pressed:
		Geom.scale = Settings.read("ui_scale_override")
	else:
		Geom.scale = Geom.calculate_scale_from_dpi()


func _on_sbScaleOverride_value_changed(value: float) -> void:
	
	if Settings.read("ui_scale_override_enabled"):
		Settings.store("ui_scale_override", value / 100.0)
		Geom.scale = value / 100.0
