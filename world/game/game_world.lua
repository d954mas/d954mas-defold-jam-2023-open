local COMMON = require "libs.common"
local EcsGame = require "world.game.ecs.game_ecs"
local ENUMS = require "world.enums.enums"
local DEBUG_INFO = require "debug.debug_info"
local ACTIONS = require "libs.actions.actions"
local COMMANDS = require "world.game.commands.commands"
local CommandsExecutor = require "world.game.commands.command_executor"

local LevelCreator = require "world.game.levels.level_creator"
local Lights = require "world.game.lights"

local IS_DEV = COMMON.CONSTANTS.VERSION_IS_DEV

local TAG = "GAME_WORLD"

---@class GameWorld
local GameWorld = COMMON.class("GameWorld")

---@param world World
function GameWorld:initialize(world)
	self.world = assert(world)
	self.ecs_game = EcsGame(self.world)
	self.lights = Lights(world)
	self.commands_executor = CommandsExecutor()
	self:reset_state()
end

function GameWorld:reset_state()
	self.animate_ambient_action = nil
	self.animate_fog_action = nil
	self.animate_fog_color_action = nil

	self.actions = ACTIONS.Parallel()
	self.actions.drop_empty = false
	self.state = {
		block_input = true,
		time = 0,
		floor = 1,
		state = ENUMS.GAME_STATE.RUN,
		mouse_lock = true,
	}
	self.lights:reset()
end

function GameWorld:game_loaded()
	DEBUG_INFO.game_reset()
	self.world.balance:init_floors()
	self.ecs_game:add_systems()
	self.level_creator = LevelCreator(self.world)
	self.level_creator:create()
	self:camera_set_first_person(true)
	self.commands_executor:command_add(COMMANDS.FirstFloorStartCommand())
	self.commands_executor:act(0)
	self.world.sounds:play_music(self.world.sounds.music.game)
end

function GameWorld:update(dt)
	if (self.state.state == ENUMS.GAME_STATE.RUN) then
		self.commands_executor:act(dt)
		if (IS_DEV) then DEBUG_INFO.ecs_update_dt = socket.gettime() end
		self.ecs_game:update(dt)
		if IS_DEV then DEBUG_INFO.update_ecs_dt(socket.gettime() - DEBUG_INFO.ecs_update_dt) end

		self.state.time = self.state.time + dt
		if (self.actions) then self.actions:update(dt) end
		if (self.animate_ambient_action) then
			self.animate_ambient_action:update(dt)
			if (self.animate_ambient_action:is_finished()) then
				self.animate_ambient_action = nil
			end
		end
		if (self.animate_fog_action) then
			self.animate_fog_action:update(dt)
			if (self.animate_fog_action:is_finished()) then
				self.animate_fog_action = nil
			end
		end
		if (self.animate_fog_color_action) then
			self.animate_fog_color_action:update(dt)
			if (self.animate_fog_action:is_finished()) then
				self.animate_fog_color_action = nil
			end
		end
	else
		--or not drawing
		self.ecs_game:update(0)
	end
end

function GameWorld:final()
	self:reset_state()
	self.ecs_game:clear()
end

function GameWorld:on_input(action_id, action)
	if (self.state.state == ENUMS.GAME_STATE.RUN) then
		self.ecs_game:add_entity(self.ecs_game.entities:create_input(action_id, action))
	end
	if (action_id == COMMON.HASHES.INPUT.F5 and action.pressed) then
		if (COMMON.CONSTANTS.TARGET_IS_EDITOR) then
			local data = game.get_world_level_data()
			local path = "./assets/levels/test_level.bin"
			local file = io.open(path, "wb")
			file:write(data)
			file:close()
		end
	elseif (action_id == COMMON.HASHES.INPUT.F8 and action.pressed and not self.state.load_world) then
		local path = "./assets/levels/test_level.bin"
		local status, file = pcall(io.open, path, "rb")
		if (not status) then
			COMMON.i("can't open file:" .. tostring(file), TAG)
		else
			if (file) then
				local contents, read_err = file:read("*all")
				if (not contents) then
					COMMON.i("can't read file:\n" .. read_err, TAG)
				else
					game.load_world_level_data(contents)
					self.state.load_world = true
					timer.delay(2 / 60, false, function()
						self.state.load_world = false
					end)
				end
				file:close()
			else
				COMMON.i("no file", TAG)
			end
		end
	end
