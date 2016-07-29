local resolutionEngine = require('resolutionEngine')

local scaleF = resolutionEngine.scaleFloat
local scaleR = resolutionEngine.scaleRoundToZero

local function paintPadded(color, left, top, width, height, padding)
  love.graphics.setColor(color)
  love.graphics.rectangle(
    'fill',
    scaleR(left) - padding,
    scaleR(top) - padding,
    scaleR(left + width) - scaleR(left) + padding * 2,
    scaleR(top + height) - scaleR(top) + padding * 2)
end

local function paint(color, left, top, width, height)
  paintPadded(color, left, top, width, height, 0)
end

return {
  paint = paint,
  paintPadded = paintPadded,
}
