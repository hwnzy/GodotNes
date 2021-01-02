# author: hwnzy
# date: 2020.4.12

class_name PPU

var nes = null
var vram_mem = null
var sprite_mem = null
var vram_address = null
var vram_buffered_read_value = null
var vram_tmp_address = null
var first_write = null
var sram_address = null
var current_mirroring = null
var request_end_frame = null
var nmi_ok = null
var dummy_cycle_toggle = null
var valid_tile_data = null
var nmi_counter = null
var scanline_alreay_rendered = null
var f_nmi_on_vblank = null
var f_sprite_size = null
var f_bg_pattern_table = null
var f_sp_pattern_table = null
var f_addr_inc = null
var f_n_tbl_address = null
var f_color = null
var f_sp_visibility = null
var f_bg_visibility = null
var f_sp_clipping = null
var f_bg_clipping = null
var f_dis_type = null
var cnt_fv = null
var cnt_v = null
var cnt_h = null
var cnt_vt = null
var cnt_ht = null
var reg_fv = null
var reg_v = null
var reg_h = null
var reg_ht = null
var reg_fh = null
var reg_s = null
var cur_nt = null
var attrib = null
var buffer = null
var bg_buffer = null
var pixrendered = null
var scantile = null
var scanline = null
var last_rendered_scanline = null
var cur_x = null
var cur_y = null
var spr_x = null
var spr_y = null
var spr_tile = null
var spr_col = null
var vert_flip = null
var hori_flip = null
var bg_priority = null
var spr0_hit_x = null
var spr0_hit_y = null
var hit_spr0 = null
var spr_palette = null
var img_palette = null
var pt_tile = null
var ntable1 = null
var name_table = null
var vram_mirror_table = null
var pal_table = null
# rendering options
var show_spr0_hit = null
var clip_to_tv_size = null

var STATUS_VRAMWRITE = 4
var STATUS_SLSPRITECOUNT =  5
var STATUS_SPRITE0HIT = 6
var STATUS_VBLANK = 7

func _init(nes_class):
	self.nes = nes_class
	self.show_spr0_hit = false
	self.clip_to_tv_size = true

func reset():
	# memory
	self.vram_mem = Array()
	self.vram_mem.resize()
	for i in range(self.vram_mem.size()):
		self.vram_mem[i] = 0
	for i in range(self.sprite_mem.size()):
		self.sprite_mem[i] = 0
	# VRAM I/O
	self.vram_address = null
	self.vram_tmp_address = null
	self.vram_buffered_read_value = 0
	self.first_write = true  # VRAM/Scroll Hi/Lo latch
	# SPR-RAM I/O
	self.sram_address = 0 # 8-bit only
	
	self.current_mirroring = -1
	self.request_end_frame = false
	self.nmi_ok = false
	self.dummy_cycle_toggle = false
	self.valid_tile_data = false
	self.nmi_counter = 0
	self.scanline_alreay_rendered = null
	
	# control flags register 1
	self.f_nmi_on_vblank = 0  # NMI on VBlank. 0=disable, 1=enable
	self.f_sprite_size = 0  # Sprite size. 0=8x8, 1=8x16
	self.f_bg_pattern_table = 0  # background pattern table address. 0=0x0000, 1=0x1000
	self.f_sp_pattern_table = 0  # sprite pattern table address. 0=0x0000,1=0x1000
	self.f_addr_inc = 0  # PPU address increment. 0=1, 1=32
	self.f_n_tbl_address = 0  # name table address. 0=0x2000, 1=0x2400, 2=0x2800, 3=0x2c00
	
	# control flags register 2
	self.f_color = 0  # background color. 0=black, 1=blue, 2=green, 4=red
	self.f_sp_visibility = 0  # sprite visibility. 0=not displayed, 1=displayed
	self.f_bg_visibility = 0  #  Background visibility. 0=Not Displayed,1=displayed
	self.f_sp_clipping = 0  # Sprite clipping. 0=Sprites invisible in left 8-pixel column,1=No clipping
	self.f_bg_clipping = 0  # Background clipping. 0=BG invisible in left 8-pixel column, 1=No clipping
	self.f_dis_type = 0  # Display type. 0=color, 1=monochrome
	
	# counters
	self.cnt_fv = 0
	self.cnt_v = 0
	self.cnt_h = 0
	self.cnt_vt = 0
	self.cnt_ht = 0
	
	# registers
	self.reg_fv = 0
	self.reg_v = 0
	self.reg_h = 0
	self.reg_vt = 0
	self.reg_ht = 0
	self.reg_fh = 0
	self.reg_s = 0
	
	# these are temporary variables used in rendering and sound procedures
	# Their states outside of those procedures can be ignored
	# TODO: the use of this is a bit weird, investigate
	self.cur_nt = null
	
	# variables used when rendering
	self.attrib = Array()
	self.attrib.resize(32)
	self.buffer = Array()
	self.buffer.resize(256*240)
	self.bg_buffer = Array()
	self.bg_buffer.resize(256*240)
	self.pixrendered = Array()
	self.pixrendered.resize(256*240)
	
	self.valid_tile_data = null
	
	self.scantile = Array()
	self.scantile.resize(32)
	
	# initialize misc vars
	self.scanline = 0
	self.last_rendered_scanline = -1
	self.cur_x = 0
	
	# sprite data
	self.spr_x = Array()  # X coordinate
	self.spr_x.resize(64)  
	self.spr_y = Array()  # Y coordinate
	self.spr_y.resize(64)  
	self.spr_tile = Array()  # Tile index (into pattern table)
	self.spr_tile.resize(64)  
	self.spr_col = Array()  # Upper two bits of color# Background priority
	self.spr_col.resize(64)  
	self.vert_flip = Array()  # Vertical Flip
	self.vert_flip.resize(64)
	self.hori_flip = Array()  # Horizontal Flip
	self.hori_flip.resize(64)
	self.bg_priority = Array()  # Background priority
	self.bg_priority.resize(64)
	self.spr0_hit_x = 0  # sprite #0 hit X coordinate
	self.spr0_hit_y = 0  # sprite #0 hit Y coordinate
	self.hit_spr0 = false
	
	# palette data
	self.spr_palette = Array()
	self.spr_palette.resize(16)
	self.img_palette = Array()
	self.img_palette.resize(16)
	
	# create pattern table tile buffers
	self.pt_tile = Array()
	self.pt_tile.resize(512)
	for i in range(512):
		self.pt_tile[i] = TILE.new()
	
	# create nametable buffers
	# name table data
	self.ntable1 = Array()
	self.ntable1.resize(4)
	self.current_mirroring = -1
	self.name_table = Array()
	self.name_table.resize(4)
	for i in range(4):
		self.name_table[i] = NameTable.new(32, 32, "Nt"+str(i))
	
	# Initialize mirroring lookup table:
	self.vram_mirror_table = Array()
	self.vram_mirror_table.resize(0x8000)
	for i in range(0x8000):
		self.vram_mirror_table[i] = i
	
	self.pal_table = PaletteTable.new()
	self.pal_table.load_ntsc_palette()
	
	self.update_control_reg1(0)
	self.update_control_reg2(0)

