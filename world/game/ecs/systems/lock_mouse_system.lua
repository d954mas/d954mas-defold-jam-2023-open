local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local POINTER = require("libs.pointer_lock")

local QUAT_TEMP = vmath.quat_rotation_z(0)
local V_TEMP = vmath.vector3()
local V_FORWARD = vmath.vector3(0, 0, -1)

---@class LockMouseSystem:ECSSystemProcessing
local System = ECS.processingSystem()
System.filter = ECS.requireAll("input_info")
System.name = "LockMouseSystem"

function System:init()
	self.config = {
		yaw = 0,
		pitch = 0,
	}

	self.input_handler = COMMON.INPUT()
	self.input_handler:add_mouse(function(_, _, action)
		self:input_mouse_move(action)
	end)

	self.input_handler:add(COMMON.HASHES.INPUT.TOUCH, function(_, _, action)
		if (action.released and self.world.game_world.game.state.mouse_lock) then
			POINTER.lock_cursor()
		end
	end, true, false, true)

	self.input_handler:add(COMMON.HASHES.INPUT.ESCAPE, function(_, action_id, action)
		if (action.released) then
			POINTER.unlock_cursor()
		end

	end, true, false, true)
	self.input_handler:add(COMMON.HASHES.INPUT.TOUCH_MULTI, function(_, action_id, action)
		self:input_touch_rotation(action)

	end, true, false, true, true)
end

function System:onAddToWorld()
	if (self.world.game_world.game.state.mouse_lock) then
		POINTER.lock_cursor()
	end
end

function System:clamp_values()
	local camera = self.world.game_world.game.level_creator.player.camera
	local camera_config = camera.first_person and camera.config_first_person or camera.config
	if self.config.yaw < 0 then
		self.config.yaw = self.config.yaw + 360
	end
	if self.config.yaw >= 360 then
		self.config.yaw = self.config.yaw - 360
	end
	self.config.pitch = COMMON.LUME.clamp(self.config.pitch, camera_config.pitch.min, camera_config.pitch.max)
end

function System:camera_update(dt)
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end


	local camera = self.world.game_world.game.level_creator.player.camera
	if not camera.first_person and not player.moving then
		--print(self.config.yaw)

		local target_yaw = COMMON.LUME.angle2(V_FORWARD.x, V_FORWARD.z, player.look_at_dir.x, player.look_at_dir.z)
		target_yaw = COMMON.LUME.normalize_angle_deg(math.deg(target_yaw))

		local diff_yaw = target_yaw - self.config.yaw
		if (math.abs(diff_yaw) > 180) then
			local dmove = 360 - math.abs(diff_yaw)
			diff_yaw = -COMMON.LUME.sign(diff_yaw) * dmove
			--diff_yaw = -COMMON.LUME.sign(diff_yaw)*(math.abs(diff_yaw) - 180)
		end

		local dir = COMMON.LUME.sign(diff_yaw)
		local add_value = dir * 360 * dt
		if (math.abs(add_value) > math.abs(diff_yaw)) then
			self.config.yaw = target_yaw
		else
			self.config.yaw = self.config.yaw + add_value
		end
		--self.config.yaw = self.config.yaw + add_value

		self:clamp_values()
	end

end

function System:input_mouse_move(action)
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	if(not COMMON.html5_is_mobile())then
		local camera = self.world.game_world.game.level_creator.player.camera
		local camera_config = camera.first_person and camera.config_first_person or camera.config
		if POINTER.locked then
			if (camera.first_person) then
				self.config.yaw = self.config.yaw + (camera_config.yaw.speed * action.dx)
				self.config.pitch = self.config.pitch + (camera_config.pitch.speed * action.dy)
			end
		end
		self:clamp_values()
	end
end

function System:input_touch_rotation(action)
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	if(COMMON.html5_is_mobile())then
		local camera = self.world.game_world.game.level_creator.player.camera
		local camera_config = camera.first_person and camera.config_first_person or camera.config
		for i, touchdata in ipairs(action.touch) do
			if (touchdata.x > 460) then
				self.config.yaw = self.config.yaw + (camera_config.yaw.speed * touchdata.dx*4)
				self.config.pitch = self.config.pitch + (camera_config.pitch.speed * touchdata.dy*4)
				break
			end
		end
	end
end

function System:preProcess(dt)
	local player = self.world.game_world.game.level_creator.player
	self.config.yaw = player.camera.yaw
	self.config.pitch = player.camera.pitch
	self:clamp_values()
end

---@param e EntityGame
function System:process(e, dt)
	if (self.world.game_world.sm:get_top()._name == self.world.game_world.sm.SCENES.GAME) then
		self.input_handler:on_input(self, e.input_info.action_id, e.input_info.action)
	else
		--POINTER.unlock_cursor()
	end
end

function System:postProcess(dt)
	self:camera_update(dt)
	self:clamp_values()
	local player = self.world.game_world.game.level_creator.player
	--	go.set(player.camera_go.root,
	--	COMMON.HASHES.EULER, TEMP_V)
	player.angle = -self.config.yaw
	player.camera.yaw = self.config.yaw
	player.camera.pitch = self.config.pitch
end

function System:onRemoveFromWorld()
	--POINTER.unlock_cursor()
end

return System