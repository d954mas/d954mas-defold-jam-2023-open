#define EXTENSION_NAME Game
#define LIB_NAME "Game"
#define MODULE_NAME "game"

#include <dmsdk/sdk.h>

#include "camera.h"
#include "utils.h"
#include "physics_object.h"
#include "physics_defold.h"

static const dmhash_t MSG_ENABLE  = dmHashString64("enable");
static const dmhash_t MSG_DISABLE = dmHashString64("disable");
static const dmhash_t LINEAR_VELOCITY_HASH = dmHashString64("linear_velocity");

static const char PHYSICS_CONTEXT_NAME[] = "__PhysicsContext";
static const uint32_t PHYSICS_CONTEXT_HASH = dmHashBuffer32(PHYSICS_CONTEXT_NAME,strlen(PHYSICS_CONTEXT_NAME));

static char* COLLISION_OBJECT_EXT = "collisionobjectc";

namespace dmGameObject {
    void GetComponentUserDataFromLua(lua_State* L, int index, HCollection collection, const char* component_ext, uintptr_t* out_user_data, dmMessage::URL* out_url, void** world);
    PropertyResult GetProperty(HInstance instance, dmhash_t component_id, dmhash_t property_id, PropertyOptions options, PropertyDesc& out_value);
    void* GetWorld(HCollection collection, uint32_t component_type_index);
}

namespace dmScript {
    dmMessage::URL* CheckURL(lua_State* L, int index);
    bool GetURL(lua_State* L, dmMessage::URL& out_url);
    bool GetURL(lua_State* L, dmMessage::URL* out_url);
    void GetGlobal(lua_State*L, uint32_t name_hash);
}


namespace dmGameSystem
{
    struct BufferResource
    {
        void* m_BufferDDF;
        dmBuffer::HBuffer        m_Buffer;
        dmhash_t                 m_NameHash;
        uint32_t                 m_ElementCount;    // The number of vertices
        uint32_t                 m_Stride;          // The vertex size (bytes)
        uint32_t                 m_Version;
    };
}

namespace dmGameSystem{
    struct PhysicsScriptContext
    {
       dmMessage::HSocket m_Socket;
       uint32_t m_ComponentIndex;
    };
     uint16_t CompCollisionGetGroupBitIndex(void* world, uint64_t group_hash);
      void RayCast(void* world, const dmPhysics::RayCastRequest& request, dmArray<dmPhysics::RayCastResponse>& results);
}

using namespace StairsGameUtils;


 // Helper to get collisionobject component and world.
static void GetCollisionObject(lua_State* L, int indx,dmGameObject::HCollection collection, void** comp, void** comp_world){
    dmMessage::URL receiver;
    dmGameObject::GetComponentUserDataFromLua(L, indx, collection, COLLISION_OBJECT_EXT, (uintptr_t*)comp, &receiver, comp_world);
}



