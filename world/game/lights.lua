local COMMON = require "libs.common"

local Lights = COMMON.class("lights")

---@param world World
function Lights:initialize(world)
	self.world = assert(world)
end

---@param render Render
function Lights:set_render(render)
	self.render = assert(render)
	local v = vmath.vector4()

	self.render.draw_opts.constants.sunlight_color = v
	self.render.draw_opts.constants.shadow_color = v
	self.render.draw_opts.constants.ambient_color = v
	self.render.draw_opts.constants.fog = v
	self.render.draw_opts.constants.fog_color = v

	self:reset()
end

function Lights:reset()
	if (not self.render) then return end
	self:set_sunlight_direction(0.5, 1, 0.1)
	self:set_sunlight_color(1, 1, 1)
	self:set_sunlight_color_intensity(0.2)
	self:set_shadow_color(0.5, 0.5, 0.5)
	self:set_shadow_color_intensity(1)

	self:set_ambient_color(0.8, 0.8, 0.8)
	self:set_ambient_color_intensity(0.8)
	self:set_fog(10, 16,  1)
	self:set_fog_color(0, 0, 0)

end

function Lights:set_ambient_color(r, g, b)
	local color = vmath.vector4(r, g, b, self.render.draw_opts.constants.ambient_color.w)
	self.render.draw_opts.constants.ambient_color = color
end

function Lights:get_ambient_color()
	return  self.render.draw_opts.constants.ambient_color
end

function Lights:get_fog_color()
	return  self.render.draw_opts.constants.fog_color
end

function Lights:get_fog()
	return  self.render.draw_opts.constants.fog
end

function Lights:set_ambient_color_intensity(intensity)
	local color = self.render.draw_opts.constants.ambient_color
	color.w = intensity
	self.render.draw_opts.constants.ambient_color = color
end

function Lights:set_ambient_color_intensity(intensity)
	local color = self.render.draw_opts.constants.ambient_color
	color.w = intensity
	self.render.draw_opts.constants.ambient_color = color
end

function Lights:set_sunlight_color(r, g, b)
	local color = vmath.vector4(r, g, b, self.render.draw_opts.constants.sunlight_color.w)
	self.render.draw_opts.constants.sunlight_color = color
end

function Lights:set_sunlight_direction(x,y,z)
	local direction = vmath.normalize(vmath.vector4(x,y,z,0))
	self.render.draw_opts.constants.sunlight_direction = direction
end

function Lights:set_sunlight_color_intensity(intensity)
	local color = self.render.draw_opts.constants.sunlight_color
	color.w = intensity
	self.render.draw_opts.constants.sunlight_color = color
end

function Lights:set_shadow_color(r, g, b)
	local color = vmath.vector4(1-r, 1-g, 1-b, self.render.draw_opts.constants.shadow_color.w)
	self.render.draw_opts.constants.shadow_color = color
end

function Lights:set_shadow_color_intensity(intensity)
	local color = self.render.draw_opts.constants.shadow_color
	color.w = intensity
	self.render.draw_opts.constants.shadow_color = color
end

function Lights:set_fog(min, max, intensity)
	local fog = vmath.vector4(min, max, 0, intensity)
	self.render.draw_opts.constants.fog = fog
end

function Lights:set_fog_color(r, g, b)
	local color = vmath.vector4(r, g, b, self.render.draw_opts.constants.fog_color.w)
	self.render.draw_opts.constants.fog_color = color
end


return Lights