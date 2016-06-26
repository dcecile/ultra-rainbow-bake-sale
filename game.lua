local extraScreens = require('extraScreens')
local proto = require('proto')
local textEngine = require('textEngine')

local targeting = proto.object:extend({
  from = nil,
  set = function (self, from)
    love.mouse.setCursor(love.mouse.getSystemCursor('crosshair'))
    self.from = from
  end,
  reset = function (self)
    love.mouse.setCursor()
    self.from = nil
  end,
})

local rectangle = proto.object:extend({
  refresh = function (self)
  end,
  draw = function (self)
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', self.left, self.top, self.width, self.height)
    if self.borderColor then
      love.graphics.setColor(self.borderColor)
      love.graphics.rectangle('line', self.left, self.top, self.width, self.height)
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    if self.left <= x and x < self.left + self.width then
      if self.top <= y and y < self.top + self.height then
        if targeting.from then
          if targeting.from:isTargetable(self) then
            targeting.from:target(self)
          end
        else
          self:clicked()
        end
      end
    end
  end,
  clicked = function (self)
  end
})

local spacer = proto.object:extend({
  refresh = function (self)
    self.height = self.margin[2] * 2 + 1
  end,
  draw = function (self)
    love.graphics.setColor(self.color)
    love.graphics.line(
      self.left + self.margin[1],
      self.top + self.margin[2],
      self.left + self.width - self.margin[1],
      self.top + self.margin[2])
  end,
  mousepressed = function (self, x, y, button, istouch)
  end,
})

local styledSpacer = spacer:extend({
  width = 300,
  margin = { 20, 10 },
  color = { 100, 100, 100 },
})

local card = rectangle:extend({
  draw = function (self)
    rectangle.draw(self)
    love.graphics.setColor(self.textColor)
    textEngine.draw(
      self.font,
      self.text,
      self.left + self.margin,
      self.top + self.margin)
  end
})

local column = proto.object:extend({
  refresh = function (self)
    local nextTop = self.top
    for i, card in ipairs(self.cards) do
      card.left = self.left
      card.top = nextTop
      card:refresh()
      nextTop = nextTop + card.height + self.margin
    end
    self.height = math.max(self.minHeight, nextTop - self.top - self.margin)
  end,
  draw = function (self)
    for i, card in ipairs(self.cards) do
      card:draw()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    for i, card in ipairs(self.cards) do
      card:mousepressed(x, y, button, istouch)
    end
  end,
  remove = function (self, card)
    for i, found in ipairs(self.cards) do
      if found == card then
        table.remove(self.cards, i)
        return
      end
    end
    error('remove failed')
  end,
  insert = function (self, card)
    table.insert(self.cards, card)
    self:refresh()
  end,
  minHeight = 0,
})

local styledColumn = column:extend({
  margin = 10
})

local styledCard = card:extend({
  color = { 255, 255, 255 },
  borderColor = { 0, 0, 0 },
  textColor = { 0, 9, 0 },
  width = 300,
  height = 50,
  margin = 13,
  font = 'big',
})

local pile = styledCard:extend({
  remove = column.remove,
  insert = column.insert,
})

