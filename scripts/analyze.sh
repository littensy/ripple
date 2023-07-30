curl -o scripts/roblox.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua

rojo sourcemap test.project.json -o sourcemap.json

luau-lsp analyze --settings=scripts/analyze-settings.json --defs=scripts/roblox.d.lua --defs=scripts/testez.d.lua --base-luaurc=.luaurc --sourcemap=sourcemap.json src

rm scripts/roblox.d.lua
