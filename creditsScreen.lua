local colors = require('colors')
local rectangleEngine = require('rectangleEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local creditsCard = ui.card:extend({
  color = colors.textBox,
  borderColor = colors.inverseText,
  textColor = colors.inverseText,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local screen

local newGame = creditsCard:extend({
  text = 'New game',
  clicked = function (self)
    screen:showNext()
  end
})

local exit = creditsCard:extend({
  text = 'Exit',
  clicked = function (self)
    love.event.quit()
  end
})

screen = ui.screen:extend({
  backgroundColor = colors.darkBackground,
  buttons = ui.column:extend({
    left = 50,
    top = 200,
    margin = 30,
    cards = { newGame, exit }
  }),
  show = function (self)
    self.credits = love.filesystem.read('credits.txt')
    ui.screen.show(self)
  end,
  paint = function (self)
    local mouseX, mouseY = love.mouse.getPosition()
    ui.cursor:clear()
    local width, height = love.graphics.getDimensions()
    self.buttons.left = width / 2 - creditsCard.width / 2
    self.buttons:refresh()
    self.buttons:checkHover(mouseX, mouseY, function ()
      ui.cursor:clickable()
    end)

    textEngine.paint(colors.inverseText, 'big', self.credits, 20, 20)
    self.buttons:paint()
  end,
  mousepressed = function (self, x, y, button, istouch)
    self.buttons:refresh()
    self.buttons:mousepressed(x, y, button, istouch)
  end,
})

return {
  screen = screen,
  requireBackwards = requireBackwards,
}
