# author: hwnzy
# date: 2020.5.16

class_name TILE

var pix = Array()
var fb_index = null
var t_index = null
var x = null
var y = null
var w = null
var h = null
var inc_x = null
var inc_y = null
var pal_index = null
var tpri = null
var c = null
var initialized = false
var opaque = Array()

func _init():
	self.pix.resize(64)
	self.opaque.resize(8)

func set_buffer(scanline):
	self.y = 0
	while self.y < 8:
		self.y += 1
		self.set_scanline(self.y, scanline[self.y], scanline[self.y+8])
		
		

func set_scanline(sline, b1, b2):
	self.initialized = true
	self.t_index = sline << 3
	self.x = 0
	while self.x < 8:
		self.x += 1
		self.pix[self.t_index + self.x] = ((b1 >> (7 - self.x)) & 1) + (((b2 >> (7 - self.x)) & 1) << 1)
		if self.pix[self.t_index + self.x] == 0:
			self.opaque[sline] = false

func render(buffer, srcx1, srcy1, srcx2, srcy2, dx, dy, palAdd, palette, flipHorizontal, flipVertical, pri, priTable):
	if (dx < -7 || dx >= 256 || dy < -7 || dy >= 240):
	  return

	self.w = srcx2 - srcx1
	self.h = srcy2 - srcy1

	if dx < 0:
	  srcx1 -= dx

	if dx + srcx2 >= 256:
	  srcx2 = 256 - dx

	if dy < 0:
	  srcy1 -= dy

	if dy + srcy2 >= 240:
	  srcy2 = 240 - dy

	if (!flipHorizontal && !flipVertical):
		self.fb_index = (dy << 8) + dx
		self.t_index = 0
		self.y = 0
		while self.y < 8:
			self.y += 1
			self.x = 0
			while self.x < 8:
				self.x += 1
				if (self.x >= srcx1 && self.x < srcx2 && self.y >= srcy1 && self.y < srcy2):
					self.pal_index = self.pix[self.t_index]
					self.tpri = priTable[self.fb_index]
					if (self.pal_index != 0 && pri <= (self.tpri & 0xff)):
						buffer[self.fb_index] = palette[self.pal_index + palAdd]
						self.tpri = (self.tpri & 0xf00) | pri
						priTable[self.fb_index] = self.tpri
				self.fb_index += 1
				self.t_index += 1
			self.fb_index -= 8
			self.fb_index += 256
	elif (flipHorizontal && !flipVertical):
		self.fb_index = (dy << 8) + dx
		self.t_index = 7
		self.y = 0
		while self.y < 8:
			self.y += 1
			self.x = 0
			while self.x < 8:
				self.x += 1
				if (self.x >= srcx1 && self.x < srcx2 && self.y >= srcy1 && self.y < srcy2):
					self.pal_index = self.pix[self.t_index]
					self.tpri = priTable[self.fb_index]
					if (self.pal_index != 0 && pri <= (self.tpri & 0xff)):
						buffer[self.fb_index] = palette[self.pal_index + palAdd]
						self.tpri = (self.tpri & 0xf00) | pri
						priTable[self.fb_index] = self.tpri
				self.fb_index += 1
				self.t_index -= 1
			self.fb_index -= 8
			self.fb_index += 256
			self.t_index += 16
	elif (!flipHorizontal && flipVertical):
		self.fb_index = (dy << 8) + dx
		self.t_index = 56
		self.y = 0
		while self.y < 8:
			self.y += 1
			self.x = 0
			while self.x < 8:
				self.x += 1
				if (self.x >= srcx1 && self.x < srcx2 && self.y >= srcy1 && self.y < srcy2):
					self.pal_index = self.pix[self.t_index]
					self.tpri = priTable[self.fb_index]
					if (self.pal_index != 0 && pri <= (self.tpri & 0xff)):
						buffer[self.fb_index] = palette[self.pal_index + palAdd]
						self.tpri = (self.tpri & 0xf00) | pri
						priTable[self.fb_index] = self.tpri
				self.fb_index += 1
				self.t_index += 1
			self.fb_index -= 8
			self.fb_index += 256
			self.t_index -= 16
	else:
		self.fb_index = (dy << 8) + dx
		self.t_index = 63
		self.y = 0
		while self.y < 8:
			self.y += 1
			self.x = 0
			while self.x < 8:
				self.x += 1
				if (self.x >= srcx1 && self.x < srcx2 && self.y >= srcy1 && self.y < srcy2):
					self.pal_index = self.pix[self.t_index]
					self.tpri = priTable[self.fb_index]
					if (self.pal_index != 0 && pri <= (self.tpri & 0xff)):
						buffer[self.fb_index] = palette[self.pal_index + palAdd]
						self.tpri = (self.tpri & 0xf00) | pri
						priTable[self.fb_index] = self.tpri
				self.fb_index += 1
				self.t_index -= 1
			self.fb_index -= 8
			self.fb_index += 256


func is_transparent(x, y):
	return self.pix[(y << 3) + x] == 0













