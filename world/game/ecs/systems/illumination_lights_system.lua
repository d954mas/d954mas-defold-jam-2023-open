local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local illumination = require "illumination.illumination"

--not forward:)
local V_FORWARD = vmath.vector3(0, 0, 1)

---@class IlluminationLightsSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("light")
System.name = "IlluminationLightsSystem"

---@param e EntityGame
function System:process(e, dt)
	local is_updated = true
	xmath.rotate(e.light_info.direction,e.light_info.rotation, V_FORWARD)
	if is_updated then
		illumination.set_light(e.light_info, e)
	end
end

return System