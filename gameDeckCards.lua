local gameUi = require('gameUi')
local gameDeckBasics = require('gameDeckBasics')
local ui = require('ui')

local deckCard = gameDeckBasics.deckCard
local drawPile = gameDeckBasics.drawPile
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local libraryCard = gameDeckBasics.libraryCard

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
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 1 hope.',
  buyCost = 1,
})

local feelingOfHope = hopeFeeling:extend({
  text = 'Feeling of hope',
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 2 hope.',
  buyCost = 2,
})

local visionOfHope = hopeFeeling:extend({
  text = 'Vision of hope',
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 4 hope.',
  buyCost = 4,
})

local itGetsBetter = deckCard:extend({
  text = 'It gets better',
  description =
    'Continual source of hope.\n'
    .. 'Play this mindset, then\n'
    .. 'activate to gain 2 hope.',
  buyCost = 2,
  playCost = 2,
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    hope:add(2)
    self.delay = true
    pay()
  end,
})

local knowledgeIsPower = deckCard:extend({
  text = 'Knowledge is power',
  description =
    'Continual source of\n'
    .. 'inspiration. Play this\n'
    .. 'mindset, then activate to\n'
    .. 'draw 2 cards.',
  buyCost = 2,
  playCost = 2,
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    hand:tryDiscardToMax(2, self, function ()
      drawPile:drawMany(2)
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
  getBoxValue = function (self)
    return '∞'
  end,
})

local ennuiLibraryCard = libraryCard:make(ennui)
ennuiLibraryCard.getBoxValue = ennui.getBoxValue
ennuiLibraryCard.animationDuration = gameUi.styledCardParticle.duration * 2

local curiosity = deckCard:extend({
  play = function (self, pay)
    local cardsToDraw = math.min(
      self.playCost + 1,
      #drawPile.cards + #discardPile.cards)
    hand:tryDiscardToMax(cardsToDraw - 1, self, function ()
      self:moveToDiscard()
      drawPile:drawMany(cardsToDraw)
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

local letItGo = deckCard:extend({
  text = 'Let it go',
  description =
    'Be present. Let go. Play\n'
    .. 'this mindset, then activate\n'
    .. 'and discard. Return one\n'
    .. 'card to the library, and\n'
    .. 'draw a new card.',
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
      source = self,
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

local libraryColumn = gameUi.styledColumn:extend({
  cards = {
    ennuiLibraryCard,
    libraryCard:make(feelingOfHope),
    libraryCard:make(visionOfHope),
    libraryCard:make(mildCuriosity),
    libraryCard:make(intenseCuriosity),
    libraryCard:make(itGetsBetter),
    libraryCard:make(knowledgeIsPower),
  }
})

return {
  glimmerOfHope = glimmerOfHope,
  letItGo = letItGo,
  ennuiLibraryCard = ennuiLibraryCard,
  libraryColumn = libraryColumn,
}
