vim.cmd([[
  set rtp+=.
  set rtp+=../plenary.nvim/

  runtime js-teleporter.lua
  runtime plugin/plenary.nvim 

  nnoremap ,,x :luafile %<CR>
]])
