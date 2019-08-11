extends Control

export(DynamicFont) var font

onready var _bg = get_node("Bg")

var _row_width = 16
var _row_index = 0
var _wrapped_buffer = null
var _hex_to_string = []
var _char_width = 0
var _offset_gutter_width = 0
var _hex_gutter_width = 0
var _ascii_gutter_width = 0
var _gutter_separation = 0
var _hovered_row = -1
var _hovered_col = -1


func _ready():
	var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
	for i in 256:
		_hex_to_string.append(str(hex[(i >> 4) & 0xf], hex[i & 0xf]))
	# Monospace font assumed
	_char_width = int(font.get_string_size("A").x)
	_offset_gutter_width = _char_width * 8
	_hex_gutter_width =  _char_width * (3 * _row_width - 1)
	_ascii_gutter_width = _char_width * _row_width
	_gutter_separation = _char_width * 2


func set_wrapped_buffer(b):
	_wrapped_buffer = b
	update()


func set_row_index(i):
	#print("Set row index ", i)
	assert(typeof(i) == TYPE_INT)
	if i != _row_index:
		_row_index = i
		update()


func get_row_index():
	return _row_index


func get_visible_row_count():
	var line_height = int(font.get_height())
	return int(rect_size.y) / line_height# + 1


func _gui_input(event):
	if event is InputEventMouseMotion:
		var mpos = event.position
		var pos = _get_row_col_from_mouse_pos(mpos)
		if pos == null:
			_set_hovered_row_col(-1, -1)
		else:
			_set_hovered_row_col(int(pos.y), int(pos.x))


func _set_hovered_row_col(row, col):
	if row != _hovered_row or col != _hovered_col:
		#print("Hover ", row, ", ", col)
		_hovered_row = row
		_hovered_col = col
		_bg.update()


func _get_row_col_from_mouse_pos(mpos):
	var hex_gutter_begin = _offset_gutter_width + _gutter_separation
	var hex_gutter_end = hex_gutter_begin + _hex_gutter_width
	
	var ascii_gutter_begin = hex_gutter_end + _gutter_separation
	var ascii_gutter_end = ascii_gutter_begin + _ascii_gutter_width
	
	if mpos.x >= hex_gutter_begin and mpos.x < hex_gutter_end:
		mpos.x -= hex_gutter_begin
		var pos = mpos / Vector2(3 * _char_width, font.get_height())
		#if pos.x - floor(pos.x) < 0.666:
		return pos.floor()
	
	elif mpos.x >= ascii_gutter_begin and mpos.x < ascii_gutter_end:
		mpos.x -= ascii_gutter_begin
		var pos = mpos / Vector2(_char_width, font.get_height())
		return pos.floor()
	
	return null


func _draw():
	if _wrapped_buffer == null:
		return
	var buffer = _wrapped_buffer.buffer
	
	var begin_offset = _row_index * _row_width
	if begin_offset > len(buffer):
		return
	
	var line_height = int(font.get_height())
	var displayed_row_count = get_visible_row_count()
	var pos = Vector2(0, 0)

	var hex_text_width = 500
	
	var offset_color = Color(1, 1, 1, 0.5)
	var text_color = Color(1, 1, 1, 0.9)
	
	for i in displayed_row_count:
		var row_begin_offset = begin_offset + i * _row_width
		if row_begin_offset >= len(buffer):
			break
		
		var row_end_offset = row_begin_offset + _row_width
		if row_end_offset > len(buffer):
			row_end_offset = len(buffer)
		
		#draw_rect(Rect2(pos, Vector2(500, line_height)), bg_color)
		pos += Vector2(0, font.get_ascent())
		
		draw_string(font, pos, _offset_to_string(row_begin_offset), offset_color)
		pos.x += _offset_gutter_width + _gutter_separation
		
		var hex_string = ""
		for j in range(row_begin_offset, row_end_offset):
			hex_string += str(_hex_to_string[buffer[j]], " ")
		draw_string(font, pos, hex_string, text_color)
		pos.x += _hex_gutter_width + _gutter_separation
		
		var sub = buffer.subarray(row_begin_offset, row_end_offset - 1)
		for j in len(sub):
			var c = sub[j]
			if c < 32 or c >= 127:
				sub[j] = 46
		var ascii_string = sub.get_string_from_ascii()
		draw_string(font, pos, ascii_string, text_color)
		
		pos.x = 0
		pos.y -= font.get_ascent()
		pos.y += line_height


func _offset_to_string(offset):
	return str( \
		_hex_to_string[(offset >> 24) & 0xff], \
		_hex_to_string[(offset >> 16) & 0xff], \
		_hex_to_string[(offset >> 8) & 0xff], \
		_hex_to_string[offset & 0xff])


func _on_Bg_draw():
	if _hovered_col == -1 or _hovered_row == -1:
		return
	var ci = _bg

	var hex_gutter_begin = _offset_gutter_width + _gutter_separation
	var ascii_gutter_begin = hex_gutter_begin + _hex_gutter_width + _gutter_separation
	
	var hcsize = Vector2(3.0 * _char_width, font.get_height())
	var hpos = Vector2(_hovered_col, _hovered_row) * hcsize

	var acsize = Vector2(_char_width, font.get_height())
	var apos = Vector2(_hovered_col, _hovered_row) * acsize
	
	var col = Color(1,1,1,0.1)
	ci.draw_rect(Rect2(hex_gutter_begin + hpos.x, 0, hcsize.x, rect_size.y), col)
	ci.draw_rect(Rect2(hex_gutter_begin, hpos.y, _hex_gutter_width, hcsize.y), col)

	ci.draw_rect(Rect2(ascii_gutter_begin + apos.x, 0, acsize.x, rect_size.y), col)
	ci.draw_rect(Rect2(ascii_gutter_begin, apos.y, _ascii_gutter_width, acsize.y), col)

