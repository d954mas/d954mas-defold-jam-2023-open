local ECS = require 'libs.ecs'

local TARGET_DIR = vmath.vector3()
local TARGET_V = vmath.vector3()
local TEMP_V = vmath.vector3()

local QUAT_TEMP = vmath.quat_rotation_z(0)

---@class PlayerFlySystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerFlySystem"

---@param e EntityGame
function System:process(e, dt)
	if(e.ghost_mode)then
		TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = 0, e.movement.input.y, 0
		local max_speed = e.movement.max_speed_fly

		xmath.mul(TARGET_V, TARGET_DIR, max_speed)
		xmath.mul(TARGET_V, TARGET_V, dt)
		xmath.add(e.position, e.position, TARGET_V)
	end
end

return System