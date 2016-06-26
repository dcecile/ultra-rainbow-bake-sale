local extraScreens = require('extraScreens')
local game = require('game')
local proto = require('proto')
local utils = require('utils')

music = nil
credits = nil

extraScreens.introScreen.gameScreen = game.screen

currentScreen = extraScreens.titleScreen
--extraScreens.titleScreen.mute = true
--currentScreen = game.screen

function love.load()
  love.window.setMode(0, 0, { msaa = 8 })
  bigFont = love.graphics.newFont(24)
  music = love.audio.newSource('bensound-anewbeginning.mp3')
  music:setLooping(true)
  credits = love.filesystem.read('credits.txt')
end

function love.keypressed(key, isrepeat)
  if key == ' ' or key == 'return' then
    love.event.quit()
  end
end

function love.mousepressed(x, y, button, istouch)
  currentScreen:mousepressed(x, y, button, istouch)
end

function love.draw()
  currentScreen:draw()
end
