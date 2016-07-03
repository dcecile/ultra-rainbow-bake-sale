local proto = require('proto')
local rectangleEngine = require('rectangleEngine')
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
  current = nil,
  selected = {},
  continue = false,
  set = function (self, new)
    cursor:startTargeting()
    self.current = new
  end,
  isSet = function (self)
    return self.current ~= nil
  end,
  reset = function (self)
    cursor:stopTargeting()
    self.current = nil
    self.selected = {}
    self.continue = false
  end,
  isTargetable = function (self, check)
    return self.current.isTargetable(check)
  end,
  target = function (self, check)
    return self.current.target(check)
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
  isSource = function (self, check)
    return self.current.source == check
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
    rectangleEngine.paintPadded(
      self.borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      self.color, self.left, self.top, self.width, self.height)
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
      if targeting:isSet() then
        if targeting:isTargetable(self) then
          targeting:target(self)
        end
      elseif self:isClickable() then
        self:clicked()
      end
    end
  end,
})

local spacer = proto.object:extend({
  refresh = function (self)
    self.height = self.margin[2] + self.margin[3] + 1
  end,
  checkHover = function (self, x, y)
  end,
  paint = function (self)
    rectangleEngine.paint(
      self.color,
      self.left + self.margin[1],
      self.top + self.margin[2],
      self.width - self.margin[1] * 2,
      1)
  end,
  mousepressed = function (self, x, y, button, istouch)
  end,
})

local heading = proto.object:extend({
  refresh = function (self)
  end,
  checkHover = function (self, x, y)
  end,
  paint = function (self)
    local text = textEngine.getTextObject(self.fontName, self.text)
    textEngine.paintTextObject(
      self.color,
      text,
      math.floor(self.left + self.width / 2 - text:getWidth() / 2),
      math.floor(self.top + self.height / 2 - text:getHeight() / 2))
  end,
  mousepressed = function (self, x, y, button, istouch)
  end,
})

local card = rectangle:extend({
  paint = function (self)
    rectangle.paint(self)
    textEngine.paint(
      self.textColor,
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
  heading = heading,
  column = column,
}
