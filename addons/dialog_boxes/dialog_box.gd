tool
extends CanvasLayer
var DialogPanelContainer = preload("./dialog_panel_container.gd")
var AutoScroller = preload("./autoscroller.gd")

signal on_state(new_state)
signal dialog_closed

enum DialogPosition { TOP, BOTTOM }
enum DialogState { HIDDEN, TRANSITION_IN, ADVANCING, WAITING_FOR_INPUT, TRANSITION_OUT }
enum TransitionMode { NONE, UNROLL, FADE }

const ANIMATION_DISPLAY_TEXT = "display_text"

export var block_input: bool = true
export(TransitionMode) var transition = TransitionMode.NONE
export var transition_time_ms: float = 20.0
export var text_speed: float = 9.0
export var speedup_factor: float = 2.0
export var height_percent: float = 0.2 
export(DialogPosition) var positioning = DialogPosition.BOTTOM setget set_positioning
export var margin: int = 0 setget set_margin
export var padding: int = 0 setget set_padding

export var meta_underlined: bool = true setget set_meta_underlined
export var tab_size: int = 4 setget set_tab_size
export var show_scroll: bool = false setget set_show_scroll
export var custom_effects: Array = [] setget set_custom_effects

export var bbcode_enabled: bool = false setget set_bbcode_enabled

export var theme: Theme setget set_theme
export var panel_stylebox: StyleBox setget set_panel_stylebox

export var normal_font: Font setget set_normal_font
export var mono_font: Font setget set_mono_font
export var bold_font: Font setget set_bold_font
export var italics_font: Font setget set_italics_font
export var bold_italics_font: Font setget set_bold_font

export var advance_indicator_texture: Texture

var _dialog_panel_container
var _text_label: RichTextLabel 
var _text_tween: Tween
var _transition_tween: Tween
var _scroller
var _advance_indicator: TextureRect	
var current_state = DialogState.HIDDEN
var text_queue: PoolStringArray = PoolStringArray()

func _init():
	_dialog_panel_container = DialogPanelContainer.new()
	_dialog_panel_container.name ="dialog_panel"
	_dialog_panel_container.theme = theme
	_dialog_panel_container.add_stylebox_override("panel", panel_stylebox)
	_dialog_panel_container.visible = false
	
	_text_label = _dialog_panel_container._text_label
	_text_label.name ="label"
	
	_text_tween = Tween.new()
	add_child(_text_tween)
	_scroller = AutoScroller.new()
	_scroller.initialize(_text_label)
	
	_transition_tween = Tween.new()
	add_child(_transition_tween)

	_advance_indicator = TextureRect.new()
	_advance_indicator.visible = false

func _ready():	
	add_child(_dialog_panel_container)
	add_child(_advance_indicator)
	
	set_process_unhandled_input(false)
		
	# We set the texture before positioning because we need to measure it.
	_advance_indicator.texture = advance_indicator_texture
	set_positioning(DialogPosition.BOTTOM)
	
	_text_tween.connect("tween_all_completed", self, "on_text_shown")
	_transition_tween.connect("tween_all_completed", self, "on_transition_finished")
	init_rich_text_label()	
	
	_dialog_panel_container.update_outline_margin()
	
		

func _unhandled_input(event):
	match current_state:
		DialogState.ADVANCING:
			if event.is_action_pressed("ui_accept"):
				_text_tween.playback_speed = speedup_factor
			elif event.is_action_released("ui_accept"):
				_text_tween.playback_speed = 1.0
		DialogState.WAITING_FOR_INPUT:
			if event.is_action_pressed("ui_accept"):
				if text_queue.empty():
					change_state(DialogState.TRANSITION_OUT)
				else:
					change_state(DialogState.ADVANCING)
				
	if block_input:
		get_tree().set_input_as_handled()


func on_text_shown():
	if current_state == DialogState.ADVANCING:
		change_state(DialogState.WAITING_FOR_INPUT)

