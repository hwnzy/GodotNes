# author: hwnzy
# date: 2020.4.7
class_name CPU

var nes = null
var mem = null
var opdata = null
var cycles_to_halt = null
var crash = null
var irq_requested = false
var irq_type = null

var REG = {
	'ACC': null, 'X': null, 'Y': null, 'SP': null,
	'PC': null, 'PC_NEW': null, 'STATUS': null
}
var F = {
	'CARRY': null, 'DECIMAL': null, 'INTERRUPT': null, 
	'INTERRYPT_NEW': null, 'OVERFLOW': null, 'SIGN': null,
	'ZERO': null, 'NOTUSED': null, 'NOTUSED_NEW': null,
	'BRK': null, 'BRK_NEW': null, 
}
enum IRQ {NORMAL, NMI, RESET}

func _init(nes_class):
	self.nes = nes_class
	self.reset()
#	print(self.mem.size())
#	self.mappers = MAPPER.new(self.mem)
#	print(self.mappers.read(0xffff))

func reset():
	# main memory
	self.mem = Array()
	self.mem.resize(0x10000)
	for i in range(0x2000):
		self.mem[i] = 0xff
	for i in range(4):
		var j = i * 0x800
		self.mem[j+0x08] = 0xf7
		self.mem[j+0x09] = 0xef
		self.mem[j+0x0a] = 0xdf
		self.mem[j+0x0f] = 0xbf
	for i in range(0x2001, self.mem.size()):
		self.mem[i] = 0
	# cpu registers
	self.REG['ACC'] = 0
	self.REG['X'] = 0
	self.REG['Y'] = 0
	# reset stack pointer
	self.REG['SP'] = 0x01ff
	self.REG['PC'] = 0x8000 - 1
	self.REG['PC_NEW'] = 0x8000 - 1
	# reset status register
	self.REG['STATUS'] = 0x28
	self.set_status(self.REG['STATUS'])
	# set flags
	self.F['CARRY'] = 0
	self.F['DECIMAL'] = 0
	self.F['INTERRUPT'] = 1
	self.F['INTERRUPT_NEW'] = 1
	self.F['OVERFLOW'] = 0
	self.F['SIGN'] = 0
	self.F['ZERO'] = 1
	
	self.F['NOTUSED'] = 0
	self.F['NOTUSED_NEW'] = 0
	self.F['BRK'] = 0
	self.F['BRK_NEW'] = 0
	
	self.opdata = OPDATA.new()
	self.cycles_to_halt = 0
	# reset crash flag
	self.crash = false
	# interrupt notification
	self.irq_requested = false
	self.irq_type = null
	
