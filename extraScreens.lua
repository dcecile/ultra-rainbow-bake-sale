local colors = require('colors')
local textEngine = require('textEngine')
local ui = require('ui')

local titleScreen
local introScreen
local doneScreen
local creditsScreen

titleScreen = {
  paint = function (self)
    local width, height = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(colors.darkBackground)
    local titleText = textEngine.getTextObject(
      'title', 
      'Ultra Rainbow Bake Sale')
    love.graphics.setColor(colors.inverseText)
    textEngine.paintTextObject(
        titleText,
        width / 2 - titleText:getWidth() / 2,
        height / 2 - titleText:getHeight() / 2)
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = introScreen
    if not self.mute then
      love.audio.play(music)
    end
  end,
  mute = false,
}

introScreen = {
  paint = function (self)
    love.graphics.setBackgroundColor(colors.darkBackground)
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(colors.textBox)
    love.graphics.rectangle('fill', 100.5, 100.5, width - 200, height - 200)
    love.graphics.setColor(colors.inverseText)

    local lines = {
      'Alex: Who\'s idea was this anyways?',
      'John: Come on, love will always conquer hatred.',
      'Alex: With baked goods? We\'ve never baked before.',
      'John: Just follow the recipe. Like in science class.',
      'Alex: You\'re no good at science.',
      'John: ...',
      'Alex: Fine, let\'s just start with some simple cupcakes.',
      'John: Now we\'re talking!',
    }

    for i, line in ipairs(lines) do
      textEngine.paint('big', line, 150, 150 + (i - 1) * 70)
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = self.gameScreen
    self.gameScreen:start()
  end,
}

doneScreen = {
  paint = function (self)
    love.graphics.setBackgroundColor(colors.lightBackground)
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(colors.textBox)
    love.graphics.rectangle('fill', 100.5, 100.5, width - 200, height - 200)
    love.graphics.setColor(colors.inverseText)
    local lines = {
      'John: We baked ' .. self.totalCupcakes .. ' cupcakes!',
      'Alex: Great!',
    }

    for i, line in ipairs(lines) do
      textEngine.paint('big', line, 150, 150 + (i - 1) * 70)
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = creditsScreen
    love.audio.stop()
  end,
}

local creditsCard = ui.card:extend({
  color = colors.textBox,
  borderColor = colors.inverseText,
  textColor = colors.inverseText,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

creditsScreen = {
  buttons = ui.column:extend({
    left = 50,
    top = 200,
    margin = 30,
    cards = {
      creditsCard:extend({
        text = 'New game',
        clicked = function (self)
          currentScreen = titleScreen
        end
      }),
      creditsCard:extend({
        text = 'Exit',
        clicked = function (self)
          love.event.quit()
        end
      }),
    },
  }),
  paint = function (self)
    love.graphics.setBackgroundColor(colors.darkBackground)
    love.graphics.setColor(colors.inverseText)
    textEngine.paint('big', credits, 20, 20)

    local width, height = love.graphics.getDimensions()
    self.buttons.left = width / 2 - creditsCard.width / 2
    self.buttons:refresh()
    self.buttons:paint()
  end,
  mousepressed = function (self, x, y, button, istouch)
    self.buttons:refresh()
    self.buttons:mousepressed(x, y, button, istouch)
  end,
}

return {
  titleScreen = titleScreen,
  introScreen = introScreen,
  doneScreen = doneScreen,
  creditsScreen = creditsScreen,
}
