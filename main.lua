local creditsScreen = require('creditsScreen')
local currentScreen = require('currentScreen')
local game = require('game')
local proto = require('proto')
local titleScreen = require('titleScreen')
local utils = require('utils')

local quitShortcut = false

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

  titleScreen.screen:show()
  creditsScreen.screen.next = titleScreen.screen

  if tonumber(os.getenv('DEBUG_URBS')) == 1 then
    titleScreen.screen.mute = true
    quitShortcut = true
    game.screen:show()
    game.screen:start()
  end
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

function love.update(time)
  currentScreen.get():update(time * 1000)
end

function love.draw()
  currentScreen.get():paint()
end
