extends VBoxContainer


@onready var _root = $"/root/Catapult"
@onready var _mods = $"../../../Mods"
@onready var _installed_list = $HBox/Installed/InstalledList
@onready var _available_list = $HBox/Available/AvailableList
@onready var _cbox_show_stock = $HBox/Installed/ShowStock
@onready var _btn_delete = $HBox/Installed/BtnDelete
@onready var _btn_add = $HBox/Available/VBox/BtnAddSelectedMod
@onready var _btn_add_all = $HBox/Available/VBox/BtnAddAllMods
@onready var _btn_get_kenan = $HBox/Available/BtnDownloadKenan
@onready var _cbox_show_installed = $HBox/Available/ShowInstalled
@onready var _lbl_mod_info = $ModInfo
@onready var _lbl_installed = $HBox/Installed/Label
@onready var _lbl_repo = $HBox/Available/Label
@onready var _dlg_reinstall = $ModReinstallDialog
@onready var _dlg_del_multiple = $DeleteMultipleDialog

var _installed_mods_view := []
var _available_mods_view := []

var _mods_to_delete := []
var _mods_to_install := []
var _ids_to_delete := []
var _ids_to_install := []
var _ids_to_reinstall := []


func _populate_list_with_mods(mods_array: Array, list: ItemList) -> void:
	
	list.clear()
	for mod in mods_array:
		list.add_item(mod["name"])
		if "location" in mod:
			var tooltip = tr("tooltip_mod_location") % mod["location"]
			list.set_item_tooltip(list.get_item_count() - 1, tooltip)


func reload_installed() -> void:
	
	var hidden_mods = 0
	var show_stock = Settings.read("show_stock_mods")
	var show_obsolete = Settings.read("show_obsolete_mods")
	
	_installed_mods_view.clear()
	
	for id in _mods.installed:
		
		var mod = _mods.installed[id]
		var show: bool
		
		var status = _mods.mod_status(id)
		if status in [0, 1]:
			show = true
		elif status in [3, 4]:
			if show_obsolete:
				if show_stock:
					show = true
				else:
					hidden_mods += 1
		elif status == 2:
			show = show_stock
			if !show:
				hidden_mods += 1
		
		if show:
			_installed_mods_view.append({
				"id": id,
				"name": mod["modinfo"]["name"],
				"location": mod["location"]
			})
			if (show_obsolete) and (status == 3):
				_installed_mods_view[-1]["name"] += " [obsolete]"
	
	_installed_mods_view.sort_custom(Callable(self, "_sorting_comparison"))
	
	_btn_delete.disabled = true
	
	_populate_list_with_mods(_installed_mods_view, _installed_list)
	
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = tr("str_installed_mods_hidden") % hidden_mods
	_lbl_installed.text = tr("lbl_installed_mods") % hidden_str
	
	for i in len(_installed_mods_view):
		var id = _installed_mods_view[i]["id"]
		if _mods.installed[id]["is_stock"]:
			_installed_list.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
			# TODO: Get color from the theme instead.


func reload_available() -> void:
	
	var include_installed = Settings.read("show_installed_mods_in_available")
	var hidden_mods = 0

	_available_mods_view.clear()
	
	for id in _mods.available:
		var mod = _mods.available[id]
		var show: bool
		
		if _mods.mod_status(id) in [0, 3]:
			show = true
		else:
			show = include_installed
	
		if show:
			_available_mods_view.append({
				"id": id,
				"name": mod["modinfo"]["name"],
				"location": mod["location"]
			})
		else:
			hidden_mods += 1
	
	_available_mods_view.sort_custom(Callable(self, "_sorting_comparison"))
	
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = tr("str_mod_repo_hidden") % hidden_mods
	_lbl_repo.text = tr("lbl_mod_repo") % hidden_str
	_btn_add.disabled = true
	
	_populate_list_with_mods(_available_mods_view, _available_list)
	
	for i in len(_available_mods_view):
		var id = _available_mods_view[i]["id"]
		if _mods.mod_status(id) in [1, 2, 4]:
			_available_list.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
				
	if _available_list.get_item_count() == 0:
		_btn_add_all.disabled = true
		_btn_add.disabled = true
	else:
		_btn_add_all.disabled = false


func _sorting_comparison(a: Dictionary, b: Dictionary) -> bool:
	
	return (a["name"].nocasecmp_to(b["name"]) == -1)


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
	result += "[u]%s[/u] %s" % [tr("str_mod_name") ,modinfo["name"]]
	
	if "id" in modinfo:
		result += " ([u]ID:[/u] %s)" % modinfo["id"]
	
	result += "\n"
	
	if "authors" in modinfo:
		result += "[u]%s[/u] %s\n" % [tr("str_mod_authors"), _array_to_text_list(modinfo["authors"])]
		
	if "maintainers" in modinfo:
		result += "[u]%s[/u] %s\n" % [tr("str_mod_maintainers"), _array_to_text_list(modinfo["maintainers"])]
		
	if "category" in modinfo:
		result += "[u]%s[/u] %s\n" % [tr("str_mod_category"), modinfo["category"]]
	
	if "description" in modinfo:
		result += "[u]%s[/u] %s\n" % [tr("str_mod_description"), modinfo["description"]]
	
	result = result.rstrip("\n")
	return result


