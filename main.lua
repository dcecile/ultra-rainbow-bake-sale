local extraScreens = require('extraScreens')
local game = require('game')
local proto = require('proto')
local utils = require('utils')

music = nil
credits = nil

extraScreens.introScreen.gameScreen = game.screen

currentScreen = extraScreens.titleScreen
extraScreens.titleScreen.mute = true
currentScreen = game.screen
game.screen:start()

function love.load()
  love.window.setTitle('Ultra Rainbow Bake Sale')
  love.window.setMode(1010, 1010, { resizable = true, msaa = 8 })
  bigFont = love.graphics.newFont(24)
  music = love.audio.newSource('bensound-anewbeginning.mp3')
  music:setVolume(0.3)
  music:setLooping(true)
  credits = love.filesystem.read('credits.txt')
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle('rough')
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
  love.graphics.origin()
  love.graphics.translate(0.5, 0.5)
  currentScreen:paint()
end
