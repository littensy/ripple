curl -o scripts/roblox.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua

rojo sourcemap test.project.json -o sourcemap.json

luau-lsp analyze --defs=scripts/testez.d.lua --defs=scripts/roblox.d.lua --base-luaurc=.luaurc --sourcemap=sourcemap.json --ignore="**/_Index/**" --no-strict-dm-types src

rm scripts/roblox.d.lua
