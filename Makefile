test:
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.lua' }"

lint:
	luacheck lua/telescope
