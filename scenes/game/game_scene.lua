local BaseScene = require "libs.sm.scene"

---@class GameScene:Scene
local Scene = BaseScene:subclass("Game")
function Scene:initialize()
	BaseScene.initialize(self, "GameScene", "/game_scene#collectionproxy")
end

function Scene:update(dt)
	BaseScene.update(self, dt)
end

function Scene:resume()
	BaseScene.resume(self)
end

function Scene:pause()
	BaseScene.pause(self)
end

function Scene:pause_done()

end

function Scene:resume_done()

end

function Scene:show_done()

end

function Scene:load_done()
	self._input = self._input or {}
end

return Scene