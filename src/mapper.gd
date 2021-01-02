# author: hwnzy
# date: 2020.4.19

class_name MAPPER

var nes = null
var utils = null
var mapper = {}

func _init(nes_class):
	self.nes = nes_class
	self.load_rom()
	self.utils = UTILS.new()

class mapper0:
	var nes
	var joy1StrobeState
	var joy2StrobeState
	var joypadLastWrite
	var zapperFired
	var zapperX
	var zapperY
	
	func _init(nes_class):
		self.nes = nes_class
		
	func copy_array_elements(src, src_pos, dest, dest_pos, length):
		for i in range(length):
			dest[dest_pos+i] =  src[src_pos+i]
		
	func reset():
		self.joy1StrobeState = 0
		self.joy2StrobeState = 0
		self.joypadLastWrite = 0
		
		self.zapperFired = false
		self.zapperX = null
		self.zapperY = null
	
	func write(address, value):
		address &= 0xffff
		if address < 0x2000:
			self.nes.cpu.mem[address & 0x7ff] = value
		elif address > 0x4017:
			self.nes.cpu.mem[address] = value
			if address >= 0x6000 && address < 0x8000:
				pass  # wirte to persistent RAM
		elif (address > 0x2007 && address < 0x4000):
			self.reg_write(0x2000 + (address & 0x7), value)
		else:
			self.reg_write(address, value)

	func writelow(address, value):
		address &= 0xffff
		if address < 0x2000:  # Mirroring of RAM
			self.nes.cpu.mem[address & 0x7ff] = value
		elif address > 0x4017:
			self.nes.cpu.mem[address] = value
		elif (address > 0x2007 && address < 0x4000):
			self.reg_write(0x2000 + (address & 0x7), value)
		else:
			self.reg_write(address, value)

	func reg_write(address, value):
		match address:
			0x2000: # PPU Control register 1
				self.nes.cpu.mem[address] = value
				self.nes.ppu.update_control_reg1(value)
			0x2001: # PPU Control register 2
				self.nes.cpu.mem[address] = value
				self.nes.ppu.update_control_reg2(value)
			0x2003: # Set Sprite RAM address
				self.nes.ppu.write_sram_address(value)
			0x2004: # write to sprite RAM
				self.nes.ppu.sram_write(value)
			0x2005: # Screen Scroll offsets
				self.nes.ppu.scroll_write(value)
			0x2006: # Set VRAM address
				self.nes.ppu.write_vram_address(value)
			0x2007: # write to VRAM
				self.nes.cpu.vram_write(value)
			0x4014: # Sprite Memory DMA Access
				self.nes.ppu.sram_dma(value)
			0x4015: # Sound Channel Switch, DMC Status
				self.nes.papu.write_reg(address, value)
			0x4016: # Joystick 1 + Strobe
				if ((value & 1) == 0 && (self.joypadLastWrite & 1) == 1):
					self.joy1StrobeState = 0
					self.joy2StrobeState = 0
				self.joypadLastWrite = value
				
			0x4017: # Sound channel frame sequencer
				self.nes.ppu.write_reg(address, value)
			
			var reg_address:  # Sound registers
				if (address >= 0x4000 && address <= 0x4017):
					self.nes.papu.write_reg(address, value)

	func read(address):
		# wrap around
		address &= 0xffff
		# check address range
		if address > 0x4017:
			# ROM
			return self.nes.cpu.mem[address]
		elif address >= 0x2000:
			return self.reg_load(address)  # I/O Ports
		else:
			return self.nes.cpu.mem[address & 0x7ff]  # RAM(mirrored)
	
	func reg_read(address):
		match (address >> 12):  # use fourth nibbe (0xF000)
			0:
				pass
			1:
				pass
			2, 3:  # PPU Registers
				match (address & 0x7):
					0x0:  # 0x2000 PPU Control Register 1.(the value is stored both in
						  # main memory and in the PPU as flags): (not in the real NES)
						return self.nes.cpu.mem[0x2000]
					0x1:  # 0x2001 PPU Control Register 2.(the value is stored both in
						  # main memory and in the PPU as flags): (not in the real NES)
						return self.nes.cpu.mem[0x2001]
					0x2:  # 0x2001 PPU status Register.(the value is stored both in
						  # main memory and in the PPU as flags): (not in the real NES)
						return self.nes.ppu.read_status_register()
					0x3:
						return 0
					0x4:  # 0x2004: Sprite Memory read.
						return self.nes.ppu.sram_load()
					0x5:
						return 0
					0x6:
						return 0
					0x7:  # 0x2007 VRAM read
						return self.nes.ppu.vram_load()
			4:  # sound+joypad registers
				match (address - 0x4015):
					0: # 0x4015  joystick 1 + strobe
						return self.nes.papu.read_reg(address)
					1: # 0x4016 joystick 1 + strobe
						return self.joy1_read()
					2: # 0x4017 joystick 2 + strobe
						var w
						if (
							self.zapperX != null &&
							self.zapperY != null &&
							self.nes.ppu.is_pixel_white(self.zapperX, self.zapperY)
						):
							w = 0
						else:
							w = 0x1 << 3
						if self.zapperFired:
							w |= 0x1 << 4
						return (self.joy2Read() | w) & 0xffff
		return 0
	
	func joy1Read():
		var ret
		match (self.joy1StrobeState):
			0, 1, 2, 3, 4, 5, 6, 7:
				ret = self.nes.controllers[1].state[self.joy1StrobeState]
			8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18:
				ret = 0
			19:
				ret = 1
			_:
				ret = 0
		self.joy1StrobeState += 1
		if self.joy1StrobeState == 24:
			self.joy1StrobeState = 0
		return ret

	func joy2Read():
		var ret
		match self.joy2StrobeState:
			0, 1, 2, 3, 4, 5, 6, 7:
				ret = self.nes.controllers[2].state[self.joy2StrobeState]
			8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18:
				ret = 0
			19:
				ret = 1
			_:
				ret = 0
			
		self.joy2StrobeState += 1
		if self.joy2StrobeState == 24:
			self.joy2StrobeState = 0
		return ret
		
	func load_rom():
		# load rom into memory
		self.load_prg_rom()
		# load chr-rom
		self.load_chr_rom()
		# load battery ram(if present)
		self.load_battery_ram()
		# reset IRQ
		self.nes.cpu.request_irq(self.nes.cpu.IRQ.RESET)
	
	func load_prg_rom():
		if self.nes.rom.rom_count > 1:
			# load the two first banks into memory
			self.load_rom_bank(0, 0x8000)
			self.load_rom_bank(0, 0xc000)
		else:
			# load the one bank into both memory locations
			self.load_rom_bank(0, 0x8000)
			self.load_rom_bank(0, 0xc000)
	
	func load_chr_rom():
		if self.nes.rom.vrom_count > 0:
			if self.nes.rom.vrom_count == 1:
				self.load_vrom_bank(0, 0x0000)
				self.load_vrom_bank(0, 0x1000)
			else:
				self.load_vrom_bank(0, 0x0000)
				self.load_vrom_bank(1, 0x1000)
		else:
			pass
		
	func load_battery_ram():
		if slf.nes.rom.battery_ram:
			var ram = self.nes.rom.battery_ram
			if ram != null && ram.length == 0x2000:
				# load battery ram into memory
				self.copy_array_elements(ram, 0, self.nes.cpu.mem, 0x6000, 0x2000)
	
	func load_rom_bank(bank, address):
		# loads a rom bank into the specified address
		bank %= self.nes.rom.rom_count
		self.copy_array_elements(self.nes.rom.rom[bank], 0, self.nes.cpu.mem, address, 16384)
	
	func load_vrom_bank(bank, address):
		if self.nes.rom.vrom_count == 0:
			return
		self.nes.ppu.trigger_rendering()
		bank %= self.nes.rom.vrom_count
		self.copy_array_elements(self.nes.rom.vrom[bank], 0, self.nes.cpu.varm_mem, address, 4096)
		
		var vrom_tile = self.nes.rom.vrom_tile[bank]
		self.copy_array_elements(vrom_tile, 0, self.nes.ppu.pt_tile, address >> 4, 256)
	
	func load_8k_rom_bank(bank8k, address):
		var bank_16k = floor(bank8k / 2) % self.nes.rom.rom_count
		var offset = (bank8k % 2) * 8192
		
		self.copy_array_elements(self.nes.rom.rom[bank_16k], offset, self.nes.cpu.mem, address, 8192)
	
	func load_32k_rom_bank(bank, address):
		self.load_rom_bank((bank * 2) % self.nes.rom.rom_count, address)
		self.load_rom_bank((bank * 2 + 1) % self.nes.rom.rom_count, address + 16384)
	
	func load_1k_vrom_bank(bank1k, address):
		if self.nes.rom.vrom_count == 0:
			return
		self.nes.ppu.trigger_rendering()
		
		var bank_4k = floor(bank1k / 4) % self.nes.rom.vrom_count
		var bank_offset = (bank1k % 4) * 1024
		self.copy_array_elements(self.nes.rom.vrom[bank_4k], bank_offset, self.nes.ppu.vram_mem, address, 1024)
		
		# update tiles
		var vrom_tile = self.nes.rom.vrom_tile[bank_4k]
		var base_index = address >> 4
		for i in range(64):
			self.nes.ppu.pt_tile[base_index + i] = vrom_tile[((bank1k % 4) << 6) + i]
	
	func load_2k_vrom_bank(bank2k, address):
		if self.nes.rom.vrom_count == 0:
			return
		self.nes.ppu.trigger_rendering()
		
		var bank_4k = floor(bank2k / 2) % self.nes.rom.vrom_count
		var bank_offset = (bank2k % 2) * 2048
		self.copy_array_elements(self.nes.rom.vrom[bank_4k], bank_offset, self.nes.ppu.vram_mem, address, 2048)
		# update tiles
		var vrom_tile = self.nes.rom.vrom_tile(bank_4k)
		var base_index = address >> 4
		for i in range(128):
			self.nes.ppu.pt_tile[base_index + i] = vrom_tile[((bank2k % 2) << 7) + i]
	
	func load_8k_vrom_bank(bank4k_start, address):
		if self.nes.rom.vrom_count == 0:
			return
		self.nes.ppu.trigger_rendering()
		self.load_vrom_bank(bank4k_start % self.nes.rom.vrom_count, address)
		self.load_vrom_bank((bank4k_start + 1) % self.nes.rom.vrom_count, address + 4096)
