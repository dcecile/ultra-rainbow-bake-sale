local colors = require('colors')
local dialogueScreen = require('dialogueScreen')
local game = require('game')
local rectangleEngine = require('rectangleEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local screen = dialogueScreen.screen:extend({
  backgroundColor = colors.darkBackground,
  lines = {
    { 'Alex', 'Who’s idea was this anyways?' },
    { 'Morgan', 'Come on, love will always conquer hatred.' },
    { 'Alex', 'With baked goods? We’ve never baked before.' },
    { 'Morgan', 'Just follow the recipe. Like in science class.' },
    { 'Alex', 'You’re no good at science.' },
    { 'Morgan', '...' },
    { 'Alex', 'Fine, let’s just start with some simple cupcakes.' },
    { 'Morgan', 'Now we’re talking!' },
  },
  mousepressed = function (self, x, y, button, istouch)
    game.screen:show()
    game.screen:start()
  end,
})

return {
  screen = screen,
}
