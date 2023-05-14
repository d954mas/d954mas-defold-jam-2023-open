#ifndef dmsdk_internal_h
#define dmsdk_internal_h

namespace dmScript {
    dmMessage::URL* CheckURL(lua_State* L, int index);
    void PushURL(lua_State* L, dmMessage::URL const& url );
}



#endif