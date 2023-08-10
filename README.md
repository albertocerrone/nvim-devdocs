# nvim-devdocs

nvim-devdocs is a plugin which brings [DevDocs](https://devdocs.io) documentations into neovim. Install, search and preview documentations directly inside neovim in markdown format with telescope integration.

## Preview

![nvim-devdocs search](./.github/preview.png)

## Installation

Lazy:

```lua
return {
  "luckasRanarison/nvim-devdocs",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {}
}
```

The plugin uses treesitter API for converting HTML to markdown so make sure you have treesitter `html` parser installed.

Inside your treesitter configuration:

```lua
{
  ensure_installed = { "html" },
}
```

## Configuration

Here is the default configuration:

```lua
{
  dir_path = vim.fn.stdpath("data") .. "/devdocs", -- installation directory
  telescope = {}, -- passed to the telescope picker
  float_win = { -- passed to nvim_open_win(), see :h api-floatwin
    relative = "editor",
    height = 25,
    width = 100,
    border = "rounded",
  },
  wrap = false, -- text wrap
  ensure_installed = {}, -- get automatically installed
}
```

## Commands

Available commands:

- `DevdocsFetch`: Fetch DevDocs metadata.
- `DevdocsInstall`: Install documentation.
- `DevdocsUninstall`: Uninstall documentation.
- `DevdocsOpen`: Open documentation in a normal buffer.
- `DevdocsOpenFloat`: Open documentation in a floating window.

## TODO

- Add documentation.
- External previewers.
- More features.

## Credits

- [The DevDocs project](https://github.com/freeCodeCamp/devdocs) for the documentations.
- [devdocs.el](https://github.com/astoff/devdocs.el) for inspiration.
