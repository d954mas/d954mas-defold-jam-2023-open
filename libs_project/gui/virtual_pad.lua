local COMMON = require "libs.common"
local CAMERAS = require "libs_project.cameras"

local VirtualPad = COMMON.class("VirtualPad")

function VirtualPad:initialize(root_name)
	self.root_name = assert(root_name)
	self:bind_vh()
	self:init_view()
	self.enabled = true
	self.touch_id = nil
end

function VirtualPad:set_enabled(enabled)
	self.enabled = enabled
end

function VirtualPad:is_enabled()
	return self.enabled
end

function VirtualPad:bind_vh()
	self.vh = {
		root = gui.get_node(self.root_name .. "/root"),
		bg = gui.get_node(self.root_name .. "/bg"),
		center = gui.get_node(self.root_name .. "/center"),
		drag = gui.get_node(self.root_name .. "/drag"),
	}
end
function VirtualPad:init_view()
	self.data = {
		position = vmath.vector3(0),
		position_drag = vmath.vector3(0),
		dist_max = 100,
		dist_safe = 10,
	}
	self:visible_set(false)
end

function VirtualPad:visible_set(visible)
	gui.set_enabled(self.vh.root, visible)
end

function VirtualPad:visible_is()
	return gui.is_enabled(self.vh.root)
end

function VirtualPad:update()
	--if (not self:visible_is() and self.data.pressed) then
	--	self:pressed(self.data.action_x, self.data.action_y)
	--end
	if (self:is_enabled()) then
		local handled = false
		--check current finger
		for _, action in ipairs(COMMON.INPUT.TOUCH_MULTI) do
			if (action.id == self.touch_id) then
				handled = action.x < 440
				break
			end
		end
		if (not handled) then
			--try find new finger
			for _, action in ipairs(COMMON.INPUT.TOUCH_MULTI) do
				if (action.id ~= self.touch_id) then
					local x, y = CAMERAS.game_camera:screen_to_gui(action.screen_x,
							action.screen_y, CAMERAS.game_camera.GUI_ADJUST.STRETCH)
					if (action.x < 440) then
						self:pressed(x, y, action.id)
						handled = true
						break
					end
				end
			end
		end
		if (not handled) then
			self:reset()
		end
	end
end

function VirtualPad:pressed(x, y, touch_id)
	self.touch_id = touch_id or 0

	self.data.position.x, self.data.position.y = x, y
	self:visible_set(true)
	gui.set_position(self.vh.root, self.data.position)
end

function VirtualPad:reset()
	self.data.pressed = false
	self.data.pressed_initial = false
	self.data.position.x, self.data.position.y = 0, 0
	self.data.position_drag.x, self.data.position_drag.y = 0, 0
	self:visible_set(false)
	self.touch_id = nil
end

function VirtualPad:on_input(action_id, action)
	if (not self.enabled) then
		return false end

	if (action_id == COMMON.HASHES.INPUT.TOUCH or action_id == COMMON.HASHES.INPUT.TOUCH_MULTI) then
		if (action_id == COMMON.HASHES.INPUT.TOUCH) then
			action.id = 0
		end
		local actions = action.touch or { action }
		for _, touch in ipairs(actions) do
			if (touch.x < 440) then
				local x, y = CAMERAS.game_camera:screen_to_gui(touch.screen_x,
						touch.screen_y, CAMERAS.game_camera.GUI_ADJUST.STRETCH)
				if (not self:visible_is()) then
					if (touch.pressed) then
						self:pressed(x, y, touch.id)
					end
				end

				if (self:visible_is()) then
					self.data.position_drag.x = x - self.data.position.x
					self.data.position_drag.y = y - self.data.position.y
					local dist = vmath.length(self.data.position_drag)
					if (dist > self.data.dist_max) then
						local scale = self.data.dist_max / dist
						self.data.position_drag.x = self.data.position_drag.x * scale
						self.data.position_drag.y = self.data.position_drag.y * scale
					end
					gui.set_position(self.vh.drag, self.data.position_drag)
				end
			end
		end
	end
end

---@return number x[-1,1]
---@return number y[-1,1]
function VirtualPad:get_data()
	local x = COMMON.LUME.clamp(self.data.position_drag.x / self.data.dist_max, -1, 1)
	local y = COMMON.LUME.clamp(self.data.position_drag.y / self.data.dist_max, -1, 1)
	return x, y
end

function VirtualPad:is_safe()
	local pos = vmath.vector3(self.data.position_drag)
	local dist = vmath.length(pos)
	return dist < self.data.dist_safe
end

return VirtualPad