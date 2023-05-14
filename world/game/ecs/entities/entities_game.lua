local COMMON = require "libs.common"
local DEBUG_INFO = require "debug.debug_info"
local DEFS = require "world.balance.def.defs"

local TABLE_REMOVE = table.remove
local TABLE_INSERT = table.insert

local DIR_UP = vmath.vector3(0, 1, 0)

local TAG = "Entities"

---@class InputInfo
---@field action_id hash
---@field action table

---@class EntityGame
---@field _in_world boolean is entity in world
---@field position vector3
---@field input_info InputInfo
---@field auto_destroy_delay number
---@field auto_destroy boolean
---@field visible boolean

---@class ENTITIES
local Entities = COMMON.class("Entities")

---@param world World
function Entities:initialize(world)
	self.world = world
	---@type EntityGame[]
	self.pool_input = {}
end



--region ecs callbacks
---@param e EntityGame
function Entities:on_entity_removed(e)
	DEBUG_INFO.game_entities = DEBUG_INFO.game_entities - 1
	e._in_world = false
	if (e.input_info) then
		TABLE_INSERT(self.pool_input, e)
	end
	if (e.physics_object) then
		game.physics_object_destroy(e.physics_object)
		e.physics_object = nil
	end
end

---@param e EntityGame
function Entities:on_entity_added(e)
	DEBUG_INFO.game_entities = DEBUG_INFO.game_entities + 1
	e._in_world = true
end

---@param e EntityGame
function Entities:on_entity_updated(e)

end
--endregion


--region Entities

local FACTORY_PLAYER_URL = msg.url("game_scene:/factory#player")
local PARTS_PLAYER = {
	ROOT = COMMON.HASHES.hash("/root"),
	LIGHT = COMMON.HASHES.hash("/light_spot"),
}
---@return EntityGame
function Entities:create_player()
	---@type EntityGame
	local e = {}
	e.player = true
	e.angle = 0
	e.player_data = {
		skin = DEFS.SKINS.SKINS_BY_ID.MINE.id
	}
	e.flashlight = {
		enabled = false
	}
	e.physics = {
		hitbox = vmath.vector3(0.4, 1.8, 0.4),
		velocity = vmath.vector3(),
		grounded = false,
	}
	e.ghost_mode = false
	e.look_at_dir = vmath.vector3(0, 0, 1)
	e.position = vmath.vector3(0, 0, 2)
	e.movement = {
		velocity = vmath.vector3(0, 0, 0),
		input = vmath.vector3(0, 0, 0),
		direction = vmath.vector3(0, 0, 0),
		max_speed = 4,
		max_speed_air_limit = 0.7,
		accel = 50 * 0.016,
		deaccel = 15 * 0.016,
		accel_air = 1.5 * 0.016,
		deaccel_air = 3 * 0.016,
		deaccel_stop = 0.5,
		strafe_power = 0.5,
		strafe_power_air = 0.66,

		pressed_jump = false,

		air_control_power = 0,
		air_control_power_a = 0
	}
	e.jump = {
		power = 800
	}
	e.camera = {
		position = vmath.vector3(),
		rotation = vmath.quat_rotation_z(0),

		position_physics = vmath.vector3(),
		hide_player = false,
		pitch_physics = 0,
		yaw = 180,
		pitch = 0,
		config = {
			physics_speed = 50,
			pitch_start_changed = 1.25, --fraction луча при котором начинается смещение  pitch
			hide_player_dist = 0.5,
			position = vmath.vector3(0.33, 2.5, 1.5),
			yaw = { speed = 0.1 },
			pitch = { speed = 0.1, min = -50, max = -25 },
		},
		config_first_person = {
			position = vmath.vector3(0, 1.75, 0),
			yaw = { speed = 0.1 },
			pitch = { speed = 0.1, min = -70, max = 70 },
		},
		first_person = true
	}
	e.visible = true

	local urls = collectionfactory.create(FACTORY_PLAYER_URL, e.position)
	e.player_go = {
		root = msg.url(assert(urls[PARTS_PLAYER.ROOT])),
		collision = nil,
		model = {
			root = nil,
			model = nil,
		},
		config = {
			scale = vmath.vector3(1),
			skin = nil,
			animation = nil,
			visible = true,
			look_dir = vmath.vector3(0, 0, 1),
			flashlight = {
				enabled = false
			}
		}
	}
	e.player_go.collision = COMMON.LUME.url_component_from_url(e.player_go.root, "collision")
	e.mass = go.get(e.player_go.collision, COMMON.HASHES.MASS)

	e.physics_linear_velocity = vmath.vector3()
	e.on_ground = false
	e.ground_normal = vmath.vector3(DIR_UP)
	e.on_ground_time = 0
	e.jump_last_time = -1

	e.physics_object = game.physics_object_create(e.player_go.root, e.player_go.collision, e.position, e.physics_linear_velocity)

	local light = self:create_light({
		color = vmath.vector4(1),
		radius = 6,
		smoothness = 0.25,
		cutoff = 0.25,
		enabled = false,
		position = vmath.vector3(e.position),
		rotation = vmath.quat_rotation_z(0)
	})

	e.flashlight.light = light

	return e
end

---@class LightInfo
local LightInfo = {
	---@type vector4
	color = "userdata",
	---@type vector3
	position = "userdata",
	---@type quat
	rotation = "userdata",
	---@type number
	radius = "number",
	---@type number
	smoothness = "number",
	---@type number
	cutoff = "number",
	---@type bool
	enabled = "boolean"
}

---@param light_info LightInfo
function Entities:create_light(light_info)
	checks("?", LightInfo)
	---@type EntityGame
	local e = {}
	e.light = true
	e.light_info = {
		color = vmath.vector4(light_info.color),
		radius = light_info.radius,
		smoothness = light_info.smoothness,
		cutoff = light_info.cutoff,
		enabled = light_info.enabled,
		position = vmath.vector3(light_info.position),
		rotation = vmath.quat(light_info.rotation),
		direction = vmath.vector3(0, 0, -1)
	}
	return e
end

---@return EntityGame
function Entities:create_input(action_id, action)
	local input = TABLE_REMOVE(self.pool_input)
	if (not input) then
		input = { input_info = {}, auto_destroy = true }
	end
	input.input_info.action_id = action_id
	input.input_info.action = action
	return input
end

--endregion

return Entities




