class_name Cpu

var mem = null
var REG_ACC = null
var REG_X = null
var REG_Y = null
var REG_SP = null
var REG_PC = null
var REG_PC_NEW = null
var REG_STATUS = null
var F_CARRY = null
var F_DECIMAL = null
var F_INTERRUPT = null
var F_INTERRUPT_NEW = null
var F_OVERFLOW = null
var F_SIGN = null
var F_ZERO = null
var F_NOTUSED = null
var F_NOTUSED_NEW = null
var F_BRK = null
var F_BRK_NEW = null
var opdata = null
var cyclesToHalt = null
var crash = null
var irqRequested = null
var irqType = null
# Declare member variables here. Examples:
# var a = 2
# var b = "text"



func _init():
	self.reset

func set_status(st):
	F_CARRY = st & 1
	F_ZERO = (st >> 1) & 1
	F_INTERRUPT = (st >> 2) & 1
	F_DECIMAL = (st >> 3) & 1
	F_BRK = (st >> 4) & 1
	F_NOTUSED = (st >> 5) & 1
	F_OVERFLOW = (st >> 6) & 1
	F_SIGN = (st >> 7) & 1
	
func reset():
	mem = Array()
	mem.resize(0x10000)
	for i in range(0x2000):
		mem[i] = 0xff
	for i in range(4):
		var j = i * 0x800
		mem[j + 0x008] = 0xf7
		mem[j + 0x009] = 0xef
		mem[j + 0x00a] = 0xdf
		mem[j + 0x00f] = 0xbf
	for i in range(0x2001, mem.size() + 1):
		mem[i] = 0
	
	# CPU Registers:
	REG_ACC = 0
	REG_X = 0
	REG_Y = 0
	# Reset Stack pointer:
	REG_SP = 0x01ff
	# Reset Program counter:
	REG_PC = 0x8000 - 1
	REG_PC_NEW = 0x8000 - 1
	# Reset Status register:
	REG_STATUS = 0x28

	set_status(0x28)

	# Set flags:
	F_CARRY = 0
	F_DECIMAL = 0
	F_INTERRUPT = 1
	F_INTERRUPT_NEW = 1
	F_OVERFLOW = 0
	F_SIGN = 0
	F_ZERO = 1

	F_NOTUSED = 1
	F_NOTUSED_NEW = 1
	F_BRK = 1
	F_BRK_NEW = 1
	
	load("res://OpData.gd")
	opdata = OpData.new()
	cyclesToHalt = 0
	
	# Reset crash flag:
	crash = false
	
	# Interrrupt notification:
	irqRequested = false
	irqType = null


