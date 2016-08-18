local colors = require('colors')
local doneScreen = require('doneScreen')
local gameCupcakeBatch = require('gameCupcakeBatch')
local gameDeckBasics = require('gameDeckBasics')
local gameDeckCards = require('gameDeckCards')
local gameKitchenBasics = require('gameKitchenBasics')
local gameUi = require('gameUi')
local particleEngine = require('particleEngine')
local rainbowStripes = require('rainbowStripes')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local settingsScreen = require('settingsScreen')
local textEngine = require('textEngine')
local tipEngine = require('tipEngine')
local ui = require('ui')

local alex = gameKitchenBasics.alex
local cupcakes = gameKitchenBasics.cupcakes
local deck = gameDeckBasics.deck
local discard = gameDeckBasics.discard
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
  deck:drawMany(5)
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
  isEndTurn = true,
  clicked = function (self)
    if self.turnCounter == 0 then
      screen:showNext(
        cupcakes.value,
        math.min(
          cupcakes.value,
          kitchen:getCleanupCost()))
    else
      if self.turnCounter >= 9 then
        gameDeckCards.ennuiInspirationCard:take(1)
      else
        gameDeckCards.ennuiInspirationCard:take(2)
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
  local targetingFailed = false
  if ui.targeting:isSet() then
    targetingFailed = not (
      ui.targeting:isSource(card)
      or ui.targeting:isSelected(card)
      or ui.targeting:isTargetable(card))
  end
  return not targetingFailed and (card.tip or card.text and card.description)
end

local infoBox = ui.rectangle:extend({
  title = nil,
  body = nil,
  font = 'big',
  color = colors.infoBoxAlpha(colors.card),
  borderColor = colors.infoBoxAlpha(colors.text),
  textColor = colors.text,
  highlightColor = colors.highlightColor,
  margin = gameUi.styledBoxCard.margin,
  width = gameUi.styledBoxCard.width,
  height = 267,
  paint = function (self)
    local color = self.color
    local textColor = self.textColor
    local borderColor = self.borderColor
    if self.tip then
      color = self.tipColor
      textColor = self.tipTextColor
      borderColor = self.tipBorderColor
    end
    rectangleEngine.paintBorder(
      borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      color, self.left, self.top, self.width, self.height)
    textEngine.paint(
      textColor,
      'bold',
      self.title,
      self.left + self.margin[1],
      self.top + self.margin[2])
    textEngine.paint(
      textColor,
      self.font,
      self.body,
      self.left + self.margin[1],
      self.top + self.margin[2] + 40)
  end,
  reset = function (self)
    self.title = 'Info box'
    self.body = 'Hover over a card to get\ndetailed info.'
    self.tip = false
  end,
  set = function (self, card)
    if card.tip then
      self.tip = true
      self.title = card.tip.text
      self.body = card.tip.description
      self.tipColor = card.color
      self.tipBorderColor = card.borderColor
      self.tipTextColor = card.textColor
    else
      self.title = card.text
      self.body = card.description
    end
  end,
})

local settingsButton = ui.card:extend({
  color = colors.card,
  borderColor = colors.text,
  textColor = colors.text,
  width = gameUi.styledBoxCard.width,
  height = gameUi.styledBoxCard.height,
  margin = { 13, 12 },
  font = 'big',
  text = 'Settings',
  description = 'Configure the program.',
  isSettings = true,
  clicked = function (self)
    settingsScreen.screen:show()
  end,
  refresh = function (self)
    self.top = kitchenMinutes.top
    self.left = hope.left
  end,
})

local tipBox = ui.card:extend({
  color = colors.card,
  borderColor = colors.hope.foreground,
  textColor = colors.hope.foreground,
  width = gameUi.styledBoxCard.width,
  height = gameUi.styledBoxCard.height,
  margin = { 13, 12 },
  font = 'big',
  normalText = 'Need a tip? Check here!',
  hoverText = 'Click to highlight!',
  text = nil,
  tip = nil,
  clicked = function (self)
    ui.tipHighlight:set({
      color = colors.hope.foreground,
      maxAlpha = 255,
      width = 3,
      duration = { 200, 4000, 2000 },
      isHighlighted = self.tip.isHighlighted,
    })
  end,
  refresh = function (self)
    self.text = self.normalText
    self.tip = tipEngine.getTip()
  end,
  checkHover = function (self, x, y, block)
    ui.card.checkHover(self, x, y, function ()
      if not ui.targeting:isSet() then
        self.text = self.hoverText
      end
      block(self)
    end)
  end,
})

local bakingColumn = gameUi.styledColumn:extend({
  left = 60,
  top = 60,
  cards = {
    infoBox,
    tipBox,
    gameUi.styledSpacerSymmetrical:extend(),
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
    discard,
    deck,
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

local inspirationColumn = gameUi.styledColumn:extend({
  left = mainColumn.left + gameUi.styledBoxCard.width + gameUi.columnSpacing,
  top = 60,
  cards = {
    hope,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.inspirationHeading,
    gameDeckCards.inspiration,
  }
})

screen = ui.screen:extend({
  backgroundColor = colors.lightBackground,
  next = doneScreen.screen,
  shapes = { bakingColumn, mainColumn, inspirationColumn, settingsButton },
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
    rainbowStripes.stripes:paintDiagonal()
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
    discard.cards = {}
    for i = 1, 5 do
      gameDeckCards.glimmerOfHope:extend():moveToDiscard({ skipParticle = true })
      gameDeckCards.letItGo:extend():moveToDiscard({ skipParticle = true })
    end
    deck.cards = {}
    hand.cards = {}
    hand.totalEnnuiRemoved = 0
    mindset.cards = {}
    kitchen.cards = {}
    kitchen.totalTasksCompleted = 0
    bakingColumn:refresh()
    local batch1 = gameCupcakeBatch.make(1)
    kitchen:insert(batch1)
    local batch2 = gameCupcakeBatch.make(2, batch1)
    kitchen:insert(batch2)
    morgan.value = 0
    alex.value = 0
    cupcakes.value = 0
    endTurn.turnCounter = 18
    ui.noActionTimeout:reset()

    local seed = love.timer.getTime()
    print(string.format('Seeding game with %f', seed))
    math.randomseed(seed)
    mainColumn:refresh()
    startTurn()
  end,
  showNext = function (self, ...)
    particleEngine.reset()
    ui.screen.showNext(self, ...)
  end,
})

return {
  screen = screen,
}
