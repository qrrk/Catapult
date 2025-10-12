class_name ThemeScaler


const _SCALABLE_CONSTANTS := {
	# Theme item constants that need to be scaled (by item type).
	# Editor types are not included.
	
	"AcceptDialog": [
		"buttons_min_height",
		"buttons_min_width",
		"buttons_separation",
	],
	"BoxContainer": [
		"separation",
	],
	"Button": [
		"h_separation",
		"outline_size",
	],
	"CheckBox": [
		"check_v_offset",
		"h_separation",
		"outline_size",
	],
	"CheckButton": [
		"check_v_offset",
		"h_separation",
		"outline_size",
	],
	"FlowContainer": [
		"h_separation",
		"v_separation",
	],
	"FoldableContainer": [
		"h_separation",
		"outline_size",
	],
	"GridContainer": [
		"h_separation",
		"v_separation",
	],
	"HBoxContainer": [
		"separation",
	],
	"HFlowContainer": [
		"h_separation",
		"v_separation",
	],
	"HSlider": [
		"center_grabber",
		"grabber_offset",
	],
	"HSplitContainer": [
		"minimum_grab_thickness",
		"separation",
	],
	"ItemList": [
		"h_separation",
		"icon_margin",
		"line_separation",
		"outline_size",
		"v_separation",
	],
	"Label": [
		"line_spacing",
		"outline_size",
		"shadow_offset_x",
		"shadow_offset_y",
		"shadow_outline_size",
	],
	"LineEdit": [
		"caret_width",
		"minimum_character_width",
		"outline_size",
	],
	"LinkButton": [
		"outline_size",
	],
	"MarginContainer": [
		"margin_bottom",
		"margin_left",
		"margin_right",
		"margin_top",
	],
	"MenuBar": [
		"h_separation",
		"outline_size",
	],
	"MenuButton": [
		"outline_size",
	],
	"OptionButton": [
		"arrow_margin",
		"h_separation",
		"outline_size",
	],
	"ProgressBar": [
		"outline_size",
	],
	"RichTextLabel": [
		"outline_size",
		"shadow_offset_x",
		"shadow_offset_y",
		"shadow_outline_size",
	],
	"SpinBox": [
		"buttons_vertical_separation",
		"buttons_width",
		"field_and_buttons_separation",
	],
	"SplitContainer": [
		"minimum_grab_thickness",
		"separation",
	],
	"TabBar": [
		"h_separation",
		"outline_size",
	],
	"TabContainer": [
		"outline_size",
		"side_margin",
	],
	"TextEdit": [
		"caret_width",
		"line_spacing",
		"outline_size",
	],
	"VBoxContainer": [
		"separation",
	],
	"VFlowContainer": [
		"h_separation",
		"v_separation",
	],
	"VSlider": [
		"center_grabber",
		"grabber_offset",
	],
	"VSplitContainer": [
		"minimum_grab_thickness",
		"separation",
	],
	"Window": [
		"close_h_offset",
		"close_v_offset",
		"resize_margin",
		"title_height",
	],
}


const _SCALABLE_SBOX_PROPS := {
	# Stylebox properties subject to scaling (by stylebox type).
	
	"StyleBoxEmpty": [
		"content_margin_left",
		"content_margin_top",
		"content_margin_right",
		"content_margin_bottom",
	],
	"StyleBoxLine": [
		"content_margin_left",
		"content_margin_top",
		"content_margin_right",
		"content_margin_bottom",
		"grow_begin",
		"grow_end",
		"thickness",
	],
	"StyleBoxTexture": [
		"content_margin_left",
		"content_margin_top",
		"content_margin_right",
		"content_margin_bottom",
		"texture_margin_left",
		"texture_margin_top",
		"texture_margin_right",
		"texture_margin_bottom",
		"expand_margin_left",
		"expand_margin_top",
		"expand_margin_right",
		"expand_margin_bottom",
	],
	"StyleBoxFlat": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"expand_margin_left",
		"expand_margin_right",
		"expand_margin_top",
		"expand_margin_bottom",
		"border_width_left",
		"border_width_top",
		"border_width_right",
		"border_width_bottom",
		"corner_radius_top_left",
		"corner_radius_top_right",
		"corner_radius_bottom_right",
		"corner_radius_bottom_left",
		"shadow_size",
		"shadow_offset",
	]
}


func make_scaled_theme(proto_path: String, scale_factor: float) -> Theme:
	
	var theme: Theme = load(proto_path)
	if theme is Theme:
		var new_theme := theme.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
		_apply_scale(new_theme, scale_factor)
		return new_theme
	else:
		Status.post(tr("msg_theme_load_error") % proto_path, Enums.MSG_ERROR)
		return null


func _apply_scale(theme: Theme, factor: float) -> void:
	pass
	_scale_constants(theme, factor)
	_scale_textures(theme, factor)
	_scale_font_sizes(theme, factor)
	_scale_styleboxes(theme, factor)


func _scale_constants(theme: Theme, factor: float) -> void:

	for item_type in theme.get_constant_type_list():
		if not item_type in _SCALABLE_CONSTANTS:
			continue
		for const_name in theme.get_constant_list(item_type):
			if not const_name in _SCALABLE_CONSTANTS[item_type]:
				continue
			var new_value = theme.get_constant(const_name, item_type) * factor
			new_value = max(1, new_value)
			theme.set_constant(const_name, item_type, new_value)


func _scale_textures(theme: Theme, factor: float) -> void:

	for tex_type in theme.get_icon_type_list():
		for tex_name in theme.get_icon_list(tex_type):
			var tex := theme.get_icon(tex_name, tex_type) as DPITexture
			if tex:
				tex.base_scale = factor
#
#
func _scale_font_sizes(theme: Theme, factor: float) -> void:
	
	theme.default_font_size = max(1, theme.default_font_size * factor)
	for sz_type in theme.get_font_size_type_list():
		for sz_name in theme.get_font_size_list(sz_type):
			var new_value: int = max(1, theme.get_font_size(sz_name, sz_type) * factor)
			theme.set_font_size(sz_name, sz_type, new_value)
#
#
func _scale_styleboxes(theme: Theme, factor: float) -> void:
	
	var unique_styleboxes := []
	for sb_type in theme.get_stylebox_type_list():
		for sb_name in theme.get_stylebox_list(sb_type):
			var sbox := theme.get_stylebox(sb_name, sb_type)
			if not sbox in unique_styleboxes:
				unique_styleboxes.append(sbox)
	
	for sbox in unique_styleboxes:
		for prop in _SCALABLE_SBOX_PROPS[sbox.get_class()]:
			if not prop in sbox:
				continue
			var value = sbox.get(prop)
			var new_value
			match typeof(value):
				TYPE_RECT2:
					# Special case for region_rect
					new_value = Rect2(value.position * factor, value.size * factor)
				_:
					new_value = value * factor
			sbox.set(prop, new_value)
			
		if (sbox is StyleBoxTexture) and (sbox.texture is DPITexture):
			sbox.texture.base_scale = factor
