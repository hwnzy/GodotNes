# author: hwnzy
# date: 2020.4.12

class_name PAPU

var CPU_FREQ_NTSC = 1789772.5  # 1789772.72727272d
var nes = null
var square1 = null
var square2 = null
var triangle = null
var noise = null
var dmc = null
var frame_irq_counter = null
var frame_irq_counter_max = null
var init_counter = null
var channel_enable_value = null
var sample_rate = null
var length_lookup = null
var dmc_freq_lookup = null
var noise_wave_length_lookup = null
var square_table = null
var tnd_table = null
var frame_irq_enabled = null
var frame_irq_active = null
var frame_clock_now = null
var started_playing = null
var record_output = null
var initing_hardware = null
var master_frame_counter = null
var derived_frame_counter = null
var count_sequence = null
var sample_timer = null
var frame_time = null
var sample_timer_max = null
var sample_count = null
var tri_value = 0
var smp_square1 = null
var smp_square2 = null
var smp_triangle = null
var smp_dmc = null
var acc_count = null
# dc removal vars
var prev_sample_L = null
var prev_sample_R = null
var smp_accum_L = null
var smp_accum_R = null
# dac range
var dac_range = null
var dc_value = null
# master volume
var master_volume = null
# stereo positioning
var stereo_posL_square1 = null
var stereo_posL_square2 = null
var stereo_posL_triangle = null
var stereo_posL_noise = null
var stereo_posL_DMC = null
var stereo_posR_square1 = null
var stereo_posR_square2 = null
var stereo_posR_triangle = null
var stereo_posR_noise = null
var stereo_posR_DMC = null

var extra_cycles = null
var max_sample = null
var min_sample = null

# panning
var panning = null


func _init(nes_class):
	self.nes = nes_class
	self.square1 = ChannelSquare.new(self, true)
	self.square2 = ChannelSquare.new(self, false)
	self.triangle = ChannelTriangle.new(self)
	self.noise = ChannelNoise.new(self)
	self.dmc = ChannelDM.new(self)
	
	self.frame_irq_counter_max = 4
	self.init_counter = 2048
	self.sample_rate = 44100
	self.frame_irq_enabled = false
	self.started_playing = false
	self.record_output = false
	self.initing_hardware = false
	self.tri_value = 0
	self.prev_sample_L = 0
	self.prev_sample_R = 0
	self.smp_accum_L = 0
	self.smp_accum_R = 0
	self.dac_range = 0
	self.dc_value = 0
	self.master_volume = 256
	self.panning = [80, 170, 100, 150, 128]
	self.set_panning(self.panning)
	# initialize lookup tables
	self.init_length_lookup()
	self.init_dmc_frequency_lookup()
	self.init_noise_wave_length_lookup()
	self.init_dac_tables()
	# init sound registers
	for i in range(0x14):
		if i == 0x10:
			self.write_reg(0x4010, 0x10)
		else:
			self.write_reg(0x4000 + i, 0)
	self.reset()

func init_length_lookup():
	# prettier-ignore
	self.length_lookup = [
		0x0A, 0xFE,
		0x14, 0x02,
		0x28, 0x04,
		0x50, 0x06,
		0xA0, 0x08,
		0x3C, 0x0A,
		0x0E, 0x0C,
		0x1A, 0x0E,
		0x0C, 0x10,
		0x18, 0x12,
		0x30, 0x14,
		0x60, 0x16,
		0xC0, 0x18,
		0x48, 0x1A,
		0x10, 0x1C,
		0x20, 0x1E
	]

func init_dmc_frequency_lookup():
	self.dmc_freq_lookup = Array()
	self.dmc_freq_lookup.resize(16)
	self.dmc_freq_lookup[0x0] = 0xd60
	self.dmc_freq_lookup[0x1] = 0xbe0
	self.dmc_freq_lookup[0x2] = 0xaa0
	self.dmc_freq_lookup[0x3] = 0xa00
	self.dmc_freq_lookup[0x4] = 0x8f0
	self.dmc_freq_lookup[0x5] = 0x7f0
	self.dmc_freq_lookup[0x6] = 0x710
	self.dmc_freq_lookup[0x7] = 0x6b0
	self.dmc_freq_lookup[0x8] = 0x5f0
	self.dmc_freq_lookup[0x9] = 0x500
	self.dmc_freq_lookup[0xa] = 0x470
	self.dmc_freq_lookup[0xb] = 0x400
	self.dmc_freq_lookup[0xc] = 0x350
	self.dmc_freq_lookup[0xd] = 0x2a0
	self.dmc_freq_lookup[0xe] = 0x240
	self.dmc_freq_lookup[0xf] = 0x1b0

