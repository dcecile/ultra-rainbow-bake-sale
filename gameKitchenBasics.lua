local colors = require('colors')
local gameDeckBasics = require('gameDeckBasics')
local gameUi = require('gameUi')
local ui = require('ui')
local utils = require('utils')

local hope = gameDeckBasics.hope

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
        return card.runCost and hope.value >= card.runCost
      end,
      target = function (card)
        hope:pay(card.runCost)
        card:run()
        self.value = self.value + 1
        self.isBusy = true
        ui.targeting:reset()
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
    end
    return false
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
    .. 'friend of Alex.',
})

local alex = playerCard:extend({
  text = 'Alex',
  description =
    'Strong, brave, caring, and\n'
    .. 'insolent. Bullies call her\n'
    .. 'gay, and it reminds her to\n'
    .. 'stay proud and pissed off.\n'
    .. 'Best friend of Morgan.',
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
