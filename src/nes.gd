# author: hwnzy
# date: 2020.4.12

extends Control

var cpu = null
var rom = null
var ppu = null
var papu = null
var mmap = null
var rom_data
var controllers = {}
const REG_X = 1

func _init():
	self.cpu = CPU.new(self)
	self.ppu = PPU.new(self)
	self.papu = PAPU.new(self)
	self.mmap = null  # set in load_rom()
	self.controllers = {
		1: CONTROLLER.new(self),
		2: CONTROLLER.new(self),
	}

func reset():
	# resets the system
	if self.mmap != null:
		self.mmap.reset()
	self.cpu.reset()
	self.ppu.reset()
	self.papu.reset()

func button_down(controller, button):
	self.controllers[controller].button_down(button)

func button_up(controller, button):
	self.controllers[controller].button_up(button)

func zapper_fire_down():
	if not self.mmap:
		return
	self.mmap.zapper_fired = true

func zapper_fire_up():
	if not self.mmap:
		return
	self.mmap.zapper_fired = false

func reload_rom():
	if self.rom_data != null:
		self.load_rom(self.rom_data)

# loads a rom file into the CPU and PPU.
# the ROM file is validated first
func load_rom(data):
	var file = File.new()
	file.open("res://roms//nestest.nes", File.READ)
	data = file.get_buffer(file.get_len())
	file.close()
	self.rom = ROM.new(self)
	self.rom.load(data)
	
	self.reset()
	self.mmap = self.rom.create_mapper()
	self.mmap.load_rom()
	self.ppu.set_mirroring(self.rom.get_mirroring_type())
	self.rom_data = data
	
