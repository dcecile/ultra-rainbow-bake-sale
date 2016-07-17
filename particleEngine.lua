local proto = require('proto')
local rectangleEngine = require('rectangleEngine')
local vectors = require('vectors')

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
    local direction = vec2(delta.x, 0):unit() + vec2(0, delta.y):unit()
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
    local direction = vec2(directionX, 0):unit() + vec2(0, delta.y):unit()
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

local cardParticle = proto.object:extend({
  origin = nil,
  target = nil,
  duration = nil,
  color = nil,
  size = nil,
  path = nil,
  next = nil,
  init = function (self)
    self.segments = self.path(self.origin, self.target)
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
        self.next()
      end
      return
    end
    local currentLength = self.totalLength * inOutQuad(self.currentTime / self.duration)
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
  paint = function (self)
    rectangleEngine.paint(
      self.color,
      self.position.x - self.size / 2,
      self.position.y - self.size / 2,
      self.size,
      self.size)
  end,
})

local function add(particle)
  particle:init()
  table.insert(active, particle)
end

local function update(time)
  local removals = {}
  local function remove(i)
    table.insert(removals, i, 1)
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
  add = add,
  update = update,
  paint = paint,
  cardParticle = cardParticle,
  essPath = essPath,
  seePath = seePath,
}
