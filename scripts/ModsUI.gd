extends VBoxContainer


signal status_message


onready var _mods = $"../../../Mods"
onready var _settings = $"/root/SettingsManager"
onready var _installed_list = $HBox/Installed/InstalledList
onready var _available_list = $HBox/Available/AvailableList
onready var _cbox_show_stock = $HBox/Installed/ShowStock
onready var _btn_delete = $HBox/Installed/BtnDelete
onready var _btn_add = $HBox/Available/VBox/BtnAddSelectedMod
onready var _btn_add_all = $HBox/Available/VBox/BtnAddAllMods
onready var _btn_get_kenan = $HBox/Available/BtnDownloadKenan
onready var _cbox_show_installed = $HBox/Available/ShowInstalled
onready var _lbl_mod_info = $ModInfo
onready var _lbl_installed = $HBox/Installed/Label
onready var _lbl_repo = $HBox/Available/Label
onready var _dlg_reinstall = $ModReinstallDialog
onready var _dlg_del_multiple = $DeleteMultipleDialog

var _gamedir = ""
var _installed_mods_view = []
var _available_mods_view = []

var _mods_to_delete = []
var _mods_to_install = []
var _ids_to_install = []
var _ids_to_reinstall = []


func _populate_list_with_mods(mods_array: Array, list: ItemList) -> void:
	
	list.clear()
	for mod in mods_array:
		list.add_item(mod["modinfo"]["name"])
		if "location" in mod:
			var tooltip = "Location: " + mod["location"]
			list.set_item_tooltip(list.get_item_count() - 1, tooltip)


func reload_installed() -> void:
	
	var hidden_mods = 0
	var show_stock = _settings.read("show_stock_mods")
	
	if show_stock:
		_installed_mods_view = _mods.installed
	else:
		_installed_mods_view.clear()
		for mod in _mods.installed:
			if not mod["is_stock"]:
				_installed_mods_view.append(mod)
			else:
				hidden_mods += 1
	
	_btn_delete.disabled = true
	
	_populate_list_with_mods(_installed_mods_view, _installed_list)
	
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = " (%s hidden)" % hidden_mods
	_lbl_installed.text = "Installed%s:" % hidden_str
	
	if show_stock:
		for i in len(_installed_mods_view):
			if _installed_mods_view[i]["is_stock"]:
				_installed_list.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
				# TODO: Get color from the theme instead.


func reload_available() -> void:
	
	var include_installed = _settings.read("show_installed_mods_in_available")
	var hidden_mods = 0
	
	if include_installed:
		_available_mods_view = _mods.available
	else:
		_available_mods_view.clear()
		for mod in _mods.available:
			if not _is_mod_installed(mod["modinfo"]):
				_available_mods_view.append(mod)
			else:
				hidden_mods += 1
		
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = " (%s hidden)" % hidden_mods
	_lbl_repo.text = "Local repository%s:" % hidden_str
	_btn_add.disabled = true
	
	_populate_list_with_mods(_available_mods_view, _available_list)
	
	if include_installed:
		for i in len(_available_mods_view):
			if _is_mod_installed(_available_mods_view[i]["modinfo"]):
				_available_list.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
				
	if _available_list.get_item_count() == 0:
		_btn_add_all.disabled = true
		_btn_add.disabled = true
	else:
		_btn_add_all.disabled = false


func _is_mod_installed(modinfo: Dictionary) -> int:
	# Returns 0 if the mod is not installed, 1 if installed,
	# and 2 if it is a stock mod.
	
	for mod in _mods.installed:
		if mod["modinfo"]["id"] == modinfo["id"]:
			if mod["is_stock"]:
				return 2
			else:
				return 1
			
	return 0


func _array_to_text_list(array) -> String:
	
	if typeof(array) == TYPE_STRING:  # Damn you Fuji :)
		return array
	
	var result = ""
	
	if len(array) > 0:
		
		for value in array:
			result += value + ", "
		
		result = result.substr(0, len(result) - 2)
	
	return result


func _make_mod_info_string(mod: Dictionary) -> String:
	
	var result = ""
	var modinfo = mod["modinfo"]
	result += "[u]Name:[/u] %s" % modinfo["name"]
	
	if "id" in modinfo:
		result += " ([u]ID:[/u] %s)" % modinfo["id"]
	
	result += "\n"
	
	if "authors" in modinfo:
		result += "[u]Authors:[/u] %s\n" % _array_to_text_list(modinfo["authors"])
		
	if "maintainers" in modinfo:
		result += "[u]Maintainers:[/u] %s\n" % _array_to_text_list(modinfo["maintainers"])
		
	if "category" in modinfo:
		result += "[u]Category:[/u] %s\n" % modinfo["category"]
	
	if "description" in modinfo:
		result += "[u]Description:[/u] %s\n" % modinfo["description"]
	
	result = result.rstrip("\n")
	return result


func _on_ShowStock_toggled(button_pressed: bool) -> void:
	
	_settings.store("show_stock_mods", button_pressed)
	reload_installed()