func trigger_rendering():
	if self.scanline >= 21 && self.scanline <= 260:
		# render sprites, and combine
		self.render_frame_partially(
			self.last_rendered_scanline + 1,
			self.scanline - 21 - self.last_rendered_scanline
		)
		# set last rendered scanline
		self.last_rendered_scanline = self.scanline - 21

func render_sprites_partially(start_scan, scan_count, bg_pri):
	if self.f_sp_visibility == 1:
		for i in range(64):
			if (self.bg_priority[i] == bg_pri &&
				self.spr_x[i] >= 0 &&
				self.spr_x[i] < 256 &&
				self.spr_y[i] + 8 >= start_scan &&
				self.spr_y[i] < start_scan + scan_count
			):
				# show sprite
				if self.f_sprite_size == 0:
					# 8x8 sprites
					var srcy1 = 0
					var srcy2 = 0
					if self.spr_y[i] == start_scan:
						srcy1 = start_scan - self.spr_y[i] - 1
					if self.spr_y[i] + 8 > start_scan + scan_count:
						srcy2 = start_scan + scan_count - self.spr_y[i] + 1
					if self.f_sp_pattern_table == 0:
						self.pt_tile[self.spr_tile[i]].render(
							self.buffer, 0, srcy1, 8, srcy2, 
							self.spr_x[i], self.spr_y[i] + 1, self.spr_col[i],
							self.spr_palette, self.hori_flip[i], self.vert_flip[i],
							i, self.pixrendered
						)
					else:
						self.pt_tile[self.spr_tile[i] + 256].render(
							self.buffer, 0, srcy1, 8, srcy2, 
							self.spr_x[i], self.spr_y[i] + 1, self.spr_col[i],
							self.spr_palette, self.hori_flip[i], self.vert_flip[i],
							i, self.pixrendered
						)
				else:
					# 8x16 sprites
					var top = self.spr_tile[i]
					if ((top & 1) != 0):
						top = self.spr_tile[i] - 1 + 256
					var srcy1 = 0
					var srcy2 = 8
					if (self.spr_y[i] < start_scan):
						srcy1 = start_scan - self.spr_y[i] - 1
					if (self.spr_y[i] + 8 > start_scan + scan_count):
						srcy2 = start_scan + scan_count - self.spr_y[i]
					self.pt_tile[top + 1 if self.vert_flip[i] else 0].render(
						self.buffer, 0, srcy1, 8, srcy2, 
						self.spr_x[i], self.spr_y[i] + 1, self.spr_col[i],
						self.spr_palette, self.hori_flip[i], self.vert_flip[i],
						i, self.pixrendered
					)
					srcy1 = 0
					srcy2 = 8
					if (self.spr_y[i] + 8 < start_scan):
						srcy1 = start_scan - (self.spr_y[i] + 8 + 1)
					if (self.spr_y[i] + 16 > start_scan + scan_count):
						srcy2 = start_scan + scan_count - (self.spr_y[i] + 8)
					self.pt_tile[top + 1 if self.vert_flip[i] else 0].render(
						self.buffer, 0, srcy1, 8, srcy2, 
						self.spr_x[i], self.spr_y[i] + 1 + 8, self.spr_col[i],
						self.spr_palette, self.hori_flip[i], self.vert_flip[i],
						i, self.pixrendered
					)

func render_frame_partially(start_scan, scan_count):
	if self.f_sp_visibility == 1:
		self.render_sprites_partially(start_scan, scan_count, true)
	if self.f_bg_visibility == 1:
		var si = start_scan << 8
		var ei = (start_scan + scan_count) << 8
		if ei > 0xf000:
			ei = 0xf000
		var buffer = self.buffer
		var bg_buffer = self.bg_buffer
		var pix_rendered = self.pixrendered
		for dest_index in range(si):
			if pix_rendered[dest_index] > 0xff:
				buffer[dest_index] = bg_buffer[dest_index]
		if self.f_sp_visibility == 1:
			self.render_sprites_partially(start_scan, scan_count, false)
		self.valid_tile_data = false

# reads data from $3f00 to $f20
# into the two buffered palettes
func update_palettes():
	for i in range(16):
		if self.f_dis_type == 0:
			self.img_palette[i] = self.pal_table.get_entry(self.vram_mem[0x3f00 + i] & 63)
		else:
			self.img_palette[i] = self.pal_table.get_entry(self.vram_mem[0x3f00 + i] & 32)
	for i in range(16):
		if self.f_dis_type == 0:
			self.spr_palette[i] = self.pal_table.get_entry(self.vram_mem[0x3f10 + i] & 63)
		else:
			self.spr_palette[i] = self.pal_table.get_entry(self.vram_mem[0x3f10 + i] & 32)

func update_control_reg1(value):
	self.trigger_rendering()
	self.f_nmi_on_vblank = (value >> 7) & 1
	self.f_sprite_size = (value >> 5) & 1
	self.f_bg_pattern_table = (value >> 4) & 1
	self.f_sp_pattern_table = (value >> 3) & 1
	self.f_addr_inc = (value >> 2) & 1
	self.f_n_tbl_address = value & 3
	
	self.reg_v = (value >> 1) & 1
	self.reg_h = value & 1
	self.reg_s = (value >> 4) & 1

