local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

---@class InputSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("input_info")
System.name = "InputSystem"

function System:init_input()
	self.movement = vmath.vector4(0) --forward/back/left/right
	self.movement_up = vmath.vector4(0) --up/down
	self.input_handler = COMMON.INPUT()
	self.input_handler:add(COMMON.HASHES.INPUT.SPACE, function()
		self:jump()
	end, true)
	self.input_handler:add(COMMON.HASHES.INPUT.F, function()
		self:flashlight()
	end, true)
end

function System:jump()
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	player.movement.pressed_jump = true
end

function System:flashlight()
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	self.world.game_world.game:player_toggle_flashlight()
end

function System:check_movement_input()
	local hashes = COMMON.HASHES.INPUT
	local PRESSED = COMMON.INPUT.PRESSED_KEYS
	self.movement.x = (PRESSED[hashes.ARROW_UP] or PRESSED[hashes.W]) and 1 or 0
	self.movement.y = (PRESSED[hashes.ARROW_DOWN] or PRESSED[hashes.S]) and 1 or 0
	self.movement.w = (PRESSED[hashes.ARROW_LEFT] or PRESSED[hashes.A]) and 1 or 0
	self.movement.z = (PRESSED[hashes.ARROW_RIGHT] or PRESSED[hashes.D]) and 1 or 0
	--self.movement_up.x = PRESSED[hashes.SPACE] and 1 or 0
	--self.movement_up.y = PRESSED[hashes.LEFT_SHIFT] and 1 or 0


end

function System:update_player_direction()
	self:check_movement_input()
	local player = self.world.game_world.game.level_creator.player
	--[[local ctx = COMMON.CONTEXT:set_context_top_game_gui()
	if (ctx.data.views.virtual_pad_1:is_enabled() and ctx.data.views.virtual_pad_1.touch_idx) then
		player.movement.input.x, player.movement.input.y = ctx.data.views.virtual_pad_1:get_data()
	else--]]
	player.movement.input.x = self.movement.z - self.movement.w --right left
	player.movement.input.y = self.movement_up.x - self.movement_up.y
	player.movement.input.z = self.movement.y - self.movement.x-- forward back

	if (COMMON.CONTEXT:exist(COMMON.CONTEXT.NAMES.GAME_GUI)) then
		local ctx = COMMON.CONTEXT:set_context_top_game_gui()
		local pad = ctx.data.views.virtual_pad
		if (pad:is_enabled()) then
			if (pad:visible_is()) then
				if (not pad:is_safe()) then
					player.movement.input.x, player.movement.input.z = pad:get_data()
					player.movement.input.z = -player.movement.input.z
				end
			end
		end
		ctx:remove()
	end

	if (player.disabled or self.world.game_world.game.state.block_input) then
		player.movement.input.x = 0
		player.movement.input.y = 0
		player.movement.input.z = 0
	end
end

---@param e EntityGame
function System:process(e, dt)
	self.input_handler:on_input(self, e.input_info.action_id, e.input_info.action)
end
function System:postProcess()
	self:update_player_direction()
end

System:init_input()

return System