# Emulates a single CPU instruction, returns the number of cycles
func emulate():
	var temp
	var add
	# check interrupts
	if self.irq_requested:
		temp = (
			self.F['CARRY'] | 
			((1 if self.F['ZERO'] == 0 else 0) << 1) |
			(self.F['INTERRUPT'] << 2) |
			(self.F['DECIMAL'] << 3) |
			(self.F['BRK'] << 4) |
			(self.F['NOTUSED'] << 5) |
			(self.F['OVERFLOW'] << 6) |
			(self.F['SIGN'] << 7)
		)
		self.REG['PC_NEW'] = self.REG['PC']
		self.F['INTERRUPT_NEW'] = self.F['INTERRUPT']
		match self.irq_type:
			0: 
				# normal irq:
				if self.F['INTERRUPT'] == 0:
					self.do_irq(temp)
			1:
				# NMI
				self.do_nonmaskable_interrupt(temp)
			2:
				# reset
				self.do_reset_interrupt()
		self.REG['PC'] = self.REG['PC_NEW']
		self.F['INTERRUPT'] = self.F['INTERRUPT_NEW']
		self.F['BRK'] = self.F['BRK_NEW']
		self.irq_requested = false
	
	var opinf = self.opdata[self.nes.mmap.read(self.REG['PC'] + 1)]
	var cycle_count = opinf >> 24
	var cycle_add = 0
	# find address mode
	var addr_mode = (opinf >> 8) & 0xff
	# increment pc by number of op bytes
	var opaddr = self.REG['PC']
	self.REG['PC'] += (opinf >> 16) & 0xff
	
	var addr = 0
	match addr_mode:
		0:  # zero page mode, use the address given after the opcode, but without high byte.
			addr = self.read(opaddr + 2)
		1:  # relative mode
			addr = self.read(opaddr + 2)
			if addr < 0x80:
				addr += self.REG['PC']
			else:
				addr += self.REG['PC'] - 256
		2:  # ignore. address is implied in instruction
			pass
		3:  # adsolute mode. use the two bytes following the opcode as an address
			addr = self.read16bit(opaddr + 2)
		4:  # accumulator mode. the address is in the accumulator register
			addr = self.REG['ACC']
		5:  # immediate mode. the value is given after the opcode
			addr = self.REG['PC']
		6:  #  zero page indexed mode, x as index. use the address given after the opcode, 
			#  then add the x register to it to get the final address
			addr = (self.read(opaddr + 2) + self.REG['X']) & 0xff
		7:  #  zero page indexed mode, y as index. use the address given after the opcode,
			#  then add the y register to it to get the final address.
			addr = (self.read(opaddr + 2) + self.REG['Y']) & 0xff
		8: # absolute indexed mode, x as index. same as zero page indexed, but with the high byte.
			addr = self.read16bit(opaddr + 2)
			if ((addr & 0xff00) != ((addr + self.REG['X']) & 0xff00)):
				cycle_add = 1
			addr += self.REG['X']
		9: # absolute indexed mode, y as index. same as zero page indexed, but with the high byte.
			addr = self.read16bit(opaddr + 2)
			if ((addr & 0xff00) != ((addr + self.REG['Y']) & 0xff00)):
				cycle_add = 1
			addr += self.REG['Y']
		10: # pre-indexed indirect mode. find the 16-bit address starting at the 
			# given location plus the  current X register. The value is the contents of the adress
			addr = self.read(opaddr + 2)
			if ((addr & 0xff00) != ((addr+self.REG['X'])&0xff00)):
				cycle_add = 1
			addr += self.REG['X']
			addr &= 0xff
			addr = self.read16bit(addr)
		11: # pos-indexed indirect mode. find the 16-bit address contained in the given
			# location (and the one following). Add to that address the content of the
			# Y register. Fetch the value stored at that address.
			addr = self.read16bit(self.read(opaddr+2))
			if ((addr & 0xff00) != ((addr + self.REG['Y'])&0xff00)):
				cycle_add = 1
			addr += self.REG['Y']
		12:
			# indirect absolute mode. find the 16-bit address contained  at the given location.
			addr = self.read16bit(opaddr + 2) # find op
			if addr < 0x1fff:
				# read from address given in op
				addr = self.mem[addr] + (self.mem[(addr & 0xff00) | (((addr & 0xff) + 1) & 0xff)] << 8)
			else:
				addr = self.nes.mmap.read(addr) + (self.nes.mmap.read((addr & 0xff00) | (((addr & 0xff) + 1) & 0xff)) << 8)
		
	# wrap around for addreses above 0XFFFF
	addr &= 0xffff
	
	# Decode & execute instruction
	
	# this should be compiled to a jump table.
	match (opinf & 0xff):
		0: # ADC add with carry
			temp = self.REG['ACC'] + self.read(addr) + self.F['CARRY']
			if ((self.REG['ACC'] ^ self.read(addr)) & 0x80) == 0 && ((self.REG['ACC'] ^ temp) & 0x80) != 0:
				self.F['OVERFLOW'] = 1
			else:
				self.F['OVERFLOW'] = 0
			self.F['CARRY'] = 1 if temp > 255 else 0
			self.F['SIGN']= (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			self.REG['ACC'] = temp & 255
			cycle_count += cycle_add
		1: # AND and memory with accumulator
			self.REG['ACC'] = self.REG['ACC'] & self.read(addr)
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 11
		2: # ASL shift left one bit
			if addr_mode == 4:
				self.F['CARRY'] = (self.REG['ACC'] >> 7) & 1
				self.REG['ACC'] = (self.REG['ACC'] << 1) & 255
				self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
				self.F['ZERO'] = self.REG['ACC']
			else:
				temp = self.read(addr)
				self.F['CARRY'] = (temp >> 7) & 1
				temp = (temp << 1) & 255
				self.F['SIGN'] = (temp >> 7) & 1
				self.F['ZERO'] = temp
				self.write(addr, temp)
		3: # BCC Branch on carry clear
			if self.F['CARRY'] == 0:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		4: # BCS Branch on carry set
			if self.F['CARRY'] == 1:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		5: # BEQ Branch on zero
			if self.F['ZERO'] == 0:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		6: # BIT 
			temp = self.read(addr)
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['OVERFLOW'] = (temp >> 6) & 1
			temp &= self.REG['ACC']
			self.F['ZERO'] = temp
		7: # BMI branch on negative result
			if self.F['SIGN'] == 1:
				cycle_count += 1
				self.REG['PC'] = addr
		8: # BNE branch on not zero
			if self.F['ZERO'] != 0:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				REG['PC'] = addr
		9: # BPL branch on positive result
			if self.F['SIGN'] == 0:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		10: # BRK
			self.REG['PC'] += 2
			self.push((self.REG['PC'] >> 8) & 255)
			self.push(self.REG['PC'] & 255)
			self.F['BRK'] = 1
			self.push(self.F['CARRY'] | 
						((1 if self.F['ZERO'] == 0 else 0) << 1) |
						(self.F['INTERRUPT'] << 2) |
						(self.F['DECIMAL'] << 3) |
						(self.F['BRK'] << 4) |
						(self.F['NOTUSED'] << 5) |
						(self.F['OVERFLOW'] << 6) |
						(self.F['SIGN'] << 7)
					)
			self.F['INTERRUPT'] = 1
			self.REG['PC'] = self.read16bit(0xfffe)
			self.REG['PC'] -= 1
		11: # BVC branch on overflow clear
			if self.F['OVERFLOW'] == 0:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		12: # BVS branch on overflow set
			if self.F['OVERFLOW'] == 1:
				cycle_count += 2 if (opaddr & 0xff00) != (addr & 0xff00) else 1
				self.REG['PC'] = addr
		13: # CLC clear carry flag
			self.F['CARRY'] = 0
		14: # CLD clear decimal flag
			self.F['DECIMAL'] = 0
		15: # CLI Clear interrupt flag
			self.F['INTERRUPT'] = 0
		16: # CLV Clear overflow flag
			self.F['OVERFLOW'] = 0
		17: # CMP Compare memory and accumulator
			temp = self.REG['ACC'] - self.read(addr)
			self.F['CARRY'] = 1 if temp >= 0 else 0
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			cycle_count += cycle_add
		18: # CPX Compare memory and index X
			temp = self.REG['X'] - self.read(addr)
			self.F['CARRY'] = 1 if temp >= 0 else 0
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
		19: # CPY Compare memory and index Y
			temp = self.REG['Y'] - self.read(addr)
			self.F['CARRY'] = 1 if temp >= 0 else 0
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
		20: # DEC decrement memory by one
			temp = (self.read(addr) - 1) & 0xff
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp
			self.write(addr, temp)
		21: # DEX Decrement index x by one
			self.REG['X'] = (self.REG['X'] - 1) & 0xff
			self.F['SIGN'] = (self.REG['X'] >> 7) & 1
			self.F['ZERO'] = self.REG['X']
		22: # DEY Decrement index y by one
			self.REG['Y'] = (self.REG['Y'] - 1) & 0xff
			self.F['SIGN'] = (self.REG['Y'] >> 7) & 1
			self.F['ZERO'] = self.REG['Y']
		23: # EOR XOR memory with accumulator, store in accumulator
			self.REG['ACC'] = (self.read(addr) ^ self.REG['ACC']) & 0xff
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			cycle_count += cycle_add
		24: # INC Increment memory by one
			temp = (self.read(addr) + 1) & 0xff
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp
			self.write(addr, temp & 0xff)
		25: # INX Increment index X by one
			self.REG['X'] = (self.REG['X'] + 1) & 0xff
			self.F['SIGN'] = (self.REG['X'] >> 7) & 1
			self.F['ZERO'] = self.REG['X']
		26: # INY Increment index Y by one
			self.REG['Y'] += 1
			self.REG['Y'] &= 0xff
			self.F['SIGN'] = (self.REG['Y'] >> 7) & 1
			self.F['ZERO'] = self.REG['Y']
		27: # JMP Jump to new location
			self.REG['PC'] = addr - 1
		28: # JSR Jump to new location, saving return address. Push return address on stack
			self.push((self.REG['PC'] >> 8) & 255)
			self.push(self.REG['PC'] & 255)
			self.REG['PC'] = addr - 1
		29: # LDA Load accumulator with memory
			self.REG['ACC'] = self.read(addr)
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			cycle_count += cycle_add
		30: # LDX Load index X with memroy
			self.REG['X'] = self.read(addr)
			self.F['SIGN'] = (self.REG['X'] >> 7) & 1
			self.F['ZERO'] = self.REG['X']
			cycle_count += cycle_add
		31: # LDY Load index Y with memory
			self.REG['Y'] = self.read(addr)
			self.F['SIGN'] = (self.REG['Y'] >> 7) & 1
			self.F['ZERO'] = self.REG['Y']
			cycle_count += cycle_add
		32: # LSR Shift right one bit
			if addr_mode == 4:  # ADDR_ACC
				temp = self.REG['ACC'] & 0xff
				self.F['CARRY'] = temp & 1
				temp = temp >> 1
				self.REG['ACC'] = temp
			else:
				temp = self.read(addr) & 0xff
				self.F['CARRY'] = temp & 1
				temp = temp >> 1
				self.write(addr, temp)
			self.F['SIGN'] = 0
			self.F['ZERO'] = temp
		33: # NOP No OPeration Ignore
			pass
		34: # ORA OR memory with accumulator, store in accumulator
			temp = (self.read(addr) | self.REG['ACC']) & 255
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp
			self.REG['ACC'] = temp
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 11
		35: # PHA Push accumulator on stack
			self.push(self.REG['ACC'])
		36: # PHP Push processor status on stack
			self.F['BRK'] = 1
			self.push(
				self.F['CARRY'] |
				((1 if self.F['ZERO'] == 0 else 0) << 1) |
				(self.F['INTERRUPT'] << 2) |
				(self.F['DECIMAL'] << 3) |
				(self.F['BRK'] << 4) |
				(self.F['NOTUSED'] << 5) |
				(self.F['OVERFLOW'] << 6) |
				(self.F['SIGN'] << 7)
			)
		37: # PLA Pull accumulator from stack
			self.REG['ACC'] = self.pull()
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
		38: # PLP Pull processor status from stack
			temp = self.pull()
			self.F['CARRY'] = temp & 1
			self.F['ZERO'] = 0 if ((temp >> 1) & 1) == 1 else 1
			self.F['INTERRUPT'] = (temp >> 2) & 1
			self.F['DECIMAL'] = (temp >> 3) & 1
			self.F['BRK'] = (temp >> 4) & 1
			self.F['NOTUSED'] = (temp >> 5) & 1
			self.F['OVERFLOW'] = (temp >> 6) & 1
			self.F['SIGN'] = (temp >> 7) & 1
			
			self.F['NOTUSED'] = 1
		39: # ROL Rotate one bit left
			if addr_mode == 4:
				temp = self.REG['ACC']
				add = self.F['CARRY']
				self.F['CARRY'] = (temp >> 7) & 1
				temp = ((temp << 1) & 0xff) + add
				self.REG['ACC'] = temp
			else:
				temp = self.read(addr)
				add = self.F['CARRY']
				self.F['CARRY'] = (temp >> 7) & 1
				temp = ((temp << 1) & 0xff) + add
				self.write(addr, temp)
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp
		40: # ROR Rotate one bit right
			if addr_mode == 4:
				add = self.F['CARRY'] << 7
				self.F['CARRY'] = self.REG['ACC'] & 1
				temp = (self.REG['ACC'] >> 1) + add
				self.REG['ACC'] = temp
			else:
				temp = self.read(addr)
				add = self.F['CARRY'] << 7
				self.F['CARRY'] = temp & 1
				temp = (temp >> 1) + add
				self.write(addr, temp)
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp
		41: # RTI Return from interrupt. Pull status and PC from stack
			temp = self.pull()
			self.F['CARRY'] = temp & 1
			self.F['ZERO'] = 1 if ((temp >> 1) & 1) == 1 else 0
			self.F['INTERRUPT'] = (temp >> 2) & 1
			self.F['DECIMAL'] = (temp >> 3) & 1
			self.F['BRK'] = (temp >> 4) & 1
			self.F['NOTUSED'] = (temp >> 5) & 1
			self.F['OVERFLOW'] = (temp >> 6) & 1
			self.F['SIGN'] = (temp >> 7) & 1
			
			self.REG['PC'] = self.pull()
			self.REG['PC'] += self.pull() << 8
			if self.REG['PC'] == 0xffff:
				return
			self.REG['PC'] -= 1
			self.F['NOTUSED'] = 1
		42: # RTS Return from subroutine. Pull PC from stack
			self.REG['PC'] = self.pull()
			self.REG['PC'] += self.pull() << 8
			if self.REG['PC'] == 0xffff:
				return # return from NSF play routine
		43: # SBC
			temp = self.REG['ACC'] - self.read(addr) - (1 - self.F['CARRY'])
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			if (
				((self.REG['ACC'] ^ temp) & 0x80) != 0 &&
				((self.REG['ACC'] ^ self.read(addr)) & 0x80) != 0
			):
				self.F['OVERFLOW'] = 1
			else:
				self.F['OVERFLOW'] = 0
			self.F['CARRY'] = 0 if temp < 0 else 1
			self.REG['ACC'] = temp & 0xff
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 1
		44: # SEC set carry flag
			self.F['CARRY'] = 1
		45: # SED Set decimal mode
			self.F['DECIMAL'] = 1
		46: # SEI Set interrupt disable status
			self.F['INTERRUPT'] = 1
		47: # STA Store accumulator in memory
			self.write(addr, self.REG['ACC'])
		48: # STX Store index X in memory
			self.write(addr, self.REG['X'])
		49: # STY Store index Y in memory
			self.write(addr, self.REG['Y'])
		50: # TAX Transfer accumulator to index X
			self.REG['X'] = self.REG['ACC']
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
		51: # TAY Transfer accumulator to index Y
			self.REG['Y'] = self.REG['ACC']
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
		52: # TSX Transfer stack pointer to index X
			self.REG['X'] = self.REG['SP'] - 0x0100
			self.F['SIGN'] = (self.REG['SP'] >> 7) & 1
			self.F['ZERO'] = self.REG['X']
		53: # TXA Transfer index X to accumulator
			self.REG['ACC'] = self.REG['X']
			self.F['SIGN'] = (self.REG['X'] >> 7) & 1
			self.F['ZERO'] = self.REG['X']
		54: # TXS Transfer index X to stack pointer
			self.REG['SP'] = self.REG['X'] + 0x0100
			self.stack_wrap()
		55: # TYA Transfer index Y to accumulator
			self.REG['ACC'] = self.REG['Y']
			self.F['SIGN'] = (self.REG['Y'] >> 7) & 1
			self.F['ZERO'] = self.REG['Y']
		56: # ALR Shift right one bit after ANDing
			temp = self.REG['ACC'] & self.read(addr)
			self.F['CARRY'] = temp & 1
			self.REG['ACC'] = temp >> 1
			self.F['ZERO'] = self.REG['ACC']
			self.F['SIGN'] = 0
		57: # ANC AND accumulator, setting carry to bit 7 result
			self.REG['ACC'] = self.REG['ACC'] & self.read(addr)
			self.REG['ZERO'] = self.REG['ACC']
			self.F['CARRY'] = (self.REG['ACC'] >> 7) & 1
			self.F['SIGN'] = self.F['CARRY']
		58: # ARR Rotate right one bit after ANDing
			temp = self.REG['ACC'] & self.read(addr)
			self.REG['ACC'] = (temp >> 1) + (self.F['CARRY'] << 7)
			self.F['ZERO'] = self.REG['ACC']
			self.F['SIGN'] = self.F['CARRY']
			self.F['CARRY'] = (temp >> 7) & 1
			self.F['OVERFLOW'] = ((temp >> 7) ^ (temp >> 6)) & 1
		59: # AXS Set X to (X AND A) - value
			temp = (self.REG['X'] & self.REG['ACC']) - self.read(addr)
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			if (
				((self.REG['X'] ^ temp) & 0x80) != 0 &&
				((self.REG['X'] ^ self.read(addr)) & 0x80) != 0
			):
				self.F['OVERFLOW'] = 1
			else:
				self.F['OVERFLOW'] = 0
			self.F['CARRY'] = 0 if temp < 0 else 1
			self.REG['X'] = temp & 0xff
		60: # LAX Load A and X with memory
			self.REG['ACC'] = self.read(addr)
			self.REG['X'] = self.REG['ACC']
			self.REG['ZERO'] = self.REG['ACC']
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			cycle_count += cycle_add
		61: # SAX Store A AND X in memory
			self.write(addr, self.REG['ACC'] & self.REG['X'])
		62: # DCP Decrement memory by one
			temp = (self.read(addr) - 1) & 0xff
			self.write(addr, temp)
			# then compare with the accumulator
			temp = self.REG['ACC'] - temp
			self.F['CARRY'] = 1 if temp >= 0 else 0
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 11
		63: # ISC Increment memory by one
			temp = (self.read(addr) + 1) & 0xff
			self.write(addr, temp)
			# then subtract from the accumulator
			temp = self.REG['ACC'] - temp - (1 - self.F['CARRY'])
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			if (
				((self.REG['ACC'] ^ temp) & 0x80) != 0 &&
				((self.REG['ACC'] ^ self.read(addr)) & 0x80) != 0
			):
				self.F['OVERFLOW'] = 1
			else:
				self.F['OVERFLOW'] = 0
			self.F['CARRY'] = 0 if temp < 0 else 1
			self.REG['ACC'] = temp & 0xff
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 11
		64: # RLA Rotate one bit left
			temp = self.read(addr)
			add = self.F['CARRY']
			self.F['CARRY'] = (temp >> 7) & 1
			temp = ((temp << 1) & 0xff) + add
			self.write(addr, temp)
			# then AND with the accumulator
			self.REG['ACC'] = self.REG['ACC'] & temp
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			if addr_mode != 11:
				cycle_count += cycle_add # PostIdInd = 11
		65: # RRA Rotate one bit right
			temp = self.read(addr)
			add = self.F['CARRY'] << 7
			self.F['CARRY'] = temp & 1
			temp = (temp >> 1) + add
			self.write(addr, temp)
			# then add to the accumulator
			temp = self.REG['ACC'] + self.read(addr) + self.F['CARRY']
			if (
				((self.REG['ACC'] ^ temp) & 0x80) != 0 &&
				((self.REG['ACC'] ^ self.read(addr)) & 0x80) == 0
			):
				self.F['OVERFLOW'] = 1
			else:
				self.F['OVERFLOW'] = 0
			self.F['CARRY'] = 1 if temp > 255 else 0
			self.F['SIGN'] = (temp >> 7) & 1
			self.F['ZERO'] = temp & 0xff
			self.REG['ACC'] = temp & 0xff
			if addr_mode != 11:
				cycle_count += cycle_add  # PostIdxInd = 11
		66: # SLO Shift one bit left
			temp = self.read(addr)
			self.F['CARRY'] = (temp >> 7) & 1
			temp = (temp << 1) & 0xff
			self.write(addr, temp)
			# then OR with the accumulator
			self.REG['ACC'] = self.REG['ACC'] | temp
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			if addr_mode != 11:
				cycle_count += cycle_add
		67: # SRE Shift one bit right
			temp = self.read(addr) & 0xff
			self.F['CARRY'] = temp & 1
			temp = temp >> 1
			self.write(addr, temp)
			# then XOR with the accumulator
			self.REG['ACC'] = self.REG['ACC'] | temp
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			if addr_mode != 11:
				cycle_count += cycle_add
		67: # SRE Shift one bit right
			temp = self.read(addr) & 0xff
			self.F['CARRY'] = temp & 1
			temp = temp >> 1
			self.write(addr, temp)
			# Then XOR with the accumulator
			self.REG['ACC'] = self.REG['ACC'] ^ temp
			self.F['SIGN'] = (self.REG['ACC'] >> 7) & 1
			self.F['ZERO'] = self.REG['ACC']
			if addr_mode != 11:
				cycle_count += cycle_count
		68: # SKB Do nothing
			pass
		69: # IGN Do nothing but load. TODO: Properly implement the double-reads
			self.read(addr)
			if addr_mode != 11:
				cycle_count += cycle_add
		var unknown_op:
			print("Game crashed, inavlid opcode at address ", opaddr, unknown_op)
			
	return cycle_count
	
	
func stack_wrap():
	self.REG['SP'] = 0x0100 | (self.REG['SP'] & 0xff)

func set_status(st):
	self.F['CARRY'] = st & 1
	self.F['ZERO'] = (st >> 1) & 1
	self.F['INTERRUPT'] = (st >> 2) & 1
	self.F['DECIMAL'] = (st >> 3) & 1
	self.F['BRK'] = (st >> 4) & 1
	self.F['NOTUSED'] = (st >> 5) & 1
	self.F['OVERFLOW'] = (st >> 6) & 1
	self.F['SIGN'] = (st >> 7) & 1

func get_status():
	var ret =  self.F['CARRY'] | \
				(self.F['ZERO'] << 1) | \
				(self.F['INTERRUPT'] << 2) | \
				(self.F['DECIMAL'] << 3) | \
				(self.F['BRK'] << 4) | \
				(self.F['NOTUSED'] << 5) | \
				(self.F['OVERFLOW'] << 6) | \
				(self.F['SIGN'] << 7)
	return ret

func do_request_interrupt():
	self.REG['PC_NEW'] = self.nes.mmap.read(0xfffc) | (self.nes.mmap.read(0xfffd) << 8)
	self.REG['PC_NEW'] -= 1

func push(value):
	self.nes.mmap.write(self.REG['SP'], value)
	self.REG['SP'] -= 1
	self.REG['SP'] = 0x0100 | (self.REG['SP'] & 0xff)
	
func pull():
	self.REG['SP'] += 1
	self.REG['SP'] = 0x0100 | self.REG['SP'] & 0xff
	return self.nes.mmap.read(self.REG['SP'])

func do_irq(status):
	self.REG['PC_NEW'] += 1
	self.push((self.REG['PC_NEW'] >> 8) & 0xff)
	self.push(self.REG['PC_NEW'] & 0xff)
	self.push(status)
	self.F['INTERRUPT_NEW'] = 1
	self.F['BRK_NEW'] = 0
	self.REG['PC_NEW'] = self.nes.mmap.read(0xfffe) | (self.nes.mmap.read(0xffff) << 8)
	self.REG['PC_NEW'] -= 1

func do_nonmaskable_interrupt(status):
	if (self.nes.mmap.read(0x2000) & 128) != 0:
		# check whether vblank interrupts are enabled
		self.REG['PC_NEW'] += 1
		self.push((self.REG['PC_NEW'] >> 8) & 0xff)
		self.push(self.REG['PC_NEW'] & 0xff)
		self.push(status)
		
		self.REG['PC_NEW'] = self.nes.mmap.read(0xfffa) | (self.nes.mmap.load(0xfffb) << 8)
		self.REG['PC_NEW'] -= 1

func do_reset_interrupt():
	self.REG['PC_NEW'] = self.nes.mmap.read(0xfffc) | (self.nes.mmap.read(0xfffd) << 8)
	self.REG['PC_NEW'] -= 1

func request_irq(itype):
	if self.irq_requested:
		if itype == self.IRQ.NORMAL:
			return
	self.irq_requested = true
	self.irq_type = itype

func read(addr):
	if addr < 0x2000:
		return self.mem[addr & 0x7ff]
	else:
		return self.nes.mmap.read(addr)

func read16bit(addr):
	if addr < 0x1fff:
		return self.mem[addr & 0x7ff] | (self.mem[(addr + 1) & 0x7ff] << 8)
	else:
		return self.nes.mmap.read(addr) | (self.nes.mmap.read(addr+1) << 8)

func write(addr, val):
	if addr < 0x2000:
		self.mem[addr & 0x7ff] = val
	else:
		self.nes.mmap.wirte(addr, val)

