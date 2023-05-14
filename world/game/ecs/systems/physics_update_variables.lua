local ECS = require 'libs.ecs'

---@class PhysicsUpdateVariables:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("physics_object")
System.name = "PhysicsUpdateVariables"

function System:update(dt)
	game.physics_objects_update_variables()
end

return System