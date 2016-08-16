return {
  darkBackground = { 128, 0, 128 },
  lightBackground = { 240, 200, 255 },
  text = { 60, 60, 60 },
  disabledText = { 213, 213, 213 },
  inverseText = { 255, 255, 255 },
  textBox = { 80, 0, 80 },
  card = { 255, 255, 255 },
  cardParticle = { 255, 255, 255, 180 },
  highlightColor = { 202, 255, 204 },
  selectedBorderColor = { 200, 200, 200 },
  spacer = { 150, 150, 150 },
  heading = { 100, 100, 100 },
  hope = {
    foreground = { 255, 75, 217 },
    background = { 255, 231, 250 },
  },
  hopeDisabled = {
    foreground = { 236, 194, 227 },
    background = { 255, 231, 250 },
  },
  cardPile = {
    foreground = { 0, 216, 202 },
    background = { 233, 255, 254 },
  },
  time = {
    foreground = { 137, 137, 137 },
    background = { 244, 244, 244 },
  },
  cupcakes = {
    foreground = { 170, 50, 255 },
    background = { 246, 233, 255 },
  },
  player = {
    foreground = { 97, 153, 255 },
    background = { 243, 246, 255 },
  },
  playerDisabled = {
    foreground = { 209, 221, 241 },
    background = { 246, 249, 252 },
  },
  rainbow = {
    { 255, 181, 181 },
    { 255, 224, 187 },
    { 255, 251, 187 },
    { 155, 255, 186 },
    { 187, 208, 255 },
    { 242, 157, 255 },
  },
  noActionAlpha = function (color)
    return { color[1], color[2], color[3], 128 }
  end,
  infoBoxAlpha = function (color)
    return { color[1], color[2], color[3], 30 }
  end,
  unselectableAlpha = function (color)
    return { color[1], color[2], color[3], 180 }
  end,
}
