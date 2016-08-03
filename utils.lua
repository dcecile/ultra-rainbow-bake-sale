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

return {
  sum = sum,
  method = method,
  defaultOptions = defaultOptions,
}