static int Script_Get(lua_State* L, dmhash_t property_id, dmGameObject::PropertyDesc& property_desc){
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);

   // dmMessage::URL sender;
   // dmScript::GetURL(L, &sender);

    dmMessage::URL* target = dmScript::CheckURL(L, 1);

    dmGameObject::HInstance target_instance = dmScript::CheckGOInstance(L,1);
   // dmGameObject::HInstance target_instance = dmGameObject::GetInstanceFromIdentifier(dmGameObject::GetCollection(instance), target.m_Path);
    if (target_instance == 0)
        return luaL_error(L, "Could not find any instance with id '%s'.", dmHashReverseSafe64(target->m_Path));
    dmGameObject::PropertyOptions property_options;
    property_options.m_Index = 0;
    property_options.m_HasKey = 0;


    dmGameObject::PropertyResult result = dmGameObject::GetProperty(target_instance, target->m_Fragment, property_id, property_options, property_desc);
    switch (result)
    {
    case dmGameObject::PROPERTY_RESULT_OK:
        {
           // dmGameObject::LuaPushVar(L, property_desc.m_Variant);
            return 1;
        }
    case dmGameObject::PROPERTY_RESULT_RESOURCE_NOT_FOUND:
        {
            return luaL_error(L, "Property '%s' not found!", dmHashReverseSafe64(property_id));

        }
    case dmGameObject::PROPERTY_RESULT_INVALID_INDEX:
        {
            return luaL_error(L, "Invalid index %d for property '%s'", property_options.m_Index+1, dmHashReverseSafe64(property_id));
        }
    case dmGameObject::PROPERTY_RESULT_INVALID_KEY:
        {
            return luaL_error(L, "Invalid key '%s' for property '%s'", dmHashReverseSafe64(property_options.m_Key), dmHashReverseSafe64(property_id));
        }
    case dmGameObject::PROPERTY_RESULT_NOT_FOUND:
        {
            const char* path = dmHashReverseSafe64(target->m_Path);
            const char* property = dmHashReverseSafe64(property_id);
            if (target->m_Fragment)
            {
                return luaL_error(L, "'%s#%s' does not have any property called '%s'", path, dmHashReverseSafe64(target->m_Fragment), property);
            }
            return luaL_error(L, "'%s' does not have any property called '%s'", path, property);
        }
    case dmGameObject::PROPERTY_RESULT_COMP_NOT_FOUND:
        return luaL_error(L, "Could not find component '%s' when resolving '%s'", dmHashReverseSafe64(target->m_Fragment), lua_tostring(L, 1));
    default:
        // Should never happen, programmer error
        return luaL_error(L, "go.get failed with error code %d", result);
    }
    return 0; // shouldn't reach this point
}


 // Helper to get collisionobject component and world.
static int CollisionGetLinearVelocityRaw(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 3);
    StairsGameUtils::check_arg_count(L, 1);
    dmGameObject::PropertyDesc property_desc;
    Script_Get(L,LINEAR_VELOCITY_HASH,property_desc);

    lua_pushnumber(L, property_desc.m_Variant.m_V4[0]);
    lua_pushnumber(L, property_desc.m_Variant.m_V4[1]);
    lua_pushnumber(L, property_desc.m_Variant.m_V4[2]);
    return 3;
}

