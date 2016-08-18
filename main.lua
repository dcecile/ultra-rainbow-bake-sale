love.filesystem.setRequirePath('?.lua;src/?.lua;lib/?.lua')

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

local nominalWidth, nominalHeight = 1160, 1069

function love.load()
  love.filesystem.setIdentity('ultra-rainbow-bake-sale')
  local settings = settingsScreen.load()

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
    titleScreen.screen:start()
    titleScreen.screen:show()
  end
end

function takeScreenshot(width, height)
  local mouseX, mouseY = resolutionEngine.getUnscaledMousePosition()
  local originalGetUnscaledMousePosition = resolutionEngine.getUnscaledMousePosition
  resolutionEngine.getUnscaledMousePosition = function ()
    return mouseX, mouseY
  end
  resolutionEngine.setResolution(width, height)
  local canvas = love.graphics.newCanvas(width, height, normal, 8)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(currentScreen.get().backgroundColor)
  currentScreen.get():update(0)
  currentScreen.get():paint()
  love.graphics.setCanvas()
  resolutionEngine.getUnscaledMousePosition = originalGetUnscaledMousePosition
  canvas:newImageData():encode('png', 'shot.png')
  print('Saved screenshot')
end

function love.keypressed(key, isrepeat)
  if key == 'escape' then
    if currentScreen.get() == settingsScreen.screen then
      settingsScreen.screen:showNext()
    else
      settingsScreen.screen:show(currentScreen.get())
    end
  elseif debugMode.isActive then
    if key == ' ' or key == 'return' then
      love.event.quit()
    elseif key == 's' then
      takeScreenshot(315, 250)
    elseif key == 'd' then
      local forumWidth = 780
      takeScreenshot(forumWidth, forumWidth / nominalWidth * nominalHeight)
    elseif key == 'f' then
      takeScreenshot(nominalWidth, nominalHeight)
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
