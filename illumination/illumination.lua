local M = { }

local V4 = vmath.vector4()

M.need_update = false
M.light_idx_by_object = { }
M.lights = { }
M.constants = {}

local function update_light(light, idx)
	for _, constants in ipairs(M.constants) do
		V4.x,V4.y,V4.z = light.position.x, light.position.y, light.position.z
		constants.lights_position[idx] = V4
		V4.x,V4.y,V4.z = light.direction.x, light.direction.y, light.direction.z
		xmath.normalize(V4, V4)
		constants.lights_direction[idx] = V4
		constants.lights_color[idx] = light.color

		local radius = light.radius or 0
		local smoothness = math.max(0, math.min(light.smoothness or 1, 1))
		local cutoff = math.max(0, math.min(light.cutoff or 1, 1))

		V4.x = radius
		V4.y = smoothness
		V4.z = math.cos(cutoff * math.pi)
		constants.lights_data1[idx] = V4
	end
end

local function add_light(light, url)
	local index = #M.lights + 1
	M.lights[index] = light
	M.light_idx_by_object[url] = index

	update_light(light, index)
end

local function replace_light(light, url)
	local index = M.light_idx_by_object[url]
	M.lights[index] = light

	update_light(light, index)
end

local function delete_light(url)
	local removed_index = M.light_idx_by_object[url]
	table.remove(M.lights, removed_index)
	M.light_idx_by_object[url] = nil
	--update shifted lights
	for i = removed_index, #M.lights do
		update_light(M.lights[i], i)
	end
end

function M.set_light(light, url)
	assert(url, 'Can\'t set a light without an url')

	local light_is_on = light and light.color.w > 0 and light.radius > 0 and light.cutoff > 0 and light.enabled

	if M.light_idx_by_object[url] then
		if light_is_on then
			replace_light(light, url)
		else
			delete_light(url)
		end
	elseif light_is_on then
		add_light(light, url)
	end
end

function M.prepare_render()
	for _, constants in ipairs(M.constants) do
		local data = constants.lights
		data.x = #M.lights
		constants.lights = data
	end
end

function M.add_constants(constants)
	constants.lights_position = {}
	constants.lights_direction = {}
	constants.lights_color = {}
	constants.lights_data1 = {}
	constants.lights = vmath.vector4()
	table.insert(M.constants,constants)
end

return M