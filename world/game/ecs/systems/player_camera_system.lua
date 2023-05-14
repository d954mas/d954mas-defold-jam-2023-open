local ECS = require 'libs.ecs'
local RENDER_3D = require("render.render3d")


local TEMP_DMOVE = vmath.vector3(0)
local PLAYER_POS = vmath.vector3(0)
local TEMP_Q_YAW = vmath.quat_rotation_z(0)
local TEMP_Q_YAW_REVERSE = vmath.quat_rotation_z(0)
local TEMP_Q = vmath.quat_rotation_z(0)

---@class PlayerCameraSystem:ECSSystem
local System = ECS.system()
System.name = "PlayerCameraSystem"

function System:init()
	self.field_of_view = math.rad(42.5)
	self.near_clip = 0.1
	self.far_clip = 1000
end

function System:onLocationChanged()
	self.pitch = nil
	self.position = nil
end

---@param e EntityGame
function System:update(dt)
	if (self.world.game_world.game.state.dead) then return end
	local player = self.world.game_world.game.level_creator.player
	local camera = player.camera
	local config = camera.first_person and camera.config_first_person or camera.config
	local yaw_rad = math.rad(camera.yaw)
	local pitch_rad = math.rad(camera.pitch)
	local position = config.position

	--use physics camera
	if(not player.camera.first_person)then
		pitch_rad = math.rad(camera.pitch_physics)
		position = camera.position_physics
	end

	PLAYER_POS.x, PLAYER_POS.y, PLAYER_POS.z = player.position.x, player.position.y, player.position.z
	xmath.quat_rotation_y(TEMP_Q_YAW, yaw_rad)
	xmath.quat_rotation_y(TEMP_Q_YAW_REVERSE, -yaw_rad)

	xmath.rotate(TEMP_DMOVE, TEMP_Q_YAW_REVERSE,position)

	--xmath.rotate(player.camera.position, TEMP_Q_YAW_REVERSE, player.camera.position)
	xmath.add(player.camera.position, PLAYER_POS, TEMP_DMOVE)

	--ORIENTATION
	xmath.quat_rotation_x(TEMP_Q, pitch_rad)
	xmath.quat_mul(player.camera.rotation, TEMP_Q_YAW_REVERSE, TEMP_Q)




	game.camera_set_view_position(player.camera.position)
	game.camera_set_view_rotation(player.camera.rotation)
end

return System