func update_control_reg2(value):
	self.trigger_rendering()
	self.f_color = (value >> 7) & 1
	self.f_sp_visibility = (value >> 5) & 1
	self.f_bg_visibility = (value >> 4) & 1
	self.f_sp_clipping = (value >> 3) & 1
	self.f_bg_clipping = (value >> 2) & 1
	self.f_dis_type = value & 3
	
	if self.f_dis_type == 0:
		self.pal_table.set_emphasis(self.f_color)
	
	self.update_palettes()

# define a mirrored area in the address lookup table.
# Assumes the regions don't overlap
# The 'to' region is the region that is physically in memory.
func define_mirror_region(from_start, to_start, size):
	for i in range(size):
		self.vram_mirror_table[from_start + i] = to_start + i

# sets Nametabe mirroring
func set_mirroring(mirroring):
	if mirroring == self.current_mirroring:
		return
	self.current_mirroring = mirroring
	self.trigger_rendering()
	# remove mirroring
	if self.vram_mirror_table == null:
		self.vram_mirror_table = Array()
		self.vram_mirror_table.resize(0x8000)
	for i in range(0x8000):
		self.vram_mirror_table[i] = i
	# palette mirroring
	self.define_mirror_region(0x3f20, 0x3f00, 0x20)
	self.define_mirror_region(0x3f40, 0x3f00, 0x20)
	self.define_mirror_region(0x3f80, 0x3f00, 0x20)
	self.define_mirror_region(0x3fc0, 0x3f00, 0x20)
	# additional mirroring
	self.define_mirror_region(0x3000, 0x2000, 0xf00)
	self.define_mirror_region(0x4000, 0x0000, 0x4000)
	if mirroring == self.nes.rom.HORIZONTAL_MIRRORING:
		# Horizontal mirroring
		self.ntable1[0] = 0
		self.ntable1[1] = 0
		self.ntable1[2] = 1
		self.ntable1[3] = 1
		
		self.define_mirror_region(0x2400, 0x2000, 0x400)
		self.define_mirror_region(0x2c00, 0x2800, 0x400)
	elif mirroring == self.nes.rom.VERTICAL_MIRRORING:
		# vertical mirroring
		self.ntable1[0] = 0
		self.ntable1[1] = 1
		self.ntable1[2] = 0
		self.ntable1[3] = 1
		
		self.define_mirror_region(0x2800, 0x2000, 0x400)
		self.define_mirror_region(0x2c00, 0x2400, 0x400)
	elif mirroring == self.nes.rom.SINGLESCREEN_MIRRORING:
		# single screen mirroring
		self.ntable1[0] = 0
		self.ntable1[1] = 0
		self.ntable1[2] = 0
		self.ntable1[3] = 0
		
		self.define_mirror_region(0x2400, 0x2000, 0x400)
		self.define_mirror_region(0x2800, 0x2000, 0x400)
		self.define_mirror_region(0x2c00, 0x2000, 0x400)
	elif mirroring == self.nes.rom.SINGLESCREEN_MIRRORING2:
		self.ntable1[0] = 0
		self.ntable1[1] = 0
		self.ntable1[2] = 0
		self.ntable1[3] = 0
		
		self.define_mirror_region(0x2400, 0x2400, 0x400)
		self.define_mirror_region(0x2800, 0x2400, 0x400)
		self.define_mirror_region(0x2c00, 0x2400, 0x400)
	else:
		# assume four-screen mirroring
		self.ntable1[0] = 0
		self.ntable1[1] = 1
		self.ntable1[2] = 2
		self.ntable1[3] = 3

func start_vblank():
	# do NMI
	self.nes.cpu.request_irq(self.nes.cpu.IRQ.NMI)
	# make sure everything is rendered
	if self.last_rendered_scanline < 239:
		self.render_frame_partially(
			self.last_rendered_scanline + 1, 
			240 - self.last_rendered_scanline
		)

func regs_to_address():
	var b1 = (self.reg_fv & 7) << 4
	b1 |= (self.reg_v & 1) << 3
	b1 |= (self.reg_h & 1) << 2
	b1 |= (self.reg_vt >> 3) & 3
	var b2 = (self.reg_vt & 7) << 5
	b2 |= self.reg_ht & 31
	self.vram_tmp_address = ((b1 << 8) | b2) & 0x7fff

# updates the scroll register from a new VRAM address
func regs_from_address():
	var address = (self.vram_tmp_address >> 8) & 0xff
	self.reg_fv = (address >> 4) & 7
	self.reg_v = (address >> 3) & 1
	self.reg_h = (address >> 2) & 1
	self.reg_vt = (self.reg_vt & 7) | ((address & 3) << 3)
	
	address = self.vram_tmp_address & 0xff
	self.reg_vt = (self.reg_vt & 24) | ((address >> 5) & 7)
	self.reg_ht = address & 31

func cnts_to_address():
	var b1 = (self.cnt_fv & 7) << 4
	b1 |= (self.cnt_v & 1) << 3
	b1 |= (self.cnt_h & 1) << 2
	b1 |= (self.cnt_vt >> 3) & 3
	var b2 = (self.cnt_vt & 7) << 5
	b2 |= self.cnt_ht & 31
	self.vram_address = ((b1 << 8) | b2) & 0x7fff

# updates the scroll registers from a new VRAM address
func cnts_from_address():
	var address = (self.vram_address >> 8) & 0xff
	self.cnt_fv = (address >> 4) & 3
	self.cnt_v = (address >> 3) & 1
	self.cnt_h = (address >> 2) & 1
	self.cnt_vt = (self.cnt_vt & 7) | ((address & 3) << 3)
	address = self.vram_address & 0xff
	self.cnt_vt = (self.cnt_vt & 24) | ((address >> 5) & 7)
	self.cnt_ht = address & 31

func set_status_flag(flag, value):
	var n = 1 << flag
	self.nes.cpu.mem[0x2002] = (self.nes.cpu.mem[0x2002] & (255 - n)) | (n if value else 0)

