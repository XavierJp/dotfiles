-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.ignorecase = true
opt.smartcase = true
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.undofile = true
opt.inccommand = "split"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.cursorline = true
opt.splitbelow = true
opt.splitright = true
opt.showmode = false
opt.updatetime = 250
opt.timeoutlen = 300
opt.fillchars = { eob = " " }
opt.pumheight = 10
opt.laststatus = 3

-- Plugins
require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      on_highlights = function(hl, _)
        hl.Comment = { fg = hl.Comment.fg, italic = false }
        hl["@comment"] = { link = "Comment" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { "branch" },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
        },
        lualine_x = { "diagnostics" },
        lualine_y = { "filetype" },
        lualine_z = { "%l:%c" },
      },
      inactive_sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "%l:%c" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash", "c", "css", "diff", "go", "html", "javascript", "json",
        "lua", "luadoc", "markdown", "markdown_inline", "python", "query",
        "regex", "rust", "toml", "tsx", "typescript", "vim", "vimdoc",
        "vue", "yaml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}, {
  performance = { rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } } },
})

-- Keymaps
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic quickfix" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Diagnostics
vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
  virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- Neovide
if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h13"
  vim.g.neovide_cursor_animation_length = 0.08
  vim.g.neovide_cursor_trail_size = 0.4
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_padding_top = 4
  vim.g.neovide_padding_bottom = 4
  vim.g.neovide_padding_left = 8
  vim.g.neovide_padding_right = 8

  map("n", "<D-s>", "<cmd>w<cr>", { desc = "Save" })
  map({ "n", "v" }, "<D-c>", '"+y', { desc = "Copy" })
  map({ "n", "v", "i" }, "<D-v>", function()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end, { desc = "Paste" })
  map({ "n", "v" }, "<D-a>", "ggVG", { desc = "Select all" })
  map("n", "<D-z>", "u", { desc = "Undo" })
  map("n", "<D-w>", "<cmd>bd<cr>", { desc = "Close buffer" })
end
