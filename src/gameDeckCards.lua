local gameUi = require('gameUi')
local gameDeckBasics = require('gameDeckBasics')
local ui = require('ui')

local deck = gameDeckBasics.deck
local deckCard = gameDeckBasics.deckCard
local discard = gameDeckBasics.discard
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local inspirationCard = gameDeckBasics.inspirationCard
local mindset = gameDeckBasics.mindset

local hopeFeeling = deckCard:extend({
  playCost = 0,
  isHope = true,
  play = function (self, pay)
    hope:add(self.buyCost)
    self:moveToDiscard()
    pay()
  end,
})

local glimmerOfHope = hopeFeeling:extend({
  text = 'Glimmer of hope',
  description =
    'Baking needs hope, and this\n'
    .. 'is a fundamental source of\n'
    .. 'it. Play and discard to gain 1\n'
    .. 'hope.',
  buyCost = 1,
})

local feelingOfHope = hopeFeeling:extend({
  text = 'Feeling of hope',
  description =
    'Baking needs hope, and this\n'
    .. 'is a fundamental source of\n'
    .. 'it. Play and discard to gain 2\n'
    .. 'hope.',
  buyCost = 2,
})

local visionOfHope = hopeFeeling:extend({
  text = 'Vision of hope',
  description =
    'Baking needs hope, and this\n'
    .. 'is a fundamental source of\n'
    .. 'it. Play and discard to gain 4\n'
    .. 'hope.',
  buyCost = 4,
})

local mindsetCard = deckCard:extend({
  isMindset = true,
  isSafeMindset = function (self)
    return false
  end,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
})

local itGetsBetter = mindsetCard:extend({
  text = 'It gets better',
  description =
    'Continual source of hope.\n'
    .. 'Play this mindset, then\n'
    .. 'activate to gain 2 hope.',
  buyCost = 2,
  playCost = 2,
  activateCost = 0,
  isHope = true,
  isSafeMindset = function (self)
    return true
  end,
  activate = function (self, pay)
    hope:add(2)
    self.delay = true
    pay()
  end,
})

local knowledgeIsPower = mindsetCard:extend({
  text = 'Knowledge is power',
  description =
    'Continual source of\n'
    .. 'strength. Play this mindset,\n'
    .. 'then activate to draw 2\n'
    .. 'cards.',
  buyCost = 2,
  playCost = 2,
  activateCost = 0,
  isSafeMindset = function (self)
    return #hand.cards <= 3
  end,
  activate = function (self, pay)
    hand:tryDiscardToMax(2, self, function ()
      deck:drawMany(2)
      self.delay = true
      pay()
    end)
  end,
})

local ennui = deckCard:extend({
  text = 'Ennui',
  description =
    'Boredom. Enervation.\n'
    .. 'Un-motivation. Fatigue.\n'
    .. 'Cannot be played.',
  playCost = math.huge,
  buyCost = math.huge,
  animationSpeed = 0.5,
  isEnnui = true,
  getBoxValue = function (self)
    return '∞'
  end,
})

local ennuiInspirationCard = inspirationCard:make(ennui)
ennuiInspirationCard.getBoxValue = ennui.getBoxValue

local curiosity = deckCard:extend({
  play = function (self, pay)
    local cardsToDraw = math.min(
      self.playCost + 1,
      #deck.cards + #discard.cards)
    hand:tryDiscardToMax(cardsToDraw - 1, self, function ()
      self:moveToDiscard()
      deck:drawMany(cardsToDraw)
      pay()
    end)
  end,
})

local mildCuriosity = curiosity:extend({
  text = 'Mild curiosity',
  description =
    'Don’t be afraid of the\n'
    .. 'unknown. Play and discard\n'
    .. 'to draw 2 cards.',
  buyCost = 1,
  playCost = 1,
})

local intenseCuriosity = curiosity:extend({
  text = 'Intense curiosity',
  description =
    'Don’t be afraid of the\n'
    .. 'unknown. Play and discard\n'
    .. 'to draw 4 cards.',
  buyCost = 3,
  playCost = 3,
})

local letItGo = mindsetCard:extend({
  text = 'Let it go',
  description =
    'Be present. Let go. Play\n'
    .. 'this mindset, then activate\n'
    .. 'and discard. Remove one\n'
    .. 'card-in-hand completely\n'
    .. 'from play, and draw a new\n'
    .. 'one.',
  buyCost = 1,
  playCost = 1,
  activateCost = 0,
  isLetItGo = true,
  isClickable = function (self)
    if self.column == mindset then
      return mindsetCard.isClickable(self) and #hand.cards > 0
    else
      return mindsetCard.isClickable(self)
    end
  end,
  activate = function (self, pay)
    ui.targeting:set({
      source = self,
      isTargetable = function (card)
        return card.column == hand
      end,
      target = function (card)
        if card.isEnnui then
          hand.totalEnnuiRemoved = hand.totalEnnuiRemoved + 1
        end
        card:remove()
        deck:drawMany(1)
        self:moveToDiscard()
        ui.targeting:reset()
        pay()
      end,
    })
  end,
})

local inspiration = gameUi.styledColumn:extend({
  cards = {
    ennuiInspirationCard,
    inspirationCard:make(feelingOfHope),
    inspirationCard:make(visionOfHope),
    inspirationCard:make(mildCuriosity),
    inspirationCard:make(intenseCuriosity),
    inspirationCard:make(itGetsBetter),
    inspirationCard:make(knowledgeIsPower),
  }
})

return {
  glimmerOfHope = glimmerOfHope,
  letItGo = letItGo,
  ennuiInspirationCard = ennuiInspirationCard,
  inspiration = inspiration,
}
