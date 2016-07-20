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

return {
  sum = sum,
  method = method,
}