func _on_ShowInstalled_toggled(button_pressed: bool) -> void:
	
	_settings.store("show_installed_mods_in_available", button_pressed)
	reload_available()


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 1:
		return
	
	_cbox_show_stock.pressed = _settings.read("show_stock_mods")
	_cbox_show_installed.pressed = _settings.read("show_installed_mods_in_available")
	_lbl_mod_info.bbcode_text = "Select a mod in either list to see its details here."
	_btn_delete.disabled = true
	_btn_add.disabled = true
	
	reload_installed()
	reload_available()


func _on_InstalledList_multi_selected(index: int, selected: bool) -> void:
	
	var selection = Array(_installed_list.get_selected_items())
	var active_idx: int
	if selected:
		active_idx = index
	elif len(selection) > 0:
		active_idx = selection.max()
	
	_lbl_mod_info.bbcode_text = _make_mod_info_string(_installed_mods_view[active_idx])
	_lbl_mod_info.scroll_to_line(0)
	
	var only_stock_selected = true
	for idx in selection:
		if not _installed_mods_view[idx]["is_stock"]:
			only_stock_selected = false
			break
			
	if (len(selection) == 0) or (only_stock_selected):
		_btn_delete.disabled = true
	else:
		_btn_delete.disabled = false


func _on_AvailableList_multi_selected(index: int, selected: bool) -> void:
	
	var selection = Array(_available_list.get_selected_items())
	var active_idx: int
	if selected:
		active_idx = index
	elif len(selection) > 0:
		active_idx = selection.max()
	
	var only_stock_selected = true
	for idx in selection:
		if not _is_mod_installed(_available_mods_view[idx]["modinfo"]) == 2:
			only_stock_selected = false
			break
			
	if (len(selection) == 0) or (only_stock_selected):
		_btn_add.disabled = true
	else:
		_btn_add.disabled = false
	
	_lbl_mod_info.bbcode_text = _make_mod_info_string(_available_mods_view[active_idx])
	_lbl_mod_info.scroll_to_line(0)


func _on_BtnDownloadKenan_pressed() -> void:
	
	_mods.retrieve_kenan_pack()
	yield(_mods, "modpack_retrieval_finished")
	reload_available()


func _on_BtnDelete_pressed() -> void:
	
	var selection = _installed_list.get_selected_items()
	_mods_to_delete = []
	var skipped_mods = 0
	
	for index in selection:
		if not _installed_mods_view[index]["is_stock"]:
			_mods_to_delete.append(_installed_mods_view[index]["modinfo"]["id"])
		else:
			skipped_mods += 1
	
	if skipped_mods == 1:
		emit_signal("status_message", "One of the selected mods is stock and cannot be deleted.")
	elif skipped_mods > 1:
		emit_signal("status_message", "%s of the selected mods are stock and cannot be deleted." % skipped_mods)
	
	var num = len(_mods_to_delete)
	if num > 1:
		_dlg_del_multiple.dialog_text = "Deleting %s mods." % num
		_dlg_del_multiple.rect_min_size = get_tree().root.size * Vector2(0.4, 0.1)
		_dlg_del_multiple.set_as_minsize()
		_dlg_del_multiple.popup_centered()
		return
	
	_mods.delete_mods(_mods_to_delete)
	yield(_mods, "mod_deletion_finished")
	reload_installed()
	reload_available()


func _on_DeleteMultipleDialog_confirmed() -> void:
	
	_mods.delete_mods(_mods_to_delete)
	yield(_mods, "mod_deletion_finished")
	reload_installed()
	reload_available()


func _on_BtnAddSelectedMod_pressed() -> void:
	
	var selection = _available_list.get_selected_items()
	_mods_to_install = []
	var num_stock = 0
	
	for index in selection:
		var mod = _available_mods_view[index]
		var status = _is_mod_installed(mod["modinfo"])
		if status == 2:
				num_stock += 1
		_mods_to_install.append({"id": mod["modinfo"]["id"], "installed_status": status})
	
	if num_stock == 1:
		emit_signal("status_message", "One mod already comes with the game, so it will not be installed.")
	elif num_stock > 1:
		emit_signal("status_message", "%s mods already come with the game, so they will not be installed." % num_stock)
	
	_ids_to_install = []
	_ids_to_reinstall = []
	for item in _mods_to_install:
		match item["installed_status"]:
			0:
				_ids_to_install.append(item["id"])
			1:
				_ids_to_reinstall.append(item["id"])
	
	if len(_ids_to_reinstall) > 0:
		_dlg_reinstall.open(len(_ids_to_reinstall))
	else:
		_do_mod_installation()


func _on_BtnAddAllMods_pressed() -> void:
	
	for i in _available_list.get_item_count():
		_available_list.select(i, false)
		
	_on_BtnAddSelectedMod_pressed()


func _do_mod_installation() -> void:
	
	if len(_ids_to_reinstall) > 0:
		_mods.delete_mods(_ids_to_reinstall)
		yield(_mods, "mod_deletion_finished")
		_mods.install_mods(_ids_to_install + _ids_to_reinstall)
		yield(_mods, "mod_installation_finished")
	else:
		_mods.install_mods(_ids_to_install)
		yield(_mods, "mod_installation_finished")
	
	reload_installed()
	reload_available()


func _on_ModReinstallDialog_response_yes() -> void:
	
	_do_mod_installation()


func _on_ModReinstallDialog_response_no() -> void:
	
	_ids_to_reinstall.clear()
	_do_mod_installation()
