local colors = require('colors')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local unscaleF = resolutionEngine.unscaleFloat

local function paintLines(color, lines)
    local separator = textEngine.getTextObject('big', '/')
    local margin = 22
    local separatorLeft = 267
    local top = 155
    local lineHeight = 70

    for i, line in ipairs(lines) do
      local lineTop = top + (i - 1) * lineHeight
      local name = textEngine.getTextObject('big', line[1])
      local nameLeft = separatorLeft - margin - unscaleF(name:getWidth())
      local text = textEngine.getTextObject('big', line[2])
      local textLeft = separatorLeft + unscaleF(separator:getWidth()) + margin
      textEngine.paintTextObject(color, name, nameLeft, lineTop)
      textEngine.paintTextObject(color, separator, separatorLeft, lineTop)
      textEngine.paintTextObject(color, text, textLeft, lineTop)
    end
end

local screen = ui.screen:extend({
  paint = function (self)
    ui.cursor:clickable()
    local width, height = resolutionEngine.getUnscaledDimensions()
    rectangleEngine.paint(
      colors.textBox, 100, 100, width - 200, height - 200)
    paintLines(colors.inverseText, self.lines)
  end,
})

return {
  screen = screen,
}