func init_noise_wave_length_lookup():
	self.noise_wave_length_lookup = Array()
	self.noise_wave_length_lookup.resize(16)
	self.noise_wave_length_lookup[0x0] = 0x004
	self.noise_wave_length_lookup[0x1] = 0x008
	self.noise_wave_length_lookup[0x2] = 0x010
	self.noise_wave_length_lookup[0x3] = 0x020
	self.noise_wave_length_lookup[0x4] = 0x040
	self.noise_wave_length_lookup[0x5] = 0x060
	self.noise_wave_length_lookup[0x6] = 0x080
	self.noise_wave_length_lookup[0x7] = 0x0a0
	self.noise_wave_length_lookup[0x8] = 0x0ca
	self.noise_wave_length_lookup[0x9] = 0x0fe
	self.noise_wave_length_lookup[0xa] = 0x17c
	self.noise_wave_length_lookup[0xb] = 0x1fc
	self.noise_wave_length_lookup[0xc] = 0x2fa
	self.noise_wave_length_lookup[0xd] = 0x3f8
	self.noise_wave_length_lookup[0xe] = 0x7f2
	self.noise_wave_length_lookup[0xf] = 0xfe4

func init_dac_tables():
	var value
	var ival
	var i
	var max_sqr = 0
	var max_tnd = 0
	self.square_table = Array()
	self.square_table.resize(32*16)
	self.tnd_table = Array()
	self.tnd_table.resize(204*16)
	for i in range(32*16):
		value = 95.52 / (8128.0 / (i / 16.0) + 100.0)
		value *= 0.98411
		value *= 50000.0
		ival = floor(value)
		self.square_table[i] = ival
		if (ival > max_sqr):
			max_sqr = ival
	for i in range(204*16):
		value = 163.67 / (24329.0 / (i / 16.0) + 100.0)
		value *= 0.98411
		value *= 50000.0
		ival = floor(value)
		self.tnd_table[i] = ival
		if (ival > max_tnd):
			max_tnd = ival
	self.dac_range = max_sqr + max_tnd
	self.dc_value = self.dac_range / 2

func update_stereo_pos():
	self.stereo_posL_square1 = (self.panning[0] * self.master_volume) >> 8
	self.stereo_posL_square2 = (self.panning[1] * self.master_volume) >> 8
	self.stereo_posL_triangle = (self.panning[2] * self.master_volume) >> 8
	self.stereo_posL_noise = (self.panning[3] * self.master_volume) >> 8
	self.stereo_posL_DMC = (self.panning[4] & self.master_volume) >> 8
	
	self.stereo_posR_square1 = self.master_volume - self.stereo_posL_square1
	self.stereo_posR_square2 = self.master_volume - self.stereo_posL_square2
	self.stereo_posR_triangle = self.master_volume - self.stereo_posL_triangle
	self.stereo_posR_noise = self.master_volume - self.stereo_posL_noise
	self.stereo_posR_DMC = self.master_volume - self.stereo_posL_DMC

func frame_counter_tick():
	self.derived_frame_counter += 1
	if self.derived_frame_counter >= self.frame_irq_counter_max:
		self.derived_frame_counter = 0
	if self.derived_frame_counter == 1 || self.derived_frame_counter == 3:
		# clock length & sweep
		self.triangle.clock_length_counter()
		self.square1.clock_length_counter()
		self.square2.clock_length_counter()
		self.noise.clock_length_counter()
		self.square1.clock_sweep()
		self.square2.clock_sweep()
	if (self.derived_frame_counter >= 0 && self.derived_frame_counter < 4):
		# clock linear & decay
		self.square1.clock_env_decay()
		self.square2.clock_env_decay()
		self.noise.clock_env_decay()
		self.triangle.clock_linear_counter()
	if (self.derived_frame_counter == 3 && self.count_sequence == 0):
		# enable IRQ
		self.frame_irq_active = true
	# end of 240HZ tick

# updates channel enable status.
# this is done on writes to the channel enable register(0x4015), 
# and when the user enables/disables channels in the GUI.
func update_channel_enable(value):
	self.channel_enable_value = value & 0xffff
	self.square1.set_enabled((value & 1) != 0)
	self.square2.set_enabled((value & 2) != 0)
	self.triangle.set_enabled((value & 4) != 0)
	self.noise.set_enabled((value & 8) != 0)
	self.dmc.set_enabled((value & 16) != 0)

