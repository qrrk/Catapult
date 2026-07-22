extends VBoxContainer


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
	
	for id in %ModManager.installed:
		
		var mod = %ModManager.installed[id]
		var show_mod: bool
		
		var status = %ModManager.mod_status(id)
		if status in [0, 1]:
			show_mod = true
		elif status in [3, 4]:
			if show_obsolete:
				if show_stock:
					show_mod = true
				else:
					hidden_mods += 1
		elif status == 2:
			show_mod = show_stock
			if !show_mod:
				hidden_mods += 1
		
		if show_mod:
			_installed_mods_view.append({
				"id": id,
				"name": mod["modinfo"]["name"],
				"location": mod["location"]
			})
			if (show_obsolete) and (status == 3):
				_installed_mods_view[-1]["name"] += " [obsolete]"
	
	_installed_mods_view.sort_custom(_sorting_comparison)
	
	%DeleteModsBtn.disabled = true
	
	_populate_list_with_mods(_installed_mods_view, %InstalledModsList)
	
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = tr("str_installed_mods_hidden") % hidden_mods
	%InstalledModsLabel.text = tr("lbl_installed_mods") % hidden_str
	
	for i in len(_installed_mods_view):
		var id = _installed_mods_view[i]["id"]
		if %ModManager.installed[id]["is_stock"]:
			%InstalledModsList.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
			# TODO: Get color from the theme instead.


func reload_available() -> void:
	
	var include_installed = Settings.read("show_installed_mods_in_available")
	var hidden_mods = 0

	_available_mods_view.clear()
	
	for id in %ModManager.available:
		var mod = %ModManager.available[id]
		var show_mod: bool
		
		if %ModManager.mod_status(id) in [0, 3]:
			show_mod = true
		else:
			show_mod = include_installed
	
		if show_mod:
			_available_mods_view.append({
				"id": id,
				"name": mod["modinfo"]["name"],
				"location": mod["location"]
			})
		else:
			hidden_mods += 1
	
	_available_mods_view.sort_custom(_sorting_comparison)
	
	var hidden_str = ""
	if hidden_mods > 0:
		hidden_str = tr("str_mod_repo_hidden") % hidden_mods
	%ModRepoLabel.text = tr("lbl_mod_repo") % hidden_str
	%AddSelectedModsBtn.disabled = true
	
	_populate_list_with_mods(_available_mods_view, %AvailableModsList)
	
	for i in len(_available_mods_view):
		var id = _available_mods_view[i]["id"]
		if %ModManager.mod_status(id) in [1, 2, 4]:
			%AvailableModsList.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))
				
	if %AvailableModsList.get_item_count() == 0:
		%AddAllModsBtn.disabled = true
		%AddSelectedModsBtn.disabled = true
	else:
		%AddAllModsBtn.disabled = false


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
	
	%ShowStockModsSwitch.button_pressed = Settings.read("show_stock_mods")
	%ShowInstalledModsSwitch.button_pressed = Settings.read("show_installed_mods_in_available")
	%ModInfoText.text = tr("lbl_mod_info")
	%DeleteModsBtn.disabled = true
	%AddSelectedModsBtn.disabled = true
	
	reload_installed()
	reload_available()


func _on_InstalledList_multi_selected(index: int, selected: bool) -> void:
	
	var selection = Array(%InstalledModsList.get_selected_items())
	var active_idx: int
	if selected:
		active_idx = index
	elif len(selection) > 0:
		active_idx = selection.max()
	
	var active_id = _installed_mods_view[active_idx]["id"]
	%ModInfoText.text = _make_mod_info_string(%ModManager.installed[active_id])
	%ModInfoText.scroll_to_line(0)
	
	var only_stock_selected = true
	for idx in selection:
		var mod_id = _installed_mods_view[idx]["id"]
		if not %ModManager.installed[mod_id]["is_stock"]:
			only_stock_selected = false
			break
			
	if (len(selection) == 0) or (only_stock_selected):
		%DeleteModsBtn.disabled = true
	else:
		%DeleteModsBtn.disabled = false


