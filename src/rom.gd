# author: hwnzy
# date: 2020.4.6
class_name ROM
#	 0-3: string    "NES"<EOF>
#	   4: byte      以16384(0x4000)字节作为单位的PRG-ROM大小数量
#	   5: byte      以 8192(0x2000)字节作为单位的CHR-ROM大小数量
#	   6: bitfield  Flags 6
#	   7: bitfield  Flags 7
#	8-15: byte      保留用, 应该为0. 其实有些在用了, 目前不管
#	Flags 6:
#	7       0
#	---------
#	NNNN FTBM
#
#	N: Mapper编号低4位
#	F: 4屏标志位. (如果该位被设置, 则忽略M标志)
#	T: Trainer标志位.  1表示 $7000-$71FF加载 Trainer
#	B: SRAM标志位 $6000-$7FFF拥有电池供电的SRAM.
#	M: 镜像标志位.  0 = 水平, 1 = 垂直.
#
#	Byte 7 (Flags 7):
#	7       0
#	---------
#	NNNN xxPV
#
#	N: Mapper编号高4位
#	P: Playchoice 10标志位. 被设置则表示为PC-10游戏
#	V: Vs. Unisystem标志位. 被设置则表示为Vs.  游戏
#	x: 未使用
var nes = null
var offset = null
var rom_data = Array()
var header = Array()  # nes2.0文件头
var rom = Array()
var vrom = Array()
var vrom_tile = Array()
var mapperName = Array()
var length = null
var rom_count = null  # 以16384(0x4000)字节作为单位的PRG-ROM大小数量
var vrom_count = null  # 以 8192(0x2000)字节作为单位的CHR-ROM大小数量
var mirroring = null  # 镜像水平位，0 = 水平，1 = 垂直
var battery_ram = null  # SRAM标志位，$6000-$7FFF拥有电池供电的SRAM
var trainer = null  # Trainer标志位，1表示 $7000-$71FF加载 Trainer
var four_screen = null  # 四屏标志位，如果改位被设置则忽略镜像标志位
var mapper_type = null  # mapper编号

enum MIRRORING_TYPES {
	VERTICAL_MIRRORING, HORIZONTAL_MIRRORING, FOURSCREEN_MIRRORING, SINGLESCREEN_MIRRORING,
	SINGLESCREEN_MIRRORING2, SINGLESCREEN_MIRRORING3, SINGLESCREEN_MIRRORING4, CHRROM_MIRRORING
	}

# Called when the node enters the scene tree for the first time.
func _init(nes_class):
	self.nes = nes_class
	self.mapperName.resize(92)
	
	for i in range(92):
		self.mapperName[i] = "Unknown Mapper"
	
	self.mapperName[0] = "Direct Access"
	self.mapperName[1] = "Nintendo MMC1"
	self.mapperName[2] = "UNROM"
	self.mapperName[3] = "CNROM"
	self.mapperName[4] = "Nintendo MMC3"
	self.mapperName[5] = "Nintendo MMC5"
	self.mapperName[6] = "FFE F4xxx"
	self.mapperName[7] = "AOROM"
	self.mapperName[8] = "FFE F3xxx"
	self.mapperName[9] = "Nintendo MMC2"
	self.mapperName[10] = "Nintendo MMC4"
	self.mapperName[11] = "Color Dreams Chip"
	self.mapperName[12] = "FFE F6xxx"
	self.mapperName[15] = "100-in-1 switch"
	self.mapperName[16] = "Bandai chip"
	self.mapperName[17] = "FFE F8xxx"
	self.mapperName[18] = "Jaleco SS8806 chip"
	self.mapperName[19] = "Namcot 106 chip"
	self.mapperName[20] = "Famicom Disk System"
	self.mapperName[21] = "Konami VRC4a"
	self.mapperName[22] = "Konami VRC2a"
	self.mapperName[23] = "Konami VRC2a"
	self.mapperName[24] = "Konami VRC6"
	self.mapperName[25] = "Konami VRC4b"
	self.mapperName[32] = "Irem G-101 chip"
	self.mapperName[33] = "Taito TC0190/TC0350"
	self.mapperName[34] = "32kB ROM switch"
	
	self.mapperName[64] = "Tengen RAMBO-1 chip"
	self.mapperName[65] = "Irem H-3001 chip"
	self.mapperName[66] = "GNROM switch"
	self.mapperName[67] = "SunSoft3 chip"
	self.mapperName[68] = "SunSoft4 chip"
	self.mapperName[69] = "SunSoft5 FME-7 chip"
	self.mapperName[71] = "Camerica chip"
	self.mapperName[78] = "Irem 74HC161/32-based"
	self.mapperName[91] = "Pirate HK-SF3 chip"


