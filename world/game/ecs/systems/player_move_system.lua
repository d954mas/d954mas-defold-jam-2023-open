local COMMON = require "libs.common"
local ECS = require 'libs.ecs'

local TARGET_DIR = vmath.vector3()
local TARGET_V = vmath.vector3()
local TEMP_V = vmath.vector3()

local V_UP = vmath.vector3(0, 1, 0)

local IMPULSE_V = vmath.vector3(0, 0, 0)

local QUAT_TEMP = vmath.quat_rotation_z(0)

---@class PlayerMoveSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerMoveSystem"

---@param e EntityGame
function System:ground_movement(e, dt)
	TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, 0, -e.movement.direction.y
	local max_speed = e.movement.input.z ~= 0 and e.movement.max_speed or e.movement.max_speed * e.movement.strafe_power
	if (vmath.length(TARGET_DIR) > 0) then
		--ignore if normal look up it can be like
		--vmath.vector3(-7.1524499389852e-07, 1, 1.3351240340853e-05) so ignore that
		if (e.ground_normal.y ~= 1) then
			xmath.cross(TARGET_DIR, e.ground_normal, TARGET_DIR)
			xmath.cross(TARGET_DIR, TARGET_DIR, e.ground_normal)
			--if (TARGET_DIR.y > 0) then
			--	TARGET_DIR.y = TARGET_DIR.y * 0.9
			--end
		end
		xmath.normalize(TARGET_DIR, TARGET_DIR)
	end
	xmath.mul(TARGET_V, TARGET_DIR, max_speed)

	local is_accel = vmath.dot(TARGET_V, e.movement.velocity) > 0

	local accel = is_accel and e.movement.accel or e.movement.deaccel
	if (e.movement.direction.x == 0 and e.movement.direction.y == 0) then
		xmath.lerp(e.movement.velocity, e.movement.deaccel_stop, e.physics_linear_velocity, TARGET_V)
		e.movement.velocity.y = 0
	else
		local current_speed = vmath.length(e.physics_linear_velocity)
		if (false and current_speed < 10) then
			e.movement.velocity.x = e.physics_linear_velocity.x + TARGET_DIR.x
			e.movement.velocity.y = e.physics_linear_velocity.y + TARGET_DIR.y
			e.movement.velocity.z = e.physics_linear_velocity.z + TARGET_DIR.z
			if (vmath.length(e.movement.velocity) > max_speed) then
				e.movement.velocity.x = TARGET_V.x
				e.movement.velocity.y = TARGET_V.y
				e.movement.velocity.z = TARGET_V.z
			end
		else
			local a = current_speed / max_speed
			if a < 0.5 then
				xmath.lerp(e.movement.velocity, accel , e.physics_linear_velocity, TARGET_V)
			else
				xmath.lerp(e.movement.velocity, accel, e.physics_linear_velocity, TARGET_V)
			end
		end
	end


	--	e.movement.velocity = vmath.lerp(accel, e.movement.velocity, target)
	if (vmath.length(e.movement.velocity) < 0.001) then
		e.movement.velocity.x = 0
		e.movement.velocity.y = 0
		e.movement.velocity.z = 0
	end
	--if (self.world.game_world.game.state.time - e.jump_last_time > 1) then
		e.physics_linear_velocity.y = e.movement.velocity.y
--	end
	e.physics_linear_velocity.x = e.movement.velocity.x
	e.physics_linear_velocity.z = e.movement.velocity.z

end

