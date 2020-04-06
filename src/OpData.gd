class_name Opdata

# Generates and  provides an array of details about instructions
var opdata = []
var inst_name = []
var addr_desc = []
var cyc_table = []
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
	DUMMY #  dummy instruction used for 'halting' the processor some cycles
}
enum ADDR {
	ZP, REL, IMP, ABS, ACC, IMM, ZPX, ZPY, ABSX, ABSY, PREIDXIND, POSTIDXIND, INDABS
}

func set_op(inst, op, addr, size, cycles):
	opdata[op] = (inst & 0xff) | ((addr & 0xff) << 8) | ((size & 0xff) << 16) | ((cycles & 0xff) << 24)

func _init():
	opdata.resize(256)
	for i in range(256):
		opdata[i] = 0xff
	# Now fill in all vaild opcodes:
	set_op(INS.ADC, 0x69, ADDR.IMM, 2, 2)
	set_op(INS.ADC, 0x65, ADDR.ZP, 2, 3)
	set_op(INS.ADC, 0x75, ADDR.ZPX, 2, 4)
	set_op(INS.ADC, 0x6d, ADDR.ABS, 3, 4)
	set_op(INS.ADC, 0x7d, ADDR.ABSX, 3, 4)
	set_op(INS.ADC, 0x79, ADDR.ABSY, 3, 4)
	set_op(INS.ADC, 0x61, ADDR.PREIDXIND, 2, 6)
	set_op(INS.ADC, 0x71, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.AND, 0x29, ADDR.IMM, 2, 2)
	set_op(INS.AND, 0x25, ADDR.ZP, 2, 3)
	set_op(INS.AND, 0x35, ADDR.ZPX, 2, 4)
	set_op(INS.AND, 0x2d, ADDR.ABS, 3, 4)
	set_op(INS.AND, 0x3d, ADDR.ABSX, 3, 4)
	set_op(INS.AND, 0x39, ADDR.ABSY, 3, 4)
	set_op(INS.AND, 0x21, ADDR.PREIDXIND, 2, 6)
	set_op(INS.AND, 0x31, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.ASL, 0x0a, ADDR.ACC, 1, 2)
	set_op(INS.ASL, 0x06, ADDR.ZP, 2, 5)
	set_op(INS.ASL, 0x16, ADDR.ZPX, 2, 6)
	set_op(INS.ASL, 0x0e, ADDR.ABS, 3, 6)
	set_op(INS.ASL, 0x1e, ADDR.ABSX, 3, 7)
	set_op(INS.BCC, 0x90, ADDR.REL, 2, 2)
	set_op(INS.BCS, 0xb0, ADDR.REL, 2, 2)
	set_op(INS.BEQ, 0xf0, ADDR.REL, 2, 2)
	set_op(INS.BIT, 0x24, ADDR.ZP, 2, 3)
	set_op(INS.BIT, 0x2c, ADDR.ABS, 3, 4)
	set_op(INS.BMI, 0x30, ADDR.REL, 2, 2)
	set_op(INS.BNE, 0xd0, ADDR.REL, 2, 2)
	set_op(INS.BPL, 0x10, ADDR.REL, 2, 2)
	set_op(INS.BRK, 0x00, ADDR.IMP, 1, 7)
	set_op(INS.BVC, 0x50, ADDR.REL, 2, 2)
	set_op(INS.BVS, 0x70, ADDR.REL, 2, 2)
	set_op(INS.CLC, 0x18, ADDR.IMP, 1, 2)
	set_op(INS.CLD, 0xd8, ADDR.IMP, 1, 2)
	set_op(INS.CLI, 0x58, ADDR.IMP, 1, 2)
	set_op(INS.CLV, 0xb8, ADDR.IMP, 1, 2)
	set_op(INS.CMP, 0xc9, ADDR.IMM, 2, 2)
	set_op(INS.CMP, 0xc5, ADDR.ZP, 2, 3)
	set_op(INS.CMP, 0xd5, ADDR.ZPX, 2, 4)
	set_op(INS.CMP, 0xcd, ADDR.ABS, 3, 4)
	set_op(INS.CMP, 0xdd, ADDR.ABSX, 3, 4)
	set_op(INS.CMP, 0xd9, ADDR.ABSY, 3, 4)
	set_op(INS.CMP, 0xc1, ADDR.PREIDXIND, 2, 6)
	set_op(INS.CMP, 0xd1, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.CPX, 0xe0, ADDR.IMM, 2, 2)
	set_op(INS.CPX, 0xe4, ADDR.ZP, 2, 3)
	set_op(INS.CPX, 0xec, ADDR.ABS, 3, 4)
	set_op(INS.CPY, 0xc0, ADDR.IMM, 2, 2)
	set_op(INS.CPY, 0xc4, ADDR.ZP, 2, 3)
	set_op(INS.CPY, 0xcc, ADDR.ABS, 3, 4)
	set_op(INS.DEC, 0xc6, ADDR.ZP, 2, 5)
	set_op(INS.DEC, 0xd6, ADDR.ZPX, 2, 6)
	set_op(INS.DEC, 0xce, ADDR.ABS, 3, 6)
	set_op(INS.DEC, 0xde, ADDR.ABSX, 3, 7)
	set_op(INS.DEX, 0xca, ADDR.IMP, 1, 2)
	set_op(INS.DEY, 0x88, ADDR.IMP, 1, 2)
	set_op(INS.EOR, 0x49, ADDR.IMM, 2, 2)
	set_op(INS.EOR, 0x45, ADDR.ZP, 2, 3)
	set_op(INS.EOR, 0x55, ADDR.ZPX, 2, 4)
	set_op(INS.EOR, 0x4d, ADDR.ABS, 3, 4)
	set_op(INS.EOR, 0x5d, ADDR.ABSX, 3, 4)
	set_op(INS.EOR, 0x59, ADDR.ABSY, 3, 4)
	set_op(INS.EOR, 0x41, ADDR.PREIDXIND, 2, 6)
	set_op(INS.EOR, 0x51, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.INC, 0xe6, ADDR.ZP, 2, 5)
	set_op(INS.INC, 0xf6, ADDR.ZPX, 2, 6)
	set_op(INS.INC, 0xee, ADDR.ABS, 3, 6)
	set_op(INS.INC, 0xfe, ADDR.ABSX, 3, 7)
	set_op(INS.INX, 0xe8, ADDR.IMP, 1, 2)
	set_op(INS.INY, 0xc8, ADDR.IMP, 1, 2)
	set_op(INS.JMP, 0x4c, ADDR.ABS, 3, 3)
	set_op(INS.JMP, 0x6c, ADDR.INDABS, 3, 5)
	set_op(INS.JSR, 0x20, ADDR.ABS, 3, 6)
	set_op(INS.LDA, 0xa9, ADDR.IMM, 2, 2)
	set_op(INS.LDA, 0xa5, ADDR.ZP, 2, 3)
	set_op(INS.LDA, 0xb5, ADDR.ZPX, 2, 4)
	set_op(INS.LDA, 0xad, ADDR.ABS, 3, 4)
	set_op(INS.LDA, 0xbd, ADDR.ABSX, 3, 4)
	set_op(INS.LDA, 0xb9, ADDR.ABSY, 3, 4)
	set_op(INS.LDA, 0xa1, ADDR.PREIDXIND, 2, 6)
	set_op(INS.LDA, 0xb1, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.LDX, 0xa2, ADDR.IMM, 2, 2)
	set_op(INS.LDX, 0xa6, ADDR.ZP, 2, 3)
	set_op(INS.LDX, 0xb6, ADDR.ZPY, 2, 4)
	set_op(INS.LDX, 0xae, ADDR.ABS, 3, 4)
	set_op(INS.LDX, 0xbe, ADDR.ABSY, 3, 4)
	set_op(INS.LDY, 0xa0, ADDR.IMM, 2, 2)
	set_op(INS.LDY, 0xa4, ADDR.ZP, 2, 3)
	set_op(INS.LDY, 0xb4, ADDR.ZPX, 2, 4)
	set_op(INS.LDY, 0xac, ADDR.ABS, 3, 4)
	set_op(INS.LDY, 0xbc, ADDR.ABSX, 3, 4)
	set_op(INS.LSR, 0x4a, ADDR.ACC, 1, 2)
	set_op(INS.LSR, 0x46, ADDR.ZP, 2, 5)
	set_op(INS.LSR, 0x56, ADDR.ZPX, 2, 6)
	set_op(INS.LSR, 0x4e, ADDR.ABS, 3, 6)
	set_op(INS.LSR, 0x5e, ADDR.ABSX, 3, 7)
	set_op(INS.NOP, 0x1a, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0x3a, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0x5a, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0x7a, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0xda, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0xea, ADDR.IMP, 1, 2)
	set_op(INS.NOP, 0xfa, ADDR.IMP, 1, 2)
	set_op(INS.ORA, 0x09, ADDR.IMM, 2, 2)
	set_op(INS.ORA, 0x05, ADDR.ZP, 2, 3)
	set_op(INS.ORA, 0x15, ADDR.ZPX, 2, 4)
	set_op(INS.ORA, 0x0d, ADDR.ABS, 3, 4)
	set_op(INS.ORA, 0x1d, ADDR.ABSX, 3, 4)
	set_op(INS.ORA, 0x19, ADDR.ABSY, 3, 4)
	set_op(INS.ORA, 0x01, ADDR.PREIDXIND, 2, 6)
	set_op(INS.ORA, 0x11, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.PHA, 0x48, ADDR.IMP, 1, 3)
	set_op(INS.PHP, 0x08, ADDR.IMP, 1, 3)
	set_op(INS.PLA, 0x68, ADDR.IMP, 1, 4)
	set_op(INS.PLP, 0x28, ADDR.IMP, 1, 4)
	set_op(INS.ROL, 0x2a, ADDR.ACC, 1, 2)
	set_op(INS.ROL, 0x26, ADDR.ZP, 2, 5)
	set_op(INS.ROL, 0x36, ADDR.ZPX, 2, 6)
	set_op(INS.ROL, 0x2e, ADDR.ABS, 3, 6)
	set_op(INS.ROL, 0x3e, ADDR.ABSX, 3, 7)
	set_op(INS.ROR, 0x6a, ADDR.ACC, 1, 2)
	set_op(INS.ROR, 0x66, ADDR.ZP, 2, 5)
	set_op(INS.ROR, 0x76, ADDR.ZPX, 2, 6)
	set_op(INS.ROR, 0x6e, ADDR.ABS, 3, 6)
	set_op(INS.ROR, 0x7e, ADDR.ABSX, 3, 7)
	set_op(INS.RTI, 0x40, ADDR.IMP, 1, 6)
	set_op(INS.RTS, 0x60, ADDR.IMP, 1, 6)
	set_op(INS.SBC, 0xe9, ADDR.IMM, 2, 2)
	set_op(INS.SBC, 0xe5, ADDR.ZP, 2, 3)
	set_op(INS.SBC, 0xf5, ADDR.ZPX, 2, 4)
	set_op(INS.SBC, 0xed, ADDR.ABS, 3, 4)
	set_op(INS.SBC, 0xfd, ADDR.ABSX, 3, 4)
	set_op(INS.SBC, 0xf9, ADDR.ABSY, 3, 4)
	set_op(INS.SBC, 0xe1, ADDR.PREIDXIND, 2, 6)
	set_op(INS.SBC, 0xf1, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.SEC, 0x38, ADDR.IMP, 1, 2)
	set_op(INS.SED, 0xf8, ADDR.IMP, 1, 2)
	set_op(INS.SEI, 0x78, ADDR.IMP, 1, 2)
	set_op(INS.STA, 0x85, ADDR.ZP, 2, 3)
	set_op(INS.STA, 0x95, ADDR.ZPX, 2, 4)
	set_op(INS.STA, 0x8d, ADDR.ABS, 3, 4)
	set_op(INS.STA, 0x9d, ADDR.ABSX, 3, 5)
	set_op(INS.STA, 0x99, ADDR.ABSY, 3, 5)
	set_op(INS.STA, 0x81, ADDR.PREIDXIND, 2, 6)
	set_op(INS.STA, 0x91, ADDR.POSTIDXIND, 2, 6)
	set_op(INS.STX, 0x86, ADDR.ZP, 2, 3)
	set_op(INS.STX, 0x96, ADDR.ZPY, 2, 4)
	set_op(INS.STX, 0x8e, ADDR.ABS, 3, 4)
	set_op(INS.STY, 0x84, ADDR.ZP, 2, 3)
	set_op(INS.STY, 0x94, ADDR.ZPX, 2, 4)
	set_op(INS.STY, 0x8c, ADDR.ABS, 3, 4)
	set_op(INS.TAX, 0xaa, ADDR.IMP, 1, 2)
	set_op(INS.TAY, 0xa8, ADDR.IMP, 1, 2)
	set_op(INS.TSX, 0xba, ADDR.IMP, 1, 2)
	set_op(INS.TXA, 0x8a, ADDR.IMP, 1, 2)
	set_op(INS.TXS, 0x9a, ADDR.IMP, 1, 2)
	set_op(INS.TYA, 0x98, ADDR.IMP, 1, 2)
	set_op(INS.ALR, 0x4b, ADDR.IMM, 2, 2)
	set_op(INS.ANC, 0x0b, ADDR.IMM, 2, 2)
	set_op(INS.ANC, 0x2b, ADDR.IMM, 2, 2)
	set_op(INS.ARR, 0x6b, ADDR.IMM, 2, 2)
	set_op(INS.AXS, 0xcb, ADDR.IMM, 2, 2)
	set_op(INS.LAX, 0xa3, ADDR.PREIDXIND, 2, 6)
	set_op(INS.LAX, 0xa7, ADDR.ZP, 2, 3)
	set_op(INS.LAX, 0xaf, ADDR.ABS, 3, 4)
	set_op(INS.LAX, 0xb3, ADDR.POSTIDXIND, 2, 5)
	set_op(INS.LAX, 0xb7, ADDR.ZPY, 2, 4)
	set_op(INS.LAX, 0xbf, ADDR.ABSY, 3, 4)
	set_op(INS.SAX, 0x83, ADDR.PREIDXIND, 2, 6)
	set_op(INS.SAX, 0x87, ADDR.ZP, 2, 3)
	set_op(INS.SAX, 0x8f, ADDR.ABS, 3, 4)
	set_op(INS.SAX, 0x97, ADDR.ZPY, 2, 4)
	set_op(INS.DCP, 0xc3, ADDR.PREIDXIND, 2, 8)
	set_op(INS.DCP, 0xc7, ADDR.ZP, 2, 5)
	set_op(INS.DCP, 0xcf, ADDR.ABS, 3, 6)
	set_op(INS.DCP, 0xd3, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.DCP, 0xd7, ADDR.ZPX, 2, 6)
	set_op(INS.DCP, 0xdb, ADDR.ABSY, 3, 7)
	set_op(INS.DCP, 0xdf, ADDR.ABSX, 3, 7)
	set_op(INS.ISC, 0xe3, ADDR.PREIDXIND, 2, 8)
	set_op(INS.ISC, 0xe7, ADDR.ZP, 2, 5)
	set_op(INS.ISC, 0xef, ADDR.ABS, 3, 6)
	set_op(INS.ISC, 0xf3, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.ISC, 0xf7, ADDR.ZPX, 2, 6)
	set_op(INS.ISC, 0xfb, ADDR.ABSY, 3, 7)
	set_op(INS.ISC, 0xff, ADDR.ABSX, 3, 7)
	set_op(INS.RLA, 0x23, ADDR.PREIDXIND, 2, 8)
	set_op(INS.RLA, 0x27, ADDR.ZP, 2, 5)
	set_op(INS.RLA, 0x2f, ADDR.ABS, 3, 6)
	set_op(INS.RLA, 0x33, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.RLA, 0x37, ADDR.ZPX, 2, 6)
	set_op(INS.RLA, 0x3b, ADDR.ABSY, 3, 7)
	set_op(INS.RLA, 0x3f, ADDR.ABSX, 3, 7)
	set_op(INS.RRA, 0x63, ADDR.PREIDXIND, 2, 8)
	set_op(INS.RRA, 0x67, ADDR.ZP, 2, 5)
	set_op(INS.RRA, 0x6f, ADDR.ABS, 3, 6)
	set_op(INS.RRA, 0x73, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.RRA, 0x77, ADDR.ZPX, 2, 6)
	set_op(INS.RRA, 0x7b, ADDR.ABSY, 3, 7)
	set_op(INS.RRA, 0x7f, ADDR.ABSX, 3, 7)
	set_op(INS.SLO, 0x03, ADDR.PREIDXIND, 2, 8)
	set_op(INS.SLO, 0x07, ADDR.ZP, 2, 5)
	set_op(INS.SLO, 0x0f, ADDR.ABS, 3, 6)
	set_op(INS.SLO, 0x13, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.SLO, 0x17, ADDR.ZPX, 2, 6)
	set_op(INS.SLO, 0x1b, ADDR.ABSY, 3, 7)
	set_op(INS.SLO, 0x1f, ADDR.ABSX, 3, 7)
	set_op(INS.SRE, 0x43, ADDR.PREIDXIND, 2, 8)
	set_op(INS.SRE, 0x47, ADDR.ZP, 2, 5)
	set_op(INS.SRE, 0x4f, ADDR.ABS, 3, 6)
	set_op(INS.SRE, 0x53, ADDR.POSTIDXIND, 2, 8)
	set_op(INS.SRE, 0x57, ADDR.ZPX, 2, 6)
	set_op(INS.SRE, 0x5b, ADDR.ABSY, 3, 7)
	set_op(INS.SRE, 0x5f, ADDR.ABSX, 3, 7)
	set_op(INS.SKB, 0x80, ADDR.IMM, 2, 2)
	set_op(INS.SKB, 0x82, ADDR.IMM, 2, 2)
	set_op(INS.SKB, 0x89, ADDR.IMM, 2, 2)
	set_op(INS.SKB, 0xc2, ADDR.IMM, 2, 2)
	set_op(INS.SKB, 0xe2, ADDR.IMM, 2, 2)
	set_op(INS.IGN, 0x0c, ADDR.ABS, 3, 4)
	set_op(INS.IGN, 0x1c, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0x3c, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0x5c, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0x7c, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0xdc, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0xfc, ADDR.ABSX, 3, 4)
	set_op(INS.IGN, 0x04, ADDR.ZP, 2, 3)
	set_op(INS.IGN, 0x44, ADDR.ZP, 2, 3)
	set_op(INS.IGN, 0x64, ADDR.ZP, 2, 3)
	set_op(INS.IGN, 0x14, ADDR.ZPX, 2, 4)
	set_op(INS.IGN, 0x34, ADDR.ZPX, 2, 4)
	set_op(INS.IGN, 0x54, ADDR.ZPX, 2, 4)
	set_op(INS.IGN, 0x74, ADDR.ZPX, 2, 4)
	set_op(INS.IGN, 0xd4, ADDR.ZPX, 2, 4)
	set_op(INS.IGN, 0xf4, ADDR.ZPX, 2, 4)
	
	# prettier-ignore
	cyc_table = [
		7,6,2,8,3,3,5,5,3,2,2,2,4,4,6,6,  # 0x00
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,  # 0x10
		6,6,2,8,3,3,5,5,4,2,2,2,4,4,6,6,  # 0x20
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,  # 0x30
		6,6,2,8,3,3,5,5,3,2,2,2,3,4,6,6,  # 0x40
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,  # 0x50
		6,6,2,8,3,3,5,5,4,2,2,2,5,4,6,6,  # 0x60
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,  # 0x70
		2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,  # 0x80
		2,6,2,6,4,4,4,4,2,5,2,5,5,5,5,5,  # 0x90
		2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,  # 0xA0
		2,5,2,5,4,4,4,4,2,4,2,4,4,4,4,4,  # 0xB0
		2,6,2,8,3,3,5,5,2,2,2,2,4,4,6,6,  # 0xC0
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,  # 0xD0
		2,6,3,8,3,3,5,5,2,2,2,2,4,4,6,6,  # 0xE0
		2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7   # 0xF0
	]
	inst_name.resize(70)
	# Instruction Names:
	inst_name[0] = "ADC"
	inst_name[1] = "AND"
	inst_name[2] = "ASL"
	inst_name[3] = "BCC"
	inst_name[4] = "BCS"
	inst_name[5] = "BEQ"
	inst_name[6] = "BIT"
	inst_name[7] = "BMI"
	inst_name[8] = "BNE"
	inst_name[9] = "BPL"
	inst_name[10] = "BRK"
	inst_name[11] = "BVC"
	inst_name[12] = "BVS"
	inst_name[13] = "CLC"
	inst_name[14] = "CLD"
	inst_name[15] = "CLI"
	inst_name[16] = "CLV"
	inst_name[17] = "CMP"
	inst_name[18] = "CPX"
	inst_name[19] = "CPY"
	inst_name[20] = "DEC"
	inst_name[21] = "DEX"
	inst_name[22] = "DEY"
	inst_name[23] = "EOR"
	inst_name[24] = "INC"
	inst_name[25] = "INX"
	inst_name[26] = "INY"
	inst_name[27] = "JMP"
	inst_name[28] = "JSR"
	inst_name[29] = "LDA"
	inst_name[30] = "LDX"
	inst_name[31] = "LDY"
	inst_name[32] = "LSR"
	inst_name[33] = "NOP"
	inst_name[34] = "ORA"
	inst_name[35] = "PHA"
	inst_name[36] = "PHP"
	inst_name[37] = "PLA"
	inst_name[38] = "PLP"
	inst_name[39] = "ROL"
	inst_name[40] = "ROR"
	inst_name[41] = "RTI"
	inst_name[42] = "RTS"
	inst_name[43] = "SBC"
	inst_name[44] = "SEC"
	inst_name[45] = "SED"
	inst_name[46] = "SEI"
	inst_name[47] = "STA"
	inst_name[48] = "STX"
	inst_name[49] = "STY"
	inst_name[50] = "TAX"
	inst_name[51] = "TAY"
	inst_name[52] = "TSX"
	inst_name[53] = "TXA"
	inst_name[54] = "TXS"
	inst_name[55] = "TYA"
	inst_name[56] = "ALR"
	inst_name[57] = "ANC"
	inst_name[58] = "ARR"
	inst_name[59] = "AXS"
	inst_name[60] = "LAX"
	inst_name[61] = "SAX"
	inst_name[62] = "DCP"
	inst_name[63] = "ISC"
	inst_name[64] = "RLA"
	inst_name[65] = "RRA"
	inst_name[66] = "SLO"
	inst_name[67] = "SRE"
	inst_name[68] = "SKB"
	inst_name[69] = "IGN"
	addr_desc = [
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
