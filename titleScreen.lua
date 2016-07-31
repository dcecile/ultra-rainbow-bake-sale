local audioEngine = require('audioEngine')
local colors = require('colors')
local introScreen = require('introScreen')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local unscaleF = resolutionEngine.unscaleFloat

local screen = ui.screen:extend({
  backgroundColor = colors.darkBackground,
  next = introScreen.screen,
  paint = function (self)
    ui.cursor:clickable()
    local width, height = resolutionEngine.getUnscaledDimensions()
    local titleText = textEngine.getTextObject(
      'title',
      'Ultra Rainbow Bake Sale')
    textEngine.paintTextObject(
        colors.inverseText,
        titleText,
        math.floor(width / 2 - unscaleF(titleText:getWidth()) / 2),
        math.floor(height / 2 - unscaleF(titleText:getHeight()) / 2))
  end,
  mousepressed = function (self, x, y, button, istouch)
    audioEngine.startMusic()
    self:showNext()
  end,
})

return {
  screen = screen,
}
