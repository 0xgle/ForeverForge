import ctypes, pathlib, sys
lib=ctypes.CDLL('liblua5.4.so.0')
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lib.lua_tolstring.restype=ctypes.c_char_p
s=lib.luaL_newstate();lib.luaL_openlibs(s)
code=pathlib.Path(sys.argv[1]).read_bytes()
r=lib.luaL_loadstring(s,code)
if not r:r=lib.lua_pcallk(s,0,0,0,0,None)
if r:print(lib.lua_tolstring(s,-1,None).decode());sys.exit(1)
