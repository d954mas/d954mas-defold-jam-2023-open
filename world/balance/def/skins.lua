local M = {}

M.SKINS_BY_ID = {}

M.SKINS_BY_ID.MINE = {
	factory = msg.url("game_scene:/factory/character#char_mine"),
	scale = vmath.vector3(1.95/6.8), --6.8 size of model
}

for k, v in pairs(M.SKINS_BY_ID) do
	v.id = k
end

M.SKIN_LIST = {
	M.SKINS_BY_ID.MINE,
}

return M