local current = nil

local function set(screen)
  current = screen
end

local function get()
  return current
end

return {
  set = set,
  get = get,
}