# emulates a single cpu instruction, returns the number of cycles
func emulate():
	var temp
	var add
	
	# check interrupts:
	if irqRequested:
		temp = F_CARRY | \
		((1 if F_ZERO == 0 else 0) << 1) | \
		(F_INTERRUPT << 2) | (F_DECIMAL << 3) | \
		(F_BRK << 4) | \
		(F_NOTUSED << 5) | \
		(F_OVERFLOW << 6) | \
		(F_SIGN << 7)
		
		REG_PC_NEW = REG_PC
		F_INTERRUPT_NEW = F_INTERRUPT
		match irqType:
			0:  # normal irq
				if F_INTERRUPT != 0:
					print("interrupt was masked.")
			

  // Emulates a single CPU instruction, returns the number of cycles
  emulate: function() {
	var temp;
	var add;

	// Check interrupts:
	if (this.irqRequested) {
	  temp =
		this.F_CARRY |
		((this.F_ZERO === 0 ? 1 : 0) << 1) |
		(this.F_INTERRUPT << 2) |
		(this.F_DECIMAL << 3) |
		(this.F_BRK << 4) |
		(this.F_NOTUSED << 5) |
		(this.F_OVERFLOW << 6) |
		(this.F_SIGN << 7);

	  this.REG_PC_NEW = this.REG_PC;
	  this.F_INTERRUPT_NEW = this.F_INTERRUPT;
	  switch (this.irqType) {
		case 0: {
		  // Normal IRQ:
		  if (this.F_INTERRUPT !== 0) {
			// console.log("Interrupt was masked.");
			break;
		  }
		  this.doIrq(temp);
		  // console.log("Did normal IRQ. I="+this.F_INTERRUPT);
		  break;
		}
		case 1: {
		  // NMI:
		  this.doNonMaskableInterrupt(temp);
		  break;
		}
		case 2: {
		  // Reset:
		  this.doResetInterrupt();
		  break;
		}
	  }

	  this.REG_PC = this.REG_PC_NEW;
	  this.F_INTERRUPT = this.F_INTERRUPT_NEW;
	  this.F_BRK = this.F_BRK_NEW;
	  this.irqRequested = false;
	}

	var opinf = this.opdata[this.nes.mmap.load(this.REG_PC + 1)];
	var cycleCount = opinf >> 24;
	var cycleAdd = 0;

	// Find address mode:
	var addrMode = (opinf >> 8) & 0xff;

	// Increment PC by number of op bytes:
	var opaddr = this.REG_PC;
	this.REG_PC += (opinf >> 16) & 0xff;

	var addr = 0;
	switch (addrMode) {
	  case 0: {
		// Zero Page mode. Use the address given after the opcode,
		// but without high byte.
		addr = this.load(opaddr + 2);
		break;
	  }
	  case 1: {
		// Relative mode.
		addr = this.load(opaddr + 2);
		if (addr < 0x80) {
		  addr += this.REG_PC;
		} else {
		  addr += this.REG_PC - 256;
		}
		break;
	  }
	  case 2: {
		// Ignore. Address is implied in instruction.
		break;
	  }
	  case 3: {
		// Absolute mode. Use the two bytes following the opcode as
		// an address.
		addr = this.load16bit(opaddr + 2);
		break;
	  }
	  case 4: {
		// Accumulator mode. The address is in the accumulator
		// register.
		addr = this.REG_ACC;
		break;
	  }
	  case 5: {
		// Immediate mode. The value is given after the opcode.
		addr = this.REG_PC;
		break;
	  }
	  case 6: {
		// Zero Page Indexed mode, X as index. Use the address given
		// after the opcode, then add the
		// X register to it to get the final address.
		addr = (this.load(opaddr + 2) + this.REG_X) & 0xff;
		break;
	  }
	  case 7: {
		// Zero Page Indexed mode, Y as index. Use the address given
		// after the opcode, then add the
		// Y register to it to get the final address.
		addr = (this.load(opaddr + 2) + this.REG_Y) & 0xff;
		break;
	  }
	  case 8: {
		// Absolute Indexed Mode, X as index. Same as zero page
		// indexed, but with the high byte.
		addr = this.load16bit(opaddr + 2);
		if ((addr & 0xff00) !== ((addr + this.REG_X) & 0xff00)) {
		  cycleAdd = 1;
		}
		addr += this.REG_X;
		break;
	  }
	  case 9: {
		// Absolute Indexed Mode, Y as index. Same as zero page
		// indexed, but with the high byte.
		addr = this.load16bit(opaddr + 2);
		if ((addr & 0xff00) !== ((addr + this.REG_Y) & 0xff00)) {
		  cycleAdd = 1;
		}
		addr += this.REG_Y;
		break;
	  }
	  case 10: {
		// Pre-indexed Indirect mode. Find the 16-bit address
		// starting at the given location plus
		// the current X register. The value is the contents of that
		// address.
		addr = this.load(opaddr + 2);
		if ((addr & 0xff00) !== ((addr + this.REG_X) & 0xff00)) {
		  cycleAdd = 1;
		}
		addr += this.REG_X;
		addr &= 0xff;
		addr = this.load16bit(addr);
		break;
	  }
	  case 11: {
		// Post-indexed Indirect mode. Find the 16-bit address
		// contained in the given location
		// (and the one following). Add to that address the contents
		// of the Y register. Fetch the value
		// stored at that adress.
		addr = this.load16bit(this.load(opaddr + 2));
		if ((addr & 0xff00) !== ((addr + this.REG_Y) & 0xff00)) {
		  cycleAdd = 1;
		}
		addr += this.REG_Y;
		break;
	  }
	  case 12: {
		// Indirect Absolute mode. Find the 16-bit address contained
		// at the given location.
		addr = this.load16bit(opaddr + 2); // Find op
		if (addr < 0x1fff) {
		  addr =
			this.mem[addr] +
			(this.mem[(addr & 0xff00) | (((addr & 0xff) + 1) & 0xff)] << 8); // Read from address given in op
		} else {
		  addr =
			this.nes.mmap.load(addr) +
			(this.nes.mmap.load(
			  (addr & 0xff00) | (((addr & 0xff) + 1) & 0xff)
			) <<
			  8);
		}
		break;
	  }
	}
	// Wrap around for addresses above 0xFFFF:
	addr &= 0xffff;

	// ----------------------------------------------------------------------------------------------------
	// Decode & execute instruction:
	// ----------------------------------------------------------------------------------------------------

	// This should be compiled to a jump table.
	switch (opinf & 0xff) {
	  case 0: {
		// *******
		// * ADC *
		// *******

		// Add with carry.
		temp = this.REG_ACC + this.load(addr) + this.F_CARRY;

		if (
		  ((this.REG_ACC ^ this.load(addr)) & 0x80) === 0 &&
		  ((this.REG_ACC ^ temp) & 0x80) !== 0
		) {
		  this.F_OVERFLOW = 1;
		} else {
		  this.F_OVERFLOW = 0;
		}
		this.F_CARRY = temp > 255 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		this.REG_ACC = temp & 255;
		cycleCount += cycleAdd;
		break;
	  }
	  case 1: {
		// *******
		// * AND *
		// *******

		// AND memory with accumulator.
		this.REG_ACC = this.REG_ACC & this.load(addr);
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 2: {
		// *******
		// * ASL *
		// *******

		// Shift left one bit
		if (addrMode === 4) {
		  // ADDR_ACC = 4

		  this.F_CARRY = (this.REG_ACC >> 7) & 1;
		  this.REG_ACC = (this.REG_ACC << 1) & 255;
		  this.F_SIGN = (this.REG_ACC >> 7) & 1;
		  this.F_ZERO = this.REG_ACC;
		} else {
		  temp = this.load(addr);
		  this.F_CARRY = (temp >> 7) & 1;
		  temp = (temp << 1) & 255;
		  this.F_SIGN = (temp >> 7) & 1;
		  this.F_ZERO = temp;
		  this.write(addr, temp);
		}
		break;
	  }
	  case 3: {
		// *******
		// * BCC *
		// *******

		// Branch on carry clear
		if (this.F_CARRY === 0) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 4: {
		// *******
		// * BCS *
		// *******

		// Branch on carry set
		if (this.F_CARRY === 1) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 5: {
		// *******
		// * BEQ *
		// *******

		// Branch on zero
		if (this.F_ZERO === 0) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 6: {
		// *******
		// * BIT *
		// *******

		temp = this.load(addr);
		this.F_SIGN = (temp >> 7) & 1;
		this.F_OVERFLOW = (temp >> 6) & 1;
		temp &= this.REG_ACC;
		this.F_ZERO = temp;
		break;
	  }
	  case 7: {
		// *******
		// * BMI *
		// *******

		// Branch on negative result
		if (this.F_SIGN === 1) {
		  cycleCount++;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 8: {
		// *******
		// * BNE *
		// *******

		// Branch on not zero
		if (this.F_ZERO !== 0) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 9: {
		// *******
		// * BPL *
		// *******

		// Branch on positive result
		if (this.F_SIGN === 0) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 10: {
		// *******
		// * BRK *
		// *******

		this.REG_PC += 2;
		this.push((this.REG_PC >> 8) & 255);
		this.push(this.REG_PC & 255);
		this.F_BRK = 1;

		this.push(
		  this.F_CARRY |
			((this.F_ZERO === 0 ? 1 : 0) << 1) |
			(this.F_INTERRUPT << 2) |
			(this.F_DECIMAL << 3) |
			(this.F_BRK << 4) |
			(this.F_NOTUSED << 5) |
			(this.F_OVERFLOW << 6) |
			(this.F_SIGN << 7)
		);

		this.F_INTERRUPT = 1;
		//this.REG_PC = load(0xFFFE) | (load(0xFFFF) << 8);
		this.REG_PC = this.load16bit(0xfffe);
		this.REG_PC--;
		break;
	  }
	  case 11: {
		// *******
		// * BVC *
		// *******

		// Branch on overflow clear
		if (this.F_OVERFLOW === 0) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 12: {
		// *******
		// * BVS *
		// *******

		// Branch on overflow set
		if (this.F_OVERFLOW === 1) {
		  cycleCount += (opaddr & 0xff00) !== (addr & 0xff00) ? 2 : 1;
		  this.REG_PC = addr;
		}
		break;
	  }
	  case 13: {
		// *******
		// * CLC *
		// *******

		// Clear carry flag
		this.F_CARRY = 0;
		break;
	  }
	  case 14: {
		// *******
		// * CLD *
		// *******

		// Clear decimal flag
		this.F_DECIMAL = 0;
		break;
	  }
	  case 15: {
		// *******
		// * CLI *
		// *******

		// Clear interrupt flag
		this.F_INTERRUPT = 0;
		break;
	  }
	  case 16: {
		// *******
		// * CLV *
		// *******

		// Clear overflow flag
		this.F_OVERFLOW = 0;
		break;
	  }
	  case 17: {
		// *******
		// * CMP *
		// *******

		// Compare memory and accumulator:
		temp = this.REG_ACC - this.load(addr);
		this.F_CARRY = temp >= 0 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		cycleCount += cycleAdd;
		break;
	  }
	  case 18: {
		// *******
		// * CPX *
		// *******

		// Compare memory and index X:
		temp = this.REG_X - this.load(addr);
		this.F_CARRY = temp >= 0 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		break;
	  }
	  case 19: {
		// *******
		// * CPY *
		// *******

		// Compare memory and index Y:
		temp = this.REG_Y - this.load(addr);
		this.F_CARRY = temp >= 0 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		break;
	  }
	  case 20: {
		// *******
		// * DEC *
		// *******

		// Decrement memory by one:
		temp = (this.load(addr) - 1) & 0xff;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp;
		this.write(addr, temp);
		break;
	  }
	  case 21: {
		// *******
		// * DEX *
		// *******

		// Decrement index X by one:
		this.REG_X = (this.REG_X - 1) & 0xff;
		this.F_SIGN = (this.REG_X >> 7) & 1;
		this.F_ZERO = this.REG_X;
		break;
	  }
	  case 22: {
		// *******
		// * DEY *
		// *******

		// Decrement index Y by one:
		this.REG_Y = (this.REG_Y - 1) & 0xff;
		this.F_SIGN = (this.REG_Y >> 7) & 1;
		this.F_ZERO = this.REG_Y;
		break;
	  }
	  case 23: {
		// *******
		// * EOR *
		// *******

		// XOR Memory with accumulator, store in accumulator:
		this.REG_ACC = (this.load(addr) ^ this.REG_ACC) & 0xff;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		cycleCount += cycleAdd;
		break;
	  }
	  case 24: {
		// *******
		// * INC *
		// *******

		// Increment memory by one:
		temp = (this.load(addr) + 1) & 0xff;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp;
		this.write(addr, temp & 0xff);
		break;
	  }
	  case 25: {
		// *******
		// * INX *
		// *******

		// Increment index X by one:
		this.REG_X = (this.REG_X + 1) & 0xff;
		this.F_SIGN = (this.REG_X >> 7) & 1;
		this.F_ZERO = this.REG_X;
		break;
	  }
	  case 26: {
		// *******
		// * INY *
		// *******

		// Increment index Y by one:
		this.REG_Y++;
		this.REG_Y &= 0xff;
		this.F_SIGN = (this.REG_Y >> 7) & 1;
		this.F_ZERO = this.REG_Y;
		break;
	  }
	  case 27: {
		// *******
		// * JMP *
		// *******

		// Jump to new location:
		this.REG_PC = addr - 1;
		break;
	  }
	  case 28: {
		// *******
		// * JSR *
		// *******

		// Jump to new location, saving return address.
		// Push return address on stack:
		this.push((this.REG_PC >> 8) & 255);
		this.push(this.REG_PC & 255);
		this.REG_PC = addr - 1;
		break;
	  }
	  case 29: {
		// *******
		// * LDA *
		// *******

		// Load accumulator with memory:
		this.REG_ACC = this.load(addr);
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		cycleCount += cycleAdd;
		break;
	  }
	  case 30: {
		// *******
		// * LDX *
		// *******

		// Load index X with memory:
		this.REG_X = this.load(addr);
		this.F_SIGN = (this.REG_X >> 7) & 1;
		this.F_ZERO = this.REG_X;
		cycleCount += cycleAdd;
		break;
	  }
	  case 31: {
		// *******
		// * LDY *
		// *******

		// Load index Y with memory:
		this.REG_Y = this.load(addr);
		this.F_SIGN = (this.REG_Y >> 7) & 1;
		this.F_ZERO = this.REG_Y;
		cycleCount += cycleAdd;
		break;
	  }
	  case 32: {
		// *******
		// * LSR *
		// *******

		// Shift right one bit:
		if (addrMode === 4) {
		  // ADDR_ACC

		  temp = this.REG_ACC & 0xff;
		  this.F_CARRY = temp & 1;
		  temp >>= 1;
		  this.REG_ACC = temp;
		} else {
		  temp = this.load(addr) & 0xff;
		  this.F_CARRY = temp & 1;
		  temp >>= 1;
		  this.write(addr, temp);
		}
		this.F_SIGN = 0;
		this.F_ZERO = temp;
		break;
	  }
	  case 33: {
		// *******
		// * NOP *
		// *******

		// No OPeration.
		// Ignore.
		break;
	  }
	  case 34: {
		// *******
		// * ORA *
		// *******

		// OR memory with accumulator, store in accumulator.
		temp = (this.load(addr) | this.REG_ACC) & 255;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp;
		this.REG_ACC = temp;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 35: {
		// *******
		// * PHA *
		// *******

		// Push accumulator on stack
		this.push(this.REG_ACC);
		break;
	  }
	  case 36: {
		// *******
		// * PHP *
		// *******

		// Push processor status on stack
		this.F_BRK = 1;
		this.push(
		  this.F_CARRY |
			((this.F_ZERO === 0 ? 1 : 0) << 1) |
			(this.F_INTERRUPT << 2) |
			(this.F_DECIMAL << 3) |
			(this.F_BRK << 4) |
			(this.F_NOTUSED << 5) |
			(this.F_OVERFLOW << 6) |
			(this.F_SIGN << 7)
		);
		break;
	  }
	  case 37: {
		// *******
		// * PLA *
		// *******

		// Pull accumulator from stack
		this.REG_ACC = this.pull();
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		break;
	  }
	  case 38: {
		// *******
		// * PLP *
		// *******

		// Pull processor status from stack
		temp = this.pull();
		this.F_CARRY = temp & 1;
		this.F_ZERO = ((temp >> 1) & 1) === 1 ? 0 : 1;
		this.F_INTERRUPT = (temp >> 2) & 1;
		this.F_DECIMAL = (temp >> 3) & 1;
		this.F_BRK = (temp >> 4) & 1;
		this.F_NOTUSED = (temp >> 5) & 1;
		this.F_OVERFLOW = (temp >> 6) & 1;
		this.F_SIGN = (temp >> 7) & 1;

		this.F_NOTUSED = 1;
		break;
	  }
	  case 39: {
		// *******
		// * ROL *
		// *******

		// Rotate one bit left
		if (addrMode === 4) {
		  // ADDR_ACC = 4

		  temp = this.REG_ACC;
		  add = this.F_CARRY;
		  this.F_CARRY = (temp >> 7) & 1;
		  temp = ((temp << 1) & 0xff) + add;
		  this.REG_ACC = temp;
		} else {
		  temp = this.load(addr);
		  add = this.F_CARRY;
		  this.F_CARRY = (temp >> 7) & 1;
		  temp = ((temp << 1) & 0xff) + add;
		  this.write(addr, temp);
		}
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp;
		break;
	  }
	  case 40: {
		// *******
		// * ROR *
		// *******

		// Rotate one bit right
		if (addrMode === 4) {
		  // ADDR_ACC = 4

		  add = this.F_CARRY << 7;
		  this.F_CARRY = this.REG_ACC & 1;
		  temp = (this.REG_ACC >> 1) + add;
		  this.REG_ACC = temp;
		} else {
		  temp = this.load(addr);
		  add = this.F_CARRY << 7;
		  this.F_CARRY = temp & 1;
		  temp = (temp >> 1) + add;
		  this.write(addr, temp);
		}
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp;
		break;
	  }
	  case 41: {
		// *******
		// * RTI *
		// *******

		// Return from interrupt. Pull status and PC from stack.

		temp = this.pull();
		this.F_CARRY = temp & 1;
		this.F_ZERO = ((temp >> 1) & 1) === 0 ? 1 : 0;
		this.F_INTERRUPT = (temp >> 2) & 1;
		this.F_DECIMAL = (temp >> 3) & 1;
		this.F_BRK = (temp >> 4) & 1;
		this.F_NOTUSED = (temp >> 5) & 1;
		this.F_OVERFLOW = (temp >> 6) & 1;
		this.F_SIGN = (temp >> 7) & 1;

		this.REG_PC = this.pull();
		this.REG_PC += this.pull() << 8;
		if (this.REG_PC === 0xffff) {
		  return;
		}
		this.REG_PC--;
		this.F_NOTUSED = 1;
		break;
	  }
	  case 42: {
		// *******
		// * RTS *
		// *******

		// Return from subroutine. Pull PC from stack.

		this.REG_PC = this.pull();
		this.REG_PC += this.pull() << 8;

		if (this.REG_PC === 0xffff) {
		  return; // return from NSF play routine:
		}
		break;
	  }
	  case 43: {
		// *******
		// * SBC *
		// *******

		temp = this.REG_ACC - this.load(addr) - (1 - this.F_CARRY);
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		if (
		  ((this.REG_ACC ^ temp) & 0x80) !== 0 &&
		  ((this.REG_ACC ^ this.load(addr)) & 0x80) !== 0
		) {
		  this.F_OVERFLOW = 1;
		} else {
		  this.F_OVERFLOW = 0;
		}
		this.F_CARRY = temp < 0 ? 0 : 1;
		this.REG_ACC = temp & 0xff;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 44: {
		// *******
		// * SEC *
		// *******

		// Set carry flag
		this.F_CARRY = 1;
		break;
	  }
	  case 45: {
		// *******
		// * SED *
		// *******

		// Set decimal mode
		this.F_DECIMAL = 1;
		break;
	  }
	  case 46: {
		// *******
		// * SEI *
		// *******

		// Set interrupt disable status
		this.F_INTERRUPT = 1;
		break;
	  }
	  case 47: {
		// *******
		// * STA *
		// *******

		// Store accumulator in memory
		this.write(addr, this.REG_ACC);
		break;
	  }
	  case 48: {
		// *******
		// * STX *
		// *******

		// Store index X in memory
		this.write(addr, this.REG_X);
		break;
	  }
	  case 49: {
		// *******
		// * STY *
		// *******

		// Store index Y in memory:
		this.write(addr, this.REG_Y);
		break;
	  }
	  case 50: {
		// *******
		// * TAX *
		// *******

		// Transfer accumulator to index X:
		this.REG_X = this.REG_ACC;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		break;
	  }
	  case 51: {
		// *******
		// * TAY *
		// *******

		// Transfer accumulator to index Y:
		this.REG_Y = this.REG_ACC;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		break;
	  }
	  case 52: {
		// *******
		// * TSX *
		// *******

		// Transfer stack pointer to index X:
		this.REG_X = this.REG_SP - 0x0100;
		this.F_SIGN = (this.REG_SP >> 7) & 1;
		this.F_ZERO = this.REG_X;
		break;
	  }
	  case 53: {
		// *******
		// * TXA *
		// *******

		// Transfer index X to accumulator:
		this.REG_ACC = this.REG_X;
		this.F_SIGN = (this.REG_X >> 7) & 1;
		this.F_ZERO = this.REG_X;
		break;
	  }
	  case 54: {
		// *******
		// * TXS *
		// *******

		// Transfer index X to stack pointer:
		this.REG_SP = this.REG_X + 0x0100;
		this.stackWrap();
		break;
	  }
	  case 55: {
		// *******
		// * TYA *
		// *******

		// Transfer index Y to accumulator:
		this.REG_ACC = this.REG_Y;
		this.F_SIGN = (this.REG_Y >> 7) & 1;
		this.F_ZERO = this.REG_Y;
		break;
	  }
	  case 56: {
		// *******
		// * ALR *
		// *******

		// Shift right one bit after ANDing:
		temp = this.REG_ACC & this.load(addr);
		this.F_CARRY = temp & 1;
		this.REG_ACC = this.F_ZERO = temp >> 1;
		this.F_SIGN = 0;
		break;
	  }
	  case 57: {
		// *******
		// * ANC *
		// *******

		// AND accumulator, setting carry to bit 7 result.
		this.REG_ACC = this.F_ZERO = this.REG_ACC & this.load(addr);
		this.F_CARRY = this.F_SIGN = (this.REG_ACC >> 7) & 1;
		break;
	  }
	  case 58: {
		// *******
		// * ARR *
		// *******

		// Rotate right one bit after ANDing:
		temp = this.REG_ACC & this.load(addr);
		this.REG_ACC = this.F_ZERO = (temp >> 1) + (this.F_CARRY << 7);
		this.F_SIGN = this.F_CARRY;
		this.F_CARRY = (temp >> 7) & 1;
		this.F_OVERFLOW = ((temp >> 7) ^ (temp >> 6)) & 1;
		break;
	  }
	  case 59: {
		// *******
		// * AXS *
		// *******

		// Set X to (X AND A) - value.
		temp = (this.REG_X & this.REG_ACC) - this.load(addr);
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		if (
		  ((this.REG_X ^ temp) & 0x80) !== 0 &&
		  ((this.REG_X ^ this.load(addr)) & 0x80) !== 0
		) {
		  this.F_OVERFLOW = 1;
		} else {
		  this.F_OVERFLOW = 0;
		}
		this.F_CARRY = temp < 0 ? 0 : 1;
		this.REG_X = temp & 0xff;
		break;
	  }
	  case 60: {
		// *******
		// * LAX *
		// *******

		// Load A and X with memory:
		this.REG_ACC = this.REG_X = this.F_ZERO = this.load(addr);
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		cycleCount += cycleAdd;
		break;
	  }
	  case 61: {
		// *******
		// * SAX *
		// *******

		// Store A AND X in memory:
		this.write(addr, this.REG_ACC & this.REG_X);
		break;
	  }
	  case 62: {
		// *******
		// * DCP *
		// *******

		// Decrement memory by one:
		temp = (this.load(addr) - 1) & 0xff;
		this.write(addr, temp);

		// Then compare with the accumulator:
		temp = this.REG_ACC - temp;
		this.F_CARRY = temp >= 0 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 63: {
		// *******
		// * ISC *
		// *******

		// Increment memory by one:
		temp = (this.load(addr) + 1) & 0xff;
		this.write(addr, temp);

		// Then subtract from the accumulator:
		temp = this.REG_ACC - temp - (1 - this.F_CARRY);
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		if (
		  ((this.REG_ACC ^ temp) & 0x80) !== 0 &&
		  ((this.REG_ACC ^ this.load(addr)) & 0x80) !== 0
		) {
		  this.F_OVERFLOW = 1;
		} else {
		  this.F_OVERFLOW = 0;
		}
		this.F_CARRY = temp < 0 ? 0 : 1;
		this.REG_ACC = temp & 0xff;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 64: {
		// *******
		// * RLA *
		// *******

		// Rotate one bit left
		temp = this.load(addr);
		add = this.F_CARRY;
		this.F_CARRY = (temp >> 7) & 1;
		temp = ((temp << 1) & 0xff) + add;
		this.write(addr, temp);

		// Then AND with the accumulator.
		this.REG_ACC = this.REG_ACC & temp;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 65: {
		// *******
		// * RRA *
		// *******

		// Rotate one bit right
		temp = this.load(addr);
		add = this.F_CARRY << 7;
		this.F_CARRY = temp & 1;
		temp = (temp >> 1) + add;
		this.write(addr, temp);

		// Then add to the accumulator
		temp = this.REG_ACC + this.load(addr) + this.F_CARRY;

		if (
		  ((this.REG_ACC ^ this.load(addr)) & 0x80) === 0 &&
		  ((this.REG_ACC ^ temp) & 0x80) !== 0
		) {
		  this.F_OVERFLOW = 1;
		} else {
		  this.F_OVERFLOW = 0;
		}
		this.F_CARRY = temp > 255 ? 1 : 0;
		this.F_SIGN = (temp >> 7) & 1;
		this.F_ZERO = temp & 0xff;
		this.REG_ACC = temp & 255;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 66: {
		// *******
		// * SLO *
		// *******

		// Shift one bit left
		temp = this.load(addr);
		this.F_CARRY = (temp >> 7) & 1;
		temp = (temp << 1) & 255;
		this.write(addr, temp);

		// Then OR with the accumulator.
		this.REG_ACC = this.REG_ACC | temp;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 67: {
		// *******
		// * SRE *
		// *******

		// Shift one bit right
		temp = this.load(addr) & 0xff;
		this.F_CARRY = temp & 1;
		temp >>= 1;
		this.write(addr, temp);

		// Then XOR with the accumulator.
		this.REG_ACC = this.REG_ACC ^ temp;
		this.F_SIGN = (this.REG_ACC >> 7) & 1;
		this.F_ZERO = this.REG_ACC;
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }
	  case 68: {
		// *******
		// * SKB *
		// *******

		// Do nothing
		break;
	  }
	  case 69: {
		// *******
		// * IGN *
		// *******

		// Do nothing but load.
		// TODO: Properly implement the double-reads.
		this.load(addr);
		if (addrMode !== 11) cycleCount += cycleAdd; // PostIdxInd = 11
		break;
	  }

	  default: {
		// *******
		// * ??? *
		// *******

		this.nes.stop();
		this.nes.crashMessage =
		  "Game crashed, invalid opcode at address $" + opaddr.toString(16);
		break;
	  }
	} // end of switch

	return cycleCount;
  },

  load: function(addr) {
	if (addr < 0x2000) {
	  return this.mem[addr & 0x7ff];
	} else {
	  return this.nes.mmap.load(addr);
	}
  },

  load16bit: function(addr) {
	if (addr < 0x1fff) {
	  return this.mem[addr & 0x7ff] | (this.mem[(addr + 1) & 0x7ff] << 8);
	} else {
	  return this.nes.mmap.load(addr) | (this.nes.mmap.load(addr + 1) << 8);
	}
  },

  write: function(addr, val) {
	if (addr < 0x2000) {
	  this.mem[addr & 0x7ff] = val;
	} else {
	  this.nes.mmap.write(addr, val);
	}
  },

  requestIrq: function(type) {
	if (this.irqRequested) {
	  if (type === this.IRQ_NORMAL) {
		return;
	  }
	  // console.log("too fast irqs. type="+type);
	}
	this.irqRequested = true;
	this.irqType = type;
  },

  push: function(value) {
	this.nes.mmap.write(this.REG_SP, value);
	this.REG_SP--;
	this.REG_SP = 0x0100 | (this.REG_SP & 0xff);
  },

  stackWrap: function() {
	this.REG_SP = 0x0100 | (this.REG_SP & 0xff);
  },

  pull: function() {
	this.REG_SP++;
	this.REG_SP = 0x0100 | (this.REG_SP & 0xff);
	return this.nes.mmap.load(this.REG_SP);
  },

  pageCrossed: function(addr1, addr2) {
	return (addr1 & 0xff00) !== (addr2 & 0xff00);
  },

  haltCycles: function(cycles) {
	this.cyclesToHalt += cycles;
  },

  doNonMaskableInterrupt: function(status) {
	if ((this.nes.mmap.load(0x2000) & 128) !== 0) {
	  // Check whether VBlank Interrupts are enabled

	  this.REG_PC_NEW++;
	  this.push((this.REG_PC_NEW >> 8) & 0xff);
	  this.push(this.REG_PC_NEW & 0xff);
	  //this.F_INTERRUPT_NEW = 1;
	  this.push(status);

	  this.REG_PC_NEW =
		this.nes.mmap.load(0xfffa) | (this.nes.mmap.load(0xfffb) << 8);
	  this.REG_PC_NEW--;
	}
  },

  doResetInterrupt: function() {
	this.REG_PC_NEW =
	  this.nes.mmap.load(0xfffc) | (this.nes.mmap.load(0xfffd) << 8);
	this.REG_PC_NEW--;
  },

  doIrq: function(status) {
	this.REG_PC_NEW++;
	this.push((this.REG_PC_NEW >> 8) & 0xff);
	this.push(this.REG_PC_NEW & 0xff);
	this.push(status);
	this.F_INTERRUPT_NEW = 1;
	this.F_BRK_NEW = 0;

	this.REG_PC_NEW =
	  this.nes.mmap.load(0xfffe) | (this.nes.mmap.load(0xffff) << 8);
	this.REG_PC_NEW--;
  },

  getStatus: function() {
	return (
	  this.F_CARRY |
	  (this.F_ZERO << 1) |
	  (this.F_INTERRUPT << 2) |
	  (this.F_DECIMAL << 3) |
	  (this.F_BRK << 4) |
	  (this.F_NOTUSED << 5) |
	  (this.F_OVERFLOW << 6) |
	  (this.F_SIGN << 7)
	);
  },

  setStatus: function(st) {
	this.F_CARRY = st & 1;
	this.F_ZERO = (st >> 1) & 1;
	this.F_INTERRUPT = (st >> 2) & 1;
	this.F_DECIMAL = (st >> 3) & 1;
	this.F_BRK = (st >> 4) & 1;
	this.F_NOTUSED = (st >> 5) & 1;
	this.F_OVERFLOW = (st >> 6) & 1;
	this.F_SIGN = (st >> 7) & 1;
  },

  JSON_PROPERTIES: [
	"mem",
	"cyclesToHalt",
	"irqRequested",
	"irqType",
	// Registers
	"REG_ACC",
	"REG_X",
	"REG_Y",
	"REG_SP",
	"REG_PC",
	"REG_PC_NEW",
	"REG_STATUS",
	// Status
	"F_CARRY",
	"F_DECIMAL",
	"F_INTERRUPT",
	"F_INTERRUPT_NEW",
	"F_OVERFLOW",
	"F_SIGN",
	"F_ZERO",
	"F_NOTUSED",
	"F_NOTUSED_NEW",
	"F_BRK",
	"F_BRK_NEW"
  ],

  toJSON: function() {
	return utils.toJSON(this);
  },

  fromJSON: function(s) {
	utils.fromJSON(this, s);
  }
};

// Generates and provides an array of details about instructions
var OpData = function() {
  this.opdata = new Array(256);

  // Set all to invalid instruction (to detect crashes):
  for (var i = 0; i < 256; i++) this.opdata[i] = 0xff;

  // Now fill in all valid opcodes:

  // prettier-ignore
  this.cycTable = new Array(
	/*0x00*/ 7,6,2,8,3,3,5,5,3,2,2,2,4,4,6,6,
	/*0x10*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
	/*0x20*/ 6,6,2,8,3,3,5,5,4,2,2,2,4,4,6,6,
	/*0x30*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
	/*0x40*/ 6,6,2,8,3,3,5,5,3,2,2,2,3,4,6,6,
	/*0x50*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
	/*0x60*/ 6,6,2,8,3,3,5,5,4,2,2,2,5,4,6,6,
	/*0x70*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
	/*0x80*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
	/*0x90*/ 2,6,2,6,4,4,4,4,2,5,2,5,5,5,5,5,
	/*0xA0*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
	/*0xB0*/ 2,5,2,5,4,4,4,4,2,4,2,4,4,4,4,4,
	/*0xC0*/ 2,6,2,8,3,3,5,5,2,2,2,2,4,4,6,6,
	/*0xD0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
	/*0xE0*/ 2,6,3,8,3,3,5,5,2,2,2,2,4,4,6,6,
	/*0xF0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7
  );

  this.instname = new Array(70);

  this.addrDesc = new Array(
	"Zero Page           ",
	"Relative            ",
	"Implied             ",
	"Absolute            ",
	"Accumulator         ",
	"Immediate           ",
	"Zero Page,X         ",
	"Zero Page,Y         ",
	"Absolute,X          ",
	"Absolute,Y          ",
	"Preindexed Indirect ",
	"Postindexed Indirect",
	"Indirect Absolute   "
  );
};

OpData.prototype = {
  INS_ADC: 0,
  INS_AND: 1,
  INS_ASL: 2,

  INS_BCC: 3,
  INS_BCS: 4,
  INS_BEQ: 5,
  INS_BIT: 6,
  INS_BMI: 7,
  INS_BNE: 8,
  INS_BPL: 9,
  INS_BRK: 10,
  INS_BVC: 11,
  INS_BVS: 12,

  INS_CLC: 13,
  INS_CLD: 14,
  INS_CLI: 15,
  INS_CLV: 16,
  INS_CMP: 17,
  INS_CPX: 18,
  INS_CPY: 19,

  INS_DEC: 20,
  INS_DEX: 21,
  INS_DEY: 22,

  INS_EOR: 23,

  INS_INC: 24,
  INS_INX: 25,
  INS_INY: 26,

  INS_JMP: 27,
  INS_JSR: 28,

  INS_LDA: 29,
  INS_LDX: 30,
  INS_LDY: 31,
  INS_LSR: 32,

  INS_NOP: 33,

  INS_ORA: 34,

  INS_PHA: 35,
  INS_PHP: 36,
  INS_PLA: 37,
  INS_PLP: 38,

  INS_ROL: 39,
  INS_ROR: 40,
  INS_RTI: 41,
  INS_RTS: 42,

  INS_SBC: 43,
  INS_SEC: 44,
  INS_SED: 45,
  INS_SEI: 46,
  INS_STA: 47,
  INS_STX: 48,
  INS_STY: 49,

  INS_TAX: 50,
  INS_TAY: 51,
  INS_TSX: 52,
  INS_TXA: 53,
  INS_TXS: 54,
  INS_TYA: 55,

  INS_ALR: 56,
  INS_ANC: 57,
  INS_ARR: 58,
  INS_AXS: 59,
  INS_LAX: 60,
  INS_SAX: 61,
  INS_DCP: 62,
  INS_ISC: 63,
  INS_RLA: 64,
  INS_RRA: 65,
  INS_SLO: 66,
  INS_SRE: 67,
  INS_SKB: 68,
  INS_IGN: 69,

  INS_DUMMY: 70, // dummy instruction used for 'halting' the processor some cycles

  // -------------------------------- //

  // Addressing modes:
  ADDR_ZP: 0,
  ADDR_REL: 1,
  ADDR_IMP: 2,
  ADDR_ABS: 3,
  ADDR_ACC: 4,
  ADDR_IMM: 5,
  ADDR_ZPX: 6,
  ADDR_ZPY: 7,
  ADDR_ABSX: 8,
  ADDR_ABSY: 9,
  ADDR_PREIDXIND: 10,
  ADDR_POSTIDXIND: 11,
  ADDR_INDABS: 12,

  setOp: function(inst, op, addr, size, cycles) {
	this.opdata[op] =
	  (inst & 0xff) |
	  ((addr & 0xff) << 8) |
	  ((size & 0xff) << 16) |
	  ((cycles & 0xff) << 24);
  }
};

module.exports = CPU;