func render_bg_scanline(bgBuffer, scan):
	var base_tile = 0 if self.reg_s == 0 else 256
	var dest_index = (scan << 8) - self.reg_fh
	self.cur_nt = self.ntable1[self.cnt_v + self.cnt_v + self.cnt_h]
	self.cnt_ht = self.reg_ht
	self.cnt_h = self.reg_h
	self.cur_nt = self.ntable1[self.cnt_v + self.cnt_v + self.cnt_h]
	
	if scan < 240 && scan - self.cnt_fv >= 0:
		var tscanoffset = self.cnt_fv << 3
		var scantile = self.scanline
		var attrib = self.attrib
		var pt_tile = self.pt_tile
		var name_table = self.name_table
		var img_palette = self.img_palette
		var pixrendered = self.pixrendered
		var target_buffer = self.bg_buffer if bgBuffer else self.buffer
		var t
		var tpix
		var att
		var col
		for tile in range(32):
			if scan >= 0:
				# fetch tile & attrib data:
				if self.valid_tile_data:
					# get data from array
					t = scantile[tile]
					if not t:
						continue
					tpix = t.pix
					att = attrib[tile]
				else:
					# fetch data
					t = pt_tile[base_tile + name_table[self.cur_nt].get_tile_index(self.cnt_ht, self.cnt_vt)]
					if not t:
						continue
					tpix = t.pix
					att = name_table[self.cur_nt].get_attrib(self.cnt_ht, self.cnt_vt)
					scantile[tile] = t
					attrib[tile] = att
				# render tile scanline
				var sx = 0
				var x = (tile << 3) - self.reg_fh
				if (x > -8):
					if (x < 0):
						dest_index -= x
						sx = -x
					if t.opaque[self.cnt_fv]:
						while sx < 8:
							sx += 1
							target_buffer[dest_index] = img_palette[tpix[tscanoffset + sx] + att]
							pixrendered[dest_index] |= 256
							dest_index += 1
					else:
						while sx < 8:
							sx += 1
							col = tpix[tscanoffset + sx]
							if col != 0:
								target_buffer[dest_index] = img_palette[col + att]
								pixrendered[dest_index] |= 256
							dest_index += 1
			# increase horizontal tile counter
			self.cnt_ht += 1
			if (self.cnt_ht == 32):
				self.cnt_ht = 0
				self.cnt_h += 1
				self.cnt_h %= 2
				self.cur_nt = self.ntable1[(self.cnt_v << 1) + self.cnt_h]
		# tile data for one row should now have been fetched.
		# so the data in the array is vaild
		self.valid_tile_data = true
	# update vertical scroll
	self.cnt_fv += 1
	if self.cnt_fv == 8:
		self.cnt_fv = 0
		self.cnt_vt += 1
		if self.cnt_vt == 30:
			self.cnt_vt = 0
			self.cnt_v += 1
			self.cnt_v %= 2
			self.cur_nt = self.ntable1[(self.cnt_v << 1) + self.cnt_h]
		elif self.cnt_vt == 32:
			self.cnt_vt = 0
		# invaildate fetched data
		self.valid_tile_data = false

func check_sprite0(scan):
	self.spr0_hit_x = -1
	self.spr0_hit_y = -1
	var toffset 
	var t_index_add = 0 if self.f_sp_pattern_table else 256
	var x
	var y
	var t
	var buffer_index
	x = self.spr_x[0]
	y = self.spr_y[0] + 1
	if self.f_sprite_size == 0:
		# 8x8 sprites
		# check range
		if (y <= scan && y + 8 > scan && x >= -7 && x < 256):
			# sprite is in range. Draw scanline
			t = self.pt_tile[self.spr_tile[0] + t_index_add]
			if self.vert_flip[0]:
				toffset = 7 - (scan - y)
			else:
				toffset = scan - y
			toffset *= 8
			buffer_index = scan * 256 + x
			if (self.hori_flip[0]):
				for i in range(7, -1, -1):
					if (x >= 0 && x < 256):
						if buffer_index >= 0 && buffer_index < 61440 && self.pixrendered[buffer_index] != 0:
							if t.pix[toffset + i] != 0:
								self.spr0_hit_x = buffer_index % 256
								self.spr0_hit_y = scan
								return true
					x += 1
					buffer_index += 1
			else:
				for i in range(8):
					if (x >= 0 && x < 256):
						if (
							buffer_index >= 0 &&
							buffer_index < 61440 &&
							self.pixrendered[buffer_index] != 0
						):
							if t.pix[toffset + i] != 0:
								self.spr0_hit_x = buffer_index % 256
								self.spr0_hit_y = scan
								return true
					x += 1
					buffer_index += 1
	else:
		# 8x16 sprites
		# check range
		if (y <= scan && y + 16 > scan && x >= -7 && x < 256):
			# sprite is in range
			# draw scanline
			if (self.vert_flip[0]):
				toffset = 15 - (scan - y)
			else:
				toffset = scan - y
			if toffset < 8:
				# first half of sprite
				t = self.pt_tile[self.spr_tile[0] + (1 if self.vert_flip[0] else 0) + (255 if (self.spr_tile[0] & 1) != 0 else 0)]
			else:
				# second half of sprite
				t = self.pt_tile[self.spr_tile[0] + (0 if self.vert_flip[0] else 1) + (255 if (self.spr_tile[0] & 1) != 0 else 0)]
				if self.vert_flip[0]:
					toffset = 15 - toffset
				else:
					toffset -= 8
			toffset *= 8
			buffer_index = scan * 256 + x
			if self.hori_flip[0]:
				for i in range(7, -1, -1):
					if (x >= 0 && x < 256):
						if (buffer_index >= 0 &&
							buffer_index < 61440 &&
							self.pixrendered[buffer_index] != 0
						):
							if t.pix[toffset + i] != 0:
								self.spr0_hit_x = buffer_index % 256
								self.spr0_hit_y = scan
								return true
					x += 1
					buffer_index += 1
			else:
				for i in range(8):
					if (x >= 0 && x < 256):
						if(
							buffer_index >= 0 &&
							buffer_index < 61440 &&
							self.pixrendered[buffer_index] != 0
						):
							if t.pix[toffset + i] != 0:
								self.spr0_hit_x = buffer_index % 256
								self.spr0_hit_y = scan
								return true
					x += 1
					buffer_index += 1
	
	return false

