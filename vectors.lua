local vec3_metatable = {}
vec3_metatable.__index = {}

local function vec3(x, y, z)
  local vector = {
    x = x,
    y = y,
    z = z
  }
  setmetatable(vector, vec3_metatable)
  return vector
end

local function vec2(x, y)
  return vec3(x, y, 0)
end

function vec3_metatable.__add(a, b)
  return vec3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function vec3_metatable.__sub(a, b)
  return vec3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function vec3_metatable.__unm(a)
  return vec3(-a.x, -a.y, -a.z)
end

function vec3_metatable.__index.scale(a, b)
  return vec3(a.x * b, a.y * b, a.z * b)
end

function vec3_metatable.__index.length(a)
  return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

function vec3_metatable.__index.unit(a, b)
  local length = a:length()
  return a:scale(1 / length)
end

function vec3_metatable.__index.dot(a, b)
  return a.x * b.x + a.y * b.y + a.z * b.z
end

return {
  vec3 = vec3,
  vec2 = vec2
}
