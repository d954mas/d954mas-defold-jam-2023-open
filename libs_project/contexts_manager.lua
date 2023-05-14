local CLASS = require "libs.middleclass"
local ContextManager = require "libs.contexts_manager"

---@class ContextManagerProject:ContextManager
local Manager = CLASS.class("ContextManagerProject", ContextManager)

Manager.NAMES = {
	MAIN = "MAIN",
	GAME = "GAME",
	GAME_GUI = "GAME_GUI",
	BUILDING_BLOCKS = "BUILDING_BLOCKS",
}

---@class ContextStackWrapperMain:ContextStackWrapper
-----@field data ScriptMain

---@return ContextStackWrapperMain
function Manager:set_context_top_main()
	return self:set_context_top_by_name(self.NAMES.MAIN)
end

---@class ContextStackWrapperGame:ContextStackWrapper
-----@field data ScriptGame

---@return ContextStackWrapperGame
function Manager:set_context_top_game()
	return self:set_context_top_by_name(self.NAMES.GAME)
end

---@class ContextStackWrapperGameGui:ContextStackWrapper
-----@field data GameSceneGuiScript

---@return ContextStackWrapperGameGui
function Manager:set_context_top_game_gui()
	return self:set_context_top_by_name(self.NAMES.GAME_GUI)
end

return Manager()