static int PhysicsCountMask(lua_State *L){
    DM_LUA_STACK_CHECK(L, 1);
    StairsGameUtils::check_arg_count(L, 1);
    uint32_t mask = 0;
    luaL_checktype(L, 1, LUA_TTABLE);


    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return DM_LUA_ERROR("Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    lua_pushnil(L);
    while (lua_next(L, 1) != 0)
    {
        mask |= dmGameSystem::CompCollisionGetGroupBitIndex(world, dmScript::CheckHash(L, -1));
        lua_pop(L, 1);
    }
    lua_pushnumber(L,mask);
    return 1;
}

int Physics_RayCastSingleExist(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);

    dmMessage::URL sender;
    if (!dmScript::GetURL(L, &sender)) {
        return luaL_error(L, "could not find a requesting instance for physics.raycast");
    }

    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return DM_LUA_ERROR("Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    dmVMath::Point3 from( *dmScript::CheckVector3(L, 1) );
    dmVMath::Point3 to( *dmScript::CheckVector3(L, 2) );

    uint32_t mask = luaL_checknumber(L,3);


    dmArray<dmPhysics::RayCastResponse> hits;
    hits.SetCapacity(32);

    dmPhysics::RayCastRequest request;
    request.m_From = from;
    request.m_To = to;
    request.m_Mask = mask;
    request.m_ReturnAllResults = 0;

    dmGameSystem::RayCast(world, request, hits);
    lua_pushboolean(L,!hits.Empty());
    return 1;
}

int Physics_RayCastSingle(lua_State* L)
{
  //  DM_LUA_STACK_CHECK(L, 4);

    dmMessage::URL sender;
    if (!dmScript::GetURL(L, &sender)) {
        return luaL_error(L, "could not find a requesting instance for physics.raycast");
    }

    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return luaL_error(L,"Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    dmVMath::Point3 from( *dmScript::CheckVector3(L, 1) );
    dmVMath::Point3 to( *dmScript::CheckVector3(L, 2) );

    uint32_t mask = luaL_checknumber(L,3);

    dmArray<dmPhysics::RayCastResponse> hits;
    hits.SetCapacity(32);

    dmPhysics::RayCastRequest request;
    request.m_From = from;
    request.m_To = to;
    request.m_Mask = mask;
    request.m_ReturnAllResults = 0;

    dmGameSystem::RayCast(world, request, hits);
    lua_pushboolean(L,!hits.Empty());
    if(hits.Empty()){
        return 1;
    }else{
        dmPhysics::RayCastResponse& resp1 = hits[0];
        lua_pushnumber(L,resp1.m_Position.getX());
        lua_pushnumber(L,resp1.m_Position.getY());
        lua_pushnumber(L,resp1.m_Position.getZ());

        lua_pushnumber(L,resp1.m_Normal.getX());
        lua_pushnumber(L,resp1.m_Normal.getY());
        lua_pushnumber(L,resp1.m_Normal.getZ());
        return 7;
    }
}

 // Helper to get collisionobject component and world.
static int MeshSetAABB(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    dmBuffer::HBuffer mesh = dmScript::CheckBufferUnpack(L, 1);
    //dmBuffer::Result validate = dmBuffer::ValidateBuffer(mesh);
   // if(validate!=dmBuffer::RESULT_OK ){
    //    luaL_error(L,"buffer invalid");
   // }

    float* positions = 0x0;
    uint32_t components = 0;
    uint32_t stride = 0;
    uint32_t count = 0;
    dmBuffer::Result r = dmBuffer::GetStream(mesh, dmHashString64("position"), (void**)&positions, &count, &components, &stride);


    if (r == dmBuffer::RESULT_OK) {
        //must have at least 1 point
        if(count>0){
            float aabb[6];
            //min
            aabb[0] = positions[0];
            aabb[1] = positions[1];
            aabb[2] = positions[2];
            //max
            aabb[3] = positions[0];
            aabb[4] = positions[1];
            aabb[5] = positions[2];
            positions += stride;
            for (int i = 1; i < count; ++i){
                float x = positions[0];
                float y = positions[1];
                float z = positions[2];
                if(x<aabb[0]) aabb[0] = x;
                if(y<aabb[1]) aabb[1] = y;
                if(z<aabb[2]) aabb[2] = z;

                if(x>aabb[3]) aabb[3] = x;
                if(y>aabb[4]) aabb[4] = y;
                if(z>aabb[5]) aabb[5] = z;
                positions += stride;
            }
           // dmLogInfo("AABB{%.3f %.3f %.3f %.3f %.3f %.3f}",aabb[0],aabb[1],aabb[2],aabb[3],aabb[4],aabb[5])
            dmBuffer::Result metaDataResult = dmBuffer::SetMetaData(mesh, dmHashString64("AABB"), &aabb, 6, dmBuffer::VALUE_TYPE_FLOAT32);
            if (metaDataResult != dmBuffer::RESULT_OK) {
                luaL_error(L,"dmBuffer can't set AABB metadata");
            }
        }
    } else {
        luaL_error(L,"dmBuffer can't get position.Error:%d",r);
    }
    return 0;
}

static int GoGetPosition(lua_State* L){
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 2);
    if (!dmScript::IsVector3(L, 1)){
        luaL_error(L,"need vector3");
    }
    dmMessage::URL* target = dmScript::CheckURL(L, 2);

    Vectormath::Aos::Vector3 *out = dmScript::ToVector3(L, 1);
    dmGameObject::HInstance target_instance = dmScript::CheckGOInstance(L,2);
    if (target_instance == 0)
          return luaL_error(L, "Could not find any instance with id '%s'.", dmHashReverseSafe64(target->m_Path));
    dmVMath::Point3 result =  GetPosition(target_instance);
    out->setX(result.getX());
    out->setY(result.getY());
    out->setZ(result.getZ());
    return 0;
}

static int GoGetRotation(lua_State* L){
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 2);
    if (!dmScript::IsQuat(L, 1)){
        luaL_error(L,"need quat");
    }
    dmMessage::URL* target = dmScript::CheckURL(L, 2);

    Vectormath::Aos::Quat *out = dmScript::ToQuat(L, 1);
    dmGameObject::HInstance target_instance = dmScript::CheckGOInstance(L,2);
    if (target_instance == 0)
          return luaL_error(L, "Could not find any instance with id '%s'.", dmHashReverseSafe64(target->m_Path));
    *out =  GetRotation(target_instance);
    return 0;
}

