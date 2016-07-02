local proto = require('proto')
local textEngine = require('textEngine')

local cursor = proto.object:extend({
  isTargeting = false,
  isClickable = false,
  clear = function (self)
    self.isClickable = false
    self:refresh()
  end,
  clickable = function (self)
    self.isClickable = true
    self:refresh()
  end,
  startTargeting = function (self)
    self.isTargeting = true
    self:refresh()
  end,
  stopTargeting = function (self)
    self.isTargeting = false
    self:refresh()
  end,
  refresh = function (self)
    if self.isTargeting then
      love.mouse.setCursor(love.mouse.getSystemCursor('crosshair'))
    elseif self.isClickable then
      love.mouse.setCursor(love.mouse.getSystemCursor('hand'))
    else
      love.mouse.setCursor()
    end
  end,
})

local targeting = proto.object:extend({
  from = nil,
  selected = {},
  continue = false,
  set = function (self, from)
    cursor:startTargeting()
    self.from = from
  end,
  reset = function (self)
    cursor:stopTargeting()
    self.from = nil
    self.selected = {}
    self.continue = false
  end,
  toggleSelected = function (self, new)
    for i, old in ipairs(self.selected) do
      if old == new then
        table.remove(self.selected, i)
        return
      end
    end
    table.insert(self.selected, new)
  end,
  isSelected = function (self, check)
    for i, found in ipairs(self.selected) do
      if found == check then
        return true
      end
    end
    return false
  end
})

local rectangle = proto.object:extend({
  refresh = function (self)
  end,
  paint = function (self)
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', self.left, self.top, self.width, self.height)
    if self.borderColor then
      love.graphics.setColor(self.borderColor)
      love.graphics.rectangle('line', self.left, self.top, self.width, self.height)
    end
  end,
  isInside = function (self, x, y)
    if self.left <= x and x < self.left + self.width then
      if self.top <= y and y < self.top + self.height then
        return true
      end
    end
    return false
  end,
  isClickable = function (self)
    return self.clicked ~= nil
  end,
  checkHover = function (self, x, y)
    if self:isClickable() and self:isInside(x, y) then
      cursor:clickable()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    if self:isInside(x, y) then
      if targeting.from then
        if targeting.from.isTargetable(self) then
          targeting.from.target(self)
        end
      elseif self:isClickable() then
        self:clicked()
      end
    end
  end,
})

local spacer = proto.object:extend({
  refresh = function (self)
    self.height = self.margin[2] * 2 + 1
  end,
  checkHover = function (self, x, y)
  end,
  paint = function (self)
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

local card = rectangle:extend({
  paint = function (self)
    rectangle.paint(self)
    love.graphics.setColor(self.textColor)
    textEngine.paint(
      self.font,
      self.text,
      self.left + self.margin[1],
      self.top + self.margin[2])
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
  checkHover = function (self, x, y)
    for i, card in ipairs(self.cards) do
      card:checkHover(x, y)
    end
  end,
  paint = function (self)
    for i, card in ipairs(self.cards) do
      card:paint()
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

return {
  cursor = cursor,
  targeting = targeting,
  rectangle = rectangle,
  card = card,
  spacer = spacer,
  column = column,
}
