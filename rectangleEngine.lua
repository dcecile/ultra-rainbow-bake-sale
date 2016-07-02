local function paint(color, left, top, width, height)
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', left, top, width, height)
end

local function paintPadded(color, left, top, width, height, padding)
  paint(
    color,
    left - padding,
    top - padding,
    width + padding * 2,
    height + padding * 2)
end

return {
  paint = paint,
  paintPadded = paintPadded,
}
