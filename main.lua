local creditsScreen = require('creditsScreen')
local currentScreen = require('currentScreen')
local game = require('game')
local proto = require('proto')
local titleScreen = require('titleScreen')
local utils = require('utils')

music = nil
credits = nil
local quitShortcut = false

titleScreen.screen:show()
creditsScreen.screen.next = titleScreen.screen

if os.getenv('DEBUG_URBS') then
  titleScreen.screen.mute = true
  quitShortcut = true
  game.screen:show()
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
  currentScreen.get():mousepressed(x, y, button, istouch)
end

function love.draw()
  currentScreen.get():paint()
end
