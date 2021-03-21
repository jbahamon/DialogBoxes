tool
extends PanelContainer

enum DialogPosition { TOP, BOTTOM }

var _positioning: int

var _margin_container: MarginContainer
var _outline_margin_container: MarginContainer
var _text_label: RichTextLabel

func _init():
	_margin_container = MarginContainer.new()
	_outline_margin_container = MarginContainer.new()
	_text_label = RichTextLabel.new()


func _ready():
	self.add_child(_margin_container)
	_margin_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_margin_container.size_flags_vertical = SIZE_EXPAND_FILL
	_margin_container.rect_clip_content = true
	
	_margin_container.add_child(_outline_margin_container)

	update_outline_margin()

	_outline_margin_container.add_child(_text_label)	

func set_dialog_margin(new_margin: float):
	margin_top = new_margin
	margin_bottom = new_margin
	margin_left = new_margin
	margin_right = new_margin
	

func get_max_outline():
	var max_outline = 0
	var normal = _text_label.get_font("normal_font")
	var bold = _text_label.get_font("bold_font")
	var italics = _text_label.get_font("italics_font")
	var bold_italics = _text_label.get_font("bold_italics_font")
	var mono  = _text_label.get_font("mono_font")
	
	if normal.has_outline() and "outline_size" in normal:
		max_outline = max(max_outline, normal.outline_size)

	if bold.has_outline() and "outline_size" in bold:
		max_outline = max(max_outline, bold.outline_size)

	if italics.has_outline() and "outline_size" in italics:
		max_outline = max(max_outline, italics.outline_size)

	if bold_italics.has_outline() and "outline_size" in bold_italics:
		max_outline = max(max_outline, bold_italics.outline_size)
		
	if mono.has_outline() and "outline_size" in mono:
		max_outline = max(max_outline, mono.outline_size)

	return max_outline
	
func set_padding(new_padding: float):
	_margin_container.set("custom_constants/margin_top", new_padding)
	_margin_container.set("custom_constants/margin_bottom", new_padding)
	_margin_container.set("custom_constants/margin_left", new_padding)
	_margin_container.set("custom_constants/margin_right", new_padding)
	
func set_positioning(new_positioning: int, height_percent: float, margin: int):
	match new_positioning:
		DialogPosition.BOTTOM:
			set_anchors_and_margins_preset(PRESET_BOTTOM_WIDE, PRESET_MODE_MINSIZE, margin)
			set_anchor_and_margin(MARGIN_TOP, 1.0 - height_percent, margin)
			grow_vertical = GROW_DIRECTION_BEGIN
			size_flags_horizontal = SIZE_EXPAND_FILL
		DialogPosition.TOP:
			set_anchors_and_margins_preset(PRESET_TOP_WIDE, PRESET_MODE_MINSIZE, margin)
			set_anchor_and_margin(MARGIN_BOTTOM, height_percent, margin)
			grow_vertical = GROW_DIRECTION_END
			size_flags_horizontal = SIZE_EXPAND_FILL
		_: return
	
	_positioning = new_positioning
	
func update_outline_margin():
	var max_outline = get_max_outline()
	print(max_outline)
	_outline_margin_container.margin_top = max_outline
	_outline_margin_container.margin_bottom = max_outline
	_outline_margin_container.margin_left = max_outline
	_outline_margin_container.margin_right = max_outline