func end_scanline():
	match self.scanline:
		19: # Dummy scanline. may be variable length
			if self.dummy_cycle_toggle:
				# remove dead cycle at end of scanline for next scanline:
				self.cur_x = 1
				self.dummy_cycle_toggle = !self.dummy_cycle_toggle
		20:  # clear vblank flag
			self.set_status_flag(self.STATUS_VBLANK, false)
			# clear sprite #0 hit flag
			self.set_status_flag(self.STATUS_SPRITE0HIT, false)
			self.hit_spr0 = false
			self.spr0_hit_x = -1
			self.spr0_hit_y = 01
			
			if self.f_bg_visibility == 1 || self.f_sp_visibility == 1:
				# update counters
				self.cnt_fv = self.reg_fv
				self.cnt_v = self.reg_v
				self.cnt_h = self.reg_h
				self.cnt_vt = self.reg_vt
				self.cnt_ht = self.reg_ht
				
				if self.f_bg_visibility == 1:
					# render dummy scanline
					self.render_bg_scanline(false, 0)
			
			if self.f_bg_visibility == 1 && self.f_sp_visibility == 1:
				# check sprite 0 hit for first scanline
				self.check_sprite0(0)
			if self.f_bg_visibility == 1 || self.f_sp_visibility == 1:
				# clock mapper IRQ counter
				self.nes.mmap.clock_irq_counter()
		261:
			# dead scanline, no rendering, set VINT
			self.set_status_flag(self.STATUS_VBLANK, true)
			self.request_end_frame = true
			self.nmi_counter = 0
			# wrap around
			self.scanline = -1  # will be incremented to 0
		_:
			if self.scanline >= 21 && self.scanline <= 260:
				# render normally
				if self.f_bg_visibility == 1:
					if !self.scanline_alreay_rendered:
						# update scroll
						self.cnt_ht = self.reg_ht
						self.cnt_h = self.reg_h
						self.render_bg_scanline(true, self.scanline + 1 - 21)
					self.scanline_alreay_rendered = false
					# check for sprite 0 (next scanline)
					if (!self.hit_spr0 && self.f_sp_visibility == 1):
						if (self.spr_x[0] >= -7 &&
							self.spr_x[0] < 256 &&
							self.spr_y[0] + 1 <= self.scanline - 20 &&
							(self.spr_y[0] + 1 + (8 if self.f_sprite_size == 0 else 16)) >= self.scanline - 20
						):
							if self.check_sprite0(self.scanline - 20):
								self.hit_spr0 = true
				if self.f_bg_visibility == 1 || self.f_sp_visibility == 1:
					# clock maaper IRQ counter
					self.nes.mmap.clock_irq_counter()
	self.scanline += 1
	self.regs_to_address()
	self.cnts_to_address()

func start_frame():
	# set background color
	var bg_color = 0
	if self.f_dis_type == 0:
		# color display
		# f_color determines color emphasis.
		# use first entry of image palette as BG color
		bg_color = self.img_palette[0]
	else:
		# monochrome display
		# f_color determines the bg color
		match self.f_color:
			0: # black
				bg_color = 0x000000
			1: # green
				bg_color = 0x00ff00
			2: # blue
				bg_color = 0xff0000
			3: # invalid. use black
				bg_color = 0x000000
			4: # red
				bg_color = 0x0000ff
			_: # invaild. use black
				bg_color = 0x0
		var buffer = self.buffer
		for i in range(256 * 240):
			buffer[i] = bg_color
		var pixrendered = self.pixrendered
		for i in range(pixrendered.size()):
			self.pixrendered[i] = 65

func end_frame():
	var Buffer = self.buffer
	# draw spr#0 hit coordinates
	if self.show_spr0_hit:
		# spr 0 position
		if(
			self.spr_x[0] >= 0 &&
			self.spr_x[0] < 256 &&
			self.spr_y[0] >= 0 &&
			self.spr_y[0] < 240
		):
			for i in range(256):
				Buffer[(self.spr_y[0] << 8) + i] = 0xff5555
			for i in range(240):
				Buffer[(i << 8) + self.spr_x[0]] = 0xff5555
		# hit position
		if (
			self.spr0_hit_x >= 0 &&
			self.spr0_hit_x < 256 &&
			self.spr0_hit_y >= 0 &&
			self.spr0_hit_y < 240
		):
			for i in range(256):
				Buffer[(self.spr0_hit_y << 8) + i] = 0x55ff55
			for i in range(240):
				Buffer[(i << 8) + self.spr0_hit_x] = 0x55ff55
	# this is a bit lazy
	# if either the sprites or the background should be chipped
	# both are chipped after rendering is finished
	if (
		self.clip_to_tv_size || 
		self.f_bg_clipping == 0 ||
		self.f_sp_clipping == 0
	):
		# clip left 8-pixels column
		for y in range(240):
			for x in range(8):
				Buffer[(y << 8) + x] = 0
	if self.clip_to_tv_size:
		# clip right 8-pixels column too
		for y in range(240):
			for x in range(8):
				Buffer[(y << 8) + 255 - x] = 0
	
	# clip top and bottom 8 pixels
	if self.clip_to_tv_size:
		for y in range(8):
			for x in range(256):
				Buffer[(y << 8) + x] = 0
				Buffer[((239 - y) << 8) + x] = 0
	
	self.nes.ui.write_frame(Buffer)

# updates the internally buffered sprite
# data with this new byte of info.
func sprite_ram_write_update(address, value):
	var t_index = floor(address / 4)
	if t_index == 0:
		self.check_sprite0(self.scanline - 20)
	if address % 4 == 0:
		# Y coordinate
		self.spr_y[t_index] = value
	elif address % 4 == 1:
		# Tile index
		self.spr_tile[t_index] = value
	elif address % 4 == 2:
		# attributes
		self.vert_flip[t_index] = (value & 0x80) != 0
		self.hori_flip[t_index] = (value & 0x40) != 0
		self.bg_priority[t_index] = (value & 0x20) != 0
		self.spr_col[t_index] = (value & 3) << 2
	elif address % 4 == 3:
		# X coordinate
		self.spr_x[t_index] = value

