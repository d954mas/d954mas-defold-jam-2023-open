local ECS = require 'libs.ecs'
local illumination = require "illumination.illumination"

---@class DaySystem:ECSSystem
local System = ECS.system()
System.name = "DaySystem"

local daycycle = {
	{
		sunlight_direction = vmath.vector3(-179, 20, 0),
		sunlight_color = vmath.vector3(1, 1, 1),
		sunlight_brightness = 1,
		ambient_color = vmath.vector3(0.5, 0.5, 0.5),
		ambient_level = 1,
		fog_color = vmath.vector3(0, 0, 0.1),
		duration = 10
	}, {
		sunlight_direction = vmath.vector3(-70, 90, 0),
		sunlight_color = vmath.vector3(1, 1, 1),
		sunlight_brightness = 1,
		ambient_color = vmath.vector3(1, 1, 1),
		ambient_level = 0.3,
		fog_color = vmath.vector3(0.53, 0.8, 0.92),
		duration = 10
	}, {
		sunlight_direction = vmath.vector3(0, 20, 0),
		sunlight_color = vmath.vector3(0.5, 0.2, 0),
		sunlight_brightness = 0.1,
		ambient_color = vmath.vector3(0.5, 0.2, 0),
		ambient_level = 0.1,
		fog_color = vmath.vector3(0.3, 0.2, 0),
		duration = 10
	}, {
		sunlight_direction = vmath.vector3(0, 20, 0),
		sunlight_color = vmath.vector3(0.318, 0.261, 0.413),
		sunlight_brightness = 0,
		ambient_color = vmath.vector3(0.318, 0.261, 0.413),
		ambient_level = 0.1,
		fog_color = vmath.vector3(0, 0, 0.1),
		duration = 5
	}
}

function System:onAddToWorld()
	self.urls = {
		illumination_go = msg.url('illumination'),
		illumination = msg.url('illumination#illumination'),
		firefly = msg.url('firefly'),
		firefly_light = msg.url('firefly#light'),
		fireplace = msg.url('fireplace#light'),
		spot_red = msg.url('light_red'),
		spot_green = msg.url('light_green')
	}
	--illumination.set_debug(true)
	--self:run_daycycle()
end

function System:run_daycycle(index)
	local target = daycycle[index or 1]
	local duration = index and target.duration or 0
	index = index or 1

	go.animate(self.urls.illumination_go, 'euler', go.PLAYBACK_ONCE_FORWARD, target.sunlight_direction, go.EASING_LINEAR, duration, 0, function()
		self:run_daycycle(index == #daycycle and 1 or (index + 1))
	end)

	go.cancel_animations(self.urls.illumination)

	go.animate(self.urls.illumination, 'sunlight_color', go.PLAYBACK_ONCE_FORWARD, target.sunlight_color, go.EASING_LINEAR, duration)
	go.animate(self.urls.illumination, 'sunlight_brightness', go.PLAYBACK_ONCE_FORWARD, target.sunlight_brightness, go.EASING_LINEAR, duration)
	go.animate(self.urls.illumination, 'ambient_color', go.PLAYBACK_ONCE_FORWARD, target.ambient_color, go.EASING_LINEAR, duration)
	go.animate(self.urls.illumination, 'ambient_level', go.PLAYBACK_ONCE_FORWARD, target.ambient_level, go.EASING_LINEAR, duration)
	go.animate(self.urls.illumination, 'fog_color', go.PLAYBACK_ONCE_FORWARD, target.fog_color, go.EASING_LINEAR, duration)
end

function System:update(dt)
--	local ambient_color = go.get(self.urls.illumination, 'ambient_color')
--	local ambient_level = go.get(self.urls.illumination, 'ambient_level')
--	local sunlight_color = go.get(self.urls.illumination, 'sunlight_color')
--	local sunlight_brightness = go.get(self.urls.illumination, 'sunlight_brightness')
--	local fog_color = go.get(self.urls.illumination, 'fog_color')
--	--self.world.game_world.game.lights:set_ambient_color(ambient_color.x,ambient_color.y,ambient_color.z)
	--self.world.game_world.game.lights:set_ambient_color_intensity(ambient_level)
	--self.world.game_world.game.lights:set_fog_color(fog_color.x,fog_color.y,fog_color.z)
	--self.world.game_world.game.lights:set_sunlight_color(sunlight_color.x,sunlight_color.y,sunlight_color.z)
	--self.world.game_world.game.lights:set_sunlight_color_intensity(sunlight_brightness)
end

return System