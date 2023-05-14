local COMMON = require "libs.common"

local M = {}


-- Lighting & Fog
M.light_ambient_color = vmath.vector3()
M.light_ambient_intensity = 0
M.light_directional_intensity = 0
M.light_directional_direction = vmath.vector3()
M.fog_intensity = 0
M.fog_range_from = 0
M.fog_range_to = 0
M.fog_color = vmath.vector3()

function M.reset()
	M.fov = math.rad(42.5)
	M.near = 0.1
	M.far = 100

	M.light_ambient_color = vmath.vector3(1, 1, 1)
	M.light_ambient_intensity = 0.25
	M.light_directional_intensity = 1.25
	M.light_directional_direction = vmath.vector3(-0.43193421279068, -0.86386842558136, -0.259160527674408)

	M.fog_intensity = 1.0
	M.fog_range_from = 50.0
	M.fog_range_to = 100.0
	M.fog_color = vmath.vector3(0.839, 0.957, 0.98)
end

-- Reset variables to default values
M.reset()


return M