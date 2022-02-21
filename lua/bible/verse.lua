local Verse = {}
Verse.__index = Verse

function Verse:new()
  local this = { bibleName = "", bookName = "", chapterNr = {}, verseNr = 0 }
  setmetatable(this, self)
  return this
end

function Verse:nl()
  table.insert(self.lines, self.current)
  self.current = ""
  self.lineNr = self.lineNr + 1
end

