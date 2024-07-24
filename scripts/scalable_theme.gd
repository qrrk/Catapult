extends Theme
class_name ScalableTheme


const _SCALABLE_CONSTANTS := {
	# Theme item constants that need to be scaled (by item type).
	# Editor types are not included.
	
	"BoxContainer": [
		"separation"
	],
	"Button": [
		"h_separation"
	],
	"CheckBox": [
		"check_v_offset",
		"h_separation",
	],
	"CheckButton": [
		"check_v_offset",
		"h_separation",
	],
	"ColorPicker": [
		"h_width",
		"label_width",
		"margin",
		"sv_height",
		"sv_width",
	],
	"ColorPickerButton": [
		"h_separation",
	],
	"GridContainer": [
		"h_separation",
		"v_separation",
	],
	"HBoxContainer": [
		"separation",
	],
	"HSeparator": [
		"separation",
	],
	"HSplitContainer": [
		"separation",
	],
	"ItemList": [
		"h_separation",
		"icon_margin",
		"line_separation",
		"v_separation",
	],
	"Label": [
		"line_spacing",
		"shadow_offset_x",
		"shadow_offset_y",
	],
	"LinkButton": [
		"underline_spacing",
	],
	"MarginContainer": [
		"offset_bottom",
		"offset_left",
		"offset_right",
		"offset_top",
	],
	"MenuButton": [
		"h_separation",
	],
	"OptionButton": [
		"arrow_margin",
		"h_separation",
	],
	"PopupMenu": [
		"h_separation",
		"v_separation",
	],
	"RichTextLabel": [
		"line_separation",
		"shadow_offset_x",
		"shadow_offset_y",
		"table_h_separation",
		"table_v_separation",
	],
	"TabContainer": [
		"h_separation",
		"label_valign_bg",
		"label_valign_fg",
		"side_margin",
		"top_margin",
	],
	"TabBar": [
		"h_separation",
		"label_valign_bg",
		"label_valign_fg",
		"top_margin",
	],
	"TextEdit": [
		"line_spacing",
	],
	"TooltipLabel": [
		"shadow_offset_x",
		"shadow_offset_y",
	],
	"Tree": [
		"button_margin",
		"h_separation",
		"item_margin",
		"scroll_border",
		"scroll_speed",
		"v_separation",
	],
	"VBoxContainer": [
		"separation",
	],
	"VSeparator": [
		"separation",
	],
	"VSplitContainer": [
		"separation",
	],
	"Window": [
		"close_h_offset",
		"close_v_offset",
		"scaleborder_size",
		"title_height",
	],
}

const _SCALABLE_FONT_PROPS := [
	# Font properties subject to scaling (for DynamicFont).
	
	"size",
	"outline_size",
	"spacing_top",
	"spacing_bottom",
	"extra_spacing_char",
	"extra_spacing_space",
]

const _SCALABLE_SBOX_PROPS := {
	# Stylebox properties subject to scaling (by stylebox type).
	
	"StyleBoxEmpty": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
	],
	"StyleBoxLine": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"grow_begin",
		"grow_end",
		"thickness",
	],
	"StyleBoxTexture": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"expand_margin_left",
		"expand_margin_right",
		"expand_margin_top",
		"expand_margin_bottom",
		"offset_left",
		"offset_right",
		"offset_top",
		"offset_bottom",
		"region_rect",
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
		"corner_detail",
		"shadow_size",
		"shadow_offset",
	]
}

var _saved_constants: Dictionary
var _saved_tex_sizes: Dictionary
var _saved_font_props: Dictionary
var _saved_sbox_props: Dictionary


func _init() -> void:
	
	_saved_constants = _save_constants()
	_saved_tex_sizes = _save_texture_sizes()
	_saved_font_props = _save_font_properties()
	_saved_sbox_props = _save_stylebox_properties()


func apply_scale(factor: float) -> void:

	_scale_constants(factor)
	_scale_textures(factor)
	_scale_fonts(factor)
	_scale_styleboxes(factor)


