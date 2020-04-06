# author: hwnzy
# date: 2020.4.6
extends Control
class_name rom

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
var rom_data = null
var header = null  # nes2.0文件头
var rom_count = null  # 以16384(0x4000)字节作为单位的PRG-ROM大小数量
var vrom_count = null  # 以 8192(0x2000)字节作为单位的CHR-ROM大小数量
var mirroring = null  # 镜像水平位，0 = 水平，1 = 垂直
var battery_ram = null  # SRAM标志位，$6000-$7FFF拥有电池供电的SRAM
var trainer = null  # Trainer标志位，1表示 $7000-$71FF加载 Trainer
var four_screen = null  # 四屏标志位，如果改位被设置则忽略镜像标志位
var mapper_type = null  # mapper编号

# Called when the node enters the scene tree for the first time.
func _init():
	load_rom()

func get_header_info(header):
	rom_count = header[4]
	vrom_count = header[5]
	mirroring = 0 if header[6] & 1 == 0 else 1
	battery_ram = header[6] & 2
	trainer = header[6] & 4
	four_screen = header[6] & 8
	mapper_type = (header[6] >> 4) | (header[7] & 0xf0)

func load_rom():
	var file = File.new()
	file.open("res://roms//nestest.nes", File.READ)
	rom_data = file.get_buffer(file.get_len())
	header = rom_data.subarray(0, 15)
	get_header_info(header)
	print(rom_count)
	print(vrom_count)
	file.close()
