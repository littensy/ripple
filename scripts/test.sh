rojo build test.project.json -o test.rbxl

run-in-roblox --place test.rbxl --script scripts/run-tests.server.lua

rm test.rbxl
