extends Window


func _on_about_to_popup() -> void:
	
	%rtlLicenses.clear()
	%rtlLicenses.scroll_to_line(0)
	
	_add_section("Catapult", FileAccess.get_file_as_string("res://LICENSE"))
	_add_section("Godot Engine", Engine.get_license_text())
	_add_section("Font: Fantasque Sans Mono", FileAccess.get_file_as_string("res://fonts/licenses/FantasqueSansMono.txt"))
	_add_section("Font: Hack", FileAccess.get_file_as_string("res://fonts/licenses/Hack.txt"))
	_add_section("Font: Inconsolata LGC", FileAccess.get_file_as_string("res://fonts/licenses/Inconsolata-LGC.txt"))
	_add_section("Font: PT Mono", FileAccess.get_file_as_string("res://fonts/licenses/PT_Mono.txt"))
	_add_section("Font: Ubuntu Mono", FileAccess.get_file_as_string("res://fonts/licenses/UbuntuMono.txt"))


func _on_lbl_licenses_meta_clicked(_meta: Variant) -> void:
	
	popup_centered_ratio(0.9)


func _add_section(heading: String, contents: String) -> void:
	
	%rtlLicenses.append_text("[br][p align=c][b]" + heading + "[/b][/p][br][br]")
	%rtlLicenses.append_text("[p align=l]" + contents + "[/p][br][hr][br]")