---@param e EntityGame
function System:air_movement(e, dt)
	local current_velocity = e.physics_linear_velocity
	--CURRENT_VELOCITY_DIR.x, CURRENT_VELOCITY_DIR.y, CURRENT_VELOCITY_DIR.z = current_velocity.x, 0, current_velocity.y
	local max_speed = e.movement.max_speed * e.movement.max_speed_air_limit

	if (e.movement.input.x == 0 and e.movement.input.z == 0) then
		e.movement.direction.x = -current_velocity.x
		e.movement.direction.y = current_velocity.z
		TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, 0, -e.movement.direction.y
		if (vmath.length(TARGET_DIR) > 0) then
			xmath.normalize(TARGET_DIR, TARGET_DIR)
		end

		TEMP_V.x, TEMP_V.y, TEMP_V.z = current_velocity.x, 0, -current_velocity.z
		local reset_limit = vmath.length(TEMP_V)

		TEMP_V.x, TEMP_V.y, TEMP_V.z = current_velocity.x, 0, current_velocity.z
		local new_velocity
		if (reset_limit > 10) then
			new_velocity = TEMP_V + vmath.vector3(e.movement.direction.x, 0, -e.movement.direction.y) * (0.1 * max_speed * 1 * dt)
		else
			new_velocity = TEMP_V + TARGET_DIR * (20 * 1 * dt)
		end

		local new_velocity_len = vmath.length(new_velocity)
		if (new_velocity_len > max_speed) then
			xmath.mul(new_velocity, new_velocity, max_speed / new_velocity_len)
			new_velocity_len = vmath.length(new_velocity)
		end

		TEMP_V.x, TEMP_V.y, TEMP_V.z = current_velocity.x, 0, current_velocity.z
		local diff = new_velocity - TEMP_V
		local diff_len = 0
		if (diff.x == diff.x and diff.y == diff.y and diff.z == diff.z) then
			diff_len = vmath.length(diff)
		end
		if (reset_limit and diff_len > reset_limit) then
			new_velocity.x = 0
			new_velocity.z = 0
		end

		if (new_velocity_len < 0.001) then
			current_velocity.x = 0
			current_velocity.z = 0
		else
			current_velocity.x = new_velocity.x
			current_velocity.z = new_velocity.z
		end

		e.movement.direction.x = 0
		e.movement.direction.y = 0
	else
		TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, 0, -e.movement.direction.y
		max_speed = e.movement.input.z ~= 0 and max_speed or max_speed * e.movement.strafe_power_air
		xmath.mul(TARGET_V, TARGET_DIR, max_speed)
		e.movement.velocity.x = e.physics_linear_velocity.x
		e.movement.velocity.y = 0
		e.movement.velocity.z = e.physics_linear_velocity.z

		local is_accel = vmath.dot(TARGET_V, e.movement.velocity) > 0
		local accel = is_accel and e.movement.accel_air or e.movement.deaccel_air
		local current_speed = vmath.length(e.movement.velocity)
		if (current_speed < 10) then
			e.movement.velocity.x = e.physics_linear_velocity.x + TARGET_DIR.x * 0.5
			--e.movement.velocity.y = e.physics_linear_velocity.y --+ TARGET_DIR.y * 0.5
			e.movement.velocity.z = e.physics_linear_velocity.z + TARGET_DIR.z * 0.5
			TEMP_V.x = e.movement.velocity.x
			TEMP_V.y = 0
			TEMP_V.z = e.movement.velocity.z
			local dspeed = vmath.length(TEMP_V) / max_speed
			if (dspeed > 1) then
				e.movement.velocity.x = TARGET_V.x / dspeed
				--e.movement.velocity.y = TARGET_V.y
				e.movement.velocity.z = TARGET_V.z / dspeed
			end
		else
			TEMP_V.x, TEMP_V.y, TEMP_V.z = e.physics_linear_velocity.x, 0, e.physics_linear_velocity.z
			xmath.lerp(e.movement.velocity, accel, TEMP_V, TARGET_V)
			e.movement.velocity.y = e.physics_linear_velocity.y
		end


		--]]--]]



		--	e.movement.velocity = vmath.lerp(accel, e.movement.velocity, target)
		if (vmath.length(e.movement.velocity) < 0.001) then
			e.movement.velocity.x = 0
			e.movement.velocity.z = 0
		end
		e.physics_linear_velocity.x = e.movement.velocity.x
		e.physics_linear_velocity.z = e.movement.velocity.z
	end


end

---@param e EntityGame
function System:process(e, dt)
	local time = self.world.game_world.game.state.time
	--normalize keyboard input
	if e.movement.input.x ~= 0 or e.movement.input.z ~= 0 then
		e.movement.direction.x = e.movement.input.x * (e.on_ground and e.movement.strafe_power or e.movement.strafe_power_air)
		e.movement.direction.y = -e.movement.input.z
		xmath.normalize(e.movement.direction, e.movement.direction)
	else
		e.movement.direction.x = 0
		e.movement.direction.y = 0
	end

	--if e.angle then
	xmath.quat_rotation_z(QUAT_TEMP, math.rad(e.angle))
	xmath.rotate(e.movement.direction, QUAT_TEMP, e.movement.direction)

	if(e.movement.direction.x ~=0 or e.movement.direction.y ~= 0)then
		e.look_at_dir.x = e.movement.direction.x
		e.look_at_dir.z = -e.movement.direction.y
	end

	--end

	if (e.on_ground) then
		--pressed jump.Minimum 3 frames in air or jump velocity can be resseted
		e.in_jump = time - e.jump_last_time < (0.167 * 4)
	end

	e.movement.air_control_power = 0
	e.movement.air_control_power_a = 0
	if (e.on_ground) then
		self:ground_movement(e, dt)
	else
		self:air_movement(e, dt)
	end



	local need_force = false
	if (e.movement.pressed_jump) then
		e.movement.pressed_jump = false

		local delta_ground_time = (time - e.on_ground_time)
		--2 frames min stay on ground before next jump or player can have strange jumps
		local on_ground = (e.on_ground and delta_ground_time > (0.167 * 2))
				or delta_ground_time < 0.1 --coyot time
		if (on_ground and time - e.jump_last_time > 0.5) then
			e.jump_last_time = time
			e.in_jump = true
			xmath.mul(IMPULSE_V, V_UP, (e.jump.power * e.mass))

			e.physics_linear_velocity.y = 0
			--e.physics_reset_y_velocity = self.world.game_world.game.state.time
			need_force = true
		end
	end

	if (need_force) then
		msg.post(e.player_go.collision, COMMON.HASHES.MSG.PHYSICS.APPLY_FORCE, { force = IMPULSE_V, position = e.position })
	end

	physics.wakeup(e.player_go.collision)



	e.moving = (math.abs(e.movement.velocity.x) > 0 or math.abs(e.movement.velocity.z) > 0)
			and (math.abs(e.movement.direction.x) > 0 or math.abs(e.movement.direction.y) > 0)

	if(e.on_ground and not e.moving and e.on_ground_time>1 and not e.in_jump and e.physics_linear_velocity.y<0.1)then
		go.set(e.player_go.collision,"linear_damping",1)
	else
		go.set(e.player_go.collision,"linear_damping",0)
	end

--	print(e.position)
end

return System