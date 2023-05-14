local M = {}
M.idx = 0

---@type BufferResourceData[]
M.free_buffers = {}
---@type BufferResourceData[]
M.all_buffers = {}

local function create_default_native_buffer()
	return buffer.create(1, {
		{ name = hash("data1"), type = buffer.VALUE_TYPE_UINT16, count = 1 },
		{ name = hash("data2"), type = buffer.VALUE_TYPE_UINT16, count = 1 },
		{ name = hash("data3"), type = buffer.VALUE_TYPE_UINT16, count = 1 },
	})
end

function M.init()
	M.buffer = create_default_native_buffer()
	for i = 1, 32 do
		table.insert(M.free_buffers, M.create_new_buffer(M.buffer))
	end
end

function M.get()
	local buffer = table.remove(M.free_buffers)
	if not buffer then
		buffer = M.create_new_buffer()
	end
	buffer.free = false
	return buffer
end

function M.free(buffer_data)
	assert(buffer_data)
	assert(type(buffer_data.buffer), "userdata")
	assert(not buffer_data.free)
	buffer_data.free = true
	resource.set_buffer(buffer_data.buffer, create_default_native_buffer())
	table.insert(M.free_buffers, buffer_data)
end

function M.create_new_buffer()
	M.idx = M.idx + 1
	local name = "/runtime_buffer_" .. M.idx .. ".bufferc"
	local new_buffer = resource.create_buffer(name, { buffer = M.buffer })

	---@class BufferResourceData
	local buffer_resource = {}
	buffer_resource.name = name
	buffer_resource.buffer = new_buffer
	buffer_resource.free = true

	table.insert(M.all_buffers, buffer_resource)

	return buffer_resource
end


return M