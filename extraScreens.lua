local colors = require('colors')
local rectangleEngine = require('rectangleEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local titleScreen
local introScreen
local doneScreen
local creditsScreen

titleScreen = {
  paint = function (self)
    ui.cursor:clickable()
    local width, height = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(colors.darkBackground)
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
    currentScreen = introScreen
    if not self.mute then
      love.audio.play(music)
    end
  end,
  mute = false,
}

local function paintLines(color, lines)
    local separator = textEngine.getTextObject('big', '/')
    local margin = 22
    local separatorLeft = 267
    local top = 155
    local lineHeight = 70

    for i, line in ipairs(lines) do
      local lineTop = top + (i - 1) * lineHeight
      local name = textEngine.getTextObject('big', line[1])
      local nameLeft = separatorLeft - margin - name:getWidth()
      local text = textEngine.getTextObject('big', line[2])
      local textLeft = separatorLeft + separator:getWidth() + margin
      textEngine.paintTextObject(color, name, nameLeft, lineTop)
      textEngine.paintTextObject(color, separator, separatorLeft, lineTop)
      textEngine.paintTextObject(color, text, textLeft, lineTop)
    end
end

introScreen = {
  paint = function (self)
    ui.cursor:clickable()
    love.graphics.setBackgroundColor(colors.darkBackground)
    local width, height = love.graphics.getDimensions()
    rectangleEngine.paintPadded(
      colors.textBox, 0, 0, width, height, -100)

    paintLines(colors.inverseText, {
      { 'Alex', 'Who\'s idea was this anyways?' },
      { 'Morgan', 'Come on, love will always conquer hatred.' },
      { 'Alex', 'With baked goods? We\'ve never baked before.' },
      { 'Morgan', 'Just follow the recipe. Like in science class.' },
      { 'Alex', 'You\'re no good at science.' },
      { 'Morgan', '...' },
      { 'Alex', 'Fine, let\'s just start with some simple cupcakes.' },
      { 'Morgan', 'Now we\'re talking!' },
    })
  end,
  mousepressed = function (self, x, y, button, istouch)
    currentScreen = self.gameScreen
    self.gameScreen:start()
  end,
}

doneScreen = {
  paint = function (self)
    ui.cursor:clickable()
    love.graphics.setBackgroundColor(colors.lightBackground)
    local width, height = love.graphics.getDimensions()
    rectangleEngine.paintPadded(
      colors.textBox, 0, 0, width, height, -100)
    paintLines(colors.inverseText, {
      { 'Morgan', 'We baked ' .. self.totalCupcakes .. ' cupcakes!' },
      { 'Alex', 'Great!' },
    })
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
    local mouseX, mouseY = love.mouse.getPosition()
    ui.cursor:clear()
    local width, height = love.graphics.getDimensions()
    self.buttons.left = width / 2 - creditsCard.width / 2
    self.buttons:refresh()
    self.buttons:checkHover(mouseX, mouseY)

    love.graphics.setBackgroundColor(colors.darkBackground)
    textEngine.paint(colors.inverseText, 'big', credits, 20, 20)
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
