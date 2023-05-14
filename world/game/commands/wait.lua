local COMMON = require "libs.common"
local Base = require "world.game.commands.command_base"

---@class WaitCommand:CommandBase
local Cmd = COMMON.class("WaitCommand", Base)

function Cmd:initialize(data)
	Base.initialize(self, data)
end

function Cmd:check_data(data)
	checks("?", "?")
end

function Cmd:act(dt)
	COMMON.COROUTINES.coroutine_wait(self.data.time)
end

return Cmd