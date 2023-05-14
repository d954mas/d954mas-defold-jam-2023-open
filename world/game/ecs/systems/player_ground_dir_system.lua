local COMMON = require "libs.common"
local ECS = require 'libs.ecs'


local V_UP = vmath.vector3(0, 1, 0)

local IMPULSE_V = vmath.vector3(0, 0, 0)

local QUAT_TEMP = vmath.quat_rotation_z(0)

---@class PlayerGroundDirSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerMoveSystem"

---@param e EntityGame
function System:process(e, dt)
	local normal = e.ground_normal or V_UP
	if(not e.on_ground)then normal = V_UP end
	if(not e.moving)then normal = V_UP end
	--normal.x = 0--avoid rotation on edges



	--make it not so strength
	local normal_a = 0.75
	local normal_player = V_UP * normal_a + normal * (1 - normal_a)
	xmath.normalize(normal_player, normal_player)
	if (normal_player.x ~= normal_player.x or normal_player.y ~= normal_player.y or normal_player.z ~= normal_player.z) then
		normal_player = math.vector3(0, 1, 0)
	end
	xmath.quat_from_to(QUAT_TEMP, V_UP, normal_player)
	--pprint(normal_player)
	go.set_rotation(QUAT_TEMP, e.player_go.root)
end

return System