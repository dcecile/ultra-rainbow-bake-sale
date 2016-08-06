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

  local nominalWidth, nominalHeight = 1160, 1069
  local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
  local windowHeight = desktopHeight * 0.7
  local windowWidth = nominalWidth * windowHeight / nominalHeight
  love.window.setTitle('Ultra Rainbow Bake Sale')
  love.window.setMode(
    math.floor(windowWidth),
    math.floor(windowHeight),
    {
      resizable = true,
      msaa = 8,
      fullscreen = settings.isFullscreen,
    })
  resolutionEngine.setNominal(nominalWidth, nominalHeight)
  resolutionEngine.setOnChanged(function ()
    textEngine.reset()
  end)

  audioEngine.setMusicIsOn(settings.musicIsOn)

  creditsScreen.screen.next = titleScreen.screen

  if debugMode.isActive then
    game.screen:show()
    game.screen:start()
  else
    titleScreen.screen:show()
  end
end

function takeScreenshot(width, height)
  resolutionEngine.setResolution(width, height)
  local canvas = love.graphics.newCanvas(width, height, normal, 8)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(currentScreen.get().backgroundColor)
  currentScreen.get():update(0)
  currentScreen.get():paint()
  love.graphics.setCanvas()
  canvas:newImageData():encode('png', 'shot.png')
  print('Saved screenshot')
end

function love.keypressed(key, isrepeat)
  if debugMode.isActive then
    if key == ' ' or key == 'return' then
      love.event.quit()
    elseif key == 's' then
      takeScreenshot(315, 250)
    elseif key == 'd' then
      takeScreenshot(933, 860)
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
