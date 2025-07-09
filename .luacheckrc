cache = true
std = luajit
codes = true

globals = {
  "vim",
  -- FIXME: remove
  "_TeleporterConfigurationValues"
}

read_globals = {
  "vim"
}

ignore = {
  "631", -- max_line_length
  "212/_.*", -- unused argument, for vars with "_" prefix
  "214", -- used variable with unused hint ("_" prefix)
  -- "121", -- setting read-only global variable 'vim'
  "122", -- setting read-only field of global variable 'vim'
  -- "581", -- negation of a relational operator- operator can be flipped (not for tables)
}
