curl -o bin/roblox.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau

rojo sourcemap -o sourcemap.json

luau-lsp analyze \
	--defs=bin/roblox.d.luau \
	--flag:LuauFixIndexerSubtypingOrdering=true \
	--flag:LuauInstantiateInSubtyping=true \
	--sourcemap=sourcemap.json \
	--ignore="**/node_modules/**" \
	packages test storybook benchmarks

selene packages test storybook benchmarks

stylua --check packages test storybook benchmarks

rm bin/roblox.d.luau
