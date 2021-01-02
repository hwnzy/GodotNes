# author: hwnzy
# date: 2020.5.28

class_name CONTROLLER

var nes = null
var state = Array()

enum BUTTON {A, B, SELECT, START, UP, DOWN, LEFT, RIGHT}


func _init(nes_class):
	self.nes = nes_class
	self.state.resize(8)
	for i in range(self.state.size()):
		self.state[i] = 0x40

func reset():
	pass

func button_down(key):
	self.state[key] = 0x41

func button_up(key):
	self.state[key] = 0x40
