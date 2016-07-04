local extraScreens = require('extraScreens')
local game = require('game')
local proto = require('proto')
local utils = require('utils')

music = nil
credits = nil
local quitShortcut = false

extraScreens.introScreen.gameScreen = game.screen

currentScreen = extraScreens.titleScreen

if os.getenv('DEBUG_URBS') then
  extraScreens.titleScreen.mute = true
  quitShortcut = true
  currentScreen = game.screen
  game.screen:start()
end

function love.load()
  love.window.setTitle('Ultra Rainbow Bake Sale')
  love.window.setMode(
    1700,
    1010,
    {
      resizable = true,
      msaa = 8,
      fullscreen = false,
    })
  bigFont = love.graphics.newFont(24)
  music = love.audio.newSource('bensound-anewbeginning.mp3')
  music:setVolume(0.3)
  music:setLooping(true)
  credits = love.filesystem.read('credits.txt')
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle('rough')
end

function love.keypressed(key, isrepeat)
  if quitShortcut then
    if key == ' ' or key == 'return' then
      love.event.quit()
    end
  end
end

function love.mousepressed(x, y, button, istouch)
  currentScreen:mousepressed(x, y, button, istouch)
end

function love.draw()
  currentScreen:paint()
end