# clocks the frame counter. it should be clocked at
# twice the cpu speed, so the cycles will be divided by 2
# for those counters that are clocked at cpu speed.
func clock_frame_counter(n_cycles):
	if self.init_counter > 0:
		if self.initing_hardware:
			self.init_counter -= n_cycles
			if self.init_counter <= 0:
				self.initing_hardware = false
			return
	# don't process ticks beyond next sampling
	n_cycles += self.extra_cycles
	var max_cycles = self.sample_timer_max - self.sample_timer
	if n_cycles << 10 > max_cycles:
		self.extra_cycles = ((n_cycles << 10) - max_cycles) >> 10
		n_cycles -= self.extra_cycles
	else:
		self.extra_cycles = 0
	var dmc = self.dmc
	var triangle = self.triangle
	var square1 = self.square1
	var square2 = self.square2
	var noise = self.noise
	
	# clock DMC
	if dmc.is_enabled:
		dmc.shift_counter -= n_cycles << 3
		while (dmc.shift_counter <= 0 && dmc.dma_frequency > 0):
			dmc.shift_counter += dmc.dma_frequency
			dmc.clock_dmc()
	
	# clock triangle channel prog timer:
	if (triangle.prog_timer_max > 0):
		triangle.prog_timer_count -= n_cycles
		while triangle.prog_timer_count <= 0:
			triangle.prog_timer_count += triangle.prog_timer_max + 1
			if (triangle.linear_counter > 0 && triangle.length_counter > 0):
				triangle.triangle_counter += 1
				triangle.triangle_counter &= 0x1f
				if (triangle.is_enabled):
					if (triangle.triangle_counter >= 0x10):
						# normal value
						triangle.sample_value = triangle.triangle_counter & 0xf
					else:
						# inverted value
						triangle.sample_value = 0xf - (triangle.triangle_counter & 0xf)
					triangle.sample_value <<= 4
	# clock square channel 1 prog timer:
	square1.prog_timer_count -= n_cycles
	if square1.prog_timer_count <= 0:
		square1.prog_timer_count += (square1.prog_timer_max + 1) << 1
		square1.square_counter += 1
		square1.suqare_counter &= 0x7
		square1.update_sample_value()
	# clock square channel 2 prog timer:
	square2.prog_timer_count -= n_cycles
	if square2.prog_timer_count <= 0:
		square2.prog_timer_count += (square2.prog_timer_max + 1) << 1
		square2.square_counter += 1
		square2.suqare_counter &= 0x7
		square2.update_sample_value()
	# clock noise channel prog timer:
	var acc_c = n_cycles
	if noise.prog_timer_count - acc_c > 0:
		# Do all cycles at once:
		noise.prog_timer_count -= acc_c
		noise.acc_count += acc_c
		noise.acc_value += acc_c * noise.sample_value
	else:
		# slow-step
		while(acc_c > 0):
			acc_c -= 1
			noise.prog_timer_count -= 1
			if (noise.prog_timer_count <= 0 && noise.prog_timer_max > 0):
				# update noise shift register
				noise.shift_reg <<= 1
				noise.tmp = (
					(noise.shift_reg << (1 if noise.random_mode == 0 else 6)) ^
					noise.shift_reg &
					0x8000
				)
				if noise.tmp != 0:
					# sample value must be 0
					noise.shift_reg |= 0x01
					noise.random_bit = 0
					noise.sample_value = 0
				else:
					# find sample value
					noise.random_big = 1
					if noise.is_enabled && noise.length_counter > 0:
						noise.sample_value = noise.master_volume
					else:
						noise.sample_value = 0
				noise.prog_timer_count += noise.prog_timer_max
			noise.acc_value += noise.sample_value
			noise.acc_count += 1
	# frame IRQ handling
	if self.frame_irq_enabled && self.frame_irq_active:
		self.nes.cpu.request_irq(self.nes.cpu.IRQ.NORMAL)
	# clock frame counter at double CPU speed
	self.master_frame_counter += n_cycles << 1
	if self.master_frame_counter >= self.frame_time:
		# 240HZ tick
		self.master_frame_counter -= self.frame_time
		self.frame_counter_tick()
	# accumulate sample value
	self.acc_sample(n_cycles)
	# clock sample timer
	self.sample_timer += n_cycles << 10
	if self.sample_timer >= self.sample_timer_max:
		# sample channels
		self.sample()
		self.sample_timer -= self.sample_timer_max

func acc_sample(cycles):
	# special treatment for triangle channel - need to interpolate
	if self.triangle.sample_condition:
		self.tri_value = floor(
			(self.triangle.prog_timer_count << 4) / (self.triangle.prog_timer_max + 1)
		)
		if self.tri_value > 16:
			self.tri_value = 16
		if self.triangle.triangle_counter >= 16:
			self.tri_value = 16 - self.tri_value
		# add non-interpolated sample value
		self.tri_value += self.triangle.sample_value
	# Now sample normally
	if cycles == 2:
		self.smp_triangle += self.tri_value << 1
		self.smp_dmc += self.dmc.sample << 1
		self.smp_square1 += self.square1.sample_value << 1
		self.smp_square2 += self.square2.sample_value << 1
		self.acc_count += 2
	elif cycles == 4:
		self.smp_triangle += self.tri_value << 2
		self.smp_dmc += self.dmc.sample << 2
		self.smp_square1 += self.square1.sample_value << 2
		self.smp_square2 += self.square2.sample_value << 2
		self.acc_count += 4
	else:
		self.smp_triangle += self.tri_value * cycles
		self.smp_dmc += self.dmc.sample * cycles
		self.smp_square1 += self.square1.sample_value * cycles
		self.smp_square2 += self.square2.sample_value * cycles
		self.acc_count += cycles