local drawPile = pile:extend({
  refresh = function (self)
    self.text = 'Draw / ' .. #self.cards
  end,
  shuffle = function (self)
    local newCards = {}
    while #self.cards > 0 do
      local nextIndex = math.random(#self.cards)
      local nextCard = table.remove(self.cards, nextIndex)
      table.insert(newCards, nextCard)
    end
    self.cards = newCards
  end,
  cards = {},
})

local discardPile = pile:extend({
  refresh = function (self)
    self.text = 'Discard / ' .. #self.cards
  end,
})

local hand = styledColumn:extend({
  cards = {},
  minHeight = styledCard.height * 5 + styledColumn.margin * 4
})

local mindset = styledColumn:extend({
  cards = {},
  minHeight = styledCard.height * 5 + styledColumn.margin * 4
})

local hope = styledCard:extend({
  refresh = function (self)
    self.text = 'Hope / ' .. self.value
  end,
  value = 0,
  tryPay = function (self, cost, block)
    if self.value >= cost then
      self.value = self.value - cost
      block()
    end
  end
})

local cupcakes = styledCard:extend({
  refresh = function (self)
    self.text = 'Total cupcakes / ' .. self.value
  end,
  value = 0,
})

local bankCard = styledCard:extend({
  clicked = function (self)
    hope:tryPay(self.card.cost, function ()
      local newCard = self.card:extend()
      discardPile:insert(newCard)
    end)
  end,
  make = function (self, card)
    return self:extend({
      card = card,
      text = '[' .. card.text .. ']',
    })
  end
})

local noAction = function (self)
end

local deckCard = styledCard:extend({
  column = discardPile,
  clicked = noAction,
  moveToDraw = function (self)
    self:move(drawPile, noAction)
  end,
  moveToHand = function (self)
    self:move(hand, self.play)
  end,
  moveToMindset = function (self)
    self:move(mindset, self.activate)
    self.delay = true
  end,
  moveToDiscard = function (self)
    self:move(discardPile, noAction)
  end,
  move = function (self, newColumn, newClicked)
    self.column:remove(self)
    newColumn:insert(self)
    self.column = newColumn
    self.clicked = newClicked
  end,
  remove = function (self)
    self.column:remove(self)
  end,
})

local hopeCard = deckCard:extend({
  play = function (self)
    hope.value = hope.value + self.cost
    self:moveToDiscard()
  end,
})

local glimmerOfHope = hopeCard:extend({
  text = 'Glimmer of hope',
  cost = 1
})

local feelingOfHope = hopeCard:extend({
  text = 'Feeling of hope',
  cost = 2
})

local visionOfHope = hopeCard:extend({
  text = 'Vision of hope',
  cost = 4
})

local bakeCupcakes = deckCard:extend({
  text = 'Bake some cupcakes',
  cost = 2,
  play = function (self)
    hope:tryPay(10, function ()
      cupcakes.value = cupcakes.value + 12
      self:moveToDiscard()
    end)
  end,
})

local letItGo = deckCard:extend({
  text = 'Let it go',
  cost = 1,
  play = function (self)
    hope:tryPay(1, function ()
      self:moveToMindset()
    end)
  end,
  activate = function (self)
    if not self.delay then
      targeting:set(self)
    end
  end,
  isTargetable = function (self, card)
    return card.column == hand
  end,
  target = function (self, card)
    card:remove()
    self:moveToDiscard()
    targeting:reset()
  end
})

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

local function startTurn()
  hope.value = 0
  while #hand.cards > 0 do
    hand.cards[1]:moveToDiscard()
  end
  for i = 1, 5 do
    if #drawPile.cards > 0 then
      drawPile.cards[1]:moveToHand()
    elseif #discardPile.cards > 0 then
      while #discardPile.cards > 0 do
        discardPile.cards[1]:moveToDraw()
      end
      drawPile:shuffle()
      drawPile.cards[1]:moveToHand()
    else
    end
  end
  for i, card in ipairs(mindset.cards) do
    card.delay = false
  end
end

local endTurn = styledCard:extend({
  turnCounter = 8,
  refresh = function (self)
    self.text = 'End turn / ' .. self.turnCounter
  end,
  clicked = function (self)
    if self.turnCounter == 0 then
      extraScreens.doneScreen.totalCupcakes = cupcakes.value
      currentScreen = extraScreens.doneScreen
    else
      self.turnCounter = self.turnCounter - 1
      startTurn()
    end
  end
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
  left = 430,
  top = 60,
  cards = {
    hope,
    styledSpacer:extend(),
    bankCard:make(bakeCupcakes),
    bankCard:make(glimmerOfHope),
    bankCard:make(feelingOfHope),
    bankCard:make(visionOfHope),
    bankCard:make(letItGo),
  }
})

local seed = love.timer.getTime()
print('seed', seed)
math.randomseed(seed)
mainColumn:refresh()
drawPile:shuffle()
startTurn()

local screen = {
  color = { 240, 200, 255 },
  shapes = { mainColumn, bankColumn },
  draw = function (self)
    love.graphics.setBackgroundColor(self.color)
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:draw()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    local resetTargeting = targeting.from ~= nil
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:mousepressed(x, y, button, istouch)
    end
    if resetTargeting then
      targeting:reset()
    end
  end
}

return {
  screen = screen
}