func load(data):
	self.offset = 0
	self.length = rom_data.size()
	self.offset = 16
	self.header.resize(self.offset)
	for i in range(self.offset):
		self.header[i] = data[i] & 0xff
	self.get_header_info()
	self.load_prg_rom()  # load PRG-ROM banks
	self.load_chr_rom()
	self.create_vrom_tile()
	

func get_header_info():
	self.rom_count = self.header[4]
	self.vrom_count = self.header[5] * 2 # Get the number of 4kB banks, not 8kB
	self.mirroring = 0 if self.header[6] & 1 == 0 else 1
	self.battery_ram = self.header[6] & 2
	self.trainer = self.header[6] & 4
	self.four_screen = self.header[6] & 8
	self.mapper_type = (self.header[6] >> 4) | (self.header[7] & 0xf0)

func load_prg_rom():
	self.rom = Array()
	self.rom.resize(self.rom_count)
	for i in range(self.rom_count):
		self.rom[i] = Array()
		self.rom[i].resize(16384)
		for j in range(16384):
			if self.offset + j >= self.length:
				break
			self.rom[i][j] = self.rom_data[self.offset+j] & 0xff
		self.offset += 16384

func load_chr_rom():
	self.vrom = Array()
	self.vrom.resize(self.vrom_count)
	for i in range(self.vrom_count):
		self.vrom[i] = Array()
		self.vrom[i].resize(4096)
		for j in range(4096):
			if self.offset + j >= self.length:
				break
			self.vrom[i][j] = self.rom_data[self.offset+j] & 0xff
		offset += 4096

func create_vrom_tile():
	self.vrom_tile = Array()
	for i in range(self.vrom_count):
		self.vrom_tile[i] = Array()
		self.vrom_tile.resize(256)
		for j in range(256):
			self.vrom_tile[i][j] = TILE.new()

func convert_chr_rom_banks_to_tiles():
	var tile_index
	var left_over
	for v in range(self.vrom_count):
		for i in range(4096):
			tile_index = i >> 4
			left_over = i % 16
			if left_over < 8:
				self.vrom_tile[v][tile_index].set_scanline(
					left_over,
					self.vrom[v][i],
					self.vrom[v][i + 8]
				)
			else:
				self.vrom_tile[v][tile_index].set_scanline(
					left_over-8,
					self.vrom[v][i-8],
					self.vrom[v][i]
				)

func get_mirroring_type():
	if self.four_screen:
		return self.MIRRORING_TYPES.FOURSCREEN_MIRRORING
	if self.mirroring == 0:
		return self.MIRRORING_TYPES.HORIZONTAL_MIRRORING
	return self.MIRRORING_TYPES.VERTICAL_MIRRORING

func get_mapper_name():
	if self.mapper_type >= 0 && self.mapper_type < self.mapperName.size():
		return self.mapperName[self.mapper_type]
	return "Unknown Mapper, " + self.mapperType
	
func mapper_supported():
	return self.mapperName[self.mapper_type] != "undefined"

func create_mapper():
	if self.mapper_supported():
		return
	else:
		print('error')
