local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local ENUMS = require 'world.enums.enums'
local DEFS = require "world.balance.def.defs"

local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

local V_FORWARD = vmath.vector3(0, 0, -1)
local LOOK_DIFF = vmath.vector3(0, 0, -1)
local DMOVE = vmath.vector3(0, 0, -1)

local V_LOOK_DIR = vmath.vector3(0, 0, -1)
local TEMP_V = vmath.vector3(0, 0, 0)

local Q_TEMP = vmath.quat_rotation_z(0)
local Q_ROTATION = vmath.quat_rotation_z(0)

---@class DrawPlayerSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.requireAll("player")
System.name = "PlayerDrawSystem"

---@param e EntityGame
function System:get_animation(e)
	local anim = ENUMS.ANIMATIONS.IDLE
	if (e.moving) then
		anim = ENUMS.ANIMATIONS.RUN
	end
	return anim
end

---@param e EntityGame
function System:onAdd(e)

end

---@param e EntityGame
function System:process(e, dt)
	if (e.player_data.skin ~= e.player_go.config.skin) then
		e.player_go.config.skin = e.player_data.skin
		e.player_go.config.animation = nil
		--DELETE PREV SKIN
		if (e.player_go.model.root) then
			go.delete(e.player_go.model.root)
			e.player_go.model.root = nil
			e.player_go.model.model = nil
		end
	end

	if (e.player_go.model.root == nil) then
		local skin_def = assert(DEFS.SKINS.SKINS_BY_ID[e.player_go.config.skin])
		local urls = collectionfactory.create(skin_def.factory, nil, nil, nil,
				skin_def.scale)
		local go_url = urls[PARTS.ROOT]
	--	go.set_parent(go_url, e.player_go.root, false)
		e.player_go.model.root = msg.url(go_url)
		e.player_go.model.model = COMMON.LUME.url_component_from_url(e.player_go.model.root, COMMON.HASHES.MODEL)
		e.player_go.config.visible = true
	end

	local visible = not e.camera.first_person
	if (visible ~= e.player_go.config.visible) then
		e.player_go.config.visible = visible
		--msg.post(e.player_go.root, visible and COMMON.HASHES.MSG.ENABLE or COMMON.HASHES.MSG.DISABLE)
		msg.post(e.player_go.model.root, visible and COMMON.HASHES.MSG.ENABLE or COMMON.HASHES.MSG.DISABLE)
	end

	local anim = self:get_animation(e)

	if (e.player_go.config.animation ~= anim) then
		e.player_go.config.animation = anim
		if (anim == ENUMS.ANIMATIONS.IDLE) then
			model.play_anim(e.player_go.model.model, "idle", go.PLAYBACK_ONCE_FORWARD)
		elseif (anim == ENUMS.ANIMATIONS.RUN) then
			model.play_anim(e.player_go.model.model, "run", go.PLAYBACK_LOOP_FORWARD, { blend_duration = 0.05 })
		end

	end
	go.set_position(e.position, e.player_go.model.root)




	--if (e.player_go.model.root) then
	V_LOOK_DIR.x, V_LOOK_DIR.y, V_LOOK_DIR.z = e.look_at_dir.x, 0, e.look_at_dir.z
	if (vmath.length(V_LOOK_DIR) == 0) then
		V_LOOK_DIR.x = V_FORWARD.x
		V_LOOK_DIR.y = V_FORWARD.y
		V_LOOK_DIR.z = V_FORWARD.z
	end
	xmath.normalize(V_LOOK_DIR, V_LOOK_DIR)

	xmath.sub(LOOK_DIFF, V_LOOK_DIR, e.player_go.config.look_dir)
	local diff_len = vmath.length(LOOK_DIFF)
	if (diff_len > 1.9) then
		xmath.quat_rotation_y(Q_ROTATION, math.rad(1))
		xmath.rotate(e.player_go.config.look_dir, Q_ROTATION, e.player_go.config.look_dir)
		xmath.lerp(e.player_go.config.look_dir, 0.3, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 1) then
		xmath.lerp(e.player_go.config.look_dir, 0.3, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 0.6) then
		xmath.lerp(e.player_go.config.look_dir, 0.2, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 0.1) then
		xmath.normalize(DMOVE, LOOK_DIFF)
		local scale = 3 --diff_len>0.1 and 0.8 or 0.6
		xmath.mul(DMOVE, DMOVE, scale * dt)
		if (vmath.length(DMOVE) > diff_len) then
			DMOVE.x = LOOK_DIFF.x
			DMOVE.y = LOOK_DIFF.y
			DMOVE.z = LOOK_DIFF.z
		end
		xmath.add(e.player_go.config.look_dir, e.player_go.config.look_dir, DMOVE)
	else
		--e.player_go.config.look_dir.x = V_LOOK_DIR.x
		--e.player_go.config.look_dir.y = V_LOOK_DIR.y
		--e.player_go.config.look_dir.z = V_LOOK_DIR.z
	end

	xmath.normalize(e.player_go.config.look_dir, e.player_go.config.look_dir)
	xmath.quat_from_to(Q_ROTATION, V_FORWARD, e.player_go.config.look_dir)

	if (Q_ROTATION.x ~= Q_ROTATION.x or Q_ROTATION.y ~= Q_ROTATION.y or Q_ROTATION.z ~= Q_ROTATION.z) then
		xmath.quat_rotation_y(Q_ROTATION, math.pi)
	end
	if (e.player_go.model) then
		go.set_rotation(Q_ROTATION, e.player_go.model.root)
	end



	if (e.camera.first_person) then
		e.flashlight.light.light_info.rotation.x = e.camera.rotation.x
		e.flashlight.light.light_info.rotation.y = e.camera.rotation.y
		e.flashlight.light.light_info.rotation.z = e.camera.rotation.z
		e.flashlight.light.light_info.rotation.w = e.camera.rotation.w

		e.flashlight.light.light_info.position.x = e.camera.position.x
		e.flashlight.light.light_info.position.y = e.camera.position.y
		e.flashlight.light.light_info.position.z = e.camera.position.z
	else
		e.flashlight.light.light_info.rotation.x = Q_ROTATION.x
		e.flashlight.light.light_info.rotation.y = Q_ROTATION.y
		e.flashlight.light.light_info.rotation.z = Q_ROTATION.z
		e.flashlight.light.light_info.rotation.w = Q_ROTATION.w

		TEMP_V.x, TEMP_V.y, TEMP_V.z = 0, 1.75, -0.5
		xmath.rotate(TEMP_V,Q_ROTATION,TEMP_V)
		xmath.add(TEMP_V,e.position,TEMP_V)
		e.flashlight.light.light_info.position.x = TEMP_V.x
		e.flashlight.light.light_info.position.y = TEMP_V.y
		e.flashlight.light.light_info.position.z = TEMP_V.z
	end

	if (e.flashlight.light.light_info.enabled ~= e.flashlight.enabled) then
		e.flashlight.light.light_info.enabled = e.flashlight.enabled
	end


end

return System