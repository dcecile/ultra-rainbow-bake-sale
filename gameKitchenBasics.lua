local colors = require('colors')
local gameDeckBasics = require('gameDeckBasics')
local gameUi = require('gameUi')
local ui = require('ui')
local utils = require('utils')

local discardPile = gameDeckBasics.discardPile
local drawPile = gameDeckBasics.drawPile
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local mindset = gameDeckBasics.mindset

local batch = gameUi.styledColumn:extend({
  activeTimer = nil,
  tick = function (self, remove)
    if self.activeTimer then
      self.activeTimer()
    end
    local newActions = {}
    for i, action in ipairs(self.actions) do
      if not action.isDone then
        local ready = true
        for j, depend in ipairs(action.depends) do
          if not depend.isDone then
            ready = false
            break
          end
        end
        if ready then
          self.active:insert(action)
        else
          table.insert(newActions, action)
        end
      end
    end
    self.actions = newActions
    if #self.actions == 0 and #self.active.cards == 0 then
      remove()
    end
  end,
  getCleanupCost = function (self)
    return utils.sum(self.active.cards, utils.method.getCleanupCost)
      + utils.sum(self.actions, utils.method.getCleanupCost)
  end,
  getCleanupCount = function (self)
    return utils.sum(self.active.cards, utils.method.getCleanupCount)
      + utils.sum(self.actions, utils.method.getCleanupCount)
  end,
})

local kitchen = gameUi.styledColumn:extend({
  tick = function (self)
    local removals = {}
    local function remove(i)
      table.insert(removals, i, 1)
    end
    for i, batch in ipairs(self.cards) do
      batch:tick(function () remove(i) end)
    end
    for i, j in ipairs(removals) do
      table.remove(self.cards, j)
    end
  end,
  getCleanupCost = function (self)
    return utils.sum(self.cards, utils.method.getCleanupCost)
  end,
  getCleanupCount = function (self)
    return utils.sum(self.cards, utils.method.getCleanupCount)
  end,
})

local playerCard = gameUi.styledBoxCard:extend({
  refresh = function (self)
    if self:isClickable() then
      self.textColor = colors.player.foreground
    else
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    if self.isBusy then
      return colors.playerDisabled
    else
      return colors.player
    end
  end,
  getBoxValue = function (self)
    return self.value
  end,
  clicked = function (self)
    ui.targeting:set({
      source = self,
      isTargetable = function (card)
        return self:isSecretTargetable(card)
          or card.runCost and hope.value >= card.runCost
      end,
      target = function (card)
        if self:isSecretTargetable(card) then
          self:secretTarget(card)
          self.isBusy = true
          ui.targeting:reset()
        else
          hope:pay(card.runCost)
          card:run()
          self.value = self.value + 1
          self.isBusy = true
          ui.targeting:reset()
        end
      end,
    })
  end,
  isClickable = function (self)
    return not self.isBusy
  end,
})

local morgan = playerCard:extend({
  text = 'Morgan',
  description =
    'Enthusiastic, kind, caring,\n'
    .. 'and sensitive. Bullies call\n'
    .. 'him gay, but he’s more\n'
    .. 'worried about how other\n'
    .. 'kids are affected. Best\n'
    .. 'friend of Alex.\n'
    .. '(Secret ability is acquiring\n'
    .. 'new cards.)',
  isSecretTargetable = function (self, card)
    return #hand.cards < 5
      and card.isBuyable and card:isBuyable()
  end,
  secretTarget = function (self, card)
    hope:pay(card.card.buyCost)
    card:takeToHand()
  end,
})

local alex = playerCard:extend({
  text = 'Alex',
  description =
    'Strong, brave, caring, and\n'
    .. 'insolent. Bullies call her\n'
    .. 'gay, and it reminds her to\n'
    .. 'stay proud and pissed off.\n'
    .. 'Best friend of Morgan.\n'
    .. '(Secret ability is rallying\n'
    .. 'mindsets.)',
  isSecretTargetable = function (self, card)
    return #hand.cards < 5 and #mindset.cards < 5
      and card.column == mindset
  end,
  secretTarget = function (self, card)
    local function findIn(location, condition)
      for i, search in ipairs(location.cards) do
        if condition(search) then
          return search
        end
      end
      return nil
    end
    local function find(condition)
      return findIn(hand, condition)
        or findIn(drawPile, condition)
        or findIn(discardPile, condition)
    end
    local newMindset =
      find(function (search) return search.text == card.text end)
      or find(function (search) return search.isMindset end)
    if newMindset then
      newMindset:moveToMindset()
    end
    drawPile:drawMany(1)
  end,
})

local cupcakes = gameUi.styledBoxCard:extend({
  text = 'Total cupcakes',
  description =
    'The current recipe is for\n'
    .. 'cupcakes. Bake and\n'
    .. 'decorate, to prepare for\n'
    .. 'tomorrow’s bake sale.',
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

local pendingCleanup = gameUi.styledBoxCard:extend({
  text = 'Pending cleanup',
  description =
    'Don’t forget to clean up\n'
    .. 'the kitchen. During baking\n'
    .. 'is less stressful than after\n'
    .. 'baking.',
  textColor = colors.cupcakes.foreground,
  borderColor = colors.cupcakes.foreground,
  getBoxColors = function (self)
    return colors.cupcakes
  end,
  getBoxValue = function (self)
    return kitchen:getCleanupCount()
  end,
})

local kitchenAction = gameUi.styledBoxCard:extend({
  isDone = false,
  isHidden = false,
  borderColor = colors.cupcakes.foreground,
  refresh = function (self)
    if (not morgan.isBusy or not alex.isBusy) and hope.value >= self.runCost then
      self.boxColors = colors.hope
      self.textColor = colors.cupcakes.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.runCost
  end,
  run = function (self)
    self.isDone = true
    if not self.isHidden then
      self.batch.active:remove(self)
    end
  end,
  getCleanupCost = function (self)
    if self.cleanupTrigger then
      if self.cleanupTrigger.isDone and not self.isDone then
        return self.runCost
      end
    end
    return 0
  end,
  getCleanupCount = function (self)
    local cost = self:getCleanupCost()
    if cost > 0 then
      return 1
    else
      return 0
    end
  end,
})

return {
  batch = batch,
  kitchen = kitchen,
  morgan = morgan,
  alex = alex,
  cupcakes = cupcakes,
  pendingCleanup = pendingCleanup,
  kitchenAction = kitchenAction,
}