# CPU register $2002: 
# read the status register
func read_status_register():
	var tmp = self.nes.cpu.mem[0x2002]
	# reset scroll & VRAM Address toggle
	self.first_write = true
	# clear vblank flag
	self.set_status_flag(self.STATUS_VBLANK, false)
	# fetch status data
	return tmp

# CPU Register $2003:
# Write the SPR-RAM address that is used for sramWrite (Register 0x2004 in CPU memory map)
func write_sram_address(address):
	self.sram_address = address

# CPU Register $2004 (R):
# Read from SPR-RAM (Sprite RAM).
# The address should be set first.
func sram_load():
	return self.sprite_mem[self.sram_address]

# CPU Register $2004 (W):
# Write to SPR-RAM (Sprite RAM).
# The address should be set first.
func sram_write(value):
	self.sprite_mem[self.sram_address] = value
	self.sprite_ram_write_update(self.sram_address, value)
	self.sram_address += 1  # increment address
	self.sram_address %= 0x100

# CPU Register $2005:
# Write to scroll registers.
# The first write is the vertical offset, the second is the 
# horizontal offset
func scroll_write(value):
	self.trigger_rendering()
	if self.first_write:
		# first write, horizontal scroll
		self.reg_ht = (value >> 3) & 31
		self.reg_fh = value & 7
	else:
		# second write, vertical scroll
		self.reg_fv = value & 7
		self.reg_vt = (value >> 3) & 31
	self.first_write = !self.first_write

# CPU Register $2006
# Sets the address used when reading/writing from/to VRAM
# The first write sets the high byte, the second the low byte.
func write_vram_address(address):
	if self.first_write:
		self.reg_fv = (address >> 4) & 3
		self.reg_v = (address >> 3) & 1
		self.reg_h = (address >> 2) & 1
		self.reg_vt = (self.reg_vt & 7) | ((address & 3) << 3)
	else:
		self.trigger_rendering()
		self.reg_vt = (self.reg_vt & 24) | ((address >> 5) & 7)
		self.reg_ht = address & 31
		
		self.cnt_fv = self.reg_fv
		self.cnt_v = self.reg_v
		self.cnt_h = self.reg_h
		self.cnt_vt = self.reg_vt
		self.cnt_ht = self.reg_ht
		
		self.check_sprite0(self.scanline - 20)
	
	self.first_write = !self.first_write
	# invoke mapper latch
	self.cnts_to_address()
	if (self.vram_address < 0x2000):
		self.nes.mmap.latch_access(self.vram_address)

# updates the internal pattern
# table buffers with this new byte.
# In vNES, there is a version of this with 4 arguments which isn't used
func pattern_write(address, value):
	var tile_index = floor(address / 16)
	var left_over = address % 16
	if left_over < 8:
		self.pt_tile[tile_index].set_scanline(left_over, value, self.vram_mem[address + 8])
	else:
		self.pt_tile[tile_index].set_scanline(left_over-8, self.varm_mem[address-8], value)

# updates the internal name table buffers
# with this new byte
func name_table_write(index, address, value):
	self.name_table[index].tile[address] = value
	# update sprite #0 hit:
	self.check_sprite0(self.scanline - 20)

# update the internal pattern
# table buffers with this new attribute
# table byte.
func attrib_table_write(index, address, value):
	self.name_table[index].write_attrib(address, value)

# this will write to PPU memory, and
# update internally buffered data appropriately
func write_mem(address, value):
	self.vram_mem[address] = value;
	
	# Update internally buffered data:
	if (address < 0x2000):
		self.vramMem[address] = value
		self.pattern_write(address, value)
	elif (address >= 0x2000 && address < 0x23c0):
		self.name_table_write(self.ntable1[0], address - 0x2000, value)
	elif (address >= 0x23c0 && address < 0x2400):
		self.attrib_table_write(self.ntable1[0], address - 0x23c0, value)
	elif (address >= 0x2400 && address < 0x27c0):
		self.name_table_write(self.ntable1[1], address - 0x2400, value)
	elif (address >= 0x27c0 && address < 0x2800):
		self.attrib_table_write(self.ntable1[1], address - 0x27c0, value)
	elif (address >= 0x2800 && address < 0x2bc0):
		self.name_table_write(self.ntable1[2], address - 0x2800, value)
	elif (address >= 0x2bc0 && address < 0x2c00):
		self.attrib_table_write(self.ntable1[2], address - 0x2bc0, value)
	elif (address >= 0x2c00 && address < 0x2fc0):
		self.name_table_write(self.ntable1[3], address - 0x2c00, value)
	elif (address >= 0x2fc0 && address < 0x3000):
		self.attrib_table_write(self.ntable1[3], address - 0x2fc0, value)
	elif (address >= 0x3f00 && address < 0x3f20):
		self.update_palettes()


# reads from memory, taking into account
# mirroring/mapping of address ranges
func mirrored_load(address):
	return self.vram_mem[self.vram_mirror_table[address]]


# writes to memory, taking into account
# mirroring/mapping of address ranges
func mirrored_write(address, value):
	if address >= 0x3f00 && address < 0x3f20:
		# palette write mirroring
		if (address == 0x3f00 || address == 0x3f10):
			self.write_mem(0x3f00, value)
			self.write_mem(0x3f10, value)
		elif (address == 0x3f04 || address == 0x3f14):
			self.write_mem(0x3f04, value)
			self.write_mem(0x3f14, value)
		elif (address == 0x3f08 || address == 0x3f18):
			self.write_mem(0x3f08, value)
			self.write_mem(0x3f18, value)
		elif (address == 0x3f0c || address == 0x3f1c):
			self.write_mem(0x3f0c, value)
			self.write_mem(0x3f1c, value)
		else:
			self.write_mem(address, value)
	else:
		# use lookup table for mirrored address
		if address < self.vram_mirror_table.size():
			self.write_mem(self.vram_mirror_table[address], value)
		else:
			print("Invalid VRAM address: " + str(address))