# samples the channels, mixes the output together, then writes to buffer
func sample():
	var sq_index
	var tnd_index
	if self.acc_count > 0:
		self.smp_square1 <<= 4
		self.smp_square1 = floor(self.smp_square1 / self.acc_count)
		self.smp_square2 <<= 4
		self.smp_square2 = floor(self.smp_square2 / self.acc_count)
		self.smp_triangle = floor(self.smp_triangle / self.acc_count)
		self.smp_dmc <<= 4
		self.smp_dmc = floor(self.smp_dmc / self.acc_count)
		self.acc_count = 0
	else:
		self.smp_square1 = self.square1.sample_value << 4
		self.smp_square2 = self.square2.sample_value << 4
		self.smp_triangle = self.triangle.sample_value
		self.smp_dmc = self.dmc.sample << 4
	var smp_noise = floor(self.noise.acc_value << 4) / self.noise.acc_count
	self.noise.acc_value = smp_noise >> 4
	self.noise.acc_count = 1
	# stereo sound
	# left channel:
	sq_index = (self.smp_square1 * self.stereo_posL_square1 + 
		self.smp_square2 * self.stereo_posL_square2
	) >> 8
	tnd_index = (3 * self.smp_triangle * self.stereo_posL_triangle +
		(smp_noise << 1) * self.stereo_posL_noise + 
		self.smp_dmc * self.stereo_posL_DMC
	) >> 8
	if sq_index >= self.square_table.length:
		sq_index = self.square_table.length - 1
	if tnd_index >= self.tnd_table.length:
		tnd_index = self.tnd_table.length - 1
	var sample_value_L = self.square_table[sq_index] + self.tnd_table[tnd_index] - self.dc_value
	
	# right channel
	sq_index = (self.smp_square1 * self.stereo_posR_square1 + 
		self.smp_square2 * self.stereo_posR_square2
	) >> 8
	tnd_index = (3 * self.smp_triangle * self.stereo_posR_triangle +
		(smp_noise << 1) * self.stereo_posR_noise + 
		self.smp_dmc * self.stereo_posR_DMC
	) >> 8
	if sq_index >= self.square_table.length:
		sq_index = self.square_table.length - 1
	if tnd_index >= self.tnd_table.length:
		tnd_index = self.tnd_table.length - 1
	var sample_value_R = self.square_table[sq_index] + self.tnd_table[tnd_index] - self.dc_value
	
	# remove DC from left channel
	var smp_diff_L = sample_value_L - self.prev_sample_L
	self.prev_sample_L += smp_diff_L
	self.smp_accum_L += smp_diff_L - (self.smp_accum_L >> 10)
	sample_value_L = self.smp_accum_L
	
	# remove DC from right channel
	var smp_diff_R = sample_value_R - self.prev_sample_R
	self.prev_sample_R += smp_diff_R
	self.smp_accum_R += smp_diff_R - (self.smp_accum_R >> 10)
	sample_value_R = self.smp_accum_R
	
	# write
	if (sample_value_L > self.max_sample):
		self.max_sample = sample_value_L
	if (sample_value_R  < self.min_sample):
		self.min_sample = sample_value_L
	if self.nes.opts.on_audio_sample:
		self.nes.opts.on_audio_sample(sample_value_L / 32768, sample_value_R / 32768)
	
	# reset sampled values
	self.smp_square1 = 0
	self.smp_square2 = 0
	self.smp_triangle = 0
	self.smp_dmc = 0

func get_length_max(value):
	return self.length_lookup[value >> 3]

func get_dmc_frequency(value):
	if value >= 0 && value < 0x10:
		return self.dmc_freq_lookup[value]
	return 0

func get_noise_wave_length(value):
	if (value >= 0 && value < 0x10):
		return self.noise_wave_length_lookup[value]
	return 0

func set_panning(pos):
	for i in range(5):
		self.panning[i] = pos[i]
	self.update_stereo_pos()

func set_master_volume(value):
	if value < 0:
		value = 0
	if value > 256:
		value = 256
	self.master_volume = value
	self.update_stereo_pos()


# eslint-disable-next-line no-unused-vars
func read_reg(address):
	var tmp = 0
	tmp |= self.square1.get_length_status()
	tmp |= self.square2.get_length_status() << 1
	tmp |= self.triangle.get_length_status() << 2
	tmp |= self.noise.get_length_status() << 3
	tmp |= self.dmc.get_length_status() << 4
	tmp |= (self.frame_irq_active && 1 if self.frame_irq_enabled else 0) << 6
	tmp |= self.dmc.get_irq_status() << 7
	
	self.frame_irq_active = false
	self.dmc.irq_generated = false
	
	return tmp & 0xffff

