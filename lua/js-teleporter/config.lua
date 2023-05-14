_TeleporterConfigurationValues = _TeleporterConfigurationValues or {}

local config = {}
config.values = _TeleporterConfigurationValues

local teleporter_default = {
	-- Root directory of source.
	source_root = "src",
	-- Root directories of tests.
	-- Files under configured directories are considered tests.
	test_source_roots = { "__tests__" },
	-- Suffix to determine if the file is a test.
	test_file_suffix = ".test",
	-- Root directories of storybook.
	-- Files under configured directories are considered storybook.
	storybook_source_roots = { "stories" },
	-- Suffix to determine if the file is a storybook.
	storybook_file_suffix = ".stories",
	-- Extensions to determine if the file is a test file.
	extensions_for_test = { ".ts", ".js", ".tsx", ".jsx", ".mts", ".mjs", ".cts", ".cjs" },
	-- Extensions to determine if the file is a storybook.
	extensions_for_storybook = { ".tsx", ".jsx" },
	-- Files in these directories are ignored
	ignore_path = { "node_modules" },
}

local first_non_nil = function(...)
	local n = select("#", ...)
	for i = 1, n do
		local value = select(i, ...)
		if value ~= nil then
			return value
		end
	end
end

config.set_options = function(opts)
	local get = function(name, default_value)
		return first_non_nil(opts[name], teleporter_default[name], default_value)
	end

	local set = function(name, default_value)
		config.values[name] = get(name, default_value)
	end

	for k, v in pairs(teleporter_default) do
		set(k, v)
	end

	local M = {}
	M.get = get
	return M
end

config.set_options({})

return config