static int PhysicsUpdateVariables(lua_State* L){
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    if (!lua_istable(L, 1)) {
        luaL_error(L,"need entities table");
    }
    int len = luaL_getn(L, 1);
    for (int i = 1; i<=len; ++i) {
        //get entity
        lua_rawgeti(L,1,i);

        lua_getfield(L,-1,"physics_go_url");
       // dmMessage::URL* target = dmScript::CheckURL(L, -1);
        dmGameObject::HInstance target_instance = dmScript::CheckGOInstance(L,-1);
        if (target_instance == 0){
            //return luaL_error(L, "Could not find any instance with id", dmHashReverseSafe64(target->m_Path));
            return luaL_error(L, "Could not find instance");
        }
        lua_pop(L,1);

        lua_getfield(L,-1,"position");
        Vectormath::Aos::Vector3 *out = dmScript::CheckVector3(L, -1);
        lua_pop(L,1);

        *out =  Vectormath::Aos::Vector3(GetPosition(target_instance));


        lua_getfield(L,-1,"physics_linear_velocity");
        Vectormath::Aos::Vector3 *linear_velocity = dmScript::CheckVector3(L, -1);
        lua_pop(L,1);


        lua_getfield(L,-1,"physics_collision_url");
        dmGameObject::PropertyDesc property_desc;
        dmMessage::URL* target = dmScript::CheckURL(L, -1);
        target_instance = dmScript::CheckGOInstance(L,-1);
        lua_pop(L,1);

        if (target_instance == 0) return luaL_error(L, "Could not find any instance with id '%s'.", dmHashReverseSafe64(target->m_Path));
        dmGameObject::PropertyOptions property_options;
        property_options.m_Index = 0;
        property_options.m_HasKey = 0;
      //  dmLogInfo("url:%s %s",dmHashReverseSafe64(target->m_Path),dmHashReverseSafe64(target->m_Fragment))
        dmGameObject::PropertyResult result = dmGameObject::GetProperty(target_instance, target->m_Fragment, LINEAR_VELOCITY_HASH, property_options, property_desc);
        switch (result){
            case dmGameObject::PROPERTY_RESULT_OK:{
                break;
            }
            case dmGameObject::PROPERTY_RESULT_RESOURCE_NOT_FOUND:{
                luaL_error(L, "Property '%s' not found!", dmHashReverseSafe64(LINEAR_VELOCITY_HASH));
            }
            case dmGameObject::PROPERTY_RESULT_INVALID_INDEX:{
                return luaL_error(L, "Invalid index %d for property '%s'", property_options.m_Index+1, dmHashReverseSafe64(LINEAR_VELOCITY_HASH));
            }
            case dmGameObject::PROPERTY_RESULT_INVALID_KEY:{
                return luaL_error(L, "Invalid key '%s' for property '%s'", dmHashReverseSafe64(property_options.m_Key), dmHashReverseSafe64(LINEAR_VELOCITY_HASH));
            }
            case dmGameObject::PROPERTY_RESULT_NOT_FOUND:{
                const char* path = dmHashReverseSafe64(target->m_Path);
                const char* property = dmHashReverseSafe64(LINEAR_VELOCITY_HASH);
                if (target->m_Fragment){
                    luaL_error(L, "'%s#%s' does not have any property called '%s'", path, dmHashReverseSafe64(target->m_Fragment), property);
                }
                luaL_error(L, "'%s' does not have any property called '%s'", path, property);
            }
            case dmGameObject::PROPERTY_RESULT_COMP_NOT_FOUND:
               return luaL_error(L, "Could not find component '%s' when resolving '%s'", dmHashReverseSafe64(target->m_Fragment), lua_tostring(L, 1));
            default:
               // Should never happen, programmer error
               return luaL_error(L, "go.get failed with error code %d", result);
        }

        linear_velocity->setX(property_desc.m_Variant.m_V4[0]);
        linear_velocity->setY(property_desc.m_Variant.m_V4[1]);
        linear_velocity->setZ(property_desc.m_Variant.m_V4[2]);

        lua_pop(L,1);
    }

   return 0;
}


