tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("SimpleDialogBox", "CanvasLayer", preload("simple_dialog_box.gd"), preload("icon.png"))


func _exit_tree():
	remove_custom_type("SimpleDialogBox")
