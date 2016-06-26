object = {}
setmetatable(object, object)

function object.extend(self, table)
  clone = table or {}
  clone.__index = self
  setmetatable(clone, clone)
  return clone
end

return {
  object = object
}
