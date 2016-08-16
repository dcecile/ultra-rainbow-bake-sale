local resolutionEngine = require('resolutionEngine')

local scaleF = resolutionEngine.scaleFloat
local scaleR = resolutionEngine.scaleRoundToZero

local function scaleRectangle(left, top, width, height)
  return {
    left = scaleR(left),
    top = scaleR(top),
    width = scaleR(left + width) - scaleR(left),
    height = scaleR(top + height) - scaleR(top)
  }
end

local function paint(color, left, top, width, height)
  local scaled = scaleRectangle(left, top, width, height)
  love.graphics.setColor(color)
  love.graphics.rectangle(
    'fill',
    scaled.left,
    scaled.top,
    scaled.width,
    scaled.height)
end

local function paintRounded(color, left, top, width, height)
  local scaled = scaleRectangle(left, top, width, height)
  local radius = scaled.height / 2
  love.graphics.setColor(color)
  love.graphics.rectangle(
    'fill',
    scaled.left,
    scaled.top,
    scaled.width,
    scaled.height)
  love.graphics.circle(
    'fill',
    scaled.left,
    scaled.top + radius,
    radius,
    30)
  love.graphics.circle(
    'fill',
    scaled.left + scaled.width,
    scaled.top + radius,
    radius,
    30)
end

local function paintBorder(color, left, top, width, height, padding)
  local scaled = scaleRectangle(left, top, width, height)
  love.graphics.setColor(color)
  love.graphics.rectangle(
    'fill',
    scaled.left - padding,
    scaled.top,
    padding,
    scaled.height)
  love.graphics.rectangle(
    'fill',
    scaled.left + scaled.width,
    scaled.top,
    padding,
    scaled.height)
  love.graphics.rectangle(
    'fill',
    scaled.left - padding,
    scaled.top - padding,
    scaled.width + 2 * padding,
    padding)
  love.graphics.rectangle(
    'fill',
    scaled.left - padding,
    scaled.top + scaled.height,
    scaled.width + 2 * padding,
    padding)
end

return {
  paint = paint,
  paintRounded = paintRounded,
  paintBorder = paintBorder,
}
