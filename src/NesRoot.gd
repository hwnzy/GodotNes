extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var test_array = [0, 0]

# Called when the node enters the scene tree for the first time.
func _ready():
	load("test.gd")
	var a = Character.new()
	a.print_health()
	a = 1 + \
	3 + \
	4
	print(a)

func test_print():
	print(test_array)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
