extends VBoxContainer


@onready var _sound = $"/root/Catapult/Sound"
@onready var _installed_list = $HBox/Installed/InstalledList
@onready var _available_list = $HBox/Downloadable/AvailableList
@onready var _btn_delete = $HBox/Installed/BtnDelete
@onready var _btn_install = $HBox/Downloadable/BtnInstall
@onready var _dlg_confirm_del = $ConfirmDelete
@onready var _dlg_manual_dl = $ConfirmManualDownload
@onready var _dlg_file = $InstallFromFileDialog
@onready var _cbox_stock = $HBox/Installed/ShowStock

var _installed_packs = []


func refresh_installed() -> void:
	
	_installed_packs = _sound.get_installed(Settings.read("show_stock_sound"))
		
	_installed_list.clear()
	for pack in _installed_packs:
		_installed_list.add_item(pack["name"])
		var desc = ""
		if pack["description"] == "":
			desc = tr("str_no_sound_desc")
		else:
			desc = _break_up_string(pack["description"], 60)
		_installed_list.set_item_tooltip(_installed_list.get_item_count() - 1, desc)


func _break_up_string(text: String, approx_width_chars: int) -> String:
	
	var result = text
	
	for pos in range(approx_width_chars, len(result), approx_width_chars):
			
		while true:
			if result[pos] == " ":
				result.erase(pos, 1)
				result = result.insert(pos, "\n")
				break
			else:
				pos -= 1
	
	return result


func _populate_available() -> void:
	
	_available_list.clear()
	for pack in _sound.SOUNDPACKS:
		_available_list.add_item(pack["name"])
		
		
func _is_pack_installed(name: String) -> bool:
	
	for pack in _installed_packs:
		if pack["name"] == name:
			return true
			
	return false


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 2:
		return
		
	_cbox_stock.button_pressed = Settings.read("show_stock_sound")
	
	_btn_delete.disabled = true
	_btn_install.disabled = true
	_btn_install.text = tr("btn_install_sound")
	
	_populate_available()
	refresh_installed()


func _on_ShowStock_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_stock_sound", button_pressed)
	refresh_installed()


func _on_InstalledList_item_selected(index: int) -> void:
	
	if _installed_list.disabled:
		return  # https://github.com/godotengine/godot/issues/37277
	
	if len(_installed_packs) > 0:
		_btn_delete.disabled = _installed_packs[index]["is_stock"]
	else:
		_btn_delete.disabled = true


func _on_BtnDelete_pressed() -> void:
	
	var name = _installed_packs[_installed_list.get_selected_items()[0]]["name"]
	_dlg_confirm_del.dialog_text = tr("dlg_sound_deletion_text") % name
	_dlg_confirm_del.get_cancel_button().text = tr("btn_cancel")
	_dlg_confirm_del.size = Vector2(200, 100)
	_dlg_confirm_del.popup_centered()


func _on_ConfirmDelete_confirmed() -> void:
	
	_sound.delete_pack(_installed_packs[_installed_list.get_selected_items()[0]]["name"])
	await _sound.soundpack_deletion_finished
	refresh_installed()
	
	if len(_installed_list.get_selected_items()) == 0:
		_btn_delete.disabled = true


func _on_AvailableList_item_selected(index: int) -> void:
	
	if _installed_list.disabled:
		return  # https://github.com/godotengine/godot/issues/37277
	
	_btn_install.disabled = false
	var pack_name = _sound.SOUNDPACKS[index]["name"]
	if _is_pack_installed(pack_name):
		_btn_install.text = tr("btn_reinstall_sound")
	else:
		_btn_install.text = tr("btn_install_sound")


func _on_BtnInstall_pressed() -> void:
	
	var pack_index = _available_list.get_selected_items()[0]
	var pack = _sound.SOUNDPACKS[pack_index]
	
	if ("manual_download" in pack) and (pack["manual_download"] == true):
		_dlg_manual_dl.size = Vector2(300, 150)
		_dlg_manual_dl.get_cancel_button().text = tr("btn_cancel")
		_dlg_manual_dl.popup_centered()
	else:
		if _is_pack_installed(pack["name"]):
			_sound.install_pack(pack_index, null, true)
		else:
			_sound.install_pack(pack_index)
		await _sound.soundpack_installation_finished
		refresh_installed()


func _on_ConfirmManualDownload_confirmed() -> void:
	
	var pack = _sound.SOUNDPACKS[_available_list.get_selected_items()[0]]
	
	OS.shell_open(pack["url"])
	_dlg_file.current_dir = Paths.own_dir
	_dlg_file.popup_centered_ratio(0.9)
	


func _on_InstallFromFileDialog_file_selected(path: String) -> void:
	
	var index = _available_list.get_selected_items()[0]
	var name = _sound.SOUNDPACKS[index]["name"]
	
	if _is_pack_installed(name):
		_sound.install_pack(index, path, true, true)
	else:
		_sound.install_pack(index, path, false, true)
	
	await _sound.soundpack_installation_finished
	refresh_installed()
