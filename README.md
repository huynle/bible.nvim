# Bible.nvim
a neovim plugin that helps you study your bible a little more effectively.

It does so by using [bg2md.rb](https://github.com/jgclark/BibleGateway-to-Markdown) as the default provider.
**Please read disclaimer on [bg2md.rb](https://github.com/jgclark/BibleGateway-to-Markdown) if are using it as your
default provider.**

**WORK IN PROGRESS** - it is not stable yet, breaking changes can happen at any time.


# Plan for Bible.nvim
+ BibleStudy mode
  + be able to select bible text and make note -- using zk-nvim, make a literature note
  + be able to select bible text and link it to existing notes or ideas
  + click on commentaries, and follow commentaries
  + be able to have multiple views, configurable
    + chain of verse lookup, follow an idea.
+ LookUp Mode
  + selected verses can be displayed in multiple versions -- good for comparing text, learn hebrew, latin, etc

## Features
* [ ] framework that supports multiple providers. so you can get your bible from anywhere you have access to.
  + Local provider, or BibleGateway through bg2md, and more?
* [x] Single Verse lookup
* [ ] Multiple verse lookup
* [ ] Clean display
* [ ] Reference the bible verse in the view with cursor
* [ ] Tests
* [ ] Docs

# Credits
Bit and pieces of this plugin is gather from these plugins

* [bg2md.rb](https://github.com/jgclark/BibleGateway-to-Markdown)
