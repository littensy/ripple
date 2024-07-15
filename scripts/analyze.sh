curl -o scripts/roblox.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau

rojo sourcemap test.project.json -o sourcemap.json

luau-lsp analyze \
	--settings=scripts/analyze-settings.json \
	--defs=scripts/roblox.d.luau \
	--defs=scripts/testez.d.luau \
	--base-luaurc=.luaurc \
	--sourcemap=sourcemap.json src

rm scripts/roblox.d.luau
