local audioEngine = require('audioEngine')
local colors = require('colors')
local creditsScreen = require('creditsScreen')
local dialogueScreen = require('dialogueScreen')
local rectangleEngine = require('rectangleEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local screen = dialogueScreen.screen:extend({
  next = creditsScreen.screen,
  show = function (self, totalCupcakes, totalCleanupCost)
    local cleanupText = ''
    if totalCleanupCost > 0 then
      cleanupText = ' But getting help to clean up cost us ' .. totalCleanupCost .. ' cupcakes!'
    end
    self.lines = {
      { 'Morgan', 'We baked ' .. totalCupcakes .. ' cupcakes!' },
      { 'Alex', 'Great!' .. cleanupText },
    }
    dialogueScreen.screen.show(self)
  end,
  mousepressed = function (self, x, y, button, istouch)
    audioEngine.stopMusic()
    self:showNext()
  end,
})

return {
  screen = screen,
}
