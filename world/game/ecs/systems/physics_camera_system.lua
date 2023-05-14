local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local TEMP_POS = vmath.vector3(0)
local PLAYER_POS = vmath.vector3(0)
local TEMP_DPOS = vmath.vector3(0)
local TEMP_DMOVE = vmath.vector3(0)
local TEMP_RAY_START = vmath.vector3(0)
local TEMP_V = vmath.vector3(0)
local TEMP_DIRECTION = vmath.vector3(0)
local TEMP_Q_YAW = vmath.quat_rotation_z(0)
local TEMP_Q_YAW_REVERSE = vmath.quat_rotation_z(0)
local TEMP_Q = vmath.quat_rotation_z(0)

--cast multiple rays to avoid camera flicking
local RAYS = {
	--base
	{ delta = vmath.vector3(0, 2, 0), angle = 0 },
	--little change in y
	--{ delta = vmath.vector3(0, 1.49, 0), angle = 0 },
	--{ delta = vmath.vector3(0, 1.51, 0), angle = 0 },
	--little change for angle
	--	{ delta = vmath.vector3(0, 1.5, 0), angle = math.rad(1) },
	--	{ delta = vmath.vector3(0, 1.5, 0), angle = math.rad(-1) },
}

---@class PhysicsCameraSystem:ECSSystem
local System = ECS.system()
System.name = "PhysicsCameraSystem"

function System:init()
	self.camera_raycast_groups = {
		hash("obstacle"), hash("camera")
	}
	self.camera_raycast_mask = game.physics_count_mask(self.camera_raycast_groups)
	self.hit_points = {}
	for i = 1, #RAYS do
		self.hit_points[i] = { hit = false, hit_point = vmath.vector3(), hit_normal = vmath.vector3() }
	end
	self.hit = false
	self.hit_frames = 0
end

