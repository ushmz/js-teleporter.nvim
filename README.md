# js-teleporter.nvim

js-teleporter.nvim is NeoVim extension to teleport between files like following in JavaScript/TypeScript project.

- .js(x) or .ts(x) file <-> test file
- .jsx or tsx file <-> storybook

**This plugin is inspired by [sa2taka/js-teleporter](https://github.com/sa2taka/js-teleporter). Thanks for a great plugin.**

<!--
## Demo

### Test - Demo

### Storybook - Demo
-->

## Setup

**Neovim v0.8.0 or above is required.**

Use your favorite package manager.

```lua
{ 'ushmz/js-teleporter.nvim' }
```

## Default value

```lua
require("js-teleporter").setup({
  -- Root directory of source.
  source_root = "src",
  -- Root directories of tests.
  -- Files under configured directories are considered tests.
  test_roots = { "__tests__" },
  -- Suffix to determine if the file is a test.
  test_file_suffix = ".test",
  -- Root directories of storybook.
  -- Files under configured directories are considered storybook.
  story_root = { "stories" },
  -- Suffix to determine if the file is a storybook.
  story_file_suffix = ".stories",
  -- Extensions to determine if the file is a test file.
  test_extensions = { ".ts", ".js", ".tsx", ".jsx", ".mts", ".mjs", ".cts", ".cjs" },
  -- Extensions to determine if the file is a storybook.
  story_extensions = { ".tsx", ".jsx" },
  -- Files in these directories are ignored
  ignore_path = { "node_modules" },
})
```