func _save_constants() -> Dictionary:

	var constants := {}

	for item_type in get_constant_type_list():
		if item_type in _SCALABLE_CONSTANTS:
			constants[item_type] = {}
			for const_name in get_constant_list(item_type):
				if const_name in _SCALABLE_CONSTANTS[item_type]:
					var value = get_constant(const_name, item_type)
					if value > 0:
						constants[item_type][const_name] = value

	return constants


func _save_texture_sizes() -> Dictionary:

	var tex_sizes := {}

	for item_type in get_icon_type_list():
		for icon_name in get_icon_list(item_type):
			var icon := get_icon(icon_name, item_type)
			if (icon is ImageTexture) and (not icon in tex_sizes) and (icon.get_size() != Vector2.ZERO):
				tex_sizes[icon] = icon.get_size()

	for item_type in get_stylebox_type_list():
		for sbox_name in get_stylebox_list(item_type):
			var sbox = get_stylebox(sbox_name, item_type)
			if sbox is StyleBoxTexture:
				var texture = sbox.texture
				if (texture is ImageTexture) and (not texture in tex_sizes) and (texture.get_size() != Vector2.ZERO):
					tex_sizes[texture] = texture.get_size()

	return tex_sizes


func _save_font_properties() -> Dictionary:

	var font_props := {
		default_font: {}
	}

	for item_type in get_font_type_list():
		for font_name in get_font_list(item_type):
			var font := get_font(font_name, item_type)
			if (font is FontFile) and (not font in font_props):
				font_props[font] = {}

	for font in font_props:
		if not font:
			continue
		for prop in _SCALABLE_FONT_PROPS:
			var value = font.get(prop)
			if value == null:
				push_error("Font %s does not have the property %s." % [font, prop])
				continue
			if value > 0:
				font_props[font][prop] = value

	return font_props


func _save_stylebox_properties() -> Dictionary:

	var sbox_props := {}

	for item_type in get_stylebox_type_list():
		for sbox_name in get_stylebox_list(item_type):
			var sbox = get_stylebox(sbox_name, item_type)

			if not sbox in sbox_props:
				sbox_props[sbox] = {}

			var sbox_type = sbox.get_class()
			for prop in _SCALABLE_SBOX_PROPS[sbox_type]:

				if not prop in sbox:
					continue
				var value = sbox.get(prop)
				var discard := false

				match typeof(value):
					TYPE_VECTOR2:
						# Special case for shadow_offset
						if value == Vector2.ZERO:
							discard = true
					TYPE_RECT2:
						# Special case for region_rect
						if not value.has_area():
							discard = true
					_:
						if value <= 0:
							discard = true

				if not discard:
					sbox_props[sbox][prop] = value


	return sbox_props


func _scale_constants(factor: float) -> void:

	for item_type in _saved_constants:
		for const_name in _saved_constants[item_type]:
			var new_value = _saved_constants[item_type][const_name] * factor
			new_value = max(1, new_value)
			set_constant(const_name, item_type, new_value)


func _scale_textures(factor: float) -> void:

	for texture in _saved_tex_sizes:
		texture.set_size_override(_saved_tex_sizes[texture] * factor)


func _scale_fonts(factor: float) -> void:

	for font in _saved_font_props:
		for prop in _saved_font_props[font]:
			var new_value = _saved_font_props[font][prop] * factor
			new_value = max(1, new_value)
			font.set(prop, new_value)


func _scale_styleboxes(factor: float) -> void:

	for sbox in _saved_sbox_props:
		for prop in _saved_sbox_props[sbox]:
			var value = _saved_sbox_props[sbox][prop]
			var new_value
			match typeof(value):
				TYPE_RECT2:
					# Special case for region_rect
					new_value = Rect2(value.position * factor, value.size * factor)
				TYPE_VECTOR2:
					# Special case for shadow_offset
					new_value = value * factor
				_:
					new_value = value * factor
					new_value = max(1, new_value)
			sbox.set(prop, new_value)
