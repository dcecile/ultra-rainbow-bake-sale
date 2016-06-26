local textEngine = require('textEngine')

local titleScreen
local introScreen
local doneScreen
local creditsScreen

titleScreen = {
  draw = function (self)
    local width, height = love.graphics.getDimensions()
    love.graphics.setBackgroundColor({ 128, 0, 128 })
    local titleText = textEngine.getTextObject(
      'title', 
      'Ultra Rainbow Bake Sale')
    love.graphics.setColor({ 255, 255, 255 })
    love.graphics.draw(
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
  draw = function (self)
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor({ 0, 0, 0 })
    love.graphics.rectangle('fill', 100, 100, width - 200, height - 200)
    love.graphics.setColor({ 255, 255, 255 })

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
      textEngine.draw('big', line, 150, 150 + (i - 1) * 70)
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = self.gameScreen
  end,
}

doneScreen = {
  draw = function (self)
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor({ 0, 0, 0 })
    love.graphics.rectangle('fill', 100, 100, width - 200, height - 200)
    love.graphics.setColor({ 255, 255, 255 })
    local lines = {
      'John: We baked ' .. self.totalCupcakes .. ' cupcakes!',
      'Alex: Great!',
    }

    for i, line in ipairs(lines) do
      textEngine.draw('big', line, 150, 150 + (i - 1) * 70)
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = creditsScreen
    love.audio.stop()
  end,
}

creditsScreen = {
  draw = function (self)
    love.graphics.setBackgroundColor({ 128, 0, 128 })
    love.graphics.setColor({ 255, 255, 255 })
    textEngine.draw('big', credits, 20, 20)
  end,
  mousepressed = function (self, x, y, button, istouch)
  end,
}

return {
  titleScreen = titleScreen,
  introScreen = introScreen,
  doneScreen = doneScreen,
  creditsScreen = creditsScreen,
}