# CPU Register $2007(R):
# Read from PPU memory. The address should be set first
func vram_load():
	var tmp
	self.cnts_to_address()
	self.regs_to_address()
	# if address is in range 0x0000-0x3EFF, return buffered values:
	if (self.vram_address <= 0x3eff):
		tmp = self.vram_buffered_read_value
		# update buffered value
		if (self.vram_address < 0x2000):
			self.vram_buffered_read_value = self.vram_mem[self.vram_address]
		else:
			self.vram_buffered_read_value = self.mirrored_load(self.vram_address)
		# mapper latch access
		if self.vram_address < 0x2000:
			self.nes.mmap.latch_access(self.vram_address)
		# increment by either 1 or 32, depending on d2 of control register 1:
		self.vram_address += 32 if self.f_addr_inc else 1
		self.cnts_from_address()
		self.regs_from_address()
		return tmp  # return the previous buffered value
	# no buffering in this mem range, read normally
	tmp = self.mirrored_load(self.vram_address)
	# increment by either 1 or 32, depending on d2 of control register 1:
	self.vram_address += 32 if self.f_addr_inc else 1
	self.cnts_from_address()
	self.regs_from_address()
	return tmp 


# CPU Register $2007(W):
# write to PPU memory, The address should be set first.
func vram_write(value):
	self.trigger_rendering()
	self.cnts_to_address()
	self.regs_to_address()
	
	if self.vram_address >= 0x2000:
		# mirroring is used
		self.mirrored_write(self.vram_address, value)
	else:
		# write normally
		self.write_mem(self.vram_address, value)
		# invoke mapper latch
		self.nes.mmap.latch_access(self.vram_address)
	# increment by either 1 or 32, depending on d2 of control register 1
	self.vram_address += 32 if self.f_addr_in == 1 else 1
	self.regs_from_address()
	self.cnts_from_address()

# CPU Register $4014
# write 256 bytes of main memory
# into sprite RAM
func sram_DMA(value):
	var base_address = value * 0x100
	var data
	for i in range(self.sram_address, 256):
		data = self.nes.cpu.mem[base_address + i]
		self.sprite_mem[i] = data
		self.sprite_ram_write_update(i, data)
	self.nes.cpu.halt_cycles(513)

func inc_tile_counter(count):
	for _i in range(count, 0, -1):
		self.cnt_ht += 1
		if self.cnt_ht == 32:
			self.cnt_ht = 0
			self.cnt_vt += 1
			if self.cnt_vt >= 30:
				self.cnt_h += 1
				if self.cnt_h == 2:
					self.cnt_h = 0
					self.cnt_v += 1
					if self.cnt_v == 2:
						self.cnt_v = 0
						self.cnt_fv += 1
						self.cnt_fv &= 0x7

func do_NMI():
	# set VBlank flag
	self.set_status_flag(self.STATUS_VBLANK, true)
	self.nes.cpu.request_irq(self.nes.cpu.IRQ.NMI)

func is_pixel_white(x, y):
	self.trigger_rendering()
	return self.nes.ppu.buffer[(y << 8) + x] == 0xffffff

class NameTable:
	var width = null
	var height = null
	var name = null
	var tile = null
	var attrib = null
	
	func _init(Width, Height, Name):
		self.width = Width
		self.height = Height
		self.name = Name
		self.tile = Array()
		self.tile.resize(Width * Height)
		self.attrib = Array()
		self.attrib.resize(Width * Height)
		for i in range(Width * Height):
			self.tile[i] = 0
			self.attrib[i] = 0
	
	func get_tile_index(x, y):
		return self.tile[y * self.width + x]
	
	func get_attrib(x, y):
		return self.attrib[y * self.width + x]
	
	func write_attrib(index, value):
		var basex = (index % 8) * 4
		var basey = floor(index / 8) * 4
		var add
		var tx
		var ty
		var attindex
		for sqy in range(2):
			for sqx in range(2):
				add = (value >> (2 * (sqy *2 + sqx))) & 3
				for y in range(2):
					for x in range(2):
						tx = basex + sqx * 2 + x
						ty = basey + sqy * 2 + y
						attindex = ty * self.width + tx
						self.attrib[attindex] = (add << 2) & 12

