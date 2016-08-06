object = {}
setmetatable(object, object)

function object.extend(self, properties)
  clone = properties or {}
  clone.__index = self
  clone.proto = self
  setmetatable(clone, clone)
  return clone
end

return {
  object = object
}
