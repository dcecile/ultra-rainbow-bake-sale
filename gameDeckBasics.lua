local colors = require('colors')
local gameUi = require('gameUi')
local particleEngine = require('particleEngine')
local ui = require('ui')
local utils = require('utils')

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
          discardPile.cards[1]:moveToDraw({ skipParticle = true })
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
  take = function (self, count, previousParticle)
    local newCard = self.card:extend()
    local currentParticle
    newCard:moveToDiscard({
      previousParticle = previousParticle,
      setParticle = function (particle)
        currentParticle = particle
      end,
    })
    if count > 1 then
      self:take(count - 1, currentParticle)
    end
  end,
  takeToHand = function (self)
    local newCard = self.card:extend()
    newCard:moveToHand()
  end,
  clicked = function (self)
    hope:pay(self.card.buyCost)
    self:take(1)
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
    self.card.left = self.left
    self.card.top = self.top
    self.card:refresh()
  end,
  isClickable = function (self)
    return self:isBuyable()
  end,
  isBuyable = function (self)
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
  column = nil,
  animationSpeed = 1,
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
  animateMoveTo = function (self, destination, particleOptions)
    local function getLeftRightParticleCenter()
      return self:getLeftRightCenter(gameUi.styledCardParticle.size / 2)
    end

    local originLeft, originRight = getLeftRightParticleCenter()
    destination:insert(self)
    local targetLeft, targetRight = getLeftRightParticleCenter()

    local origin
    local target
    local path

    if originLeft.x > targetRight.x then
      origin = originLeft
      target = targetRight
      path = particleEngine.essPath(gameUi.pathRadius)
    elseif originLeft.y < targetRight.y then
      origin = originLeft
      target = targetLeft
      path = particleEngine.seePath(gameUi.pathRadius, -1)
    else
      origin = originRight
      target = targetRight
      path = particleEngine.seePath(gameUi.pathRadius, 1)
    end

    local particle = gameUi.styledCardParticle:extend({
      origin = origin,
      target = target,
      path = path,
      duration = gameUi.styledCardParticle.duration / self.animationSpeed,
      previousParticle = particleOptions.previousParticle,
    })

    particleEngine.add(particle)
    if particleOptions.setParticle then
      particleOptions.setParticle(particle)
    end
  end,
  moveTo = function (self, destination, particleOptions)
    particleOptions = utils.defaultOptions(particleOptions)
    if self.column then
      self.column:remove(self)
    end
    if not particleOptions.skipParticle then
      self:animateMoveTo(destination, particleOptions)
    else
      destination:insert(self)
    end
    self.column = destination
  end,
  moveToDraw = function (self, particleOptions)
    self:moveTo(drawPile, particleOptions)
    self.action = nil
    self.cost = nil
    self.delay = false
  end,
  moveToHand = function (self, particleOptions)
    self:moveTo(hand, skipParticle)
    self.action = self.play
    self.cost = self.playCost
    self.delay = false
  end,
  moveToMindset = function (self, particleOptions)
    self:moveTo(mindset, particleOptions)
    self.action = self.activate
    self.cost = self.activateCost
    self.delay = true
  end,
  tryMoveToMindset = function (self, block, particleOptions)
    mindset:tryDiscardToMax(1, self, function ()
      self:moveToMindset(particleOptions)
      block()
    end)
  end,
  moveToDiscard = function (self, particleOptions)
    self:moveTo(discardPile, particleOptions)
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
