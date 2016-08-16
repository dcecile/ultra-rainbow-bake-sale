local function sum(list, transform)
  local total = 0
  for i, item in ipairs(list) do
    total = total + transform(item)
  end
  return total
end

local method = {
  __index = function (self, name)
    return function (newSelf, ...)
      return newSelf[name](newSelf, ...)
    end
  end
}
setmetatable(method, method)

local function defaultOptions(override, default)
  if override and override.__index then
    defaultOptions(override.__index, default)
    return override
  else
    override = override or {}
    default = default or {}
    override.__index = default
    setmetatable(override, override)
    return override
  end
end

local function copy(input)
  local result = {}
  for key, value in pairs(input) do
    result[key] = value
  end
  return result
end

local function map(list, transform)
  local result = {}
  for i, item in ipairs(list) do
    table.insert(result, transform(item))
  end
  return result
end

local function filter(list, condition)
  local result = {}
  for i, item in ipairs(list) do
    if condition(item) then
      table.insert(result, item)
    end
  end
  return result
end

local function concat(lists)
  local result = {}
  for i, list in ipairs(lists) do
    for j, item in ipairs(list) do
      table.insert(result, item)
    end
  end
  return result
end

local function concatMap(list, transform)
  return concat(map(list, transform))
end

local function any(list, condition)
  condition = condition or function (item) return item end
  for i, item in ipairs(list) do
    if condition(item) then
      return item
    end
  end
  return false
end

local function register(self)
  local parentScope = 2
  local newEnvironment = copy(self)
  newEnvironment.__index = getfenv(parentScope)
  setmetatable(newEnvironment, newEnvironment)
  setfenv(parentScope, newEnvironment)
end

return {
  sum = sum,
  method = method,
  defaultOptions = defaultOptions,
  map = map,
  filter = filter,
  concat = concat,
  concatMap = concatMap,
  any = any,
  register = register,
}
