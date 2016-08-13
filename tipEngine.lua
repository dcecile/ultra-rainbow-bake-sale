local gameDeckBasics = require('gameDeckBasics')
local gameDeckCards = require('gameDeckCards')
local gameKitchenBasics = require('gameKitchenBasics')
local proto = require('proto')
local utils = require('utils')

local alex = gameKitchenBasics.alex
local deck = gameDeckBasics.deck
local discard = gameDeckBasics.discard
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local inspiration = gameDeckCards.inspiration
local kitchen = gameKitchenBasics.kitchen
local mindset = gameDeckBasics.mindset
local morgan = gameKitchenBasics.morgan

utils:register()

local function findClickableCards(...)
  return concatMap({ ... }, function (area)
    return filter(area.cards, method.isClickable)
  end)
end

local function findRunnableCards(...)
  local batches = map({ ... }, function (i) return kitchen.cards[i] end)
  return concatMap(batches, function (batch)
    return filter(batch.active.cards, method.isRunnable)
  end)
end

local tip = proto.object:extend({
  text = nil,
  description = nil,
  isValid = nil,
})

local expertTip = tip:extend({
  text = 'Have fun',
  description =
    'Experiment. Try things out.\n'
    .. 'Make mistakes and get\n'
    .. 'messy. Baking has no right\n'
    .. 'answers.',
  isValid = function (self)
    return hand.totalEnnuiRemoved >= 3 and kitchen.totalTasksCompleted >= 7
  end,
  isHighlighted = function (card)
    return card:isClickable()
  end,
})

local defaultTip = expertTip:extend({
  isValid = function (self)
    return true
  end,
})

local letGoEnnuiTip = tip:extend({
  text = 'Resist ennui',
  description =
    'Ennui will bring things to a\n'
    .. 'halt. Let go of it, to focus on\n'
    .. 'what’s important.\n',
  isValid = function (self)
    local letItGo = any(findClickableCards(mindset), function (card)
      return card.isLetItGo
    end)
    local ennui = any(hand.cards, function (card)
      return card.isEnnui
    end)
    return letItGo and ennui
  end,
  isHighlighted = function (card)
    return card.column == hand and card.isEnnui
      or card.column == mindset and card.isLetItGo and card:isClickable()
  end,
})

local useMindsetTip = tip:extend({
  text = 'Mindset ready',
  description =
    'Mindsets can give a good\n'
    .. 'boost. Use them to their\n'
    .. 'full potential.',
  isValid = function (self)
    return any(findClickableCards(mindset), function (card)
      return card:isSafeMindset()
    end)
  end,
  isHighlighted = function (card)
    return card.column == mindset and card:isSafeMindset() and card:isClickable()
  end,
})

local playHopeTip = tip:extend({
  text = 'More hope',
  description =
    'Hope is needed for almost\n'
    .. 'everything; the more the\n'
    .. 'better. Play a card from the\n'
    .. 'hand that gives hope.',
  isValid = function (self)
    return any(findClickableCards(hand), function (card)
      return card.isHope and not card.isMindset
    end)
  end,
  isHighlighted = function (card)
    return card.column == hand and card.isHope and not card.isMindset and card:isClickable()
      or card == hope
  end,
})

local zeroHopeTip = playHopeTip:extend({
  text = 'Hope comes first',
  description =
    'Morgan and Alex currently\n'
    .. 'have 0 hope. Play a card\n'
    .. 'from the hand that gives\n'
    .. 'hope.',
  isValid = function (self)
    return playHopeTip.isValid(self) and hope.value == 0
  end,
})

local playMindsetTip = tip:extend({
  text = 'Prepare mindset',
  description =
    'Mindsets can’t be used\n'
    .. 'unless they’re played first.\n'
    .. 'Set some up to use later.',
  isValid = function (self)
    return #mindset.cards < 5 and any(findClickableCards(hand), function (card)
      return card.isMindset
    end)
  end,
  isHighlighted = function (card)
    return card.column == hand and card.isMindset and card:isClickable()
  end,
})

local bakeTip = tip:extend({
  text = 'Get baking',
  description =
    'Morgan and Alex have\n'
    .. 'enough hope to do some\n'
    .. 'baking. Don’t put it off.',
  isValid = function (self)
    return any(findRunnableCards(1))
  end,
  isHighlighted = function (card)
    return card.isFriend and card:isClickable()
      or card.isRunnable and card:isRunnable() and card.batch.number == 1
  end,
})

local findHopeTip = tip:extend({
  text = 'Find more hope',
  description =
    'The hope included in the\n'
    .. 'starting deck won’t be\n'
    .. 'enough. Find some new\n'
    .. 'inspiration and make the\n'
    .. 'stronger.',
  isValid = function (self)
    return any(findClickableCards(inspiration), function (inspiration)
      return inspiration.card.isHope
    end)
  end,
  isHighlighted = function (inspiration)
    return inspiration.isBuyable and inspiration:isBuyable() and inspiration.card.isHope
  end,
})

local endTurnTip = tip:extend({
  text = 'End the turn',
  description =
    'Nothing left to do except\n'
    .. 'continue. The next turn\n'
    .. 'will come with new\n'
    .. 'opportunities.',
  isValid = function (self)
    return not any(findClickableCards(hand, mindset, inspiration))
      and not morgan:isClickable() and not alex:isClickable()
  end,
  isHighlighted = function (card)
    return card.isEndTurn
  end,
})

local allTips = {
  expertTip,
  letGoEnnuiTip,
  useMindsetTip,
  zeroHopeTip,
  playHopeTip,
  playMindsetTip,
  bakeTip,
  findHopeTip,
  endTurnTip,
  defaultTip,
}

local function getTip()
  return any(allTips, method.isValid)
end

return {
  getTip = getTip,
}
