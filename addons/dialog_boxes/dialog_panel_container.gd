tool
extends PanelContainer

enum DialogPosition { TOP, BOTTOM }

var _positioning: int

var _margin_container: MarginContainer
var _text_label: RichTextLabel

func _init():
	_margin_container = MarginContainer.new()
	_text_label = RichTextLabel.new()
	
func _ready():
	self.add_child(_margin_container)
	_margin_container.add_child(_text_label)	
	_margin_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_margin_container.size_flags_vertical = SIZE_EXPAND_FILL

func set_dialog_margin(new_margin: float):
	margin_top = new_margin
	margin_bottom = new_margin
	margin_left = new_margin
	margin_right = new_margin
	

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
	
