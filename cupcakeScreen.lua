local colors = require('colors')
local currentScreen = require('currentScreen')
local rainbowStripes = require('rainbowStripes')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local ui = require('ui')

local scaleF = resolutionEngine.scaleFloat

local function paintCupcake(colors, x, y)
  love.graphics.push()
  love.graphics.scale(scaleF(1), scaleF(1))
  love.graphics.translate(x - 415, y - 165)

  love.graphics.setColor(colors.foil)
  love.graphics.polygon('fill',
    430, 235, 420, 202,
    510, 202, 500, 235)

  love.graphics.setColor(colors.cake)
  love.graphics.polygon('fill',
    422, 202, 422, 198,
    508, 198, 508, 202)

  love.graphics.setColor(colors.icing)
  love.graphics.polygon('fill',
    415, 198, 415, 185,
    515, 185, 515, 198)
  love.graphics.polygon('fill',
    424, 185, 424, 174,
    506, 174, 506, 185)
  love.graphics.polygon('fill',
    441, 174, 441, 165,
    489, 165, 489, 174)

  love.graphics.setColor(colors.icingHighlight)
  love.graphics.polygon('fill',
    425, 198,
    515, 190, 515, 198)
  love.graphics.polygon('fill',
    434, 185,
    506, 180, 506, 185)
  love.graphics.polygon('fill',
    451, 174,
    489, 170, 489, 174)

  love.graphics.setColor(colors.foilHighlight)
  love.graphics.polygon('fill',
    425, 202, 430, 202,
    434, 230)
  love.graphics.polygon('fill',
    437, 202, 442, 202,
    443, 230)
  love.graphics.polygon('fill',
    449, 202, 454, 202,
    454, 230)
  love.graphics.polygon('fill',
    461, 202, 466, 202,
    463, 230)
  love.graphics.polygon('fill',
    473, 202, 478, 202,
    473, 230)
  love.graphics.polygon('fill',
    485, 202, 490, 202,
    484, 230)
  love.graphics.polygon('fill',
    497, 202, 502, 202,
    493, 230)

  love.graphics.pop()
end

local cupcakeColors = {
  foil = { 252, 255, 174 },
  foilHighlight = { 255, 255, 255 },
  cake = { 215, 211, 127 },
  icing = { 182, 252, 255 },
  icingHighlight = { 133, 223, 223 },
}

local function paintStar(color, x, y, angle)
  love.graphics.push()
  love.graphics.setColor(color)
  love.graphics.scale(scaleF(1), scaleF(1))
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)
  local tip = 30
  local body = 7

  for i = 0, 1 do
    love.graphics.polygon('fill',
      0, -tip,
      body, -body,
      body, body,
      0, tip,
      -body, body,
      -body, -body)
    love.graphics.rotate(math.pi / 2)
  end

  love.graphics.pop()
end

local screen = ui.screen:extend({
  backgroundColor = colors.inverseText,
  paint = function (self)
    ui.cursor:clickable()

    rainbowStripes.stripes:paint()

    local screenWidth, screenHeight = resolutionEngine.getUnscaledDimensions()
    rectangleEngine.paint(
      colors.textBox, 100, 100, screenWidth - 200, screenHeight - 200)

    local cupcakeWidth = 515 - 415
    local cupcakeHeight = 235 - 165
    local marginX = 30
    local marginY = 30
    local cupcakeX = screenWidth / 2 - (cupcakeWidth * 4 + marginX * 3) / 2
    local cupcakeY = screenHeight / 2 - (cupcakeHeight * 3 + marginY * 2) / 2

    love.graphics.origin()

    for y = 0, 2 do
      for x = 0, 3 do
        paintCupcake(
          cupcakeColors,
          cupcakeX + x * (cupcakeWidth + marginX),
          cupcakeY + y * (cupcakeHeight + marginY))
      end
    end

    paintStar(
      { 255, 190, 137 },
      cupcakeX + 30,
      cupcakeY - 60,
      math.pi * (0 / 6 - 1 / 8))
    paintStar(
      { 254, 255, 137 },
      cupcakeX + 500,
      cupcakeY - 90,
      math.pi * (1 / 6 - 1 / 8))
    paintStar(
      { 144, 255, 137 },
      cupcakeX + 610,
      cupcakeY + 30,
      math.pi * (2 / 6 - 1 / 8))
    paintStar(
      { 137, 181, 255 },
      cupcakeX + 530,
      cupcakeY + 300,
      math.pi * (3 / 6 - 1 / 8))
    paintStar(
      { 255, 137, 255 },
      cupcakeX + 50,
      cupcakeY + 330,
      math.pi * (4 / 6 - 1 / 8))
    paintStar(
      { 255, 127, 127 },
      cupcakeX - 100,
      cupcakeY + 150,
      math.pi * (5 / 6 - 1 / 8))
  end,
  show = function (self)
    self.next = currentScreen.get()
    ui.screen.show(self)
  end,
  mousepressed = function (self, x, y, button, istouch)
    self:showNext()
  end,
})

return {
  paintCupcake = paintCupcake,
  paintStar = paintStar,
  screen = screen,
}
