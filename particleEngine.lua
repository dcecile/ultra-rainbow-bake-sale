local proto = require('proto')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local vectors = require('vectors')

local scaleF = resolutionEngine.scaleFloat
local vec2 = vectors.vec2

local active = {}

local function linear(t)
  return t
end

local function inQuad(t)
  return t * t
end

local function outQuad(t)
  return 1 - inQuad(1 - t)
end

local function inOutQuad(t)
  if t < 0.5 then
    return 0.5 * inQuad(2 * t)
  else
    return 0.5 + 0.5 * outQuad(2 * (t - 0.5))
  end
end

local lineSegment = proto.object:extend({
  make = function (self, origin, target)
    local delta = target - origin
    return self:extend({
      origin = origin,
      length = delta:length(),
      unit = delta:unit(),
    })
  end,
  getProgress = function (self, length)
    return self.origin + self.unit:scale(length)
  end,
})

local arcSegment = proto.object:extend({
  make = function (self, center, radius, origin, target)
    local delta = target - origin
    local length = math.abs(delta * radius)
    return self:extend({
      center = center,
      origin = origin,
      length = length,
      unit = delta / length,
      radius = radius,
    })
  end,
  makeX = function (self, origin, radius, x, y)
    local originTheta = -y * math.pi / 2
    return self:make(
      origin + vec2(0, radius * y),
      radius,
      originTheta,
      originTheta + x * y * math.pi / 2)
  end,
  makeY = function (self, origin, radius, x, y)
    local originTheta = math.pi / 2 * (1 + x)
    return self:make(
      origin + vec2(radius * x, 0),
      radius,
      originTheta,
      originTheta - x * y * math.pi / 2)
  end,
  getProgress = function (self, length)
    local theta = self.origin + self.unit * length
    return self.center
      + vec2(math.cos(theta), math.sin(theta)):scale(self.radius)
  end,
})

local function essPath(maxRadius)
  return function (origin, target)
    local delta = target - origin
    local radius = math.min(maxRadius, math.min(math.abs(delta.y), math.abs(delta.x)) / 2)
    local straight = vec2(delta.x, 0):unit():scale(math.abs(delta.x) / 2 - radius)
    local direction = delta:sign()
    local arc = direction:scale(radius)
    local arc0Start = origin + straight
    local line1Start = arc0Start + arc
    local line2Start = target - straight
    local arc1Start = line2Start - arc
    return {
      lineSegment:make(origin, arc0Start),
      arcSegment:makeX(arc0Start, radius, direction.x, direction.y),
      lineSegment:make(line1Start, arc1Start),
      arcSegment:makeY(arc1Start, radius, direction.x, direction.y),
      lineSegment:make(line2Start, target),
    }
  end
end

local function seePath(radius, directionX)
  return function (origin, target)
    local delta = target - origin
    local direction = vec2(directionX, delta.y):sign()
    local straight = vec2(0, direction.y):scale(math.abs(delta.y) - 2 * radius)
    local line0Start = origin + direction:scale(radius)
    local arc1Start = line0Start + straight
    return {
      arcSegment:makeX(origin, radius, direction.x, direction.y),
      lineSegment:make(line0Start, arc1Start),
      arcSegment:makeY(arc1Start, radius, -direction.x, direction.y),
    }
  end
end

local baseParticle = proto.object:extend({
  origin = nil,
  target = nil,
  duration = nil,
  next = nil,
  easing = inOutQuad,
  init = function (self)
    self.segments = self.path(self.origin, self.target, self.intermediate)
    self.totalLength = 0
    for i, segment in ipairs(self.segments) do
      self.totalLength = self.totalLength + segment.length
    end
    self.currentTime = 0
    self.position = self.origin
  end,
  update = function (self, time, remove)
    self.currentTime = self.currentTime + time
    if self.currentTime >= self.duration then
      remove()
      if self.next then
        self:next()
      end
      return
    end
    local currentLength = self.totalLength * self.easing(self.currentTime / self.duration)
    for i, segment in ipairs(self.segments) do
      if currentLength <= segment.length + 1e-5 then
        self.position = segment:getProgress(currentLength)
        return
      else
        currentLength = currentLength - segment.length
      end
    end
    error('segment not found')
  end,
  cancel = function (self)
    self.currentTime = self.duration
    self.next = nil
  end,
})

local cardParticle = baseParticle:extend({
  color = nil,
  size = nil,
  path = nil,
  paint = function (self)
    rectangleEngine.paint(
      self.color,
      self.position.x - self.size / 2,
      self.position.y - self.size / 2,
      self.size,
      self.size)
  end,
})

local lineParticle = baseParticle:extend({
  intermediate = {},
  path = function (origin, target, intermediate)
    local segments = {}
    for i, next in ipairs(intermediate) do
      table.insert(segments, lineSegment:make(origin, next))
      origin = next
    end
    table.insert(segments, lineSegment:make(origin, target))
    return segments
  end,
})

local shineParticle = lineParticle:extend({
  color = nil,
  width = nil,
  height = nil,
  rotation = nil,
  paint = function (self)
    love.graphics.push()
    love.graphics.scale(scaleF(1), scaleF(1))
    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.rotate(self.rotation)
    love.graphics.setColor(self.color)
    love.graphics.rectangle(
      'fill',
      -self.width / 2,
      -self.height / 2,
      self.width,
      self.height)
    love.graphics.pop()
  end,
})

local delayParticle = lineParticle:extend({
  origin = vec2(0, 0),
  target = vec2(1, 1),
  paint = function (self)
  end,
})

local linearGradientParticle = lineParticle:extend({
  easing = linear,
  paint = function (self)
  end,
  getColor = function (self)
    return { self.position.x, self.position.y, self.position.z }
  end,
})

local fadeParticle = lineParticle:extend({
  paint = function (self)
  end,
  alpha = function (self, color, maxAlpha)
    return { color[1], color[2], color[3], self.position.x * maxAlpha }
  end,
})

local fadeInParticle = fadeParticle:extend({
  origin = vec2(0, 0),
  target = vec2(1, 0),
  easing = inQuad,
})

local fadeOutParticle = fadeParticle:extend({
  origin = vec2(1, 0),
  target = vec2(0, 0),
  easing = outQuad,
})

local function reset()
  active = {}
end

local function add(particle)
  if particle.previousParticle then
    particle.previousParticle.next = function (self)
      particle.previousParticle = nil
      add(particle)
    end
  else
    particle:init()
    table.insert(active, particle)
  end
end

local function update(time)
  local removals = {}
  local function remove(i)
    table.insert(removals, 1, i)
  end
  for i, particle in ipairs(active) do
    particle:update(time, function () remove(i) end)
  end
  for i, j in ipairs(removals) do
    table.remove(active, j)
  end
end

local function paint()
  for i, particle in ipairs(active) do
    particle:paint()
  end
end

return {
  reset = reset,
  add = add,
  update = update,
  paint = paint,
  cardParticle = cardParticle,
  lineParticle = lineParticle,
  shineParticle = shineParticle,
  delayParticle = delayParticle,
  linearGradientParticle = linearGradientParticle,
  fadeInParticle = fadeInParticle,
  fadeOutParticle = fadeOutParticle,
  essPath = essPath,
  seePath = seePath,
  linear = linear,
  inQuad = inQuad,
  outQuad = outQuad,
  inOutQuad = inOutQuad,
}
