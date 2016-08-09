local colors = require('colors')
local particleEngine = require('particleEngine')
local ui = require('ui')

local styledColumn = ui.column:extend({
  margin = 10
})

local columnSpacing = 70

local styledCardParticle = particleEngine.cardParticle:extend({
  duration = 500,
  color = colors.cardParticle,
  size = 16,
})

local pathRadius = columnSpacing / 2

local styledBoxCard = ui.boxCard:extend({
  color = colors.card,
  borderColor = colors.text,
  textColor = colors.text,
  highlightColor = colors.highlightColor,
  selectedBorderColor = colors.selectedBorderColor,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local styledSpacer = ui.spacer:extend({
  width = styledBoxCard.width,
  margin = { 20, 6, 1 },
  color = colors.spacer,
})

local styledSpacerSymmetrical = styledSpacer:extend({
  margin = { styledSpacer.margin[1], styledSpacer.margin[2], styledSpacer.margin[2] },
})

local styledHeading = ui.heading:extend({
  height = 20,
  width = styledBoxCard.width,
  color = colors.heading,
  font = 'small',
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
  refresh = function (self)
    for i, card in ipairs(self.cards) do
      card.left = self.left
      card.top = self.top
      card:refresh()
    end
  end,
})

return {
  styledColumn = styledColumn,
  columnSpacing = columnSpacing,
  styledCardParticle = styledCardParticle,
  pathRadius = pathRadius,
  styledBoxCard = styledBoxCard,
  styledSpacer = styledSpacer,
  styledSpacerSymmetrical = styledSpacerSymmetrical,
  styledHeading = styledHeading,
  styledPile = styledPile,
}
