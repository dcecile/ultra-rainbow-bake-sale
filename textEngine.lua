local fontCache = {}

local textObjectCache = {}

local fontLoader = {
  big = function ()
    return love.graphics.newFont('RobotoCondensed-Light.ttf', 26)
  end,
  title = function ()
    return love.graphics.newFont('RobotoCondensed-Regular.ttf', 48)
  end,
}

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

local function paintTextObject(textObject, x, y)
  love.graphics.draw(textObject, x - 0.5, y - 0.5)
end

local function paint(fontName, text, x, y)
  local textObject = getTextObject(fontName, text)
  paintTextObject(textObject, x, y)
end

return {
  getTextObject = getTextObject,
  paintTextObject = paintTextObject,
  paint = paint,
}
