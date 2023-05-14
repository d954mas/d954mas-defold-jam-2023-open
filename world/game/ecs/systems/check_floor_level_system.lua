local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"

---@class CheckFloorLevel:ECSSystem
local System = ECS.system()
System.name = "CheckFloorLevel"

function System:init()

end


function System:update(dt)
	local floor = math.ceil(math.abs(self.world.game_world.game.level_creator.player.position.y /4+0.001))
	if(self.world.game_world.game.state.floor ~= floor)then
		self.world.game_world.balance:change_floor(self.world.game_world.game.state.floor, floor)
		self.world.game_world.game.state.floor = floor
	end



end

return System