static int SetScreenSizeLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 2);
    d954Camera::setScreenSize(luaL_checknumber(L, 1), luaL_checknumber(L, 2));
    return 0;
}

static int CameraSetViewPositionLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    d954Camera::setViewPosition(*dmScript::CheckVector3(L, 1));
    return 0;
}

static int CameraSetViewRotationLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    d954Camera::setViewRotation(*dmScript::CheckQuat(L, 1));
    return 0;
}

static int CameraGetViewLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    d954Camera::getCameraView(dmScript::CheckMatrix4(L, 1));
    return 0;
}

static int CameraGetPerspectiveLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    StairsGameUtils::check_arg_count(L, 1);
    d954Camera::getCameraPerspective(dmScript::CheckMatrix4(L, 1));
    return 0;
}

static int CameraScreenToWorldRayLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 6);
    StairsGameUtils::check_arg_count(L, 2);
    int x = luaL_checknumber(L,1);
    int y = luaL_checknumber(L,2);
    dmVMath::Vector3 pStart;
    dmVMath::Vector3 pEnd;
    d954Camera::screenToWorldRay(x,y,&pStart,&pEnd);
    lua_pushnumber(L,pStart.getX());
    lua_pushnumber(L,pStart.getY());
    lua_pushnumber(L,pStart.getZ());

    lua_pushnumber(L,pEnd.getX());
    lua_pushnumber(L,pEnd.getY());
    lua_pushnumber(L,pEnd.getZ());
    return 6;
}




// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
    {"set_screen_size", SetScreenSizeLua},
    {"camera_set_view_position", CameraSetViewPositionLua},
    {"camera_set_view_rotation", CameraSetViewRotationLua},
	{"camera_get_view", CameraGetViewLua},
	{"camera_get_perspective", CameraGetPerspectiveLua},
	{"camera_screen_to_world_ray", CameraScreenToWorldRayLua},


	{ "collision_get_linear_velocity_raw", CollisionGetLinearVelocityRaw },
    { "physics_raycast_single_exist", Physics_RayCastSingleExist },
    { "physics_raycast_single", Physics_RayCastSingle},
    { "physics_count_mask", PhysicsCountMask},

    { "mesh_set_aabb", MeshSetAABB},
    { "get_position", GoGetPosition},
    { "get_rotation", GoGetRotation},


    { "physics_update_variables", PhysicsUpdateVariables},

    { "physics_object_create", StairsGame::PhysicsObjectCreate},
    { "physics_object_destroy", StairsGame::PhysicsObjectDestroy},
    { "physics_object_set_update_position", StairsGame::PhysicsObjectSetUpdatePosition},
    { "physics_objects_update_variables", StairsGame::PhysicsObjectsUpdateVariables},
    { "physics_objects_update_linear_velocity", StairsGame::PhysicsObjectsUpdateLinearVelocity},

    {0, 0}

};

static void LuaInit(lua_State *L) {
    int top = lua_gettop(L);
    luaL_register(L, MODULE_NAME, Module_methods);
    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result AppInitializeMyExtension(dmExtension::AppParams *params) { return dmExtension::RESULT_OK; }
static dmExtension::Result InitializeMyExtension(dmExtension::Params *params) {
    // Init Lua
    LuaInit(params->m_L);
    d954Camera::reset();

    printf("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeMyExtension(dmExtension::AppParams *params) { return dmExtension::RESULT_OK; }

static dmExtension::Result FinalizeMyExtension(dmExtension::Params *params) { return dmExtension::RESULT_OK; }

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, AppInitializeMyExtension, AppFinalizeMyExtension, InitializeMyExtension, 0, 0, FinalizeMyExtension)