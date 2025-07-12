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

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'ushmz/js-teleporter.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim)

```viml
call dein#add('nvim-lua/plenary.nvim')
call dein#add('ushmz/js-teleporter.nvim')
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'ushmz/js-teleporter.nvim',
  requires = { {'nvim-lua/plenary.nvim'} }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
    {
    'ushmz/js-teleporter.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' }
    }

-- plugins/teleporter.lua:
return {
    'ushmz/js-teleporter.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' }
    }
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

## Config

| name              | type            | descriptions                                                                               | default                                                                                |
| ----------------- | --------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| source_root       | string          | Root directory of source.                                                                  | `"src"`                                                                                |
| test_roots        | array of string | Root directories of tests. Files under configured directories are considered tests.        | `["__tests__", "__specs__", "__test__", "__spec__", "tests", "specs", "test", "spec"]` |
| test_file_suffix  | string          | Suffix to determine if the file is a test.                                                 | `".test"`                                                                              |
| story_root        | array of string | Root directories of tests. Files under configured directories are considered tests.        | `["__tests__", "__specs__", "__test__", "__spec__", "tests", "specs", "test", "spec"]` |
| story_file_suffix | string          | Suffix to determine if the file is a test.                                                 | `".test"`                                                                              |
| test_extensions   | array of string | Root directories of storybook. Files under configured directories are considered storybook | `["stories"]`                                                                          |
| story_extensions  | string          | Suffix to determine if the file is a story book                                            | `.stories`                                                                             |
