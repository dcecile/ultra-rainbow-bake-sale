local nominalWidth
local nominalHeight
local scaling
local unscaledWidth
local unscaledHeight
local onChanged

local function setNominal(width, height)
  nominalWidth = width
  nominalHeight = height
end

local function setOnChanged(callback)
  onChanged = callback
end

local function refresh()
  local newScaling
  local width, height = love.graphics.getDimensions()
  width = math.max(64, width)
  height = math.max(64, height)
  if width / height > nominalWidth / nominalHeight then
    newScaling = height / nominalHeight
  else
    newScaling = width / nominalWidth
  end
  if newScaling ~= scaling then
    scaling = newScaling
    onChanged()
  end
  unscaledWidth = width / scaling
  unscaledHeight = height / scaling
end

local function getUnscaledDimensions()
  return unscaledWidth, unscaledHeight
end

local function getUnscaledMousePosition()
  local mouseX, mouseY = love.mouse.getPosition()
  return mouseX / scaling, mouseY / scaling
end

local function scaleFloat(value)
  return value * scaling
end

local function unscaleFloat(value)
  return value / scaling
end

local function scaleRoundToZero(value)
  local scaled = scaleFloat(value)
  if scaled > 0 then
    return math.floor(scaled)
  else
    return math.ceil(scaled)
  end
end

return {
  setNominal = setNominal,
  setOnChanged = setOnChanged,
  refresh = refresh,
  getUnscaledDimensions = getUnscaledDimensions,
  getUnscaledMousePosition = getUnscaledMousePosition,
  unscaleFloat = unscaleFloat,
  scaleFloat = scaleFloat,
  scaleRoundToZero = scaleRoundToZero,
}
