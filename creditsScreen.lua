local colors = require('colors')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local screen

local creditsCard = ui.card:extend({
  color = colors.textBox,
  borderColor = colors.inverseText,
  textColor = colors.inverseText,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local newGame = creditsCard:extend({
  text = 'New game',
  clicked = function (self)
    screen:showNext()
  end,
})

local exit = creditsCard:extend({
  text = 'Exit',
  clicked = function (self)
    love.event.quit()
  end,
})

screen = ui.screen:extend({
  backgroundColor = colors.darkBackground,
  buttons = ui.column:extend({
    top = 320,
    margin = 30,
    cards = { newGame, exit }
  }),
  show = function (self)
    self.credits = love.filesystem.read('credits.txt')
    ui.screen.show(self)
  end,
  update = function (self, time)
    self:refresh()
  end,
  refresh = function (self)
    local mouseX, mouseY = resolutionEngine.getUnscaledMousePosition()
    ui.cursor:clear()
    local width, height = resolutionEngine.getUnscaledDimensions()
    self.buttons.left = width / 2 - creditsCard.width / 2
    self.buttons:refresh()
    self.buttons:checkHover(mouseX, mouseY, function (card)
      if card:isClickable() then
        ui.cursor:clickable()
      end
    end)
  end,
  paint = function (self)
    textEngine.paint(colors.inverseText, 'big', self.credits, 20, 20)
    self.buttons:paint()
  end,
  mousepressed = function (self, x, y, button, istouch)
    self:refresh()
    self.buttons:mousepressed(x, y, button, istouch)
  end,
})

return {
  screen = screen,
}
