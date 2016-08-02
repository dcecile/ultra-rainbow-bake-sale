local colors = require('colors')
local doneScreen = require('doneScreen')
local gameCupcakeBatch = require('gameCupcakeBatch')
local gameDeckBasics = require('gameDeckBasics')
local gameDeckCards = require('gameDeckCards')
local gameKitchenBasics = require('gameKitchenBasics')
local gameUi = require('gameUi')
local particleEngine = require('particleEngine')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local settingsScreen = require('settingsScreen')
local textEngine = require('textEngine')
local ui = require('ui')

local alex = gameKitchenBasics.alex
local cupcakes = gameKitchenBasics.cupcakes
local discardPile = gameDeckBasics.discardPile
local drawPile = gameDeckBasics.drawPile
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local kitchen = gameKitchenBasics.kitchen
local mindset = gameDeckBasics.mindset
local morgan = gameKitchenBasics.morgan
local pendingCleanup = gameKitchenBasics.pendingCleanup

local screen

local function startTurn()
  hope.value = 0
  while #hand.cards > 0 do
    hand.cards[1]:moveToDiscard()
  end
  drawPile:drawMany(5)
  for i, card in ipairs(mindset.cards) do
    card.delay = false
  end
  morgan.isBusy = false
  alex.isBusy = false
  kitchen:tick()
end

local endTurn = gameUi.styledBoxCard:extend({
  text = 'End turn',
  description =
    'When there’s nothing left\n'
    .. 'to do, click to finish the\n'
    .. 'turn. Cards in hand will be\n'
    .. 'discarded and new ones\n'
    .. 'drawn.',
  clicked = function (self)
    if self.turnCounter == 0 then
      screen:showNext(
        cupcakes.value,
        math.min(
          cupcakes.value,
          kitchen:getCleanupCost()))
    else
      if self.turnCounter >= 9 then
        gameDeckCards.ennuiLibraryCard:take(1)
      else
        gameDeckCards.ennuiLibraryCard:take(2)
      end
      self.turnCounter = self.turnCounter - 1
      startTurn()
    end
  end,
  getBoxColors = function (self)
    return colors.time
  end,
  getBoxValue = function (self)
    return self.turnCounter
  end,
})

local kitchenMinutes = gameUi.styledBoxCard:extend({
  text = 'Kitchen minutes left',
  description =
    'The kitchen actually\n'
    .. 'belongs to Alex’s parents,\n'
    .. 'and they’re planning on\n'
    .. 'making dinner soon. Don’t\n'
    .. 'forget to clean up.',
  textColor = colors.time.foreground,
  getBoxColors = function (self)
    return colors.time
  end,
  getBoxValue = function (self)
    return endTurn.turnCounter * 5
  end,
})

local function hasInfo(card)
  return card.text and card.description
end

local infoBox = ui.rectangle:extend({
  title = nil,
  body = nil,
  font = 'big',
  borderColor = colors.text,
  color = colors.lightBackground,
  textColor = colors.text,
  highlightColor = colors.highlightColor,
  margin = gameUi.styledBoxCard.margin,
  width = gameUi.styledBoxCard.width,
  height = 315,
  paint = function (self)
    if ui.targeting:isSet() and ui.targeting:isSource(self) then
      rectangleEngine.paintPadded(
        self.highlightColor, self.left, self.top, self.width, self.height, 3)
    end
    rectangleEngine.paintPadded(
      self.borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      self.color, self.left, self.top, self.width, self.height)
    textEngine.paint(
      self.textColor,
      'bold',
      self.title,
      self.left + self.margin[1],
      self.top + self.margin[2])
    textEngine.paint(
      self.textColor,
      self.font,
      self.body,
      self.left + self.margin[1],
      self.top + self.margin[2] + 40)
  end,
  reset = function (self)
    self.title = 'Info box'
    self.body = 'Hover over a card to get\ndetailed info.'
  end,
  set = function (self, card)
    self.title = card.text
    self.body = card.description
  end,
})

local settingsButton = ui.card:extend({
  color = infoBox.color,
  borderColor = infoBox.borderColor,
  textColor = infoBox.textColor,
  width = infoBox.width,
  height = gameUi.styledBoxCard.height,
  margin = { 13, 12 },
  font = 'big',
  text = 'Settings',
  description = 'Configure the program.',
  clicked = function (self)
    settingsScreen.screen:show()
  end,
})

local bakingColumn = gameUi.styledColumn:extend({
  left = 60,
  top = 60,
  cards = {
    cupcakes,
    pendingCleanup,
    gameUi.styledSpacerSymmetrical:extend(),
    morgan,
    alex,
    kitchen,
  }
})

local mainColumn = gameUi.styledColumn:extend({
  left = bakingColumn.left + gameUi.styledBoxCard.width + gameUi.columnSpacing,
  top = 60,
  cards = {
    discardPile,
    drawPile,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.handHeading,
    hand,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.mindsetHeading,
    mindset,
    gameUi.styledSpacerSymmetrical:extend(),
    endTurn,
    kitchenMinutes,
  }
})

local libraryColumn = gameUi.styledColumn:extend({
  left = mainColumn.left + gameUi.styledBoxCard.width + gameUi.columnSpacing,
  top = 60,
  cards = {
    hope,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.libraryHeading,
    gameDeckCards.libraryColumn,
    gameUi.styledSpacerSymmetrical:extend(),
    infoBox,
    gameUi.styledSpacerSymmetrical:extend(),
    settingsButton,
  }
})

screen = ui.screen:extend({
  backgroundColor = colors.lightBackground,
  next = doneScreen.screen,
  shapes = { bakingColumn, mainColumn, libraryColumn },
  update = function (self, time)
    particleEngine.update(time)
    self:refresh()
  end,
  refresh = function (self)
    local mouseX, mouseY = resolutionEngine.getUnscaledMousePosition()
    ui.cursor:clear()
    infoBox:reset()
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:checkHover(mouseX, mouseY, function (card)
        if card:isClickable() then
          ui.cursor:clickable()
        end
        if hasInfo(card) then
          infoBox:set(card)
        end
      end)
    end
  end,
  paint = function (self)
    particleEngine.paint()
    for i, shape in ipairs(self.shapes) do
      shape:paint()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    self:refresh()
    local resetTargeting = ui.targeting:isSet()
    for i, shape in ipairs(self.shapes) do
      shape:mousepressed(x, y, button, istouch)
    end
    if resetTargeting and not ui.targeting.continue then
      ui.targeting:reset()
    end
    ui.targeting.continue = false
  end,
  start = function (self)
    particleEngine.reset()
    discardPile.cards = {
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
    }
    drawPile.cards = {}
    hand.cards = {}
    mindset.cards = {}
    kitchen.cards = {}
    bakingColumn:refresh()
    local batch1 = gameCupcakeBatch.make(1)
    kitchen:insert(batch1)
    local batch2 = gameCupcakeBatch.make(2, batch1)
    kitchen:insert(batch2)
    morgan.value = 0
    alex.value = 0
    cupcakes.value = 0
    endTurn.turnCounter = 18

    local seed = love.timer.getTime()
    print(string.format('Seeding game with %f', seed))
    math.randomseed(seed)
    mainColumn:refresh()
    drawPile:shuffle()
    startTurn()
  end,
})

return {
  screen = screen,
}
