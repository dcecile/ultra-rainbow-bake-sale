local colors = require('colors')
local extraScreens = require('extraScreens')
local proto = require('proto')
local textEngine = require('textEngine')
local ui = require('ui')

local styledColumn = ui.column:extend({
  margin = 10
})

local boxCard = ui.card:extend({
  paint = function (self)
    local borderColor = self.borderColor
    local color = self.color

    if ui.targeting.from ~= nil then
      if ui.targeting:isSelected(self) then
        love.graphics.setColor(self.selectedHighlightColor)
        love.graphics.rectangle(
          'fill',
          self.left - 3 - 0.5,
          self.top - 3 - 0.5,
          self.width + 7,
          self.height + 7)
        borderColor = self.selectedBorderColor
      elseif not ui.targeting.from.isTargetable(self) then
        color = self.untargetableColor
      end
    end

    love.graphics.setColor(color)
    love.graphics.rectangle('fill', self.left, self.top, self.width, self.height)
    if borderColor then
      love.graphics.setColor(borderColor)
      love.graphics.rectangle('line', self.left, self.top, self.width, self.height)
    end

    love.graphics.setColor(self.textColor)
    textEngine.paint(
      self.font,
      self.text,
      self.left + self.margin[1],
      self.top + self.margin[2])

    local boxColors = self:getBoxColors()
    local boxValue = self:getBoxValue()
    local boxWidth = 50
    local boxLeft = self.left + self.width - boxWidth
    love.graphics.setColor(boxColors.background)
    love.graphics.rectangle(
      'fill',
      boxLeft + 1 - 0.5,
      self.top + 1 - 0.5,
      boxWidth - 1,
      self.height - 1)
    love.graphics.setColor(boxColors.foreground)
    love.graphics.line(
      boxLeft,
      self.top + 1,
      boxLeft,
      self.top + self.height)
    local costText = textEngine.getTextObject(self.font, tostring(boxValue))
    love.graphics.setColor(boxColors.foreground)
    textEngine.paintTextObject(
      costText,
      boxLeft + boxWidth / 2 - costText:getWidth() / 2,
      self.top + self.margin[2])
  end,
})

