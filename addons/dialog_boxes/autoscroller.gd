var label: RichTextLabel
var line_lengths: PoolIntArray
var next_line_to_show: int
var lines_per_screen: int
var total_characters: int
var characters_to_discard: int
var scroll_required: bool 
var scroll: ScrollBar

func initialize(rich_text_label: RichTextLabel):
	self.label = rich_text_label
	self.scroll = self.label.get_v_scroll()

func update_scroll(percent: float):
	if not scroll_required:
		return
	
	var visible_characters = round(total_characters * percent)
	
	if next_line_to_show <= line_lengths.size() - 1:
		var new_characters = visible_characters - characters_to_discard
		if new_characters > 0:
			characters_to_discard += line_lengths[next_line_to_show]
			scroll.ratio = (next_line_to_show - lines_per_screen + 1.0)/line_lengths.size()
			print(scroll.ratio)
			next_line_to_show += 1

func reset():
	var text = label.text
	var font = label.get_font("normal")
	var width = label.rect_size.x
	var height = label.rect_size.y
	
	lines_per_screen = floor(height/font.get_string_size(text).y)
	next_line_to_show = lines_per_screen
	
	var new_line_lengths = PoolIntArray()
	
	for raw_line in text.split("\n", false):
		var words = raw_line.split(" ", false)
		var line = "" 
		for i in range(words.size()):
			var line_plus_word = line + " " + words[i]
			var line_size = font.get_string_size(line_plus_word).x
			
			if line_size > width:
				new_line_lengths.append(line.strip_edges().length())
				line = words[i]
			else:
				line = line_plus_word
		
		new_line_lengths.append(line.strip_edges().length())
			
	line_lengths = new_line_lengths
	scroll_required = line_lengths.size() > lines_per_screen
	
	characters_to_discard = 0
	for i in range(min(next_line_to_show, line_lengths.size())):
		characters_to_discard += line_lengths[i]
	
	total_characters = 0
	for length in line_lengths:
		total_characters += length
	
	
