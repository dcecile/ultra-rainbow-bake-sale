local colors = require('colors')
local currentScreen = require('currentScreen')
local proto = require('proto')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local vectors = require('vectors')

local vec2 = vectors.vec2
local unscaleF = resolutionEngine.unscaleFloat

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
  checkHover = function (self, x, y, block)
    if self:isInside(x, y) then
      block(self)
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
  getLeftCenter = function (self, margin)
    return vec2(
      self.left + margin,
      self.top + self.height / 2)
  end,
  getRightCenter = function (self, margin)
    return vec2(
      self.left + self.width - margin,
      self.top + self.height / 2)
  end,
  getLeftRightCenter = function (self, margin)
    return self:getLeftCenter(margin), self:getRightCenter(margin)
  end,
})

local spacer = rectangle:extend({
  refresh = function (self)
    self.height = self.margin[2] + self.margin[3] + 1
  end,
  paint = function (self)
    rectangleEngine.paint(
      self.color,
      self.left + self.margin[1],
      self.top + self.margin[2],
      self.width - self.margin[1] * 2,
      unscaleF(1))
  end,
})

local heading = rectangle:extend({
  paint = function (self)
    local text = textEngine.getTextObject(self.font, self.text)
    textEngine.paintTextObject(
      self.color,
      text,
      math.floor(self.left + self.width / 2 - unscaleF(text:getWidth()) / 2),
      math.floor(self.top + self.height / 2 - unscaleF(text:getHeight()) / 2))
  end,
})

local card = rectangle:extend({
  paint = function (self)
    local color = self.color
    if targeting:isSet() then
      color = colors.unselectableAlpha(color)
    end
    rectangleEngine.paintBorder(
      self.borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      color, self.left, self.top, self.width, self.height)
    textEngine.paint(
      self.textColor,
      self.font,
      self.text,
      self.left + self.margin[1],
      self.top + self.margin[2])
  end
})

local boxCard = card:extend({
  paint = function (self)
    local borderColor = self.borderColor
    local color = self.color
    local highlight = false
    local boxColors = self:getBoxColors()
    local boxForeground = boxColors.foreground
    local boxBackground = boxColors.background

    if targeting:isSet() then
      if targeting:isSource(self) then
        highlight = true
        color = colors.unselectableAlpha(color)
        boxBackground = colors.unselectableAlpha(boxBackground)
      elseif targeting:isSelected(self) then
        highlight = true
        borderColor = self.selectedBorderColor
      elseif not targeting:isTargetable(self) then
        color = colors.unselectableAlpha(color)
        boxBackground = colors.unselectableAlpha(boxBackground)
      end
    elseif not self.clicked then
      color = colors.noActionAlpha(color)
      boxBackground = colors.noActionAlpha(boxBackground)
    end

    if highlight then
      rectangleEngine.paintBorder(
        self.highlightColor, self.left, self.top, self.width, self.height, 3)
    end

    rectangleEngine.paintBorder(
      borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      color, self.left, self.top, self.width, self.height)

    textEngine.paint(
      self.textColor,
      self.font,
      self.text,
      self.left + self.margin[1],
      self.top + self.margin[2])

    local boxValue = self:getBoxValue()
    local boxWidth = 50
    local boxLeft = self.left + self.width - boxWidth
    rectangleEngine.paint(
      boxBackground, boxLeft, self.top, boxWidth, self.height)
    rectangleEngine.paint(
      boxForeground, boxLeft - unscaleF(1), self.top, unscaleF(1), self.height)
    local boxText = textEngine.getTextObject(self.font, tostring(boxValue))
    textEngine.paintTextObject(
      boxForeground,
      boxText,
      math.floor(boxLeft + boxWidth / 2 - unscaleF(boxText:getWidth()) / 2),
      self.top + self.margin[2])
  end,
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
  checkHover = function (self, x, y, block)
    for i, card in ipairs(self.cards) do
      card:checkHover(x, y, block)
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

local screen = proto.object:extend({
  show = function (self)
    currentScreen.set(self)
    love.graphics.setBackgroundColor(self.backgroundColor)
  end,
  showNext = function (self, ...)
    self.next:show(...)
  end,
  update = function (self, time)
  end,
})

return {
  cursor = cursor,
  targeting = targeting,
  rectangle = rectangle,
  card = card,
  boxCard = boxCard,
  spacer = spacer,
  heading = heading,
  column = column,
  screen = screen,
}
