extends VBoxContainer


# @onready var %SoundpackManager = $"/root/Catapult/Sound"
# @onready var %InstalledSoundsList = $HBox/Installed/InstalledList
# @onready var %AvailableSoundsList = $HBox/Downloadable/AvailableList
# @onready var %DeleteSoundBtn = $HBox/Installed/BtnDelete
# @onready var %InstallSoundBtn = $HBox/Downloadable/BtnInstall
# @onready var %ConfirmDeleteSoundDlg = $ConfirmDelete
# @onready var %ManualSoundDownloadDlg = $ConfirmManualDownload
# @onready var %InstallFromFileDialog = $InstallFromFileDialog
# @onready var %ShowStockSoundsSwitch = $HBox/Installed/ShowStock

var _installed_packs = []


func refresh_installed() -> void:
	
	_installed_packs = %SoundpackManager.get_installed(Settings.read("show_stock_sound"))
		
	%InstalledSoundsList.clear()
	for pack in _installed_packs:
		%InstalledSoundsList.add_item(pack["name"])
		var desc = ""
		if pack["description"] == "":
			desc = tr("str_no_sound_desc")
		else:
			desc = _break_up_string(pack["description"], 60)
		%InstalledSoundsList.set_item_tooltip(%InstalledSoundsList.get_item_count() - 1, desc)


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
	
	%AvailableSoundsList.clear()
	for pack in %SoundpackManager.SOUNDPACKS:
		%AvailableSoundsList.add_item(pack["name"])
		
		
func _is_pack_installed(pack_name: String) -> bool:
	
	for pack in _installed_packs:
		if pack["name"] == pack_name:
			return true
			
	return false


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 2:
		return
		
	%ShowStockSoundsSwitch.button_pressed = Settings.read("show_stock_sound")
	
	%DeleteSoundBtn.disabled = true
	%InstallSoundBtn.disabled = true
	%InstallSoundBtn.text = tr("btn_install_sound")
	
	_populate_available()
	refresh_installed()


func _on_ShowStock_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_stock_sound", button_pressed)
	refresh_installed()


func _on_InstalledList_item_selected(index: int) -> void:
	
	if %InstalledSoundsList.disabled:
		return  # https://github.com/godotengine/godot/issues/37277
	
	if len(_installed_packs) > 0:
		%DeleteSoundBtn.disabled = _installed_packs[index]["is_stock"]
	else:
		%DeleteSoundBtn.disabled = true


func _on_BtnDelete_pressed() -> void:
	
	var pack_name = _installed_packs[%InstalledSoundsList.get_selected_items()[0]]["name"]
	%ConfirmDeleteSoundDlg.dialog_text = tr("dlg_sound_deletion_text") % pack_name
	%ConfirmDeleteSoundDlg.get_cancel_button().text = tr("btn_cancel")
	%ConfirmDeleteSoundDlg.size = Vector2(200, 100)
	%ConfirmDeleteSoundDlg.popup_centered()


func _on_ConfirmDelete_confirmed() -> void:
	
	%SoundpackManager.delete_pack(_installed_packs[%InstalledSoundsList.get_selected_items()[0]]["name"])
	await %SoundpackManager.soundpack_deletion_finished
	refresh_installed()
	
	if len(%InstalledSoundsList.get_selected_items()) == 0:
		%DeleteSoundBtn.disabled = true


func _on_AvailableList_item_selected(index: int) -> void:
	
	if %InstalledSoundsList.disabled:
		return  # https://github.com/godotengine/godot/issues/37277
	
	%InstallSoundBtn.disabled = false
	var pack_name = %SoundpackManager.SOUNDPACKS[index]["name"]
	if _is_pack_installed(pack_name):
		%InstallSoundBtn.text = tr("btn_reinstall_sound")
	else:
		%InstallSoundBtn.text = tr("btn_install_sound")


func _on_BtnInstall_pressed() -> void:
	
	var pack_index = %AvailableSoundsList.get_selected_items()[0]
	var pack = %SoundpackManager.SOUNDPACKS[pack_index]
	
	if ("manual_download" in pack) and (pack["manual_download"] == true):
		%ManualSoundDownloadDlg.size = Vector2(300, 150)
		%ManualSoundDownloadDlg.get_cancel_button().text = tr("btn_cancel")
		%ManualSoundDownloadDlg.popup_centered()
	else:
		if _is_pack_installed(pack["name"]):
			%SoundpackManager.install_pack(pack_index, null, true)
		else:
			%SoundpackManager.install_pack(pack_index)
		await %SoundpackManager.soundpack_installation_finished
		refresh_installed()


func _on_ConfirmManualDownload_confirmed() -> void:
	
	var pack = %SoundpackManager.SOUNDPACKS[%AvailableSoundsList.get_selected_items()[0]]
	
	OS.shell_open(pack["url"])
	%InstallFromFileDialog.current_dir = Paths.own_dir
	%InstallFromFileDialog.popup_centered_ratio(0.9)
	


func _on_InstallFromFileDialog_file_selected(path: String) -> void:
	
	var index = %AvailableSoundsList.get_selected_items()[0]
	var pack_name = %SoundpackManager.SOUNDPACKS[index]["name"]
	
	if _is_pack_installed(pack_name):
		%SoundpackManager.install_pack(index, path, true, true)
	else:
		%SoundpackManager.install_pack(index, path, false, true)
	
	await %SoundpackManager.soundpack_installation_finished
	refresh_installed()
