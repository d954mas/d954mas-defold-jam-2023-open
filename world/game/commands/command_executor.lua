local COMMON = require "libs.common"
local TAG = "COMMAND_EXECUTOR"

---@class CommandExecutor
local Executor = COMMON.class("CommandExecutor")

function Executor:initialize()
	---@type CommandBase[]
	self.commands_queue = {}
	self:__init_coroutine()
end

function Executor:__init_coroutine()
	self.coroutine = coroutine.create(function()
		while (true) do
			local dt = coroutine.yield()
			self:__act(dt)
		end
	end)
end

function Executor:command_add(command)
	checks("?", "class:CommandBase")
	COMMON.i("add command:" .. tostring(command), TAG)
	table.insert(self.commands_queue, command)
end

function Executor:__act(dt)
	local command = table.remove(self.commands_queue, 1)
	self.current_command = command
	if command then
		COMMON.i("begin:" .. tostring(command), TAG)
		command:act(dt)
		COMMON.i("act_time:" .. self.current_command.act_time, TAG)
		COMMON.i("end:" .. tostring(command), TAG)
	end
	self.current_command = nil
end

function Executor:is_empty()
	return not self.current_command and #self.commands_queue == 0
end

function Executor:act(dt)
	COMMON.COROUTINES.coroutine_resume(self.coroutine, dt)
	if (self.current_command) then
		self.current_command.act_time = self.current_command.act_time + dt
	end
end

return Executor


