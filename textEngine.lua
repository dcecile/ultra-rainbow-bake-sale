local resolutionEngine = require('resolutionEngine')

local scaleR = resolutionEngine.scaleRoundToZero

local fontCache = {}

local textObjectCache = {}

local function loadFont(name, size)
  return love.graphics.newFont(name, math.max(1, scaleR(size)))
end

local fontLoader = {
  small = function ()
    return loadFont('RobotoCondensed-Light.ttf', 18)
  end,
  big = function ()
    return loadFont('RobotoCondensed-Light.ttf', 26)
  end,
  bold = function ()
    return loadFont('RobotoCondensed-Regular.ttf', 26)
  end,
  header = function ()
    return loadFont('RobotoCondensed-Regular.ttf', 36)
  end,
  title = function ()
    return loadFont('RobotoCondensed-Regular.ttf', 96)
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
