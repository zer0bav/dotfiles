return {
  -- 1. Treesitter (Syntax Highlight) Ayarları
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- LazyVim'in varsayılan listesine senin dillerini ekliyoruz
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "python",
          "go",
          "bash",
          "c",
          "cpp",
          "asm",
          "nasm",
          "gas",
        })
      end
    end,
  },

  -- 2. Copilot Ayarlar

  -- 2. Copilot Ayarları
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<C-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
  }, --
}