func on_transition_finished():
	if current_state == DialogState.TRANSITION_IN:
		change_state(DialogState.ADVANCING)
	elif current_state == DialogState.TRANSITION_OUT:
		change_state(DialogState.HIDDEN)

func change_state(new_state: int):
	if new_state == current_state:
		return
		
	match new_state:
		DialogState.HIDDEN:
			set_process_unhandled_input(false)
			_dialog_panel_container.visible = false
			emit_signal("dialog_closed")
		DialogState.TRANSITION_IN:
			transition_in()
		DialogState.ADVANCING:
			if _advance_indicator != null:
				_advance_indicator.visible = false
			_text_tween.reset(_scroller)
			_text_tween.reset(_text_label)
			_text_tween.playback_speed = 1.0
			set_process_unhandled_input(true)
			
			if text_queue.empty():
				# We let the state last for at least a single frame.
				change_state(DialogState.TRANSITION_OUT)
			else:
				# We have to wait until the label is inflated.
				if _text_label.rect_size == Vector2.ZERO:
					yield(_text_label, "resized")
				dequeue_text()
		DialogState.WAITING_FOR_INPUT:
			if _advance_indicator.texture != null:
				update_advance_indicator_positioning()
				_advance_indicator.visible = true
				
			set_process_unhandled_input(true)
		DialogState.TRANSITION_OUT:
			if _advance_indicator != null:
				_advance_indicator.visible = false
			transition_out()
			
	current_state = new_state
	emit_signal("on_state", new_state)

func transition_in():
	match transition:
		TransitionMode.NONE:
			yield(get_tree(), "idle_frame")
			change_state(DialogState.ADVANCING)
		TransitionMode.FADE:
			_transition_tween.interpolate_property(
				_dialog_panel_container, "modulate",
				Color(1, 1, 1, 0), Color(1, 1, 1, 1), transition_time_ms/1000.0,
				Tween.TRANS_LINEAR, Tween.EASE_IN
			)
			_transition_tween.start()
		TransitionMode.UNROLL:
			_dialog_panel_container.rect_pivot_offset = _dialog_panel_container.rect_size/2.0
			_transition_tween.interpolate_property(
				_dialog_panel_container, "rect_scale",
				Vector2(1, 0), Vector2(1, 1), transition_time_ms/1000.0,
				Tween.TRANS_LINEAR, Tween.EASE_IN
			)
			_transition_tween.start()
	
	yield(get_tree(), "idle_frame")
	_dialog_panel_container.visible = true
	
func transition_out():
	_text_label.bbcode_text = ""
	_text_label.text = ""
	match transition:
		TransitionMode.NONE:
			yield(get_tree(), "idle_frame")
			change_state(DialogState.HIDDEN)
		TransitionMode.FADE:
			_transition_tween.interpolate_property(
				_dialog_panel_container, "modulate",
				Color(1, 1, 1, 1), Color(1, 1, 1, 0), transition_time_ms/1000.0,
				Tween.TRANS_LINEAR, Tween.EASE_IN
			)
		TransitionMode.UNROLL:
			_dialog_panel_container.rect_pivot_offset = _dialog_panel_container.rect_size/2.0
			_transition_tween.interpolate_property(
				_dialog_panel_container, "rect_scale",
				Vector2(1, 1), Vector2(1, 0), transition_time_ms/1000.0,
				Tween.TRANS_LINEAR, Tween.EASE_IN
			)
			_transition_tween.start()
	

func queue_texts(texts: PoolStringArray):
	text_queue.append_array(texts)
	match current_state:
		DialogState.HIDDEN:
			change_state(DialogState.TRANSITION_IN)
			
