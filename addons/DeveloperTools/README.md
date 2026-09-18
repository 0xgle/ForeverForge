# Developer tools

Do not install this directory into WoW. Install only ForeverCore.

Tests are a finite WoW-API mock running via the system Lua 5.4 shared library
and Python ctypes. On Linux, from the extracted ZIP root:

    python3 DeveloperTools/Tests/run_lua.py DeveloperTools/Tests/test.lua

Requires Python 3 and liblua5.4.so.0. No Python package installation is required.
The source uses Lua 5.1-compatible constructs; tests run on Lua 5.4 with the
unpack alias shim. This is not a test inside WoW or its protected environment.

Previews were rendered from the actual Lua widget tree using substitute fonts
and simulated addon data. They are layout previews, not in-game screenshots.
ArtSources contains the original two generated PNG assets. The addon uses
converted power-of-two TGA files and does not load these source PNGs.