local styledBoxCard = boxCard:extend({
  color = colors.card,
  borderColor = colors.text,
  textColor = colors.text,
  selectedHighlightColor = colors.selectedHighlightColor,
  selectedBorderColor = colors.selectedBorderColor,
  untargetableColor = colors.untargetableColor,
  width = 330,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local styledSpacer = ui.spacer:extend({
  width = styledBoxCard.width,
  margin = { 20, 10 },
  color = colors.spacer,
})

local styledPile = styledBoxCard:extend({
  remove = ui.column.remove,
  insert = ui.column.insert,
  textColor = colors.cardPile.foreground,
  borderColor = colors.cardPile.foreground,
  getBoxColors = function (self)
    return colors.cardPile
  end,
  getBoxValue = function (self)
    return #self.cards
  end,
})

local discardPile = styledPile:extend({
  text = 'Discard'
})

local drawPile = styledPile:extend({
  text = 'Draw',
  shuffle = function (self)
    local newCards = {}
    while #self.cards > 0 do
      local nextIndex = math.random(#self.cards)
      local nextCard = table.remove(self.cards, nextIndex)
      table.insert(newCards, nextCard)
    end
    self.cards = newCards
  end,
  drawMany = function (self, drawCards)
    for i = 1, drawCards do
      if #self.cards > 0 then
        self.cards[1]:moveToHand()
      elseif #discardPile.cards > 0 then
        while #discardPile.cards > 0 do
          discardPile.cards[1]:moveToDraw()
        end
        self:shuffle()
        self.cards[1]:moveToHand()
      end
    end
  end,
  cards = {},
})

local styledDeckCardColumn = styledColumn:extend({
  cards = {},
  minHeight = styledBoxCard.height * 5 + styledColumn.margin * 4,
  maxCards = 5,
  tryDiscard = function (self, number, except, block)
    if number <= 0 then
      block()
    else
      ui.targeting:set({
        isTargetable = function (card)
          return card.column == self and card ~= except
        end,
        target = function (card)
          ui.targeting:toggleSelected(card)
          if #ui.targeting.selected == number then
            for i, selectedCard in ipairs(ui.targeting.selected) do
              selectedCard:moveToDiscard()
            end
            ui.targeting:reset()
            block()
          else
            ui.targeting.continue = true
          end
        end,
      })
    end
  end,
  tryDiscardToMax = function (self, modifier, except, block)
    self:tryDiscard(#self.cards + modifier - self.maxCards, except, block)
  end,
})

local hand = styledDeckCardColumn:extend()

local mindset = styledDeckCardColumn:extend()

local hope = styledBoxCard:extend({
  text = 'Hope',
  value = 0,
  add = function (self, value)
    self.value = self.value + value
  end,
  pay = function (self, cost)
    self.value = self.value - cost
  end,
  tryPay = function (self, cost, block)
    if self.value >= cost then
      self.value = self.value - cost
      block()
    end
  end,
  borderColor = colors.hope.foreground,
  textColor = colors.hope.foreground,
  getBoxColors = function (self)
    return colors.hope
  end,
  getBoxValue = function (self)
    return self.value
  end,
})

local cupcakes = styledBoxCard:extend({
  text = 'Total cupcakes',
  value = 0,
  textColor = colors.cupcakes.foreground,
  borderColor = colors.cupcakes.foreground,
  getBoxColors = function (self)
    return colors.cupcakes
  end,
  getBoxValue = function (self)
    return self.value
  end,
})

local bankCard = styledBoxCard:extend({
  clicked = function (self)
    hope:tryPay(self.card.buyCost, function ()
      local newCard = self.card:extend()
      discardPile:insert(newCard)
    end)
  end,
  make = function (self, card)
    return self:extend({
      card = card,
      text = card.text,
    })
  end,
  refresh = function (self)
    if hope.value >= self.card.buyCost then
      self.boxColors = colors.hope
      self.textColor = colors.hope.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.card.buyCost
  end,
})

local deckCard = styledBoxCard:extend({
  column = discardPile,
  clicked = function (self)
    local cost = self.cost
    if self.action and not self.delay then
      if hope.value >= cost then
        self:action(function ()
          hope:pay(cost)
        end)
      end
    end
  end,
  moveToDraw = function (self)
    self.column:remove(self)
    drawPile:insert(self)
    self.column = drawPile
    self.action = nil
    self.cost = nil
    self.delay = false
  end,
  moveToHand = function (self)
    self.column:remove(self)
    hand:insert(self)
    self.column = hand
    self.action = self.play
    self.cost = self.playCost
    self.delay = false
  end,
  tryMoveToMindset = function (self, block)
    mindset:tryDiscardToMax(1, nil, function ()
      self.column:remove(self)
      mindset:insert(self)
      self.column = mindset
      self.action = self.activate
      self.cost = self.activateCost
      self.delay = true
      block()
    end)
  end,
  moveToDiscard = function (self)
    self.column:remove(self)
    discardPile:insert(self)
    self.column = discardPile
    self.action = nil
    self.cost = nil
    self.delay = false
  end,
  remove = function (self)
    self.column:remove(self)
  end,
  refresh = function (self)
    if self.cost and hope.value >= self.cost and not self.delay then
      self.boxColors = colors.hope
      self.textColor = colors.text
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.cost
  end,
})

local hopeFeeling = deckCard:extend({
  playCost = 0,
  play = function (self, pay)
    hope:add(self.buyCost)
    self:moveToDiscard()
    pay()
  end,
})

local glimmerOfHope = hopeFeeling:extend({
  text = 'Glimmer of hope',
  buyCost = 1,
})

local feelingOfHope = hopeFeeling:extend({
  text = 'Feeling of hope',
  buyCost = 2,
})

local visionOfHope = hopeFeeling:extend({
  text = 'Vision of hope',
  buyCost = 4,
})

local hopeMindset = deckCard:extend({
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    hope:add(self.playCost)
    self.delay = true
    pay()
  end,
})

local youreNotAlone = hopeMindset:extend({
  text = 'You\'re not alone',
  buyCost = 1,
  playCost = 1,
})

local itGetsBetter = hopeMindset:extend({
  text = 'It gets better',
  buyCost = 4,
  playCost = 4,
})

local bakeCupcakes = deckCard:extend({
  text = 'Bake some cupcakes',
  buyCost = 2,
  playCost = 10,
  play = function (self, pay)
    cupcakes.value = cupcakes.value + 12
    self:moveToDiscard()
    pay()
  end,
})

local ennui = deckCard:extend({
  text = 'Ennui',
  playCost = math.huge,
  getBoxValue = function (self)
    return '∞'
  end,
})

local curiosity = deckCard:extend({
  play = function (self, pay)
    local cardsToDraw = math.min(
      self.playCost + 1,
      #drawPile.cards + #discardPile.cards)
    hand:tryDiscardToMax(cardsToDraw - 1, self, function ()
      drawPile:drawMany(cardsToDraw)
      self:moveToDiscard()
      pay()
    end)
  end,
})

local mildCuriosity = curiosity:extend({
  text = 'Mild curiosity',
  buyCost = 1,
  playCost = 1,
})

local intenseCuriosity = curiosity:extend({
  text = 'Intense curiosity',
  buyCost = 3,
  playCost = 3,
})

local letItGo = deckCard:extend({
  text = 'Let it go',
  buyCost = 1,
  playCost = 1,
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    ui.targeting:set({
      isTargetable = function (card)
        return card.column == hand
      end,
      target = function (card)
        card:remove()
        drawPile:drawMany(1)
        self:moveToDiscard()
        ui.targeting:reset()
        pay()
      end,
    })
  end,
})

local function startTurn()
  hope.value = 0
  while #hand.cards > 0 do
    hand.cards[1]:moveToDiscard()
  end
  drawPile:drawMany(5)
  for i, card in ipairs(mindset.cards) do
    card.delay = false
  end
end

local endTurn = styledBoxCard:extend({
  text = 'End turn',
  clicked = function (self)
    if self.turnCounter == 0 then
      extraScreens.doneScreen.totalCupcakes = cupcakes.value
      currentScreen = extraScreens.doneScreen
    else
      self.turnCounter = self.turnCounter - 1
      discardPile:insert(ennui:extend())
      startTurn()
    end
  end,
  getBoxColors = function (self)
    return colors.endTurn
  end,
  getBoxValue = function (self)
    return self.turnCounter
  end,
})

local mainColumn = styledColumn:extend({
  left = 60,
  top = 60,
  cards = {
    discardPile,
    drawPile,
    styledSpacer:extend(),
    hand,
    styledSpacer:extend(),
    mindset,
    styledSpacer:extend(),
    endTurn,
    cupcakes,
  }
})

local bankColumn = styledColumn:extend({
  left = mainColumn.left + styledBoxCard.width + 70,
  top = 60,
  cards = {
    hope,
    styledSpacer:extend(),
    bankCard:make(bakeCupcakes),
    bankCard:make(feelingOfHope),
    bankCard:make(visionOfHope),
    bankCard:make(mildCuriosity),
    bankCard:make(intenseCuriosity),
    bankCard:make(youreNotAlone),
    bankCard:make(itGetsBetter),
  }
})

local screen = {
  color = colors.lightBackground,
  shapes = { mainColumn, bankColumn },
  paint = function (self)
    love.graphics.setBackgroundColor(self.color)
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:paint()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    local resetTargeting = ui.targeting.from ~= nil
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:mousepressed(x, y, button, istouch)
    end
    if resetTargeting and not ui.targeting.continue then
      ui.targeting:reset()
    end
    ui.targeting.continue = false
  end,
  start = function (self)
    discardPile.cards = {
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
    }
    drawPile.cards = {}
    hand.cards = {}
    mindset.cards = {}
    cupcakes.value = 0
    endTurn.turnCounter = 8

    local seed = love.timer.getTime()
    print('seed', seed)
    math.randomseed(seed)
    mainColumn:refresh()
    drawPile:shuffle()
    startTurn()
  end,
}

return {
  screen = screen
}