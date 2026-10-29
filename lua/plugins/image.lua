return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = {
          -- render images inline in markdown/latex/typst/html buffers
          inline = true,
          -- also open them in a floating window on hover
          float = true,
          max_width = 80,
          max_height = 40,
        },
      },
    },
  },
}
