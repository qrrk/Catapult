extends Theme
class_name ScalableTheme


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
var _saved_font_sizes: Dictionary
var _saved_default_font_size: int
var _saved_sbox_props: Dictionary


func _init() -> void:
	
	_save_constants()
	_save_font_sizes()
	#_saved_sbox_props = _save_stylebox_properties()


func apply_scale(factor: float) -> void:

	# pass  # FIXME
	_scale_constants(factor)
	_scale_textures(factor)
	_scale_font_sizes(factor)
	#_scale_styleboxes(factor)


func _save_constants() -> void:

	var constants := {}

	for item_type in get_constant_type_list():
		if item_type in _SCALABLE_CONSTANTS:
			constants[item_type] = {}
			for const_name in get_constant_list(item_type):
				if const_name in _SCALABLE_CONSTANTS[item_type]:
					var value = get_constant(const_name, item_type)
					if value > 0:
						constants[item_type][const_name] = value

	_saved_constants = constants


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


func _save_font_sizes() -> void:
	
	_saved_default_font_size = default_font_size
	var font_sizes := {}
	for sz_type in get_font_size_type_list():
		font_sizes[sz_type] = {}
		for sz_name in get_font_size_list(sz_type):
			var sz_value = get_font_size(sz_name, sz_type)
			font_sizes[sz_type][sz_name] = sz_value
	_saved_font_sizes = font_sizes


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

	#for texture in _saved_tex_sizes:
		#texture.set_size_override(_saved_tex_sizes[texture] * factor)
	
	for tex_type in get_icon_type_list():
		for tex_name in get_icon_list(tex_type):
			var tex := get_icon(tex_name, tex_type) as DPITexture
			if tex:
				tex.base_scale = factor


func _scale_font_sizes(factor: float) -> void:
	
	default_font_size = max(1, _saved_default_font_size * factor)
	for sz_type in _saved_font_sizes:
		for sz_name in _saved_font_sizes[sz_type]:
			var new_value: int = max(1, _saved_font_sizes[sz_type][sz_name] * factor)
			set_font_size(sz_name, sz_type, new_value)


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