func write_reg(address, value):
	if address >= 0x4000 && address < 0x4004:
		# square wave 1 control
		self.square1.write_reg(address, value)
	elif address >= 0x4004 && address < 0x4008:
		# square 2 control
		self.square2.write_reg(address, value)
	elif address >= 0x4008 && address < 0x400c:
		# triangle control
		self.triangle.write_reg(address, value)
	elif address >= 0x400c && address <= 0x400f:
		# noise control
		self.noise.write_reg(address, value)
	elif address == 0x4010:
		# DMC play mode & DMA frequency
		self.dmc.write_reg(address, value)
	elif address == 0x4011:
		# DMC delta counter
		self.dmc.write_reg(address, value)
	elif address == 0x4012:
		# DMC play code starting address
		self.dmc.write_reg(address, value)
	elif address == 0x4013:
		# DMC play code length
		self.dmc.write_reg(address, value)
	elif address == 0x4015:
		# channel enable
		self.update_channel_enable(value)
		if (value != 0 && self.init_counter > 0):
			# start hardware initialization
			self.initing_hardware = true
		# DMC/IRQ Status
		self.dmc.write_reg(address, value)
	elif address == 0x4017:
		# frame counter control
		self.count_sequence = (value >> 7) & 1
		self.master_frame_counter = 0
		self.frame_irq_active = false
		if (((value >> 6) & 0x1) == 0):
			self.frame_irq_enabled = true
		else:
			self.frame_irq_enabled = false
		if self.count_sequence == 0:
			# NTSC
			self.frame_irq_counter_max = 4
			self.derived_frame_counter = 4
		else:
			# PAL
			self.frame_irq_counter_max = 5
			self.derived_frame_counter = 0
			self.frame_counter_tick()

func reset_counter():
	if self.count_sequence == 0:
		self.derived_frame_counter = 4
	else:
		self.derived_frame_counter = 0

func reset():
	self.sample_rate = self.nes.opts.sample_rate
	self.sample_timer_max = floor(
		(1024.0 * CPU_FREQ_NTSC * self.nes.opts.preferred_frame_rate) / 
		(self.sample_rate * 60.0)
	)
	self.frame_time = floor(
		(14915.0 * self.nes.opts.preferred_frame_rate) / 60.0
	)
	self.sample_timer = 0
	self.update_channel_enable(0)
	self.master_frame_counter = 0
	self.derived_frame_counter = 0
	self.count_sequence = 0
	self.sample_count = 0
	self.init_counter = 2048
	self.frame_irq_enabled = false
	self.initing_hardware = false
	self.reset_counter()
	self.square1.reset()
	self.square2.reset()
	self.triangle.reset()
	self.noise.reset()
	self.dmc.reset()
	self.acc_count = 0
	self.smp_square1 = 0
	self.smp_square2 = 0
	self.smp_triangle = 0
	self.smp_dmc = 0
	self.frame_irq_enabled = false
	self.frame_irq_counter_max = 4
	self.channel_enable_value = 0xff
	self.started_playing = false
	self.prev_sample_L = 0
	self.prev_sample_R = 0
	self.smp_accum_L = 0
	self.smp_accum_R = 0
	self.max_sample = -500000
	self.min_sample = 500000

