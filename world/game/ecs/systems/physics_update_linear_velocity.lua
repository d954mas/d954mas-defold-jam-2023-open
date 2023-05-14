local ECS = require 'libs.ecs'

local HASH_LINEAR_VELOCITY = hash("linear_velocity")
local GO_SET = go.set

---@class PhysicsUpdateLinearVelocity:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("physics_object")
System.name = "PhysicsUpdateLinearVelocity"

function System:update(dt)
	game.physics_objects_update_linear_velocity()
end

return System