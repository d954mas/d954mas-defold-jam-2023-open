local COMMON = require "libs.common"
local INPUT = require "libs.input_receiver"
local ENUMS = require "world.enums.enums"
local SCENE_ENUMS = require "libs.sm.enums"
local TAG = "SDK"

---@class Sdks
local Sdk = COMMON.class("Sdk")

---@param world World
function Sdk:initialize(world)
	checks("?", "class:World")
	self.world = world
	self.data = {
		gameplay_start = false
	}
end

function Sdk:init(cb)
	cb()
end


function Sdk:gameplay_start()
	if(not self.data.gameplay_start)then
		COMMON.i("gameplay start", TAG)
		self.data.gameplay_start = true
	end
end

function Sdk:gameplay_stop()
	if(not self.data.gameplay_stop)then
		COMMON.i("gameplay stop", TAG)
		self.data.gameplay_stop = false
	end
end

function Sdk:__ads_start()
	self.world.sounds:pause()
	INPUT.IGNORE = true
	local SM = reqf "libs_project.sm"
	local scene = SM:get_top()
	if (scene and scene._state == SCENE_ENUMS.STATES.RUNNING) then
		scene:pause()
	end
end

function Sdk:__ads_stop()
	self.world.sounds:resume()
	INPUT.IGNORE = false
	local SM = reqf "libs_project.sm"
	local scene = SM:get_top()
	if (scene and scene._state == SCENE_ENUMS.STATES.PAUSED) then
		scene:resume()
	end
end

function Sdk:ads_rewarded(cb)
	print("ads_rewarded")
	if (COMMON.CONSTANTS.TARGET_IS_POKI) then
		self.world.sounds:pause()
		INPUT.IGNORE = true
		local pause_game = false
		poki_sdk.rewarded_break(function(_, success)
			print("ads_rewarded success:" .. tostring(success))
			INPUT.IGNORE = false
			self.world.sounds:resume()
			if (pause_game) then
				self.world.game:game_resume()
			end
			if (cb) then cb(success) end
		end)
	elseif (COMMON.CONSTANTS.TARGET_IS_PLAY_MARKET) then
		self.admob:show_rewarded_ad(cb)
	elseif COMMON.CONSTANTS.TARGET_IS_CRAZY_GAMES then
		self.crazygames:show_rewarded_ad(cb)
	else
		if (cb) then
			cb(true) end
	end
end

function Sdk:preload_ads()
	if (COMMON.CONSTANTS.PLATFORM_IS_ANDROID) then
		self.admob:rewarded_load()
	end
end

function Sdk:ads_commercial(cb)
	print("ads_commercial")
	if (COMMON.CONSTANTS.TARGET_IS_POKI) then
		self.world.sounds:pause()
		INPUT.IGNORE = true

		poki_sdk.commercial_break(function(_)
			INPUT.IGNORE = false
			self.world.sounds:resume()
			if (cb) then cb() end
		end)
	elseif (COMMON.CONSTANTS.TARGET_IS_PLAY_MARKET) then
		self.admob:show_interstitial_ad(cb)
	elseif COMMON.CONSTANTS.TARGET_IS_CRAZY_GAMES then
		self.crazygames:show_interstitial_ad(cb)
	else
		if (cb) then cb() end
	end
end


return Sdk