class ChannelDM:
	var papu = null
	enum MODE {NORMAL, LOOP, IRQ}
	var is_enabled = null
	var has_sample = null
	var irq_generated = null
	var play_mode = null
	var dma_frequency = null
	var dma_counter = null
	var delta_counter = null
	var play_start_address = null
	var play_address = null
	var play_length = null
	var play_length_counter = null
	var shift_counter = null
	var reg4012 = null
	var reg4013 = null
	var sample = null
	var dac_lsb = null
	var data = null
	
	func _init(papu):
		self.papu = papu
		self.irq_generated = false
		self.reset()
	
	func reset():
		self.is_enabled = false
		self.irq_generated = false
		self.play_mode = self.MODE.NORMAL
		self.dma_frequency = 0
		self.dma_counter = 0
		self.delta_counter = 0
		self.play_start_address = 0
		self.play_address = 0
		self.play_length = 0
		self.play_length_counter = 0
		self.sample = 0
		self.dac_lsb = 0
		self.shift_counter = 0
		self.reg4012 = 0
		self.reg4013 = 0
		self.data = 0
	
	func next_sample():
		# fetch byte
		self.data = self.papu.nes.mmap.read(self.play_address)
		self.papu.nes.cpu.halt_cycles(4)
		
		self.play_length_counter -= 1
		self.play_address += 1
		if self.play_address > 0xffff:
			self.play_address = 0x8000
	
	func end_of_sample():
		if self.play_length_counter == 0 && self.play_mode == self.MODE.LOOP:
			# start from beginning of sample
			self.play_address = self.play_start_address
			self.play_length_counter = self.play_length
		if self.play_length_counter > 0:
			# fetch next sample
			self.next_sample()
			if self.play_length_counter == 0:
				# last byte of sample fetched, generate IRQ:
				if self.play_mode == self.MODE.IRQ:
					# generate IRQ
					self.irq_generated = true
	
	func clock_dmc():
		# only alter DAC value if the sample buffer has data
		if self.has_sample:
			if ((self.data & 1) == 0):
				# Decrement delta
				if self.delta_counter > 0:
					self.delta_counter -= 1
			else:
				# Increment delta
				if self.delta_counter < 63:
					self.delta_counter += 1
			# update sample value
			self.sample = (self.delta_counter << 1) + self.dac_lsb if self.is_enabled else 0
			# update shift register
			self.data >>= 1
		self.dma_counter -= 1
		if self.dma_counter <= 0:
			# no more sample bits
			self.has_sample = false
			self.end_of_sample()
			self.dma_counter = 8
		if self.irq_generated:
			self.papu.nes.cpu.request_irq(self.papu.nes.cpu.IRQ.NORMAL)
	
	func write_reg(address, value):
		if address == 0x4010:
			# play mode, DMA Frequency
			if (value >> 6 == 0):
				self.play_mode = self.MODE.NORMAL
			elif (((value >> 6) & 1) == 1):
				self.play_mode = self.MODE.LOOP
			elif (value >> 6 == 2):
				self.play_mode = self.MODE.IRQ
			if ((value & 0x80) == 0):
				self.irq_generated = false
			self.dma_frequency = self.papu.get_dmc_frequency(value & 0xf)
		elif address == 0x4011:
			# delta counter load register
			self.delta_counter = (value >> 1) & 63
			self.dac_lsb = value & 1
			self.sample = (self.delta_counter << 1) + self.dac_lsb # update sample value
		elif address == 0x4012:
			# DMA address load register
			self.play_start_address = (value << 6) | 0x0c000
			self.play_address = self.play_start_address
			self.reg4012 = value
		elif address == 0x4013:
			# length of play code
			self.play_length = (value << 4) + 1
			self.play_length_counter = self.play_length
			self.reg4013 = value
		elif address == 0x4015:
			# DMC/IRQ Status
			if (((value >> 4) & 1) == 0):
				# disable
				self.play_length_counter = 0
			else:
				# reset:
				self.play_address = self.play_start_address
				self.play_length_counter = self.play_length
			self.irq_generated = false
	
	func set_enabled(value):
		if (!self.is_enabled && value):
			self.play_length_counter = self.play_length
		self.is_enabled = value
	
	func get_length_status():
		return self.play_length_counter == 0 || 0 if self.is_enabled else 1
	
	func get_irq_status():
		return 1 if self.irq_generated else 0

class ChannelNoise:
	var papu = null
	var is_enabled = null
	var env_decay_disable = null
	var env_decay_loop_enable = null
	var length_counter_enable = null
	var env_reset = null
	var shift_now = null
	
	var length_counter = null
	var prog_timer_count = null
	var prog_timer_max = null
	var env_decay_rate = null
	var env_decay_counter = null
	var env_volume = null
	var master_volume = null
	var shift_reg = null
	var random_bit = null
	var random_mode = null
	var sample_value = null
	var acc_value = null
	var acc_count = null
	var tmp = null
	
	func _init(papu):
		self.papu = papu
		self.shift_reg = 1 << 14
		self.acc_value = 0
		self.acc_count = 1
		self.reset()
	
	func reset():
		self.prog_timer_count = 0
		self.prog_timer_max = 0
		self.is_enabled = false
		self.length_counter = 0
		self.length_counter_enable = false
		self.env_decay_disable = false
		self.env_decay_loop_enable = false
		self.shift_now = false
		self.env_decay_rate = 0
		self.env_decay_counter = 0
		self.env_volume = 0
		self.master_volume = 0
		self.shift_reg = 1
		self.random_bit = 0
		self.random_mode = 0
		self.sample_value = 0
		self.tmp = 0
		
	func update_sample_value():
		if (self.is_enabled && self.length_counter > 0):
			self.sample_value = self.random_bit & self.master_volume

	func clock_length_counter():
		if self.length_counter_enable && self.length_counter > 0:
			self.length_counter -= 1
			if self.length_counter == 0:
				self.update_sample_value()
	
	func clock_env_decay():
		self.env_decay_counter -= 1
		if self.env_reset:
			# reset envlope
			self.env_reset = false
			self.env_decay_counter = self.env_decay_rate + 1
			self.env_volume = 0xf
		elif self.env_decay_counter <= 0:
			# normal handling
			self.env_decay_counter = self.env_decay_rate + 1
			if self.env_volume > 0:
				self.env_volume -= 1
			else:
				self.env_volume = 0xf if self.env_decay_loop_enable else 0
		if self.env_decay_disable:
			self.master_volume = self.env_decay_rate
		else:
			self.master_volume = self.env_volume
		self.update_sample_value()

	func write_reg(address, value):
		if address == 0x400c:
			# Volume/Envelope decay:
			self.env_decay_disable = (value & 0x10) != 0
			self.env_decay_rate = value & 0xf
			self.env_decay_loop_enable = (value & 0x20) != 0
			self.length_counter_enable = (value & 0x20) == 0
			if self.env_decay_disable:
				self.master_volume = self.env_decay_rate
			else:
				self.master_volume = self.env_volume
		elif address == 0x400e:
			# programmable timer:
			self.prog_timer_max = self.papu.get_noise_wave_length(value & 0xf)
			self.random_mode = value >> 7
		elif address == 0x400f:
			# length counter
			self.length_counter = self.papu.get_length_max(value & 248)
			self.env_reset = true
	
	func set_enabled(value):
		self.is_enabled = value
		if !value:
			self.length_counter = 0
		self.update_sample_value()
		
	func length_status():
		return self.length_counter == 0 || 0 if !self.is_enabled else 1

