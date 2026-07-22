extends VBoxContainer


const _PREVIEW_TEXT_EN := [
	"A quick brown fox jumps over the lazy dog.",
	"A quart jar of oil mixed with zinc oxide makes a very bright paint.",
	"A quick movement of the enemy will jeopardize six gunboats.",
	"A wizard’s job is to vex chumps quickly in fog.",
	"Amazingly few discotheques provide jukeboxes.",
	"Few black taxis drive up major roads on quiet hazy nights.",
	"Jack quietly moved up front and seized the big ball of wax.",
	"Just keep examining every low bid quoted for zinc etchings.",
	"Just work for improved basic techniques to maximize your typing skill.",
	"My faxed joke won a pager in the cable TV quiz show.",
	"My girl wove six dozen plaid jackets before she quit.",
	"Pack my box with five dozen liquor jugs.",
	"Six big devils from Japan quickly forgot how to waltz.",
	"Six boys guzzled cheap raw plum vodka quite joyfully.",
	"Sixty zippers were quickly picked from the woven jute bag.",
	"The five boxing wizards jump quickly.",
	"The lazy major was fixing Cupid’s broken quiver.",
	"The public was amazed to view the quickness and dexterity of the juggler.",
	"We promptly judged antique ivory buckles for the next prize.",
	"Whenever the black fox jumped the squirrel gazed suspiciously.",
]

const _PREVIEW_TEXT_RU := [
	"Аэрофотосъёмка ландшафта уже выявила земли богачей и процветающих крестьян.",
	"Блеф разъедает ум, чаще цыгана живёшь беспокойно, юля — грех это!",
	"В чащах юга жил бы цитрус? Да, но фальшивый экземпляр!",
	"Вопрос футбольных энциклопедий замещая чушью: эй, где съеден ёж?",
	"Лингвисты в ужасе: фиг выговоришь этюд: «подъём челябинский, запах щец».",
	"Обдав его удушающей пылью, множество ярких фаэтонов исчезло из цирка.",
	"Однажды съев фейхоа, я, как зацикленный, ностальгирую всё чаще и больше по этому чуду.",
	"Пиши: зять съел яйцо, ещё чан брюквы… эх! Ждём фигу!",
	"Подъехал шофёр на рефрижераторе грузить яйца для обучающихся элитных медиков.",
	"Расчешись! Объявляю: туфли у камина, где этот хищный ёж цаплю задел.",
	"Съел бы ёж лимонный пьезокварц, где электрическая юла яшму с туфом похищает.",
	"Съешь ещё этих мягких французских булок, да выпей же чаю.",
	"Флегматичная эта верблюдица жуёт у подъезда засыхающий горький шиповник.",
	"Художник-эксперт с компьютером всего лишь яйца в объёмный низкий ящик чохом фасовал.",
	"Шалящий фавн прикинул объём горячих звезд этих вьюжных царств.",
	"Широкая электрификация южных губерний даст мощный толчок подъёму сельского хозяйства.",
	"Шифровальщица попросту забыла ряд ключевых множителей и тэгов.",
	"Эй, жлоб! Где туз? Прячь юных съёмщиц в шкаф.",
	"Эй, цирюльникъ, ёжик выстриги, да щетину ряхи сбрей, феном вошь за печь гони!",
	"Эти ящерицы чешут вперёд за ключом, но багаж в сейфах, поди подъедь…",
	"Южно-эфиопский грач увёл мышь за хобот на съезд ящериц.",
]

const _PREVIEW_TEXT_NUM := "1234567890 !@#$ %^&* ()[]{}"

@onready var _rng := RandomNumberGenerator.new()


func _make_preview_string() -> String:
	
	var index = _rng.randi_range(0, len(_PREVIEW_TEXT_NUM) - 1)
	var result = _PREVIEW_TEXT_NUM
	
	if Settings.read("font_preview_cyrillic"):
		index = _rng.randi_range(0, len(_PREVIEW_TEXT_RU) - 1)
		result += "\n\n" + _PREVIEW_TEXT_RU[index]
	else:
		index = _rng.randi_range(0, len(_PREVIEW_TEXT_EN) - 1)
		result += "\n\n" + _PREVIEW_TEXT_EN[index]
	
	return result


