local COMMON = require "libs.common"
local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"
local Base = require "world.game.commands.command_base"

---@class FirstFloorStartCommand:CommandBase
local Cmd = COMMON.class("FirstFloorStartCommand", Base)

function Cmd:initialize(data)
	Base.initialize(self, data)
end

function Cmd:check_data(data)
	checks("?", "?")
end

function Cmd:act(dt)
	self.world.game.state.block_input = true
	local vignette_params = vmath.vector4(0, 1, 0, 0)
	COMMON.RENDER.draw_opts_vignette.constants.tint = vmath.vector4(0, 0, 0, 1)
	COMMON.RENDER.draw_opts_vignette.constants.vignette_params = vignette_params

	self.world.sounds:play_sound(self.world.sounds.sounds.door_beep)
	COMMON.coroutine_wait(0.1)
	self.world.sounds:play_sound(self.world.sounds.sounds.door_beep)
	COMMON.coroutine_wait(0.06)
	self.world.sounds:play_sound(self.world.sounds.sounds.door_beep)
	COMMON.coroutine_wait(0.1)
	self.world.sounds:play_sound(self.world.sounds.sounds.door_beep)
	COMMON.coroutine_wait(0.3)
	self.world.sounds:play_sound(self.world.sounds.sounds.door_close)
	COMMON.coroutine_wait(2)
	local ctx = COMMON.CONTEXT:set_context_top_game_gui()
	ctx.data:add_dialog({ text = COMMON.LOCALIZATION.first_floor_awake(), time = 4 })
	ctx:remove()

	local object = {
		vignette_params = vignette_params
	}
	local tween = ACTIONS.TweenTable { object = object, property = "vignette_params",
									   to = vmath.vector4(2, 1, 0, 0), time = 3,
									   easing = TWEEN.easing.inQuad, v4 = true }
	while (tween:is_running()) do
		tween:update(coroutine.yield())
		COMMON.RENDER.draw_opts_vignette.constants.vignette_params = object.vignette_params
	end
	COMMON.RENDER.draw_opts_vignette.constants.vignette_params = object.vignette_params

	self.world.game.state.block_input = false
	COMMON.RENDER.draw_opts_vignette.constants.tint = vmath.vector4(1, 1, 1, 1)

	--
	ctx = COMMON.CONTEXT:set_context_top_game_gui()
	ctx.data:add_dialog({ text = COMMON.LOCALIZATION.first_floor_todo(), time = 2.5 })
	ctx:remove()

	local player_moved = false
	local player = self.world.game.level_creator.player
	--wait for player move or rotate
	while (not player_moved) do
		coroutine.yield()
		player_moved = player.moving or player.look_at_dir.z < 0.99
	end

	ctx = COMMON.CONTEXT:set_context_top_game_gui()
	ctx.data:add_dialog({ text = COMMON.LOCALIZATION.first_floor_door_closed(), time = 8 })
	ctx:remove()

end

return Cmd