class ChannelSquare:
	var papu = null
	var duty_lookup = null
	var imp_lookup = null
	var sqr1 = null
	var is_enabled = null
	var length_counter_enable = null
	var sweep_active = null
	var env_decay_disable = null
	var env_decay_loop_enable = null
	var env_reset = null
	var sweep_carry = null
	var update_sweep_period = null
	
	var prog_timer_count = null
	var prog_timer_max = null
	var length_counter = null
	var square_counter = null
	var sweep_counter = null
	var sweep_counter_max = null
	var sweep_mode = null
	var sweep_shift_amount = null
	var env_decay_rate = null
	var env_decay_counter = null
	var env_volume = null
	var master_volume = null
	var duty_mode = null
	var sweep_result = null
	var sample_value = null
	var vol = null
	
	func _init(papu, square1):
		self.papu = papu
		
		# prettier-ignore
		self.duty_lookup = [
			0, 1, 0, 0, 0, 0, 0, 0,
			0, 1, 1, 0, 0, 0, 0, 0,
			0, 1, 1, 1, 1, 0, 0, 0,
			1, 0, 0, 1, 1, 1, 1, 1
		]
		# prettier-ignore
		self.imp_lookup = [
			1,-1, 0, 0, 0, 0, 0, 0,
			1, 0,-1, 0, 0, 0, 0, 0,
			1, 0, 0, 0,-1, 0, 0, 0,
			-1, 0, 1, 0, 0, 0, 0, 0
		]
		self.sqr1 = square1
	
	func reset():
		self.prog_timer_count = 0
		self.prog_timer_max = 0
		self.length_counter = 0
		self.square_counter = 0
		self.sweep_counter = 0
		self.sweep_counter_max = 0
		self.sweep_mode = 0
		self.sweep_shift_amount = 0
		self.env_decay_rate = 0
		self.env_decay_counter = 0
		self.env_volume = 0
		self.master_volume = 0
		self.duty_mode = 0
		self.vol = 0
		
		self.is_enabled = false
		self.length_counter_enable = false
		self.sweep_active = false
		self.sweep_carry = false
		self.env_decay_disable = false
		self.env_decay_loop_enable = false
	
	func update_sample_value():
		if self.is_enabled && self.length_counter > 0 && self.prog_timer_max > 7:
			if (
				self.sweep_mode == 0 &&
				self.prog_timer_max + (self.prog_timer_max >> self.sweep_shift_amount) > 4095
			):
				self.sample_value = 0
			else:
				self.sample_value = self.master_volume * self.duty_lookup[(self.duty_mode << 3) + self.square_counter]
		else:
			self.sample_value = 0

	func clock_length_counter():
		if self.length_counter_enable && self.length_counter > 0:
			self.length_counter -= 1
			if self.length_counter == 0:
				self.update_sample_value()
				
	func clock_env_decay():
		self.env_decay_counter -= 1
		if self.env_reset:
			# reset envlope
			self.env_reset = false
			self.env_decay_counter = self.env_decay_rate + 1
			self.env_volume = 0xf
		elif self.env_decay_counter <= 0:
			# normal handling
			self.env_decay_counter = self.env_decay_rate + 1
			if self.env_volume > 0:
				self.env_volume -= 1
			else:
				self.env_volume = 0xf if self.env_decay_loop_enable else 0
		if self.env_decay_disable:
			self.master_volume = self.env_decay_rate
		else:
			self.master_volume = self.env_volume
		self.update_sample_value()
		
	func clock_sweep():
		self.sweep_counter -= 1
		if self.sweep_counter <= 0:
			self.sweep_counter = self.sweep_counter_max + 1
			if (
				self.sweep_active &&
				self.sweep_shift_amount > 0 &&
				self.prog_time_max > 7
			):
				# calculate result from shifter
				self.sweep_carry = false
				if self.sweep_mode == 0:
					self.prog_timer_max += (self.prog_timer_max >> self.sweep_shift_amount)
					if self.prog_timer_max > 4095:
						self.prog_timer_max = 4095
						self.sweep_carry = true
				else:
					self.prog_timer_max = self.prog_timer_max - ((self.prog_timer_max >> self.sweep_shift_amount) - (1 if self.sqr1 else 0))
		if self.update_sweep_period:
			self.update_sweep_period = false
			self.sweep_counter = self.sweep_counter_max + 1
	
	func write_reg(address, value):
		var addr_add = 0 if self.sqr1 else 4
		if address == 0x4000 + addr_add:
			# volume/envelope decay:
			self.env_decay_disable = (value & 0x10) != 0
			self.env_dacay_rate = value & 0xf
			self.env_decay_loop_enable = (value & 0x20) != 0
			self.duty_mode = (value >> 6) & 0x3
			self.length_counter_enable = (value & 0x20) == 0
			if self.env_decay_disable:
				self.master_volume = self.env_decay_rate
			else:
				self.master_volume = self.env_volume
			self.update_sample_value()
		elif (address == 0x4001 + addr_add):
			# sweep
			self.sweep_active = (value & 0x80) != 0
			self.sweep_counter_max = (value >> 4) & 7
			self.sweep_mode = (value >> 3) & 1
			self.sweep_shift_amount = value & 7
			self.update_sweep_period = true
		elif (address == 0x4002 + addr_add):
			# programmable timer
			self.prog_timer_max &= 0x700
			self.prog_timer_max |= value
		elif (address == 0x4003 + addr_add):
			# programmable time, length counter
			self.prog_timer_max &= 0xff
			self.prog_timer_max |= (value & 0x7) << 8
			if self.is_enabled:
				self.length_counter = self.papu.get_length_max(value & 0xf8)
			self.env_reset = true
	
	func set_enabled(value):
		self.is_enabled = value
		if !value:
			self.length_counter = 0
		self.update_sample_value()
	
	func get_length_status():
		return self.length_counter == 0 || 0 if !self.is_enabled else 1