func _show_current_config_info() -> void:
	
	var config: Dictionary = %FontManager.font_config
	var fields := {
		"typeface": tr("str_curr_font_config_ui"),
		"map_typeface": tr("str_curr_font_config_map"),
		"overmap_typeface": tr("str_curr_font_config_omap")}
	var text := "[u]%s[/u]\n[table=2]" % tr("str_curr_font_config")
	
	for field in fields:
		var list: Array = config[field]
		var row: String = "\n[cell]%s: [/cell]" % fields[field]
		var fonts := ""
		for i in len(list):
			if i > 0:
				fonts += "  =>"
			fonts += "  [i]%s[/i]" % list[i].get_file().get_basename()
		row += "[cell]%s[/cell]" % fonts
		text += row
	
	text += "\n[/table]"
	
	%CurrentFontConfigInfo.text = text


func _load_font_options() -> void:
	
	%FontManager.load_game_options()
	
	%FontSizeUIField.value = %FontManager.get_game_option("FONT_SIZE") as int
	%FontSizeMapField.value = %FontManager.get_game_option("MAP_FONT_SIZE") as int
	%FontSizeOvermapField.value = %FontManager.get_game_option("OVERMAP_FONT_SIZE") as int
	%FontBlendingSwitch.button_pressed = (%FontManager.get_game_option("FONT_BLENDING").to_lower() == "true")


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 3:
		return
	
	if not %FontManager.font_config_file_exists():
		Status.post(tr("msg_no_font_config_file"), Enums.MSG_WARN)
		%TabbedLayout.current_tab = 0
		return
	
	if not %FontManager.options_file_exists():
		Status.post(tr("msg_no_game_options_file"), Enums.MSG_WARN)
		%TabbedLayout.current_tab = 0
		return
		
	%FontManager.load_available_fonts()
	%FontManager.load_font_config()
	
	for btn in [%SetFontUIBtn, %SetFontMapBtn, %SetFontOvermapBtn, %SetFontAllBtn]:
		btn.disabled = true
	
	%FontsList.clear()
	for font in %FontManager.available_fonts:
		%FontsList.add_item(font["name"])
		%FontsList.set_item_tooltip(%FontsList.get_item_count() - 1, tr(font["desc_key"]))
	
	%PreviewCyrillicSwitch.button_pressed = Settings.read("font_preview_cyrillic")
	_load_font_options()
	
	%FontPreviewText.text = ""
	_show_current_config_info()


func _on_FontsList_item_selected(index: int) -> void:
	
	var font_info = %FontManager.available_fonts[index]
	var font_path := "res://fonts/ingame".path_join(font_info["file"])
	var font_res := FontFile.new()
	font_res.load_dynamic_font(font_path)
	
	%FontPreviewText.add_theme_font_override("normal_font", font_res)
	%FontPreviewText.add_theme_font_size_override("normal_font_size", 15.0 * Geom.scale)
	%FontPreviewText.text = _make_preview_string()
	
	for btn in [%SetFontUIBtn, %SetFontMapBtn, %SetFontOvermapBtn, %SetFontAllBtn]:
		btn.disabled = false


func _on_BtnSetFontX_pressed(ui: bool, map: bool, overmap: bool) -> void:
	
	var index = %FontsList.get_selected_items()[0]
	var font_name = %FontManager.available_fonts[index]["name"]
	
	if ui:
		Status.post(tr("msg_setting_ui_font") % font_name)
	if map:
		Status.post(tr("msg_setting_map_font") % font_name)
	if overmap:
		Status.post(tr("msg_setting_omap_font") % font_name)
	
	%FontManager.set_font(index, ui, map, overmap)
	_on_BtnSaveFontOptions_pressed()
	_show_current_config_info()


func _on_BtnResetFont_pressed() -> void:
	
	%FontManager.reset_font()
	_on_BtnSaveFontOptions_pressed()
	_show_current_config_info()


func _on_PreviewCyrillic_toggled(button_pressed: bool) -> void:
	
	Settings.store("font_preview_cyrillic", button_pressed)
	%FontPreviewText.text = _make_preview_string()


func _on_BtnSaveFontOptions_pressed() -> void:
	
	var size_ui := int(%FontSizeUIField.value)
	var size_map := int(%FontSizeMapField.value)
	var size_om := int(%FontSizeOvermapField.value)
	
	%FontManager.set_font_sizes(size_ui, size_map, size_om)
	
	%FontManager.set_game_option("FONT_BLENDING", str(%FontBlendingSwitch.button_pressed))
	%FontManager.write_game_options()


func _on_HelpIcon_pressed() -> void:
	
	%FontSizeHelpDialog.open()
