local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"

local FACTORY_FLOOR_NUMBER = msg.url("game_scene:/factory/floors#floor_number_base")

---@class SpawnFloorsSystem:ECSSystem
local System = ECS.system()
System.name = "SpawnFloorsSystem"

function System:init()
	self.floors_area = 8 --keep 3 floors on top, current floor, and 3 floors on bottom
	self.floors_area_keep_first = self.floors_area+6 --keep 3 floors on top, current floor, and 3 floors on bottom
end

function System:onAddToWorld()
	self.floors = { }
end

function System:remove_floor(idx)
	COMMON.i("remove floor:" .. idx, System.name)
	local floor = assert(self.floors[idx])
	go.delete(floor.root, true)
	self.floors[idx] = nil
end

function System:create_floor(idx)
	assert(not self.floors[idx])
	local floors_list = self.world.game_world.balance.floors_list
	local def = floors_list[idx]
	--finish game no more floors.
	if (not def) then return end
	COMMON.i("create floor:" .. idx, System.name)
	local floor = {
		idx = idx,
		def = def,
	}
	local position = vmath.vector3(0)
	if (floors_list[idx - 1]) then
		position.x = floors_list[idx - 1].position_end.x + floors_list[idx - 1].position_start.x
		position.z = floors_list[idx - 1].position_end.z + floors_list[idx - 1].position_start.z
	end
	for i = 1, idx - 1 do
		position.y = position.y + floors_list[i].position_end.y
	end
	floor.position = position

	floor.urls = collectionfactory.create(floor.def.factory_url, position, floor.def.rotation)
	local root = floor.urls[hash("/world")]
	local entities = floor.urls[hash("/entities")]
	go.delete(entities, true)
	floor.root = root

	if (floor.def.floor_number) then
		local string_number = tostring(floor.idx)
		local dx = 0.75
		local start_x = math.floor(#string_number/2)*-dx
		if(#string_number%2 == 0 and start_x~=0)then
			start_x = start_x + dx/2
		end

		local floor_number_cfg = floor.def.floor_number
		for i = 1, #string_number do
			local sign = string_number:sub(i, i)
			local number = collectionfactory.create(FACTORY_FLOOR_NUMBER, floor_number_cfg.position
					+vmath.vector3(start_x+dx*(i-1),0,0), floor_number_cfg.rotation,
					nil, vmath.vector3(0.005))
			local number_root = msg.url(number[hash("/root")])
			local number_sprite = COMMON.LUME.url_component_from_url(number_root, COMMON.HASHES.SPRITE)
			sprite.play_flipbook(number_sprite, "floor_" .. sign)
			go.set_parent(number_root, floor.root)
		end

	end

	self.floors[idx] = floor
end

function System:update(dt)
	local floor = self.world.game_world.game.state.floor
	--check floors that need removed
	for k, v in pairs(self.floors) do
		if (k < floor - self.floors_area
		or k > math.max(floor + self.floors_area, self.floors_area_keep_first)) then
			self:remove_floor(k)
		end
	end
	--kep self.floors_area first floor always visible. or user can see blink when new floor created
	--looks like objects add at 0,0,0 and then move to position at next frame
	for i = math.max(1, floor - self.floors_area), math.max(floor + self.floors_area, self.floors_area_keep_first) do
		if not self.floors[i] then
			self:create_floor(i)
		end
	end

end

return System