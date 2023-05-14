local ECS = require 'libs.ecs'
local UTILS = require "libs_project.utils"


local TEMP_V = vmath.vector3()

---@class PlayerPhysicsSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerPhysicsSystem"

---@param e EntityGame
function System:process(e, dt)
	e.movement.velocity.y = 0
	xmath.mul(TEMP_V, e.movement.velocity, dt)
	xmath.add(e.position, e.position, TEMP_V)
end

return System