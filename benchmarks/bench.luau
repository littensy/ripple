local function bench(name: string, test: () -> ())
	local start = os.clock()
	local iterations = 0

	while os.clock() - start < 3 do
		iterations += 1
		test()
	end

	local elapsed = os.clock() - start
	local micros = string.format("%.2f", elapsed / iterations * 1000 * 1000)

	print(`{name}: {micros} µs/iter`)
end

return bench
