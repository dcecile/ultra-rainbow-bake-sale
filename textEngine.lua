local fontCache = {}

local textObjectCache = {}

local fontLoader = {
  big = function ()
    return love.graphics.newFont(24)
  end,
  title = function ()
    return love.graphics.newFont(48)
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

local function draw(fontName, text, x, y)
  textObject = getTextObject(fontName, text)
  love.graphics.draw(textObject, x, y)
end

return {
  getTextObject = getTextObject,
  draw = draw
}
