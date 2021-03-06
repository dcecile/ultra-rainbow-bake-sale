local colors = require('colors')
local gameDeckBasics = require('gameDeckBasics')
local gameDeckCards = require('gameDeckCards')
local gameUi = require('gameUi')
local ui = require('ui')
local utils = require('utils')

local deck = gameDeckBasics.deck
local discard = gameDeckBasics.discard
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local inspiration = gameDeckCards.inspiration
local mindset = gameDeckBasics.mindset

local batch = gameUi.styledColumn:extend({
  activeTimer = nil,
  active = gameUi.styledColumn:extend({
    minHeight = gameUi.styledBoxCard.height * 2 + gameUi.styledColumn.margin * 1,
    maxCards = 2,
    cards = {},
  }),
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
          if action.cleanupTrigger then
            self.active:insert(action)
          else
            self.active:insert(action, 1)
          end
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
      table.insert(removals, 1, i)
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

local friendCard = gameUi.styledBoxCard:extend({
  isFriend = true,
  refresh = function (self)
    if self:isClickable() then
      self.textColor = colors.player.foreground
    else
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    if not self:isClickable() then
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
    if not self.isBusy then
      for i, batch in ipairs(kitchen.cards) do
        for j, action in ipairs(batch.active.cards) do
          if hope.value >= action.runCost then
            return true
          end
        end
      end
      for i, card in ipairs(inspiration.cards) do
        if self:isSecretTargetable(card) then
          return true
        end
      end
      for i, card in ipairs(mindset.cards) do
        if self:isSecretTargetable(card) then
          return true
        end
      end
    end
  end,
})

local morgan = friendCard:extend({
  text = 'Morgan',
  description =
    'Enthusiastic, kind, caring,\n'
    .. 'and sensitive. Bullies call\n'
    .. 'him gay, but he’s more\n'
    .. 'worried about other kids.\n'
    .. 'Best friend of Alex.\n'
    .. '(Secret ability is finding\n'
    .. 'inspiration.)',
  isSecretTargetable = function (self, card)
    return #hand.cards < 5
      and card.isBuyable and card:isBuyable()
  end,
  secretTarget = function (self, card)
    hope:pay(card.card.buyCost)
    card:takeToHand()
  end,
})

local alex = friendCard:extend({
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
        or findIn(deck, condition)
        or findIn(discard, condition)
    end
    local newMindset =
      find(function (search) return search.text == card.text end)
      or find(function (search) return search.isMindset end)
    if newMindset then
      newMindset:moveToMindset()
    end
    deck:drawMany(1)
  end,
})

local cupcakes = gameUi.styledBoxCard:extend({
  text = 'Cupcakes baked',
  description =
    'The current recipe is for\n'
    .. 'cupcakes. Use lots and lots\n'
    .. 'of hope to bake and\n'
    .. 'decorate, in preparation of\n'
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
  text = 'Cleanup pending',
  description =
    'Don’t forget to save some\n'
    .. 'hope for cleaning up the\n'
    .. 'kitchen. During baking is\n'
    .. 'less stressful than after\n'
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
    if self:isRunnable() then
      self.boxColors = colors.hope
      self.textColor = colors.cupcakes.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  isRunnable = function (self)
    return (not morgan.isBusy or not alex.isBusy)
      and hope.value >= self.runCost
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.runCost
  end,
  run = function (self)
    self.isDone = true
    kitchen.totalTasksCompleted = kitchen.totalTasksCompleted + 1
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
