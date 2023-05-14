local M = {}

M.START = {
	factory_url = msg.url("game_scene:/factory/floors#start"),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(1.75, -4, -5.5635),
	floor_number = { position = vmath.vector3(0, -2, -8.95) }
}
M.BASE_STAIRS_180 = {
	factory_url = msg.url("game_scene:/factory/floors#base_stairs"),
	rotation = vmath.quat_rotation_y(math.pi),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(-1.7375, -4, -1),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}
M.BASE_STAIRS = {
	factory_url = msg.url("game_scene:/factory/floors#base_stairs"),
	rotation = vmath.quat_rotation_y(0),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(1.75, -4, -5.5635),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}

M.BASE_STAIRS_LOCKED_180 = {
	factory_url = msg.url("game_scene:/factory/floors#base_stairs_locked"),
	rotation = vmath.quat_rotation_y(math.pi),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(-1.7375, -4, -1),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}
M.BASE_STAIRS_LOCKED = {
	factory_url = msg.url("game_scene:/factory/floors#base_stairs_locked"),
	rotation = vmath.quat_rotation_y(0),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(1.75, -4, -5.5635),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}

M.BASE_NO_FLOOR_180 = {
	factory_url = msg.url("game_scene:/factory/floors#base_no_floor"),
	rotation = vmath.quat_rotation_y(math.pi),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(-1.7375, -4, -1),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}
M.BASE_NO_FLOOR = {
	factory_url = msg.url("game_scene:/factory/floors#base_no_floor"),
	rotation = vmath.quat_rotation_y(0),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(1.75, -4, -5.5635),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}

M.BASE_NO_FLOOR_END_180 = {
	factory_url = msg.url("game_scene:/factory/floors#base_no_floor_end"),
	rotation = vmath.quat_rotation_y(math.pi),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(-1.7375, -4, -1),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}
M.BASE_NO_FLOOR_END = {
	factory_url = msg.url("game_scene:/factory/floors#base_no_floor_end"),
	rotation = vmath.quat_rotation_y(0),
	position_start = vmath.vector3(0),
	position_end = vmath.vector3(1.75, -4, -5.5635),
	floor_number = { position = vmath.vector3(1.75, -2, -7.95) }
}


for k, v in pairs(M) do
	M.id = k
end
return M