func dequeue_text():
	if text_queue.empty():
		return

	_text_label.visible_characters = 0
	_text_label.scroll_to_line(0)
	
	if bbcode_enabled:
		_text_label.bbcode_text = text_queue[0]
	else:
		_text_label.text = text_queue[0]
		
	text_queue.remove(0)
	
	var length = _text_label.text.length()
	var time = length/text_speed

	_text_tween.interpolate_property(_text_label, "percent_visible",
		0.0, 1.0, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)

	_scroller.reset()

	_text_tween.interpolate_method(
		_scroller, "update_scroll", 0.0, 1.0, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	_text_tween.start()


func set_margin(new_value: int):
	margin = new_value
	if _dialog_panel_container != null:
		_dialog_panel_container.set_dialog_margin(new_value)

func set_padding(new_value: int):
	padding = new_value
	if _dialog_panel_container != null:
		_dialog_panel_container.set_padding(new_value)

func update_advance_indicator_positioning():
	if _advance_indicator.texture == null:
		return
		
	_advance_indicator.rect_position = _dialog_panel_container.rect_position + _dialog_panel_container.rect_size + \
			Vector2(_dialog_panel_container.margin_right - _advance_indicator.texture.get_width(),
					_dialog_panel_container.margin_bottom - _advance_indicator.texture.get_height())
	
		
# Setters for the RichTextLabel

func init_rich_text_label():
	_text_label.rect_clip_content = false
	_text_label.theme = theme
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.meta_underlined = meta_underlined
	_text_label.tab_size = tab_size
	_text_label.custom_effects = custom_effects
	_text_label.scroll_following = false
	_text_label.scroll_active = show_scroll
	_text_label.bbcode_enabled = bbcode_enabled
	
	
func set_meta_underlined(new_value: bool):
	meta_underlined = new_value
	if _text_label != null:
		_text_label.meta_underlined = new_value


func set_tab_size(new_value: int):
	tab_size = new_value
	if _text_label != null:
		_text_label.tab_size = new_value


func set_show_scroll(new_value: bool):
	show_scroll = new_value
	if _text_label != null:
		_text_label.scroll_active = new_value


func set_custom_effects(new_value: Array):
	custom_effects = new_value
	if _text_label != null:
		_text_label.custom_effects = new_value


func set_bbcode_enabled(new_value: bool):
	bbcode_enabled = new_value
	if _text_label != null:
		_text_label.bbcode_enabled = new_value


func set_positioning(new_positioning: int):
	if _dialog_panel_container != null:
		_dialog_panel_container.set_positioning(new_positioning, height_percent, margin)
		update_advance_indicator_positioning()
	positioning = new_positioning


func set_normal_font(new_value: Font):
	normal_font = new_value
	if _text_label != null:
		_text_label.add_font_override("normal", new_value)

	if _dialog_panel_container != null:
		_dialog_panel_container.update_outline_margin()

func set_bold_font(new_value: Font):
	bold_font = new_value
	if _text_label != null:
		_text_label.add_font_override("bold", new_value)
	if _dialog_panel_container != null:
			_dialog_panel_container.update_outline_margin()

func set_italics_font(new_value: Font):
	italics_font = new_value
	if _text_label != null:
		_text_label.add_font_override("italics", new_value)
	if _dialog_panel_container != null:
			_dialog_panel_container.update_outline_margin()

func set_bold_italics_font(new_value: Font):
	bold_italics_font = new_value
	if _text_label != null:
		_text_label.add_font_override("bold_italics", new_value)
	if _dialog_panel_container != null:
			_dialog_panel_container.update_outline_margin()

func set_mono_font(new_value: Font):
	mono_font = new_value
	if _text_label != null:
		_text_label.add_font_override("mono", new_value)
	if _dialog_panel_container != null:
			_dialog_panel_container.update_outline_margin()

func set_panel_stylebox(new_value: StyleBox):
	panel_stylebox = new_value
	if _dialog_panel_container != null:
		_dialog_panel_container.add_stylebox_override("panel", new_value)
	
func set_theme(new_value: Theme):
	theme = new_value
	if _text_label != null:
		_text_label.theme = new_value

	if _dialog_panel_container != null:
		_dialog_panel_container.theme = new_value
		_dialog_panel_container.update_outline_margin()