class PaletteTable:
	var cur_table = null
	var emph_table = null
	var current_emph = -1
	
	func _init():
		self.cur_table = Array()
		self.cur_table.resize(64)
		self.emph_table = Array()
		self.emph_table.resize(8)
		self.current_emph = -1
	
	func reset():
		self.set_emphasis(0)
	
	func load_ntsc_palette():
		# prettier-ignore
		self.cur_table = [
			0x525252, 0xB40000, 0xA00000, 0xB1003D, 0x740069, 0x00005B, 
			0x00005F, 0x001840, 0x002F10, 0x084A08, 0x006700, 0x124200, 
			0x6D2800, 0x000000, 0x000000, 0x000000, 0xC4D5E7, 0xFF4000, 
			0xDC0E22, 0xFF476B, 0xD7009F, 0x680AD7, 0x0019BC, 0x0054B1, 
			0x006A5B, 0x008C03, 0x00AB00, 0x2C8800, 0xA47200, 0x000000, 
			0x000000, 0x000000, 0xF8F8F8, 0xFFAB3C, 0xFF7981, 0xFF5BC5, 
			0xFF48F2, 0xDF49FF, 0x476DFF, 0x00B4F7, 0x00E0FF, 0x00E375, 
			0x03F42B, 0x78B82E, 0xE5E218, 0x787878, 0x000000, 0x000000, 
			0xFFFFFF, 0xFFF2BE, 0xF8B8B8, 0xF8B8D8, 0xFFB6FF, 0xFFC3FF, 
			0xC7D1FF, 0x9ADAFF, 0x88EDF8, 0x83FFDD, 0xB8F8B8, 0xF5F8AC, 
			0xFFFFB0, 0xF8D8F8, 0x000000, 0x000000
		]
		self.make_tables()
		self.set_emphasis(0)
	
	func set_emphasis(emph):
		if emph != self.current_emph:
			self.current_emph = emph
			for i in range(64):
				self.cur_table[i] = self.emph_table[emph][i]
	
	func make_tables():
		var r
		var g
		var b
		var col
		var r_factor
		var g_factor
		var b_factor
		# calculate a table for each possible emphasis setting
		for emph in range(8):
			# delermine color component factors
			r_factor = 1.0
			g_factor = 1.0
			b_factor = 1.0
			if ((emph & 1) != 0):
				r_factor = 0.75
				b_factor = 0.75
			if ((emph & 2) != 0):
				r_factor = 0.75
				g_factor = 0.75
			if ((emph & 4) != 0):
				g_factor = 0.75
				b_factor = 0.75
			self.emph_table[emph] = Array()
			self.emph_table[emph].resize(64)
			# calculate table:
			for i in range(64):
				col = self.cur_table[i]
				r = floor(self.get_red(col) * r_factor)
				g = floor(self.get_green(col) * g_factor)
				b = floor(self.get_blue(col) * b_factor)
				self.emph_table[emph][i] = self.get_rgb(r, g, b)
	
	func get_entry(yiq):
		return self.cur_table[yiq]
	
	func get_red(rgb):
		return (rgb >> 16) & 0xff
	
	func get_green(rgb):
		return (rgb >> 8) & 0xff
	
	func get_blue(rgb):
		return rgb & 0xff

	func get_rgb(r, g, b):
		return (r << 16) | (g << 8) | b
	
	func load_default_palette():
		self.cur_table[0] = self.get_rgb(117, 117, 117);
		self.cur_table[1] = self.get_rgb(39, 27, 143);
		self.cur_table[2] = self.get_rgb(0, 0, 171);
		self.cur_table[3] = self.get_rgb(71, 0, 159);
		self.cur_table[4] = self.get_rgb(143, 0, 119);
		self.cur_table[5] = self.get_rgb(171, 0, 19);
		self.cur_table[6] = self.get_rgb(167, 0, 0);
		self.cur_table[7] = self.get_rgb(127, 11, 0);
		self.cur_table[8] = self.get_rgb(67, 47, 0);
		self.cur_table[9] = self.get_rgb(0, 71, 0);
		self.cur_table[10] = self.get_rgb(0, 81, 0);
		self.cur_table[11] = self.get_rgb(0, 63, 23);
		self.cur_table[12] = self.get_rgb(27, 63, 95);
		self.cur_table[13] = self.get_rgb(0, 0, 0);
		self.cur_table[14] = self.get_rgb(0, 0, 0);
		self.cur_table[15] = self.get_rgb(0, 0, 0);
		self.cur_table[16] = self.get_rgb(188, 188, 188);
		self.cur_table[17] = self.get_rgb(0, 115, 239);
		self.cur_table[18] = self.get_rgb(35, 59, 239);
		self.cur_table[19] = self.get_rgb(131, 0, 243);
		self.cur_table[20] = self.get_rgb(191, 0, 191);
		self.cur_table[21] = self.get_rgb(231, 0, 91);
		self.cur_table[22] = self.get_rgb(219, 43, 0);
		self.cur_table[23] = self.get_rgb(203, 79, 15);
		self.cur_table[24] = self.get_rgb(139, 115, 0);
		self.cur_table[25] = self.get_rgb(0, 151, 0);
		self.cur_table[26] = self.get_rgb(0, 171, 0);
		self.cur_table[27] = self.get_rgb(0, 147, 59);
		self.cur_table[28] = self.get_rgb(0, 131, 139);
		self.cur_table[29] = self.get_rgb(0, 0, 0);
		self.cur_table[30] = self.get_rgb(0, 0, 0);
		self.cur_table[31] = self.get_rgb(0, 0, 0);
		self.cur_table[32] = self.get_rgb(255, 255, 255);
		self.cur_table[33] = self.get_rgb(63, 191, 255);
		self.cur_table[34] = self.get_rgb(95, 151, 255);
		self.cur_table[35] = self.get_rgb(167, 139, 253);
		self.cur_table[36] = self.get_rgb(247, 123, 255);
		self.cur_table[37] = self.get_rgb(255, 119, 183);
		self.cur_table[38] = self.get_rgb(255, 119, 99);
		self.cur_table[39] = self.get_rgb(255, 155, 59);
		self.cur_table[40] = self.get_rgb(243, 191, 63);
		self.cur_table[41] = self.get_rgb(131, 211, 19);
		self.cur_table[42] = self.get_rgb(79, 223, 75);
		self.cur_table[43] = self.get_rgb(88, 248, 152);
		self.cur_table[44] = self.get_rgb(0, 235, 219);
		self.cur_table[45] = self.get_rgb(0, 0, 0);
		self.cur_table[46] = self.get_rgb(0, 0, 0);
		self.cur_table[47] = self.get_rgb(0, 0, 0);
		self.cur_table[48] = self.get_rgb(255, 255, 255);
		self.cur_table[49] = self.get_rgb(171, 231, 255);
		self.cur_table[50] = self.get_rgb(199, 215, 255);
		self.cur_table[51] = self.get_rgb(215, 203, 255);
		self.cur_table[52] = self.get_rgb(255, 199, 255);
		self.cur_table[53] = self.get_rgb(255, 199, 219);
		self.cur_table[54] = self.get_rgb(255, 191, 179);
		self.cur_table[55] = self.get_rgb(255, 219, 171);
		self.cur_table[56] = self.get_rgb(255, 231, 163);
		self.cur_table[57] = self.get_rgb(227, 255, 163);
		self.cur_table[58] = self.get_rgb(171, 243, 191);
		self.cur_table[59] = self.get_rgb(179, 255, 207);
		self.cur_table[60] = self.get_rgb(159, 255, 243);
		self.cur_table[61] = self.get_rgb(0, 0, 0);
		self.cur_table[62] = self.get_rgb(0, 0, 0);
		self.cur_table[63] = self.get_rgb(0, 0, 0);
		
		self.make_tables();
		self.set_emphasis(0);

