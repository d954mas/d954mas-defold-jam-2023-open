local COMMON = require "libs.common"

---@class LevelCreator
local Creator = COMMON.class("LevelCreator")

---@param world World
function Creator:initialize(world)
	self.world = world
	self.ecs = world.game.ecs_game
	self.entities = world.game.ecs_game.entities
end

function Creator:create_player()
	self.player = self.entities:create_player()
	self.ecs:add_entity(self.player)
	self.ecs:add_entity(self.player.flashlight.light)
end

function Creator:create()
	self:create_player()
end

return Creator