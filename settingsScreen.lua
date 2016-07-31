local audioEngine = require('audioEngine')
local colors = require('colors')
local currentScreen = require('currentScreen')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local textEngine = require('textEngine')
local ui = require('ui')
local versionNumber = require('versionNumber')

local settingsCard = ui.card:extend({
  color = colors.card,
  borderColor = colors.text,
  textColor = colors.text,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local settingsBoxCard = ui.boxCard:extend({
  color = settingsCard.color,
  borderColor = settingsCard.borderColor,
  textColor = settingsCard.textColor,
  width = settingsCard.width,
  height = settingsCard.height,
  margin = settingsCard.margin,
  font = settingsCard.font,
  getBoxColors = function (self)
    return colors.cupcakes
    --return {
      --foreground = settingsCard.textColor,
      --background = settingsCard.color,
    --}
  end,
})

local settingsSpacer = ui.spacer:extend({
  width = settingsCard.width,
  margin = { 12, 6, 1 },
  color = colors.spacer,
})

local screen

local backgroundMusic = settingsBoxCard:extend({
  text = 'Background music',
  refresh = function (self)
    self.isOn = audioEngine.getMusicIsOn()
  end,
  clicked = function (self)
    audioEngine.setMusicIsOn(not self.isOn)
  end,
  getBoxValue = function (self)
    if self.isOn then
      return 'On'
    else
      return 'Off'
    end
  end,
})

local fullscreen = settingsBoxCard:extend({
  text = 'Fullscreen',
  refresh = function (self)
    self.isFullscreen = love.window.getFullscreen()
  end,
  clicked = function (self)
    love.window.setFullscreen(not self.isFullscreen)
  end,
  getBoxValue = function (self)
    if self.isFullscreen then
      return 'On'
    else
      return 'Off'
    end
  end,
})

local back = settingsCard:extend({
  text = 'Back',
  clicked = function (self)
    screen:showNext()
  end,
})

local title = settingsCard:extend({
  color = colors.lightBackground,
  borderColor = colors.lightBackground,
  height = 34,
  margin = { 13, 0 },
  font = 'header',
  text = 'Settings',
})

local version = settingsCard:extend({
  color = colors.lightBackground,
  borderColor = colors.lightBackground,
  margin = { 13, 0 },
  font = 'small',
  text = 'Version ' .. versionNumber.number,
})

screen = ui.screen:extend({
  backgroundColor = colors.lightBackground,
  buttons = ui.column:extend({
    top = 80,
    margin = 24,
    cards = {
      title,
      settingsSpacer:extend(),
      backgroundMusic,
      fullscreen,
      settingsSpacer:extend(),
      back,
      settingsSpacer:extend(),
      version,
    }
  }),
  show = function (self, next)
    self.next = next
    ui.screen.show(self)
  end,
  update = function (self, time)
    self:refresh()
  end,
  refresh = function (self)
    local mouseX, mouseY = resolutionEngine.getUnscaledMousePosition()
    ui.cursor:clear()
    local width, height = resolutionEngine.getUnscaledDimensions()
    self.buttons.left = width / 2 - settingsCard.width / 2
    self.buttons:refresh()
    self.buttons:checkHover(mouseX, mouseY, function (card)
      if card:isClickable() then
        ui.cursor:clickable()
      end
    end)
  end,
  paint = function (self)
    self.buttons:paint()
  end,
  mousepressed = function (self, x, y, button, istouch)
    self:refresh()
    self.buttons:mousepressed(x, y, button, istouch)
  end,
})

return {
  screen = screen,
}
