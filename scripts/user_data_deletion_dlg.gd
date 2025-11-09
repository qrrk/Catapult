extends Window

signal response_given(delete_confirmed: bool)


func _ready() -> void:
	
	%WarningText.meta_clicked.connect(func(meta):
		OS.shell_open(meta)
		)
	
	%MainPanel.resized.connect(func():
		self.size = %MainPanel.size
		self.move_to_center()
		)
	
	get_tree().process_frame.connect(func():
		if visible:
			self.size = %MainPanel.size
		)

func open(folders_list: Array[String]) -> void:
	
	%SafetyField.clear()
	%WarningText.clear()
	%WarningText.append_text(tr("dlg_userdata_deletion_text_pt1"))
	
	%WarningText.push_list(0, RichTextLabel.LIST_DOTS, false)
	for path in folders_list:
		%WarningText.append_text("[url]%s[/url]\n" % path)
	%WarningText.pop_all()
	
	%WarningText.newline()
	%WarningText.append_text(tr("dlg_userdata_deletion_text_pt2"))
	
	popup_centered()


func close(delete_confirmed: bool) -> void:
	hide()
	response_given.emit(delete_confirmed)


func _on_DeleteSafetyField_text_changed(new_text: String) -> void:
	
	%ConfirmButton.disabled = (new_text.to_lower() != "delete")
