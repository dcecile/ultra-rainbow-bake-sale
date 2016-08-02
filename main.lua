local audioEngine = require('audioEngine')
local creditsScreen = require('creditsScreen')
local currentScreen = require('currentScreen')
local debugMode = require('debugMode')
local game = require('game')
local resolutionEngine = require('resolutionEngine')
local settingsScreen = require('settingsScreen')
local textEngine = require('textEngine')
local titleScreen = require('titleScreen')

local unscaleF = resolutionEngine.unscaleFloat

local quitShortcut = false

function love.load()
  love.filesystem.setIdentity('ultra_rainbow_bake_sale')
  local settings = settingsScreen.load()

  local width, height = 1185, 1050
  love.window.setTitle('Ultra Rainbow Bake Sale')
  love.window.setMode(
    width,
    height,
    {
      resizable = true,
      msaa = 8,
      fullscreen = settings.isFullscreen,
    })
  resolutionEngine.setNominal(width, height)
  resolutionEngine.setOnChanged(function ()
    textEngine.reset()
  end)

  audioEngine.setMusicIsOn(settings.musicIsOn)

  titleScreen.screen:show()
  creditsScreen.screen.next = titleScreen.screen

  if debugMode.isActive then
    game.screen:show()
    game.screen:start()
  end
end

function love.keypressed(key, isrepeat)
  if debugMode.isActive then
    if key == ' ' or key == 'return' then
      love.event.quit()
    end
  end
end

function love.mousepressed(x, y, button, istouch)
  resolutionEngine.refresh()
  currentScreen.get():mousepressed(unscaleF(x), unscaleF(y), button, istouch)
end

function love.update(time)
  resolutionEngine.refresh()
  currentScreen.get():update(time * 1000)
end

function love.draw()
  resolutionEngine.refresh()
  currentScreen.get():paint()
end

function love.quit()
  settingsScreen.save()
  return false
end
