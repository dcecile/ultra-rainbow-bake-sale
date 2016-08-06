local colors = require('colors')
local resolutionEngine = require('resolutionEngine')
local rectangleEngine = require('rectangleEngine')
local proto = require('proto')

local scaleF = resolutionEngine.scaleFloat

local stripes = proto.object:extend({
  paint = function (self)
    local width, height = resolutionEngine.getUnscaledDimensions()

    local margin = height / 8
    local repeats = 1
    local rainbowHeight = (height - 2 * margin) / (6 * repeats)
    for j = 1, repeats do
      for i = 1, 6 do
        rectangleEngine.paint(colors.rainbow[i], 0, margin + rainbowHeight * ((i - 1) + 6 * (j - 1)), width, rainbowHeight)
      end
    end
  end,
  paintDiagonal = function (self)
    local width, height = resolutionEngine.getUnscaledDimensions()

    local slope = 2
    local startY = 300
    local widthY = 80

    love.graphics.push()
    love.graphics.scale(scaleF(1), scaleF(1))

    for i = 1, 6 do
      local leftX0 = 0
      local leftY0 = startY + widthY * (i - 1)
      local leftX1 = 0
      local leftY1 = leftY0 + widthY
      local topX0 = leftY0 * slope
      local topY0 = 0
      local topX1 = leftY1 * slope
      local topY1 = 0
      love.graphics.setColor(colors.rainbow[i])
      love.graphics.polygon('fill',
        leftX0, leftY0, topX0, topY0,
        topX1, topY1, leftX1, leftY1)
    end

    love.graphics.pop()
  end,
})

return {
  stripes = stripes,
}
