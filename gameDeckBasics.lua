local colors = require('colors')
local gameUi = require('gameUi')
local particleEngine = require('particleEngine')
local ui = require('ui')

local discardPile = gameUi.styledPile:extend({
  text = 'Discard pile',
  description =
    'Used and acquired cards\n'
    .. 'go here.',
})

local drawPile = gameUi.styledPile:extend({
  text = 'Draw pile',
  description =
    'These are the cards that\n'
    .. 'will be drawn next. When\n'
    .. 'empty, the discard pile is\n'
    .. 'taken and shuffled.',
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

local deckCardColumn = gameUi.styledColumn:extend({
  cards = {},
  minHeight = gameUi.styledBoxCard.height * 5 + gameUi.styledColumn.margin * 4,
  maxCards = 5,
  tryDiscard = function (self, number, source, block)
    if number <= 0 then
      block()
    else
      ui.targeting:set({
        source = source,
        isTargetable = function (card)
          return card.column == self and card ~= source
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
  tryDiscardToMax = function (self, modifier, source, block)
    self:tryDiscard(#self.cards + modifier - self.maxCards, source, block)
  end,
})

local handHeading = gameUi.styledHeading:extend({
  text = 'Hand',
  description =
    'Current thoughts, feelings,\n'
    .. 'and ideas ready for action.\n'
    .. 'Click a card to pay hope\n'
    .. 'and use.',
})

local hand = deckCardColumn:extend()

local mindsetHeading = gameUi.styledHeading:extend({
  text = 'Mindset',
  description =
    'Persistent philosophies\n'
    .. 'and paradigms. Click a\n'
    .. 'card to pay hope and use.\n'
    .. 'New mindsets need one\n'
    .. 'turn to get established.',
})

local mindset = deckCardColumn:extend()

local hope = gameUi.styledBoxCard:extend({
  text = 'Hope',
  description =
    'Build up and find hope.\n'
    .. 'Use it to do good things,\n'
    .. 'or just things.',
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

local libraryHeading = gameUi.styledHeading:extend({
  text = 'Library',
  description =
    'New techniques to learn\n'
    .. 'and try out. Click a card\n'
    .. 'to pay hope and aquire.',
})

local libraryCard = gameUi.styledBoxCard:extend({
  take = function (self, count)
    local previousParticle = nil
    for i = 1, count do
      local newCard = self.card:extend()
      discardPile:insert(newCard)
      local currentParticle = gameUi.styledCardParticle:extend({
        origin = self:getLeftCenter(gameUi.styledCardParticle.size / 2),
        target = discardPile:getRightCenter(gameUi.styledCardParticle.size / 2),
        duration = self.animationDuration,
        path = particleEngine.essPath(gameUi.pathRadius),
      })
      if not previousParticle then
        particleEngine.add(currentParticle)
      else
        previousParticle.next = function ()
          particleEngine.add(currentParticle)
        end
      end
      previousParticle = currentParticle
    end
  end,
  clicked = function (self)
    hope:tryPay(self.card.buyCost, function ()
      self:take(1)
    end)
  end,
  make = function (self, card)
    return self:extend({
      card = card,
      text = card.text,
      description = card.description,
    })
  end,
  refresh = function (self)
    if self:isClickable() then
      self.boxColors = colors.hope
      self.textColor = colors.hope.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  isClickable = function (self)
    return hope.value >= self.card.buyCost
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.card.buyCost
  end,
})

local deckCard = gameUi.styledBoxCard:extend({
  column = discardPile,
  clicked = function (self)
    local cost = self.cost
    if self:isClickable() then
      self:action(function ()
        hope:pay(cost)
      end)
    end
  end,
  isClickable = function (self)
    return self.action
      and not self.delay
      and hope.value >= self.cost
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
    particleEngine.add(gameUi.styledCardParticle:extend({
      origin = drawPile:getLeftCenter(gameUi.styledCardParticle.size / 2),
      target = self:getLeftCenter(gameUi.styledCardParticle.size / 2),
      path = particleEngine.seePath(gameUi.pathRadius, -1),
    }))
    self.column = hand
    self.action = self.play
    self.cost = self.playCost
    self.delay = false
  end,
  tryMoveToMindset = function (self, block)
    mindset:tryDiscardToMax(1, self, function ()
      local origin = self:getLeftCenter(gameUi.styledCardParticle.size / 2)
      self.column:remove(self)
      mindset:insert(self)
      local target = self:getLeftCenter(gameUi.styledCardParticle.size / 2)
      particleEngine.add(gameUi.styledCardParticle:extend({
        origin = origin,
        target = target,
        path = particleEngine.seePath(gameUi.pathRadius, -1),
      }))
      self.column = mindset
      self.action = self.activate
      self.cost = self.activateCost
      self.delay = true
      block()
    end)
  end,
  moveToDiscard = function (self)
    particleEngine.add(gameUi.styledCardParticle:extend({
      origin = self:getRightCenter(gameUi.styledCardParticle.size / 2),
      target = discardPile:getRightCenter(gameUi.styledCardParticle.size / 2),
      path = particleEngine.seePath(gameUi.pathRadius, 1),
    }))
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

return {
  discardPile = discardPile,
  drawPile = drawPile,
  handHeading = handHeading,
  hand = hand,
  mindsetHeading = mindsetHeading,
  mindset = mindset,
  hope = hope,
  libraryHeading = libraryHeading,
  libraryCard = libraryCard,
  deckCard = deckCard,
}
