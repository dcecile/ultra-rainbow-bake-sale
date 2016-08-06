local audioEngine = require('audioEngine')
local colors = require('colors')
local cupcakeScreen = require('cupcakeScreen')
local introScreen = require('introScreen')
local particleEngine = require('particleEngine')
local proto = require('proto')
local rainbowStripes = require('rainbowStripes')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')
local vectors = require('vectors')

local unscaleF = resolutionEngine.unscaleFloat
local scaleF = resolutionEngine.scaleFloat
local vec2 = vectors.vec2
local vec3 = vectors.vec3

local rainbowGradient = particleEngine.linearGradientParticle:extend({
  origin = vec3(unpack(colors.rainbow[6])),
  intermediate = {
    vec3(unpack(colors.rainbow[1])),
    vec3(unpack(colors.rainbow[2])),
    vec3(unpack(colors.rainbow[3])),
    vec3(unpack(colors.rainbow[4])),
    vec3(unpack(colors.rainbow[5])),
  },
  target = vec3(unpack(colors.rainbow[6])),
  duration = 40000,
  next = function (self)
    particleEngine.add(self)
  end,
})

local titleText = proto.object:extend({
  top = nil,
  left = nil,
  width = nil,
  height = nil,
  text = 'Ultra Rainbow Bake Sale',
  font = 'title',
  textObject = nil,
  refresh = function (self)
    local width, height = resolutionEngine.getUnscaledDimensions()

    self.textObject = textEngine.getTextObject(self.font, self.text)

    self.width = unscaleF(self.textObject:getWidth())
    self.height = unscaleF(self.textObject:getHeight())
    self.left = width / 2 - self.width / 2
    self.top = height / 2 - self.height / 2
  end,
  paint = function (self)
    textEngine.paintTextObject(
      rainbowGradient:getColor(),
      self.textObject,
      self.left,
      self.top)
  end,
})

local titleTextBox = proto.object:extend({
  top = nil,
  left = nil,
  width = nil,
  height = nil,
  margin = { -30, 30 },
  refresh = function (self)
    self.left = titleText.left - self.margin[1]
    self.top = titleText.top - self.margin[2]
    self.width = titleText.width + self.margin[1] * 2
    self.height = titleText.height + self.margin[2] * 2
  end,
  paint = function (self)
    rectangleEngine.paintRounded(
      colors.inverseText,
      self.left,
      self.top,
      self.width,
      self.height)
  end,
})

local titleShine = particleEngine.shineParticle:extend({
  origin = vec2(-200, 0),
  target = vec2(-199, 0),
  width = 20,
  height = 100,
  color = { 255, 255, 255, 208 },
  rotation = math.pi / 8,
  duration = 300,
  refresh = function (self)
    local y = titleText.top + titleText.height / 2
    self.origin = vec2(titleText.left, y)
    self.target = vec2(titleText.left + titleText.width, y)
  end,
})

local titleShineDelay = particleEngine.delayParticle:extend({
  duration = 10000,
  next = function (self)
    particleEngine.add(self.proto:extend())
    particleEngine.add(titleShine:extend())
  end,
})

local cupcakeShadow = {
  foil = { 255, 255, 255 },
  foilHighlight = { 255, 255, 255 },
  cake = { 255, 255, 255 },
  icing = { 255, 255, 255 },
  icingHighlight = { 255, 255, 255 },
}

local flyingParticle = particleEngine.lineParticle:extend({
  size = nil,
  minSize = nil,
  maxSize = nil,
  easing = particleEngine.linear,
  paint = function (self)
    love.graphics.push()
    love.graphics.scale(scaleF(1), scaleF(1))
    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.scale(unscaleF(1), unscaleF(1))
    love.graphics.scale(self.size, self.size)
    love.graphics.rotate(math.pi / 8)
    self:paintSprite()
    love.graphics.pop()
  end,
  makeRandom = function (self)
    local y = math.random(3000)
    local origin = vec2(-100, y + 100)
    local target = vec2(y, 0)
    local size = math.random() * (self.maxSize - self.minSize) + self.minSize
    local speed = (size + math.random() * 0.2) / 0.3 * 0.2
    local duration = (target - origin):length() / speed
    return self:extend({
      origin = origin,
      target = target,
      duration = duration,
      size = size,
    })
  end,
})

local cupcakeParticle = flyingParticle:extend({
  minSize = 0.5,
  maxSize = 0.8,
  paintSprite = function (self)
    cupcakeScreen.paintCupcake(cupcakeShadow, 0, 0)
  end,
})

local cupcakeSpawnDelay = particleEngine.delayParticle:extend({
  duration = 200,
  next = function (self)
    particleEngine.add(self.proto:extend())
    particleEngine.add(cupcakeParticle:makeRandom())
  end,
})

local starParticle = flyingParticle:extend({
  minSize = 0.1,
  maxSize = 0.5,
  paintSprite = function (self)
    cupcakeScreen.paintStar(cupcakeShadow.icing, 0, 0, 0)
  end,
})

local starSpawnDelay = particleEngine.delayParticle:extend({
  duration = 200,
  next = function (self)
    particleEngine.add(self.proto:extend())
    particleEngine.add(starParticle:makeRandom())
  end,
})

local screen = ui.screen:extend({
  backgroundColor = colors.inverseText,
  next = introScreen.screen,
  update = function (self, time)
    self:refresh()
    particleEngine.update(time)
  end,
  refresh = function (self)
    ui.cursor:clickable()
    titleText:refresh()
    titleTextBox:refresh()
    titleShine:refresh()
  end,
  paint = function (self)
    rainbowStripes.stripes:paint()
    titleTextBox:paint()
    titleText:paint()
    particleEngine.paint()
  end,
  mousepressed = function (self, x, y, button, istouch)
    audioEngine.startMusic()
    self:showNext()
  end,
  show = function (self)
    local seed = love.timer.getTime()
    print(string.format('Seeding title with %f', seed))
    math.randomseed(seed)

    particleEngine.add(titleShineDelay:extend({
      duration = 200,
    }))
    particleEngine.add(cupcakeSpawnDelay:extend({
      duration = 200,
    }))
    particleEngine.add(starSpawnDelay:extend({
      duration = 200,
    }))
    particleEngine.add(rainbowGradient)

    ui.screen.show(self)
  end,
  showNext = function (self, ...)
    particleEngine.reset()
    ui.screen.showNext(self, ...)
  end,
})

return {
  screen = screen,
}
