local ECS = require 'libs.ecs'
local ACTIONS = require "libs.actions.actions"
local COMMON = require "libs.common"

---@class PlayerInfinitySystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerInfinitySystem"

---@param e EntityGame
function System:process(e, dt)
	if(true) then return end
	if (e.disabled) then return end
	if (e.position.y < -39) then
		e.disabled = true
		local action = ACTIONS.Function { fun = function()
			msg.post(e.player_go.collision, COMMON.HASHES.MSG.DISABLE)
			coroutine.yield()

			go.set(e.player_go.collision, COMMON.HASHES.hash("linear_velocity"), vmath.vector3(0, 0, 0))
			go.set_position(vmath.vector3(0, 10, -2), e.player_go.root)
			msg.post(e.player_go.collision, COMMON.HASHES.MSG.ENABLE)
			coroutine.yield()
			COMMON.coroutine_wait(0.5)
			e.disabled = nil
		end }
		self.world.game_world.game.actions:add_action(action)
	end
end

return System