func _on_AvailableList_multi_selected(index: int, selected: bool) -> void:
	
	var selection = Array(%AvailableModsList.get_selected_items())
	var active_idx: int
	if selected:
		active_idx = index
	elif len(selection) > 0:
		active_idx = selection.max()
	
	var active_id = _available_mods_view[active_idx]["id"]
	%ModInfoText.text = _make_mod_info_string(%ModManager.available[active_id])
	%ModInfoText.scroll_to_line(0)
	
	var only_non_installable_selected = true
	for idx in selection:
		var mod_id = _available_mods_view[idx]["id"]
		if (not mod_id in %ModManager.installed) or (%ModManager.installed[mod_id]["is_obsolete"]):
			only_non_installable_selected = false
			break
			
	if (len(selection) == 0) or (only_non_installable_selected):
		%AddSelectedModsBtn.disabled = true
	else:
		%AddSelectedModsBtn.disabled = false


func _on_BtnDownloadKenan_pressed() -> void:
	
	%ModManager.retrieve_kenan_pack()
	await %ModManager.modpack_retrieval_finished
	reload_available()


func _on_BtnDelete_pressed() -> void:
	
	var selection = %InstalledModsList.get_selected_items()
	_mods_to_delete = []
	var skipped_mods = 0
	
	for index in selection:
		var id = _installed_mods_view[index]["id"]
		if not %ModManager.installed[id]["is_stock"]:
			_mods_to_delete.append(id)
		else:
			skipped_mods += 1
	
	if skipped_mods == 1:
		Status.post(tr("msg_one_mod_is_stock"))
	elif skipped_mods > 1:
		Status.post(tr("msg_n_mods_are_stock") % skipped_mods)
	
	var num = len(_mods_to_delete)
	if num > 1:
		%DeleteMultipleModsDlg.dialog_text = tr("dlg_deleting_n_mods_text") % num
		%DeleteMultipleModsDlg.get_cancel_button().text = tr("btn_cancel")
		%DeleteMultipleModsDlg.size = Vector2(250, 100)
		%DeleteMultipleModsDlg.popup_centered()
		return
	
	%ModManager.delete_mods(_mods_to_delete)
	await %ModManager.mod_deletion_finished
	reload_installed()
	reload_available()


func _on_DeleteMultipleDialog_confirmed() -> void:
	
	%ModManager.delete_mods(_mods_to_delete)
	await %ModManager.mod_deletion_finished
	reload_installed()
	reload_available()


func _on_BtnAddSelectedMod_pressed() -> void:
	
	var selection = %AvailableModsList.get_selected_items()
	_mods_to_install = []
	var num_stock = 0

	for index in selection:
		var id = _available_mods_view[index]["id"]
		var status = %ModManager.mod_status(id)
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
		
		var status = %ModManager.mod_status(mod_id)
		if status == 4:
			_ids_to_delete.append(mod_id + "__")
			_ids_to_reinstall.append(mod_id)
		elif status == 1:
			_ids_to_delete.append(mod_id)
			_ids_to_reinstall.append(mod_id)
		elif status in [0, 3]:
			_ids_to_install.append(mod_id)
		
	if len(_ids_to_reinstall) > 0:
		%ModReinstallDialog.open(len(_ids_to_reinstall))
	else:
		_do_mod_installation()


func _on_BtnAddAllMods_pressed() -> void:
	
	for i in %AvailableModsList.get_item_count():
		%AvailableModsList.select(i, false)
		
	_on_BtnAddSelectedMod_pressed()


func _do_mod_installation() -> void:
	
	if len(_ids_to_delete) > 0:
		%ModManager.delete_mods(_ids_to_reinstall)
		await %ModManager.mod_deletion_finished
		%ModManager.install_mods(_ids_to_install + _ids_to_reinstall)
		await %ModManager.mod_installation_finished
	else:
		%ModManager.install_mods(_ids_to_install)
		await %ModManager.mod_installation_finished
	
	reload_installed()
	reload_available()


func _on_ModReinstallDialog_response_yes() -> void:
	
	_do_mod_installation()


func _on_ModReinstallDialog_response_no() -> void:
	
	_ids_to_delete.clear()
	_ids_to_reinstall.clear()
	_do_mod_installation()
