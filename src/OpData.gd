# author: hwnzy
# date: 2020.5.3

class_name OPDATA

var opdata = Array()
var cyc_table = Array()
var instname = Array()
var addr_desc = Array()
enum INS {
	ADC, AND, ASL, 
	BCC, BCS, BEQ, BIT, BMI, BNE, BPL, BRK, BVC, BVS, 
	CLC, CLD, CLI, CLV, CMP, CPX, CPY,
	DEC, DEX, DEY,
	EOR,
	INC, INX, INY, 
	JMP, JSR, 
	LDA, LDX, LDY, LSR,
	NOP,
	ORA,
	PHA, PHP, PLA, PLP,
	ROL, ROR, RTI, RTS,
	SBC, SEC, SED, SEI, STA, STX, STY,
	TAX, TAY, TSX, TXA, TXS, TYA,
	ALR, ANC, ARR, AXS, LAX, SAX, DCP, ISC, RLA, RRA, SLO, SRE, SKB, IGN,
	DUMMY  # dummy instruction used fro 'halting' the processor some cycles
}
# addressing modes
enum ADDR {
	ZP, REL, IMP, ABS, ACC, IMM, ZPX, ZPY, ABSX, ABSY, PREIDXIND, POSTIDXIND, INDABS
}


func _init():
	self.opdata = Array()
	self.opdata = opdata.reszie(256)
	# set all to invalid instruction(to detect crashes):
	for i in range(256):
		self.opda[i] = 0xff
	# now fill in all valid opcodes
	
	self.set_op(self.INS.ADC, 0x69, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.ADC, 0x65, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.ADC, 0x75, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.ADC, 0x6d, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.ADC, 0x7d, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.ADC, 0x79, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.ADC, 0x61, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.ADC, 0x71, self.ADDR.POSTIDXIND, 2, 5)

	self.set_op(self.INS.AND, 0x29, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.AND, 0x25, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.AND, 0x35, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.AND, 0x2d, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.AND, 0x3d, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.AND, 0x39, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.AND, 0x21, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.AND, 0x31, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.ASL, 0x0a, self.ADDR.ACC, 1, 2)
	self.set_op(self.INS.ASL, 0x06, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.ASL, 0x16, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.ASL, 0x0e, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.ASL, 0x1e, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.BCC, 0x90, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BCS, 0xb0, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BEQ, 0xf0, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BIT, 0x24, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.BIT, 0x2c, self.ADDR.ABS, 3, 4)
	
	self.set_op(self.INS.BMI, 0x30, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BNE, 0xd0, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BPL, 0x10, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BRK, 0x00, self.ADDR.IMP, 1, 7)
	
	self.set_op(self.INS.BVC, 0x50, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.BVS, 0x70, self.ADDR.REL, 2, 2)
	
	self.set_op(self.INS.CLC, 0x18, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.CLD, 0xd8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.CLI, 0x58, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.CLV, 0xb8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.CMP, 0xc9, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.CMP, 0xc5, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.CMP, 0xd5, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.CMP, 0xcd, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.CMP, 0xdd, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.CMP, 0xd9, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.CMP, 0xc1, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.CMP, 0xd1, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.CPX, 0xe0, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.CPX, 0xe4, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.CPX, 0xec, self.ADDR.ABS, 3, 4)
	
	self.set_op(self.INS.CPY, 0xc0, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.CPY, 0xc4, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.CPY, 0xcc, self.ADDR.ABS, 3, 4)
	
	self.set_op(self.INS.DEC, 0xc6, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.DEC, 0xd6, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.DEC, 0xce, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.DEC, 0xde, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.DEX, 0xca, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.DEY, 0x88, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.EOR, 0x49, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.EOR, 0x45, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.EOR, 0x55, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.EOR, 0x4d, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.EOR, 0x5d, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.EOR, 0x59, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.EOR, 0x41, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.EOR, 0x51, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.INC, 0xe6, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.INC, 0xf6, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.INC, 0xee, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.INC, 0xfe, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.INX, 0xe8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.INY, 0xc8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.JMP, 0x4c, self.ADDR.ABS, 3, 3)
	self.set_op(self.INS.JMP, 0x6c, self.ADDR.INDABS, 3, 5)
	
	self.set_op(self.INS.JSR, 0x20, self.ADDR.ABS, 3, 6)
	
	self.set_op(self.INS.LDA, 0xa9, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.LDA, 0xa5, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.LDA, 0xb5, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.LDA, 0xad, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.LDA, 0xbd, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.LDA, 0xb9, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.LDA, 0xa1, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.LDA, 0xb1, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.LDX, 0xa2, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.LDX, 0xa6, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.LDX, 0xb6, self.ADDR.ZPY, 2, 4)
	self.set_op(self.INS.LDX, 0xae, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.LDX, 0xbe, self.ADDR.ABSY, 3, 4)
	
	self.set_op(self.INS.LDY, 0xa0, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.LDY, 0xa4, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.LDY, 0xb4, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.LDY, 0xac, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.LDY, 0xbc, self.ADDR.ABSX, 3, 4)
	
	self.set_op(self.INS.LSR, 0x4a, self.ADDR.ACC, 1, 2)
	self.set_op(self.INS.LSR, 0x46, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.LSR, 0x56, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.LSR, 0x4e, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.LSR, 0x5e, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.NOP, 0x1a, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0x3a, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0x5a, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0x7a, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0xda, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0xea, self.ADDR.IMP, 1, 2)
	self.set_op(self.INS.NOP, 0xfa, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.ORA, 0x09, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.ORA, 0x05, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.ORA, 0x15, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.ORA, 0x0d, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.ORA, 0x1d, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.ORA, 0x19, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.ORA, 0x01, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.ORA, 0x11, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.PHA, 0x48, self.ADDR.IMP, 1, 3)
	
	self.set_op(self.INS.PHP, 0x08, self.ADDR.IMP, 1, 3)
	
	self.set_op(self.INS.PLA, 0x68, self.ADDR.IMP, 1, 4)
	
	self.set_op(self.INS.PLP, 0x28, self.ADDR.IMP, 1, 4)
	
	self.set_op(self.INS.ROL, 0x2a, self.ADDR.ACC, 1, 2)
	self.set_op(self.INS.ROL, 0x26, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.ROL, 0x36, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.ROL, 0x2e, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.ROL, 0x3e, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.ROR, 0x6a, self.ADDR.ACC, 1, 2)
	self.set_op(self.INS.ROR, 0x66, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.ROR, 0x76, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.ROR, 0x6e, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.ROR, 0x7e, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.RTI, 0x40, self.ADDR.IMP, 1, 6)
	
	self.set_op(self.INS.RTS, 0x60, self.ADDR.IMP, 1, 6)
	
	self.set_op(self.INS.SBC, 0xe9, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.SBC, 0xe5, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.SBC, 0xf5, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.SBC, 0xed, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.SBC, 0xfd, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.SBC, 0xf9, self.ADDR.ABSY, 3, 4)
	self.set_op(self.INS.SBC, 0xe1, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.SBC, 0xf1, self.ADDR.POSTIDXIND, 2, 5)
	
	self.set_op(self.INS.SEC, 0x38, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.SED, 0xf8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.SEI, 0x78, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.STA, 0x85, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.STA, 0x95, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.STA, 0x8d, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.STA, 0x9d, self.ADDR.ABSX, 3, 5)
	self.set_op(self.INS.STA, 0x99, self.ADDR.ABSY, 3, 5)
	self.set_op(self.INS.STA, 0x81, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.STA, 0x91, self.ADDR.POSTIDXIND, 2, 6)
	
	self.set_op(self.INS.STX, 0x86, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.STX, 0x96, self.ADDR.ZPY, 2, 4)
	self.set_op(self.INS.STX, 0x8e, self.ADDR.ABS, 3, 4)
	
	self.set_op(self.INS.STY, 0x84, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.STY, 0x94, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.STY, 0x8c, self.ADDR.ABS, 3, 4)
	
	self.set_op(self.INS.TAX, 0xaa, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.TAY, 0xa8, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.TSX, 0xba, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.TXA, 0x8a, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.TXS, 0x9a, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.TYA, 0x98, self.ADDR.IMP, 1, 2)
	
	self.set_op(self.INS.ALR, 0x4b, self.ADDR.IMM, 2, 2)
	
	self.set_op(self.INS.ANC, 0x0b, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.ANC, 0x2b, self.ADDR.IMM, 2, 2)
	
	self.set_op(self.INS.ARR, 0x6b, self.ADDR.IMM, 2, 2)
	
	self.set_op(self.INS.AXS, 0xcb, self.ADDR.IMM, 2, 2)
	
	self.set_op(self.INS.LAX, 0xa3, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.LAX, 0xa7, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.LAX, 0xaf, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.LAX, 0xb3, self.ADDR.POSTIDXIND, 2, 5)
	self.set_op(self.INS.LAX, 0xb7, self.ADDR.ZPY, 2, 4)
	self.set_op(self.INS.LAX, 0xbf, self.ADDR.ABSY, 3, 4)
	
	self.set_op(self.INS.SAX, 0x83, self.ADDR.PREIDXIND, 2, 6)
	self.set_op(self.INS.SAX, 0x87, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.SAX, 0x8f, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.SAX, 0x97, self.ADDR.ZPY, 2, 4)
	
	self.set_op(self.INS.DCP, 0xc3, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.DCP, 0xc7, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.DCP, 0xcf, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.DCP, 0xd3, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.DCP, 0xd7, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.DCP, 0xdb, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.DCP, 0xdf, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.ISC, 0xe3, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.ISC, 0xe7, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.ISC, 0xef, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.ISC, 0xf3, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.ISC, 0xf7, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.ISC, 0xfb, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.ISC, 0xff, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.RLA, 0x23, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.RLA, 0x27, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.RLA, 0x2f, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.RLA, 0x33, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.RLA, 0x37, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.RLA, 0x3b, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.RLA, 0x3f, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.RRA, 0x63, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.RRA, 0x67, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.RRA, 0x6f, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.RRA, 0x73, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.RRA, 0x77, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.RRA, 0x7b, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.RRA, 0x7f, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.SLO, 0x03, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.SLO, 0x07, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.SLO, 0x0f, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.SLO, 0x13, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.SLO, 0x17, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.SLO, 0x1b, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.SLO, 0x1f, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.SRE, 0x43, self.ADDR.PREIDXIND, 2, 8)
	self.set_op(self.INS.SRE, 0x47, self.ADDR.ZP, 2, 5)
	self.set_op(self.INS.SRE, 0x4f, self.ADDR.ABS, 3, 6)
	self.set_op(self.INS.SRE, 0x53, self.ADDR.POSTIDXIND, 2, 8)
	self.set_op(self.INS.SRE, 0x57, self.ADDR.ZPX, 2, 6)
	self.set_op(self.INS.SRE, 0x5b, self.ADDR.ABSY, 3, 7)
	self.set_op(self.INS.SRE, 0x5f, self.ADDR.ABSX, 3, 7)
	
	self.set_op(self.INS.SKB, 0x80, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.SKB, 0x82, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.SKB, 0x89, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.SKB, 0xc2, self.ADDR.IMM, 2, 2)
	self.set_op(self.INS.SKB, 0xe2, self.ADDR.IMM, 2, 2)
	
	self.set_op(self.INS.IGN, 0x0c, self.ADDR.ABS, 3, 4)
	self.set_op(self.INS.IGN, 0x1c, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0x3c, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0x5c, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0x7c, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0xdc, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0xfc, self.ADDR.ABSX, 3, 4)
	self.set_op(self.INS.IGN, 0x04, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.IGN, 0x44, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.IGN, 0x64, self.ADDR.ZP, 2, 3)
	self.set_op(self.INS.IGN, 0x14, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.IGN, 0x34, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.IGN, 0x54, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.IGN, 0x74, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.IGN, 0xd4, self.ADDR.ZPX, 2, 4)
	self.set_op(self.INS.IGN, 0xf4, self.ADDR.ZPX, 2, 4)
	
	# prettier ignore
	self.cyc_table = [
		 7,6,2,8,3,3,5,5,3,2,2,2,4,4,6,6, 
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		 6,6,2,8,3,3,5,5,4,2,2,2,4,4,6,6,
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		 6,6,2,8,3,3,5,5,3,2,2,2,3,4,6,6,
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		 6,6,2,8,3,3,5,5,4,2,2,2,5,4,6,6,
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		 2,6,2,6,4,4,4,4,2,5,2,5,5,5,5,5,
		 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		 2,5,2,5,4,4,4,4,2,4,2,4,4,4,4,4,
		 2,6,2,8,3,3,5,5,2,2,2,2,4,4,6,6,
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		 2,6,3,8,3,3,5,5,2,2,2,2,4,4,6,6,
		 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7
	]
	
	self.instname.resize(70)
	# instruction names
	self.instname = [
		'ADC', 'AND', 'ASL', 'BCC', 'BCS', 'BEQ', 'BIT', 
		'BMI', 'BNE', 'BPL', 'BRK', 'BVC', 'BVS', 'CLC', 
		'CLD', 'CLI', 'CLV', 'CMP', 'CPX', 'CPY', 'DEC', 
		'DEX', 'DEY', 'EOR', 'INC', 'INX', 'INY', 'JMP', 
		'JSR', 'LDA', 'LDX', 'LDY', 'LSR', 'NOP', 'ORA', 
		'PHA', 'PHP', 'PLA', 'PLP', 'ROL', 'ROR', 'RTI', 
		'RTS', 'SBC', 'SEC', 'SED', 'SEI', 'STA', 'STX', 
		'STY', 'TAX', 'TAY', 'TSX', 'TXA', 'TXS', 'TYA', 
		'ALR', 'ANC', 'ARR', 'AXS', 'LAX', 'SAX', 'DCP', 
		'ISC', 'RLA', 'RRA', 'SLO', 'SRE', 'SKB', 'IGN'
	]

	self.addr_desc = [
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
	]

func set_op(inst, op, addr, size, cycles):
	self.opdata[op] = (inst & 0xff) | ((addr & 0xff) << 8) | ((size & 0xff) << 16) | ((cycles & 0xff) << 24)
#  setOp: function(inst, op, addr, size, cycles) {
#    this.opdata[op] =
#      (inst & 0xff) |
#      ((addr & 0xff) << 8) |
#      ((size & 0xff) << 16) |
#      ((cycles & 0xff) << 24);
#  }
