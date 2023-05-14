local M = {}

--ecs systems created in require.
--so do not cache then

-- luacheck: push ignore require

local require_old = require
local require_no_cache
local require_no_cache_name
require_no_cache = function(k)
	require = require_old
	local m = require_old(k)
	if (k == require_no_cache_name) then
		--        print("load require no_cache_name:" .. k)
		package.loaded[k] = nil
	end
	require_no_cache_name = nil
	require = require_no_cache
	return m
end

local creator = function(name)
	return function(...)
		require_no_cache_name = name
		local system = require_no_cache(name)
		if (system.init) then system.init(system, ...) end
		return system
	end
end

require = creator

M.AutoDestroySystem = require "world.game.ecs.systems.auto_destroy_system"
M.InputSystem = require "world.game.ecs.systems.input_system"
M.LockMouseSystem = require "world.game.ecs.systems.lock_mouse_system"
M.DaySystem = require "world.game.ecs.systems.day_system"
M.IlluminationLightsSystem = require "world.game.ecs.systems.illumination_lights_system"
M.SpawnFloorSystem = require "world.game.ecs.systems.spawn_floors_system"
M.CheckFloorLevelSystem = require "world.game.ecs.systems.check_floor_level_system"

M.GroundCheckSystem = require "world.game.ecs.systems.ground_check_system"
M.PhysicsUpdateLinearVelocitySystem = require "world.game.ecs.systems.physics_update_linear_velocity"
M.PhysicsUpdateVariablesSystem = require "world.game.ecs.systems.physics_update_variables"

M.PlayerCameraSystem = require "world.game.ecs.systems.player_camera_system"
M.PhysicsCameraSystem = require "world.game.ecs.systems.physics_camera_system"
M.PlayerMoveSystem = require "world.game.ecs.systems.player_move_system"
M.PlayerInfinitySystem = require "world.game.ecs.systems.player_infinity_system"
M.PlayerGroundDirSystem = require "world.game.ecs.systems.player_ground_dir_system"

M.DrawPlayerSystem = require "world.game.ecs.systems.draw_player_system"

require = require_old

-- luacheck: pop

return M