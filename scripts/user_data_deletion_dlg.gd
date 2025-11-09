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

func open(folders_list: Array[String]) -> void:
	
	%SafetyField.clear()
	%WarningText.clear()
	%WarningText.append_text("Stop!\
	Misplaced user data was detected in the game directory.\
	This could happen if you ran the game directly from its executable\
	instead of using Catapult. This is not supported, and if you proceed,\
	all that data will be deleted irrecoverably.[br][br]\
	User data was found in the following folders:[br]")
	
	%WarningText.push_list(0, RichTextLabel.LIST_DOTS, false)
	for path in folders_list:
		%WarningText.append_text("[url]%s[/url]\n" % path)
	%WarningText.pop_all()
	%WarningText.newline()
	
	%WarningText.append_text("Review these folders and back up anything important before confirming.")
	
	popup_centered()


func close(delete_confirmed: bool) -> void:
	hide()
	response_given.emit(delete_confirmed)


func _on_DeleteSafetyField_text_changed(new_text: String) -> void:
	
	%ConfirmButton.disabled = (new_text.to_lower() != "delete")