class ChannelTriangle:
	var papu = null
	var is_enabled = null
	var sample_condition = null
	var length_counter_enable = null
	var lc_halt = null
	var lc_control = null
	
	var prog_timer_count = null
	var prog_timer_max = null
	var triangle_counter = null
	var length_counter = null
	var linear_counter = null
	var lc_load_value = null
	var sample_value = null
	var tmp = null
	
	func _init(papu):
		self.papu = papu
		self.reset()
	
	func reset():
		self.prog_timer_count = 0
		self.prog_timer_max = 0
		self.triangle_counter = 0
		self.is_enabled = false
		self.sample_condition = false
		self.length_counter = 0
		self.length_counter_enable = false
		self.linear_counter = 0
		self.lc_load_value = 0
		self.lc_halt = true
		self.lc_control = false
		self.tmp = 0
		self.sample_value = 0xf
	
	func update_sample_condition():
		self.sample_condition = (
			self.is_enabled &&
			self.prog_timer_max > 7 &&
			self.linear_counter > 0 &&
			self.length_counter > 0
		)
	
	func clock_length_counter():
		if (self.length_counter_enable && self.length_counter > 0):
			self.length_counter -= 1
			if self.length_counter == 0:
				self.update_sample_condition()
	
	func clock_linear_counter():
		if self.lc_halt:
			# load
			self.linear_counter = self.lc_load_value
			self.update_sample_condition()
		elif (self.linear_counter > 0):
			# decrement
			self.linear_counter -= 1
			self.update_sample_condition()
		if !self.lc_control:
			# clear halt flag
			self.lc_halt = false
	
	func get_length_status():
		return self.length_counter == 0 || 0 if !self.is_enabled else 1
	
	# eslint-disable-next-line no-unused-vars
	func read_reg(address):
		return 0
		
	func write_reg(address, value):
		if address == 0x4000:
			# new values for linear counter
			self.lc_control = (value & 0x80) != 0
			self.lc_load_value = value & 0x7f
			# length counter enable
			self.length_counter_enable = !self.lc_control
		elif (address == 0x400a):
			# programmable timer
			self.prog_timer_max &= 0x700
			self.prog_timer_max |= value
		elif (address == 0x400b):
			# programmable timer, length counter
			self.prog_timer_max &= 0xff
			self.prog_timer_max |= (value & 0x07) << 8
			self.length_counter = self.papu.get_length_max(value & 0xf8)
			self.lc_halt = true
		
		self.update_sample_condition()
	
	func clock_triangle_generator():
		self.triangle_counter += 1
		self.triangle_counter &= 0x1f
	
	func clock_programmable_timer(n_cycles):
		if self.prog_timer_max > 0:
			self.prog_timer_count += n_cycles
			while(
				self.prog_timer_max > 0 &&
				self.prog_timer_count >= self.prog_timer_max
			):
				self.prog_timer_count -= self.prog_timer_max
				if (
					self.is_enabled &&
					self.length_counter > 0 &&
					self.linear_counter > 0
				):
					self.clock_triangle_generator()
	
	func set_enabled(value):
		self.is_enabled = value
		if (!value):
			self.length_counter = 0
		self.update_sample_condition()