---@param e EntityGame
function System:update(dt)
	local player = self.world.game_world.game.level_creator.player
	local camera = player.camera

	PLAYER_POS.x, PLAYER_POS.y, PLAYER_POS.z = player.position.x, player.position.y, player.position.z
	TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = player.position.x, player.position.y, player.position.z
	xmath.quat_rotation_y(TEMP_Q_YAW, math.rad(camera.yaw))
	xmath.quat_rotation_y(TEMP_Q_YAW_REVERSE, math.rad(-camera.yaw))


	-- Кидаем несколько лучей. Находим точки касания.
	for i, ray in ipairs(RAYS) do
		xmath.add(TEMP_RAY_START, PLAYER_POS, ray.delta)

		--count end point
		TEMP_DMOVE.x = camera.config.position.x
		TEMP_DMOVE.y = camera.config.position.y
		TEMP_DMOVE.z = camera.config.position.z
		xmath.quat_rotation_y(TEMP_Q, math.rad(-camera.yaw) + ray.angle)
		xmath.rotate(TEMP_DMOVE, TEMP_Q, TEMP_DMOVE)
		xmath.add(TEMP_DMOVE, TEMP_POS, TEMP_DMOVE)

		local ray_hit, ray_x, ray_y, ray_z, nx,ny,nz = game.physics_raycast_single(TEMP_RAY_START, TEMP_DMOVE, self.camera_raycast_mask)
		self.hit_points[i].hit = ray_hit
		if (ray_hit) then
			local point = self.hit_points[i].hit_point
			point.x, point.y, point.z = ray_x, ray_y, ray_z
			local normal = self.hit_points[i].hit_normal
			normal.x, normal.y, normal.z = nx, ny, nz
		end
	end

	TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = 0, 0, 0

	--Находим точку касания к которой стремится камера.
	local count = 0
	for i, ray in ipairs(self.hit_points) do
		if (ray.hit) then
			count = count + 1
			xmath.add(TEMP_POS, TEMP_POS, ray.hit_point)

			--fixed player can see through the wall
			--find direction from camera position to player
			xmath.sub(TEMP_DMOVE,ray.hit_point,player.position)
			xmath.sub(TEMP_DMOVE,TEMP_DMOVE,RAYS[i].delta)
			xmath.normalize(TEMP_DMOVE,TEMP_DMOVE)
			xmath.mul(TEMP_DMOVE,TEMP_DMOVE,-1)

			xmath.add(TEMP_DMOVE,TEMP_DMOVE,ray.hit_normal)


			xmath.normalize(TEMP_DMOVE,TEMP_DMOVE)
			TEMP_DMOVE.y = 0

			xmath.mul(TEMP_DMOVE,TEMP_DMOVE,0.25)
			xmath.add(TEMP_POS, TEMP_POS, TEMP_DMOVE)
		end
	end
	if (count == 0) then
		TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = player.position.x, player.position.y, player.position.z
		TEMP_DMOVE.x = camera.config.position.x
		TEMP_DMOVE.y = camera.config.position.y
		TEMP_DMOVE.z = camera.config.position.z
		xmath.rotate(TEMP_DMOVE, TEMP_Q_YAW_REVERSE, TEMP_DMOVE)
		xmath.add(TEMP_POS, TEMP_POS, TEMP_DMOVE)
	else
		xmath.div(TEMP_POS, TEMP_POS, count)
	end


	--убираем смещение камеры относительно позиции игрока
	xmath.sub(TEMP_DPOS, TEMP_POS, PLAYER_POS)
	--убираем поворот. Считаем как будто поворота не было
	xmath.rotate(TEMP_DPOS, TEMP_Q_YAW, TEMP_DPOS)

	--fixed flickering. Wait for some frames to start move camera
	local hit = count > 0
	if (self.hit ~= hit) then
		self.hit = hit
		self.hit_frames = -1
	end
	self.hit_frames = self.hit_frames + 1

	if(not self.position)then
		self.position = vmath.vector3(TEMP_DPOS)
	end

	if (self.hit_frames > -1) then
		--MOVE CAMERA BY SPEED
		xmath.sub(TEMP_V, TEMP_DPOS, self.position)
		if (vmath.length(TEMP_V) < 0.01) then
			self.position.x, self.position.y, self.position.z = TEMP_DPOS.x, TEMP_DPOS.y, TEMP_DPOS.z
		else
			xmath.normalize(TEMP_DIRECTION, TEMP_V)
			xmath.mul(TEMP_DIRECTION, TEMP_DIRECTION, player.camera.config.physics_speed * dt)
			if (vmath.length_sqr(TEMP_DIRECTION) > vmath.length_sqr(TEMP_V)) then
				TEMP_DIRECTION.x, TEMP_DIRECTION.y, TEMP_DIRECTION.z = TEMP_V.x, TEMP_V.y, TEMP_V.z
			end
			xmath.add(self.position, self.position, TEMP_DIRECTION)
		end
	end

	local fraction = vmath.length_sqr(self.position) / vmath.length_sqr(camera.config.position)
	local pitch_changed = camera.config.pitch_start_changed
	if (fraction > pitch_changed) then
		fraction = 1
	else
		fraction = fraction * 1 / pitch_changed
	end
	local pitch_target = player.camera.config.pitch.min + (player.camera.config.pitch.max - player.camera.config.pitch.min) * fraction

	if (not self.pitch) then
		self.pitch = pitch_target
	else
		self.pitch = pitch_target
	end
	--	pprint(self.position)

	--возвращаем поворот и добавляем позицию игрока(не добавляем позицию)
	camera.position_physics.x,camera.position_physics.y,camera.position_physics.z =self.position.x, self.position.y, self.position.z
	local dist = vmath.length(player.camera.position_physics)
	camera.hide_player = dist <= camera.config.hide_player_dist

	--xmath.rotate(player.camera.position_physics, TEMP_Q_YAW_REVERSE, player.camera.position_physics)
	--xmath.add(player.camera.position_physics, PLAYER_POS, player.camera.position_physics)

	camera.pitch_physics = self.pitch
	--ORIENTATION
	--xmath.quat_rotation_y(player.camera.rotation, -camera.yaw)
	--xmath.quat_rotation_x(TEMP_Q, math.rad(camera.pitch_physics))

	--xmath.quat_mul(player.camera.rotation_physics, TEMP_Q_YAW_REVERSE, TEMP_Q)

end

return System