extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	print("queueing!")
	$SimpleDialogBox.queue_texts(
		PoolStringArray([
			"I guess you want to enter the Dreamlands, if you're here. But they have been restless as of late."
		])
	)
