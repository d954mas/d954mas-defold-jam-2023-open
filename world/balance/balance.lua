local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"
local TWEEN = require "libs.tween"

---@class Balance
local Balance = COMMON.class("Balance")

---@param world World
function Balance:initialize(world)
	self.world = assert(world)
	self.config = {

	}
end

function Balance:init_floors()
	self.floors_list = COMMON.LUME.clone_shallow(DEFS.FLOORS)
	self.floors_events = {
		no_way_11 = false,
		no_way_back_9 = false,
		floor_20 = false,
		floor_28 = false,
		floor_90 = false,
	}
end

function Balance:change_floor(from, to)
	print(string.format("change floor. From:%d to:%d", from, to))
	if (not self.floors_events.no_way_11) then
		if (to == 11) then
			local ctx = COMMON.CONTEXT:set_context_top_game_gui()
			ctx.data:add_dialog({ text = COMMON.LOCALIZATION.floor_11_no_way_closed(), time = 3, delay = 2 })
			ctx:remove()
			--change floor 9 to block
			self.floors_list[9] = DEFS.FLOOR_TYPES.BASE_STAIRS_LOCKED
			self.world.game.ecs_game.spawn_floor_system:remove_floor(9)
			self.floors_events.no_way_11 = true

		end
	elseif (not self.floors_events.no_way_back_9) then
		if (to == 10) then
			self.floors_events.no_way_back_9 = true
			local ctx = COMMON.CONTEXT:set_context_top_game_gui()
			ctx.data:add_dialog({ text = COMMON.LOCALIZATION.floor_9_no_way_back(), time = 3, delay = 2 })
			ctx:remove()
			--change floor 9 to block
			self.floors_list[11] = DEFS.FLOOR_TYPES.BASE_STAIRS
			self.world.game.ecs_game.spawn_floor_system:remove_floor(11)
			self.floors_list[12] = DEFS.FLOOR_TYPES.BASE_STAIRS_180
			self.world.game.ecs_game.spawn_floor_system:remove_floor(12)

			self.world.sounds:play_sound(self.world.sounds.sounds.ghost_moan_01)
			self.world.sounds:play_music(self.world.sounds.music.game_horror)
			--animate ambient
			self.world.game.lights:set_sunlight_color_intensity(0.1)
			self.world.game.lights:set_sunlight_color(0.5, 0.5, 0.5)
			self.world.game:animate_ambient(vmath.vector4(0.5, 0.5, 0.5, 0.6), 10, TWEEN.easing.inQuad)
			self.world.game.actions:add_action(function()
				COMMON.coroutine_wait(10)
				ctx = COMMON.CONTEXT:set_context_top_game_gui()
				ctx.data:add_dialog({ text = COMMON.LOCALIZATION.dialog_flashlight(), time = 3, delay = 0 })
				ctx:remove()
				COMMON.coroutine_wait(1)
				self.world.game:tooltip_use_flashlight()
			end)
		end
	elseif (not self.floors_events.floor_20) then
		if (to == 20) then
			self.floors_events.floor_20 = true
			self.world.sounds:play_sound(self.world.sounds.sounds.ghost_moan_01)
			self.world.game:animate_ambient(vmath.vector4(0.6, 0.3, 0.3, 0.3), 10, TWEEN.easing.linear)
		end

	elseif (not self.floors_events.floor_28) then
		if (to == 28) then
			self.floors_events.floor_28 = true
			local ctx = COMMON.CONTEXT:set_context_top_game_gui()
			ctx.data:add_dialog({ text = COMMON.LOCALIZATION.floor_28_no_floor(), time = 3, delay = 1 })
			ctx:remove()
			self.world.game:animate_fog(vmath.vector4(5, 8, 0, 1), 10, TWEEN.easing.linear)
		end

	elseif (not self.floors_events.floor_90) then
		if (to >= 90) then
			self.floors_events.floor_90 = true
			self.world.sm:reload()
		end
	end


end

return Balance