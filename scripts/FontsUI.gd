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
@onready var _tabs := $".."
@onready var _fonts := $"/root/Catapult/Fonts"
@onready var _list := $FontSelection/RightPane/FontsList
@onready var _btn_set_ui := $FontSelection/RightPane/Buttons/BtnSetFontUI
@onready var _btn_set_map := $FontSelection/RightPane/Buttons/BtnSetFontMap
@onready var _btn_set_om := $FontSelection/RightPane/Buttons/BtnSetFontOvermap
@onready var _btn_set_all := $FontSelection/RightPane/Buttons/BtnSetFontAll
@onready var _preview := $FontSelection/LeftPane/Preview
@onready var _cbox_cyrillic = $FontSelection/LeftPane/PreviewCyrillic
@onready var _info := $FontConfigInfo
@onready var _sb_font_ui := $FontSelection/LeftPane/FontSizeUI/sbFontSizeUI
@onready var _sb_font_map := $FontSelection/LeftPane/FontSizeMap/sbFontSizeMap
@onready var _sb_font_om := $FontSelection/LeftPane/FontSizeOvermap/sbFontSizeOM
@onready var _cbtn_blending := $FontSelection/LeftPane/FontBlending
@onready var _help_dlg := $FontSizeHelpDialog


func _make_preview_string(cyrillic: bool = false) -> String:
	
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
	
	var config: Dictionary = _fonts.font_config
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
	
	_info.text = text


func _load_font_options() -> void:
	
	_fonts.load_game_options()
	
	_sb_font_ui.value = _fonts.get_game_option("FONT_SIZE") as int
	_sb_font_map.value = _fonts.get_game_option("MAP_FONT_SIZE") as int
	_sb_font_om.value = _fonts.get_game_option("OVERMAP_FONT_SIZE") as int
	_cbtn_blending.button_pressed = (_fonts.get_game_option("FONT_BLENDING").to_lower() == "true")


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 3:
		return
	
	if not _fonts.font_config_file_exists():
		Status.post(tr("msg_no_font_config_file"), Enums.MSG_WARN)
		_tabs.current_tab = 0
		return
	
	if not _fonts.options_file_exists():
		Status.post(tr("msg_no_game_options_file"), Enums.MSG_WARN)
		_tabs.current_tab = 0
		return
		
	_fonts.load_available_fonts()
	_fonts.load_font_config()
	
	for btn in [_btn_set_ui, _btn_set_map, _btn_set_om, _btn_set_all]:
		btn.disabled = true
	
	_list.clear()
	for font in _fonts.available_fonts:
		_list.add_item(font["name"])
		_list.set_item_tooltip(_list.get_item_count() - 1, tr(font["desc_key"]))
	
	_cbox_cyrillic.button_pressed = Settings.read("font_preview_cyrillic")
	_load_font_options()
	
	_preview.text = ""
	_show_current_config_info()


func _on_FontsList_item_selected(index: int) -> void:
	
	var font_info = _fonts.available_fonts[index]
	var font_path := "res://fonts/ingame".path_join(font_info["file"])
	var font_res = FontFile.new()
	
	font_res.font_data = load(font_path)
	font_res.size = 15.0 * Geom.scale
	font_res.use_filter = true
	
	_preview.add_theme_font_override("normal_font", font_res)
	_preview.text = _make_preview_string(Settings.read("font_preview_cyrillic"))
	
	for btn in [_btn_set_ui, _btn_set_map, _btn_set_om, _btn_set_all]:
		btn.disabled = false


func _on_BtnSetFontX_pressed(ui: bool, map: bool, overmap: bool) -> void:
	
	var index = _list.get_selected_items()[0]
	var name = _fonts.available_fonts[index]["name"]
	
	if ui:
		Status.post(tr("msg_setting_ui_font") % name)
	if map:
		Status.post(tr("msg_setting_map_font") % name)
	if overmap:
		Status.post(tr("msg_setting_omap_font") % name)
	
	_fonts.set_font(index, ui, map, overmap)
	_on_BtnSaveFontOptions_pressed()
	_show_current_config_info()


func _on_BtnResetFont_pressed() -> void:
	
	_fonts.reset_font()
	_on_BtnSaveFontOptions_pressed()
	_show_current_config_info()


func _on_PreviewCyrillic_toggled(button_pressed: bool) -> void:
	
	Settings.store("font_preview_cyrillic", button_pressed)
	_preview.text = _make_preview_string(Settings.read("font_preview_cyrillic"))


func _on_BtnSaveFontOptions_pressed() -> void:
	
	var size_ui := int(_sb_font_ui.value)
	var size_map := int(_sb_font_map.value)
	var size_om := int(_sb_font_om.value)
	
	_fonts.set_font_sizes(size_ui, size_map, size_om)
	
	_fonts.set_game_option("FONT_BLENDING", str(_cbtn_blending.pressed))
	_fonts.write_game_options()


func _on_HelpIcon_pressed() -> void:
	
	_help_dlg.open()
