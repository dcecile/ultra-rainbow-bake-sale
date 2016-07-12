local colors = require('colors')
local introScreen = require('introScreen')
local textEngine = require('textEngine')
local ui = require('ui')

local screen = ui.screen:extend({
  backgroundColor = colors.darkBackground,
  next = introScreen.screen,
  paint = function (self)
    ui.cursor:clickable()
    local width, height = love.graphics.getDimensions()
    local titleText = textEngine.getTextObject(
      'title',
      'Ultra Rainbow Bake Sale')
    textEngine.paintTextObject(
        colors.inverseText,
        titleText,
        math.floor(width / 2 - titleText:getWidth() / 2),
        math.floor(height / 2 - titleText:getHeight() / 2))
  end,
  mousepressed = function (self, x, y, button, istouch)
    if not self.mute then
      love.audio.play(music)
    end
    self:showNext()
  end,
  mute = false,
})

return {
  screen = screen,
}
