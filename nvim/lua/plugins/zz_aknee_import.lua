local dotfiles_root = "/home/zer0t0/dotfiles/nvim"
local dotfiles_lua = dotfiles_root .. "/lua"

if not vim.tbl_contains(vim.opt.rtp:get(), dotfiles_root) then
  vim.opt.rtp:append(dotfiles_root)
end

if not package.path:find(dotfiles_lua, 1, true) then
  package.path = package.path .. ";" .. dotfiles_lua .. "/?.lua;" .. dotfiles_lua .. "/?/init.lua"
end

return {
  { import = "aknee.plugins" },
  { import = "aknee.plugins.lsp" },
}
