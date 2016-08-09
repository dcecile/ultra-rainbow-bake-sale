local colors = require('colors')
local rainbowStripes = require('rainbowStripes')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local screen

local creditsCard = ui.card:extend({
  color = colors.inverseText,
  borderColor = colors.text,
  textColor = colors.text,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local newGame = creditsCard:extend({
  text = 'New game',
  clicked = function (self)
    screen.next.start()
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
  backgroundColor = colors.inverseText,
  buttons = ui.column:extend({
    left = 250,
    top = 430,
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
    self.buttons:refresh()
    self.buttons:checkHover(mouseX, mouseY, function (card)
      if card:isClickable() then
        ui.cursor:clickable()
      end
    end)
  end,
  paint = function (self)
    local width, height = resolutionEngine.getUnscaledDimensions()
    rainbowStripes.stripes:paint()
    rectangleEngine.paint(colors.inverseText, self.buttons.left - 50, 0, width, height)
    textEngine.paint(colors.text, 'big', self.credits, self.buttons.left, 150)
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
