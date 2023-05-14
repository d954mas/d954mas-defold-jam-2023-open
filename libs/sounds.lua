local COMMON = require "libs.common"

local TAG = "Sound"
---@class Sounds
local Sounds = COMMON.class("Sounds")

--gate https://www.defold.com/manuals/sound/
---@param world World
function Sounds:initialize(world)
	self.world = assert(world)
	self.gate_time = 0.1
	self.gate_sounds = {}
	self.fade_in = {}
	self.fade_out = {}
	self.sounds = {
		silence = { name = "silence", url = msg.url("main:/sounds#silence") },
		door_beep = { name = "door_beep", url = msg.url("main:/sounds#door_beep") },
		door_close = { name = "silence", url = msg.url("main:/sounds#door_close") },
		ghost_moan_01 = { name = "ghost_moan_01", url = msg.url("main:/sounds#ghost_moan_01") },
	}
	self.music = {
		silence = { name = "silence", url = msg.url("main:/music#silence"), fade_in = 3, fade_out = 3 },
		game = { name = "game", url = msg.url("main:/music#silence"), fade_in = 3, fade_out = 3 },
		game_horror = { name = "game_horror", url = msg.url("main:/music#game_horror"), fade_in = 8, fade_out = 3 },
	}
	self.scheduler = COMMON.RX.CooperativeScheduler.create()
	self.subscription = COMMON.EVENT_BUS:subscribe(COMMON.EVENTS.STORAGE_CHANGED)
							  :go_distinct(self.scheduler):subscribe(function()
		self:on_storage_changed()
	end)
	self.master_gain = 1
	self.current_music = nil
end

function Sounds:on_storage_changed()
	sound.set_group_gain(COMMON.HASHES.hash("sound"), self.world.storage.options:sound_get() and 1 or 0)
	sound.set_group_gain(COMMON.HASHES.hash("music"), self.world.storage.options:music_get() and 1 or 0)
end

function Sounds:pause()
	COMMON.i("pause", TAG)
	self.master_gain = sound.get_group_gain(COMMON.HASHES.hash("master"))
	sound.set_group_gain(COMMON.HASHES.hash("master"), 0)
end

function Sounds:resume()
	COMMON.i("resume", TAG)
	sound.set_group_gain(COMMON.HASHES.hash("master"), self.master_gain)
end

function Sounds:update(dt)
	self.scheduler:update(dt)
	for k, v in pairs(self.gate_sounds) do
		self.gate_sounds[k] = v - dt
		if self.gate_sounds[k] < 0 then
			self.gate_sounds[k] = nil
		end
	end
	for k, v in pairs(self.fade_in) do
		local a = 1 - v.time / v.music.fade_in
		a = COMMON.LUME.clamp(a, 0, 1)
		sound.set_gain(v.music.url, a)
		v.time = v.time - dt
		--        print("Fade in:" .. a)
		if (a == 1) then
			self.fade_in[k] = nil
		end
	end

	for k, v in pairs(self.fade_out) do
		local a = v.time / v.music.fade_in
		a = COMMON.LUME.clamp(a, 0, 1)
		sound.set_gain(v.music.url, a)
		v.time = v.time - dt
		--      print("Fade out:" .. a)
		if (a == 0) then
			self.fade_out[k] = nil
			sound.stop(v.url)
		end
	end
end

function Sounds:play_sound(sound_obj, config)
	assert(sound_obj)
	assert(type(sound_obj) == "table")
	assert(sound_obj.url)
	config = config or {}

	if not self.gate_sounds[sound_obj] or sound_obj.no_gate then
		self.gate_sounds[sound_obj] = sound_obj.gate_time or self.gate_time
		sound.play(sound_obj.url, nil, config.on_complete)
		COMMON.i("play sound:" .. sound_obj.name, TAG)
	else
		COMMON.i("gated sound:" .. sound_obj.name .. "time:" .. self.gate_sounds[sound_obj], TAG)
	end
end
function Sounds:play_music(music_obj)
	assert(music_obj)
	assert(type(music_obj) == "table")
	assert(music_obj.url)

	if (self.current_music) then
		if (self.current_music.fade_out) then
			self.fade_out[self.current_music] = { music = self.current_music, time = self.current_music.fade_out }
			self.fade_in[self.current_music] = nil
		else
			sound.stop(self.current_music.url)
		end
	end
	sound.stop(music_obj.url)
	sound.play(music_obj.url)

	if (music_obj.fade_in) then
		sound.set_gain(music_obj.url, 0)
		self.fade_in[music_obj] = { music = music_obj, time = music_obj.fade_in }
		self.fade_out[music_obj] = nil
	end
	self.current_music = music_obj

	COMMON.i("play music:" .. music_obj.name, TAG)
end


--pressed M to enable/disable
function Sounds:toggle()
	local music = self.world.storage.options:music_get()
	if (music) then
		-- music priority
		self.world.storage.options:music_set(false)
		self.world.storage.options:sound_set(false)
	else
		self.world.storage.options:music_set(true)
		self.world.storage.options:sound_set(true)
	end
end

return Sounds