end

function GameWorld:game_pause()
	if (self.state.state == ENUMS.GAME_STATE.RUN) then
		self.state.state = ENUMS.GAME_STATE.PAUSE
		self.world.sdk:gameplay_stop()
	end
end
function GameWorld:game_resume()
	if (self.state.state == ENUMS.GAME_STATE.PAUSE) then
		self.state.state = ENUMS.GAME_STATE.RUN
		self.world.sdk:gameplay_start()
	end
end

function GameWorld:camera_set_first_person(first_person)
	local camera = self.level_creator.player.camera
	if (camera.first_person ~= first_person) then
		camera.first_person = first_person
		--camera.yaw = 0
		camera.pitch = 0
		if (COMMON.CONTEXT:exist(COMMON.CONTEXT.NAMES.GAME_GUI)) then
			local ctx = COMMON.CONTEXT:set_context_top_game_gui()
			gui.set_enabled(ctx.data.vh.crosshair, first_person)
			ctx:remove()
		end
	end
end

function GameWorld:player_toggle_flashlight()
	local player = self.level_creator.player
	player.flashlight.enabled = not player.flashlight.enabled
end

function GameWorld:animate_ambient(color, time, easing)
	if (self.animate_ambient_action) then
		while (not self.animate_ambient_action:is_finished()) do
			self.animate_ambient_action:update(1)
		end
	end

	self.animate_ambient_action = ACTIONS.Function({ fun = function()
		local current_ambient_color = self.lights:get_ambient_color()
		local object = {
			color = current_ambient_color
		}
		local tween = ACTIONS.TweenTable { object = object, property = "color",
										   to = color, time = time,
										   easing = easing, v4 = true }
		tween:update(0)
		while (not tween:is_finished()) do
			local dt = coroutine.yield()
			tween:update(dt)
			self.lights:set_ambient_color(object.color.x, object.color.y, object.color.z)
			self.lights:set_ambient_color_intensity(object.color.w)
		end

	end

	})
end

function GameWorld:animate_fog(params, time, easing)
	if (self.animate_fog_action) then
		while (not self.animate_fog_action:is_finished()) do
			self.animate_fog_action:update(1)
		end
	end

	self.animate_fog_action = ACTIONS.Function({ fun = function()
		local current_fog = self.lights:get_fog()
		local object = {
			fog = current_fog
		}
		local tween = ACTIONS.TweenTable { object = object, property = "fog",
										   to = params, time = time,
										   easing = easing, v4 = true }
		tween:update(0)
		while (not tween:is_finished()) do
			local dt = coroutine.yield()
			tween:update(dt)
			self.lights:set_fog(object.fog.x, object.fog.y, object.fog.w)
		end

	end

	})
end

function GameWorld:animate_fog_color(color, time, easing)
	if (self.animate_fog_color_action) then
		while (not self.animate_fog_color_action:is_finished()) do
			self.animate_fog_color_action:update(1)
		end
	end

	self.animate_fog_color_action = ACTIONS.Function({ fun = function()
		local current_fog_color = self.lights:get_fog_color()
		local object = {
			color = current_fog_color
		}
		local tween = ACTIONS.TweenTable { object = object, property = "color",
										   to = color, time = time,
										   easing = easing, v4 = true }
		tween:update(0)
		while (not tween:is_finished()) do
			local dt = coroutine.yield()
			tween:update(dt)
			self.lights:set_fog_color(object.color.x, object.color.y, object.color.z)
		end

	end

	})
end

function GameWorld:tooltip_use_flashlight()
	local ctx = COMMON.CONTEXT:set_context_top_game_gui()
	ctx.data:tooltip_use_flashlight_show()
	ctx:remove()
	local current_flashlight_state = self.level_creator.player.flashlight.enabled
	self.actions:add_action(function()
		while (current_flashlight_state == self.level_creator.player.flashlight.enabled) do
			coroutine.yield()
		end
		ctx = COMMON.CONTEXT:set_context_top_game_gui()
		ctx.data:tooltip_use_flashlight_hide()
		ctx:remove()
	end, true)
end

return GameWorld



