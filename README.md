# Bible.nvim
a neovim plugin that helps you study your bible a little more effectively.

## Important Disclaimers

This project is **not affiliated with or approved by BibleGateway.com**. It aims to provide an
alternative to the common practice of copying and pasting Bible text directly from
BibleGateway.com's webpages into word processors.

To clarify, this project is for personal use only and does not infringe on BibleGateway.com's
copyright. The goal is to simplify the process of accessing the text-only version of the Bible,
without any additional formatting or non-textual content that may be present on their webpages.

As a reminder, it is essential to respect the intellectual property rights of others and always
seek permission before reproducing or distributing copyrighted material. This project is intended
as a tool for personal study and reflection and should not be used for commercial purposes.

Please note that the web pages produced by BibleGateway.com contain a significant amount of
non-textual content, with the actual Bible text constituting less than 5% of the page in most
cases. The internal structure of the Bible text returned can vary significantly from version to
version and may change without notice. Therefore, any oddities you might encounter could be due to
such changes that I am not yet aware of.

## Requirement
`pup` - https://github.com/ericchiang/pup. Have it in your system path.


## Features
- [x]: 2024-01-06 can query different bible version
- [x]: 2024-01-06 Single Verse lookup
- [x]: 2024-01-06 Multiple verse lookup
- [x]: 2024-01-06 Clean display, with `popup` or `split`
- [x]: 2024-01-06 Show footnotes and references in dropdown
- [ ]: Clean up docs


* Can query BibleGateway through fullname (Genesis 1:1) or shorname (Gn 1:1). Range are also
  supported, (Gen 1:1-2)


## Configuration
- see `lua/bible/config.lua` to override

lazy.nvim configuration

```lua

{
  "huynle/bible.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>bj",
      "<Cmd>BibleLookupSelection {view = 'below'}<CR>",
      mode = { "v" },
    },
    {
      "<leader>bb",
      "<Cmd>BibleLookupSelection<CR>",
      mode = { "v" },
    },
    {
      -- look up King James Version, if not defined, used default
      "<leader>bK",
      "<Cmd>BibleLookup {version = 'KJV'}<CR>",
      mode = { "n" },
    },
    {
      "<leader>bb",
      "<Cmd>BibleLookup<CR>",
      mode = { "n" },
    },
  },
  opts = {
    lookup_defaults = {
      -- defaults, for more configuration look at lua/bible/config.lua
      version = "NABRE", -- any version that is available on  BibleGateway
      query = "Genesis 1:1", -- query can be split be commas, e.g. 'Gen 1:1, Jn 1:1'
      view = "split",  -- 'split', 'below', 'right'
      numbering = true,
      footnotes = true,
    }
  },
}

```
