local resolutionEngine = require('resolutionEngine')

local scaleR = resolutionEngine.scaleRoundToZero

local fontCache = {}

local textObjectCache = {}

local fontLoader = {
  small = function ()
    return love.graphics.newFont('RobotoCondensed-Light.ttf', scaleR(18))
  end,
  big = function ()
    return love.graphics.newFont('RobotoCondensed-Light.ttf', scaleR(26))
  end,
  bold = function ()
    return love.graphics.newFont('RobotoCondensed-Regular.ttf', scaleR(26))
  end,
  header = function ()
    return love.graphics.newFont('RobotoCondensed-Regular.ttf', scaleR(36))
  end,
  title = function ()
    return love.graphics.newFont('RobotoCondensed-Regular.ttf', scaleR(48))
  end,
}

local function reset()
  fontCache = {}
  textObjectCache = {}
end

local function getFont(fontName)
  local cachedFont = fontCache[fontName]
  if cachedFont then
    return cachedFont
  else
    local newFont = fontLoader[fontName]()
    fontCache[fontName] = newFont
    return newFont
  end
end

local function getTextObject(fontName, text)
  local key = fontName .. '/' .. text
  local cachedTextObject = textObjectCache[key]
  if cachedTextObject then
    return cachedTextObject
  else
    local newTextObject = love.graphics.newText(getFont(fontName), text)
    textObjectCache[key] = newTextObject
    return newTextObject
  end
end

local function paintTextObject(color, textObject, x, y)
  love.graphics.setColor(color)
  love.graphics.draw(textObject, scaleR(x), scaleR(y))
end

local function paint(color, fontName, text, x, y)
  local textObject = getTextObject(fontName, text)
  paintTextObject(color, textObject, x, y)
end

return {
  reset = reset,
  getTextObject = getTextObject,
  paintTextObject = paintTextObject,
  paint = paint,
}