func _on_ShowStock_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_stock_mods", button_pressed)
	reload_installed()


func _on_ShowInstalled_toggled(button_pressed: bool) -> void:
	
	Settings.store("show_installed_mods_in_available", button_pressed)
	reload_available()


func _on_Tabs_tab_changed(tab: int) -> void:
	
	if tab != 1:
		return
	
	_cbox_show_stock.button_pressed = Settings.read("show_stock_mods")
	_cbox_show_installed.button_pressed = Settings.read("show_installed_mods_in_available")
	_lbl_mod_info.text = tr("lbl_mod_info")
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
	
	var active_id = _installed_mods_view[active_idx]["id"]
	_lbl_mod_info.text = _make_mod_info_string(_mods.installed[active_id])
	_lbl_mod_info.scroll_to_line(0)
	
	var only_stock_selected = true
	for idx in selection:
		var mod_id = _installed_mods_view[idx]["id"]
		if not _mods.installed[mod_id]["is_stock"]:
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
	
	var active_id = _available_mods_view[active_idx]["id"]
	_lbl_mod_info.text = _make_mod_info_string(_mods.available[active_id])
	_lbl_mod_info.scroll_to_line(0)
	
	var only_non_installable_selected = true
	for idx in selection:
		var mod_id = _available_mods_view[idx]["id"]
		if (not mod_id in _mods.installed) or (_mods.installed[mod_id]["is_obsolete"]):
			only_non_installable_selected = false
			break
			
	if (len(selection) == 0) or (only_non_installable_selected):
		_btn_add.disabled = true
	else:
		_btn_add.disabled = false


func _on_BtnDownloadKenan_pressed() -> void:
	
	_mods.retrieve_kenan_pack()
	await _mods.modpack_retrieval_finished
	reload_available()


func _on_BtnDelete_pressed() -> void:
	
	var selection = _installed_list.get_selected_items()
	_mods_to_delete = []
	var skipped_mods = 0
	
	for index in selection:
		var id = _installed_mods_view[index]["id"]
		if not _mods.installed[id]["is_stock"]:
			_mods_to_delete.append(id)
		else:
			skipped_mods += 1
	
	if skipped_mods == 1:
		Status.post(tr("msg_one_mod_is_stock"))
	elif skipped_mods > 1:
		Status.post(tr("msg_n_mods_are_stock") % skipped_mods)
	
	var num = len(_mods_to_delete)
	if num > 1:
		_dlg_del_multiple.dialog_text = tr("dlg_deleting_n_mods_text") % num
		_dlg_del_multiple.get_cancel_button().text = tr("btn_cancel")
		_dlg_del_multiple.size = Vector2(250, 100)
		_dlg_del_multiple.popup_centered()
		return
	
	_mods.delete_mods(_mods_to_delete)
	await _mods.mod_deletion_finished
	reload_installed()
	reload_available()


func _on_DeleteMultipleDialog_confirmed() -> void:
	
	_mods.delete_mods(_mods_to_delete)
	await _mods.mod_deletion_finished
	reload_installed()
	reload_available()


func _on_BtnAddSelectedMod_pressed() -> void:
	
	var selection = _available_list.get_selected_items()
	_mods_to_install = []
	var num_stock = 0

	for index in selection:
		var id = _available_mods_view[index]["id"]
		var status = _mods.mod_status(id)
		if status == 2:
				num_stock += 1
		else:
			_mods_to_install.append(id)

	if num_stock == 1:
		Status.post(tr("msg_mod_install_one_mod_skipped"))
	elif num_stock > 1:
		Status.post(tr("msg_mod_install_n_mods_skipped") % num_stock)

	_ids_to_install = []	# What to install from scratch.
	_ids_to_delete = []		# What to delete before reinstalling.
	_ids_to_reinstall = []	# What to install again after deleteion.
	for mod_id in _mods_to_install:
		
		var status = _mods.mod_status(mod_id)
		if status == 4:
			_ids_to_delete.append(mod_id + "__")
			_ids_to_reinstall.append(mod_id)
		elif status == 1:
			_ids_to_delete.append(mod_id)
			_ids_to_reinstall.append(mod_id)
		elif status in [0, 3]:
			_ids_to_install.append(mod_id)
		
	if len(_ids_to_reinstall) > 0:
		_dlg_reinstall.open(len(_ids_to_reinstall))
	else:
		_do_mod_installation()


func _on_BtnAddAllMods_pressed() -> void:
	
	for i in _available_list.get_item_count():
		_available_list.select(i, false)
		
	_on_BtnAddSelectedMod_pressed()


func _do_mod_installation() -> void:
	
	if len(_ids_to_delete) > 0:
		_mods.delete_mods(_ids_to_reinstall)
		await _mods.mod_deletion_finished
		_mods.install_mods(_ids_to_install + _ids_to_reinstall)
		await _mods.mod_installation_finished
	else:
		_mods.install_mods(_ids_to_install)
		await _mods.mod_installation_finished
	
	reload_installed()
	reload_available()


func _on_ModReinstallDialog_response_yes() -> void:
	
	_do_mod_installation()


func _on_ModReinstallDialog_response_no() -> void:
	
	_ids_to_reinstall.clear()
	_do_mod_installation()
