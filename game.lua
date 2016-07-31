local colors = require('colors')
local cupcakeScreen = require('cupcakeScreen')
local doneScreen = require('doneScreen')
local gameDeckBasics = require('gameDeckBasics')
local gameDeckCards = require('gameDeckCards')
local gameUi = require('gameUi')
local particleEngine = require('particleEngine')
local rectangleEngine = require('rectangleEngine')
local resolutionEngine = require('resolutionEngine')
local settingsScreen = require('settingsScreen')
local textEngine = require('textEngine')
local ui = require('ui')
local utils = require('utils')

local discardPile = gameDeckBasics.discardPile
local drawPile = gameDeckBasics.drawPile
local hand = gameDeckBasics.hand
local hope = gameDeckBasics.hope
local mindset = gameDeckBasics.mindset

local kitchen
local morgan
local alex

local cupcakes = gameUi.styledBoxCard:extend({
  text = 'Total cupcakes',
  description =
    'The current recipe is for\n'
    .. 'cupcakes. Bake and\n'
    .. 'decorate, to prepare for\n'
    .. 'tomorrow’s bake sale.',
  value = 0,
  textColor = colors.cupcakes.foreground,
  borderColor = colors.cupcakes.foreground,
  getBoxColors = function (self)
    return colors.cupcakes
  end,
  getBoxValue = function (self)
    return self.value
  end,
})

local pendingCleanup = gameUi.styledBoxCard:extend({
  text = 'Pending cleanup',
  description =
    'Don’t forget to clean up\n'
    .. 'the kitchen. During baking\n'
    .. 'is less stressful than after\n'
    .. 'baking.',
  textColor = colors.cupcakes.foreground,
  borderColor = colors.cupcakes.foreground,
  getBoxColors = function (self)
    return colors.cupcakes
  end,
  getBoxValue = function (self)
    return kitchen:getCleanupCount()
  end,
})

local kitchenAction = gameUi.styledBoxCard:extend({
  isDone = false,
  isHidden = false,
  borderColor = colors.cupcakes.foreground,
  refresh = function (self)
    if (not morgan.isBusy or not alex.isBusy) and hope.value >= self.runCost then
      self.boxColors = colors.hope
      self.textColor = colors.cupcakes.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.runCost
  end,
  run = function (self)
    self.isDone = true
    if not self.isHidden then
      self.batch.active:remove(self)
    end
  end,
  getCleanupCost = function (self)
    if self.cleanupTrigger then
      if self.cleanupTrigger.isDone and not self.isDone then
        return self.runCost
      end
    end
    return 0
  end,
  getCleanupCount = function (self)
    local cost = self:getCleanupCost()
    if cost > 0 then
      return 1
    else
      return 0
    end
  end,
})

local screen

local function addBatchActions(batch, precedingActions)
  local function add(properties)
    local card = kitchenAction:extend(properties)
    card.batch = batch
    if not card.isHidden then
      table.insert(batch.actions, card)
    end
    return card
  end

  if not precedingActions then
    precedingActions = {}
  end

  batch.active = gameUi.styledColumn:extend({
    minHeight = gameUi.styledBoxCard.height * 3 + gameUi.styledColumn.margin * 2,
    cards = {},
  })
  batch.cards = {
    gameUi.styledSpacer:extend(),
    gameUi.styledHeading:extend({
      text = 'Batch #' .. batch.number,
      description =
        'Follow the recipe. Some\n'
        .. 'tasks are harder than\n'
        .. 'others. Morgan and Alex\n'
        .. 'are keen to start.',
    }),
    batch.active,
  }
  batch.actions = {}

  local measureDry = add({
    text = 'Measure dry',
    description =
      'Measure out the flours,\n'
      .. 'sugars, salts, spices, and\n'
      .. 'rising agents.',
    runCost = 1,
    depends = {},
  })
  local measureWet = add({
    text = 'Measure wet',
    description =
      'Measure out the milk and\n'
      .. 'oil. Don’t forget vanilla.',
    runCost = 1,
    depends = {},
  })
  local cleanCups = add({
    text = 'Clean measuring cups',
    description =
      'Responsibility means\n'
      .. 'cleaning up after making\n'
      .. 'a mess.',
    runCost = 2,
    cleanupTrigger = measureDry,
    depends = { measureDry, measureWet },
  })
  local mixAll = add({
    text = 'Mix together',
    description =
      'Sift to avoid packing. Pour\n'
      .. 'into the well. Mix only until\n'
      .. 'dry ingredients are\n'
      .. 'moistened. Basically done.',
    runCost = 2,
    depends = { measureDry, measureWet },
  })
  local pour = add({
    text = 'Pour batter',
    description =
      'Fill each cupcake liner\n'
      .. 'about three quarters full.\n'
      .. 'The journey is the\n'
      .. 'destination.',
    runCost = 4,
    depends = { mixAll },
  })
  local cleanBowl = add({
    text = 'Clean mixing bowl',
    description =
      'No matter how big the\n'
      .. 'problem.',
    runCost = 4,
    cleanupTrigger = mixAll,
    depends = { cleanCups, pour },
  })
  local cleanUtensils = add({
    text = 'Clean utensils',
    description =
      'But friends will always be\n'
      .. 'there to lend a hand.',
    runCost = 2,
    cleanupTrigger = measureDry,
    depends = { cleanBowl },
  })
  local bakeTimer = add({
    text = 'Bake timer',
    runCost = 3,
    depends = {},
    isHidden = true,
  })
  local burnt
  local putInOven = add({
    text = 'Put in oven',
    description =
      'In it goes. Hopefully the\n'
      .. 'portions are correct. Be\n'
      .. 'patient, and accept the\n'
      .. 'flow of time.',
    runCost = 6,
    depends = { pour, precedingActions.takeOut },
    run = function (self)
      kitchenAction.run(self)
      batch.activeTimer = function ()
        bakeTimer.runCost = bakeTimer.runCost - 1
        if bakeTimer.runCost == 0 then
          bakeTimer:run()
        elseif bakeTimer.runCost == -1 then
          batch.activeTimer = nil
          burnt()
        end
      end
    end,
  })
  local takeOut = add({
    text = 'Take out',
    description =
      'It’s done! But it does’t look\n'
      .. 'like cupcakes.',
    runCost = 4,
    depends = { bakeTimer },
    run = function (self)
      kitchenAction.run(self)
      batch.activeTimer = nil
    end
  })
  local cleanSheet = add({
    text = 'Clean baking sheet',
    description =
      'They’ll understand that\n'
      .. 'some messes are fun and\n'
      .. 'others are funny.',
    runCost = 1,
    cleanupTrigger = takeOut,
    depends = { cleanUtensils, takeOut },
  })
  local makeIcing = add({
    text = 'Make icing',
    description =
      'Very, very sweet. Use\n'
      .. 'all-natural food colouring.\n'
      .. 'The present self prepares\n'
      .. 'for the future self.',
    runCost = 6,
    depends = { mixAll },
  })
  local decorate = add({
    text = 'Decorate with icing',
    description =
      'Ah, the finishing touch. It’s\n'
      .. 'okay to get excited here\n'
      .. 'and just go wild. Show\n'
      .. 'them your free spirit!',
    runCost = 10,
    depends = { makeIcing, takeOut },
    run = function (self)
      kitchenAction.run(self)
      cupcakes.value = cupcakes.value + 12
      cupcakeScreen.screen:show(screen)
    end,
  })
  local cleanBag = add({
    text = 'Clean piping bag',
    description =
      'In the end, life itself is one\n'
      .. 'big series of messes.',
    runCost = 6,
    cleanupTrigger = makeIcing,
    depends = { cleanSheet, decorate },
  })
  function burnt()
    takeOut.isDone = true
    decorate.isDone = true
    batch.active:remove(takeOut)
    if not makeIcing.isDone then
      makeIcing.isDone = true
      batch.active:remove(makeIcing)
    else
      local extraCleanup = add({
        text = cleanBag.text,
        description = cleanBag.description,
        runCost = cleanBag.runCost,
        cleanupTrigger = cleanBag.cleanupTrigger,
        depends = cleanBag.depends,
      })
      cleanBag.depends = { extraCleanup }
    end
    cleanBag.text = 'Toss burnt cupcakes'
    cleanBag.description =
      'Sometimes things don’t go\n'
      .. 'as planned.'
    cleanBag.runCost = 2
    cleanBag.cleanupTrigger = putInOven
  end
  return function ()
    batch.startBatch({
      takeOut = takeOut,
    })
  end
end

local batch = gameUi.styledColumn:extend({
  activeTimer = nil,
  tick = function (self, remove)
    if self.activeTimer then
      self.activeTimer()
    end
    local newActions = {}
    for i, action in ipairs(self.actions) do
      if not action.isDone then
        local ready = true
        for j, depend in ipairs(action.depends) do
          if not depend.isDone then
            ready = false
            break
          end
        end
        if ready then
          self.active:insert(action)
        else
          table.insert(newActions, action)
        end
      end
    end
    self.actions = newActions
    if #self.actions == 0 and #self.active.cards == 0 then
      remove()
    end
  end,
  getCleanupCost = function (self)
    return utils.sum(self.active.cards, utils.method.getCleanupCost)
      + utils.sum(self.actions, utils.method.getCleanupCost)
  end,
  getCleanupCount = function (self)
    return utils.sum(self.active.cards, utils.method.getCleanupCount)
      + utils.sum(self.actions, utils.method.getCleanupCount)
  end,
})

kitchen = gameUi.styledColumn:extend({
  tick = function (self)
    local removals = {}
    local function remove(i)
      table.insert(removals, i, 1)
    end
    for i, batch in ipairs(self.cards) do
      batch:tick(function () remove(i) end)
    end
    for i, j in ipairs(removals) do
      table.remove(self.cards, j)
    end
  end,
  getCleanupCost = function (self)
    return utils.sum(self.cards, utils.method.getCleanupCost)
  end,
  getCleanupCount = function (self)
    return utils.sum(self.cards, utils.method.getCleanupCount)
  end,
  startBatch = function (self, number, ...)
    local newBatch = batch:extend({
      number = number,
      startBatch = function (...)
        if number < 2 then
          self:startBatch(number + 1, ...)
        end
      end,
    })
    local startNextBatch = addBatchActions(newBatch, ...)
    self:insert(newBatch)
    startNextBatch()
  end,
})

local playerCard = gameUi.styledBoxCard:extend({
  refresh = function (self)
    if self:isClickable() then
      self.textColor = colors.player.foreground
    else
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    if self.isBusy then
      return colors.playerDisabled
    else
      return colors.player
    end
  end,
  getBoxValue = function (self)
    return self.value
  end,
  clicked = function (self)
    ui.targeting:set({
      source = self,
      isTargetable = function (card)
        return card.runCost and hope.value >= card.runCost
      end,
      target = function (card)
        hope:pay(card.runCost)
        card:run()
        self.value = self.value + 1
        self.isBusy = true
        ui.targeting:reset()
      end,
    })
  end,
  isClickable = function (self)
    if not self.isBusy then
      for i, batch in ipairs(kitchen.cards) do
        for j, action in ipairs(batch.active.cards) do
          if hope.value >= action.runCost then
            return true
          end
        end
      end
    end
    return false
  end,
})

morgan = playerCard:extend({
  text = 'Morgan',
  description =
    'Enthusiastic, kind, caring,\n'
    .. 'and sensitive. Bullies call\n'
    .. 'him gay, but he’s more\n'
    .. 'worried about how other\n'
    .. 'kids are affected. Best\n'
    .. 'friend of Alex.',
})

alex = playerCard:extend({
  text = 'Alex',
  description =
    'Strong, brave, caring, and\n'
    .. 'insolent. Bullies call her\n'
    .. 'gay, and it reminds her to\n'
    .. 'stay proud and pissed off.\n'
    .. 'Best friend of Morgan.',
})

local function startTurn()
  hope.value = 0
  while #hand.cards > 0 do
    hand.cards[1]:moveToDiscard()
  end
  drawPile:drawMany(5)
  for i, card in ipairs(mindset.cards) do
    card.delay = false
  end
  morgan.isBusy = false
  alex.isBusy = false
  kitchen:tick()
end

local endTurn = gameUi.styledBoxCard:extend({
  text = 'End turn',
  description =
    'When there’s nothing left\n'
    .. 'to do, click to finish the\n'
    .. 'turn. Cards in hand will be\n'
    .. 'discarded and new ones\n'
    .. 'drawn.',
  clicked = function (self)
    if self.turnCounter == 0 then
      screen:showNext(
        cupcakes.value,
        math.min(
          cupcakes.value,
          kitchen:getCleanupCost()))
    else
      if self.turnCounter >= 9 then
        gameDeckCards.ennuiLibraryCard:take(1)
      else
        gameDeckCards.ennuiLibraryCard:take(2)
      end
      self.turnCounter = self.turnCounter - 1
      startTurn()
    end
  end,
  getBoxColors = function (self)
    return colors.time
  end,
  getBoxValue = function (self)
    return self.turnCounter
  end,
})

local kitchenMinutes = gameUi.styledBoxCard:extend({
  text = 'Kitchen minutes left',
  description =
    'The kitchen actually\n'
    .. 'belongs to Alex’s parents,\n'
    .. 'and they’re planning on\n'
    .. 'making dinner soon. Don’t\n'
    .. 'forget to clean up.',
  textColor = colors.time.foreground,
  getBoxColors = function (self)
    return colors.time
  end,
  getBoxValue = function (self)
    return endTurn.turnCounter * 5
  end,
})

local function hasInfo(card)
  return card.text and card.description
end

local infoBox = ui.rectangle:extend({
  title = nil,
  body = nil,
  font = 'big',
  borderColor = colors.text,
  color = colors.lightBackground,
  textColor = colors.text,
  highlightColor = colors.highlightColor,
  margin = gameUi.styledBoxCard.margin,
  width = gameUi.styledBoxCard.width,
  height = 315,
  paint = function (self)
    if ui.targeting:isSet() and ui.targeting:isSource(self) then
      rectangleEngine.paintPadded(
        self.highlightColor, self.left, self.top, self.width, self.height, 3)
    end
    rectangleEngine.paintPadded(
      self.borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      self.color, self.left, self.top, self.width, self.height)
    textEngine.paint(
      self.textColor,
      'bold',
      self.title,
      self.left + self.margin[1],
      self.top + self.margin[2])
    textEngine.paint(
      self.textColor,
      self.font,
      self.body,
      self.left + self.margin[1],
      self.top + self.margin[2] + 40)
  end,
  reset = function (self)
    self.title = 'Info box'
    self.body = 'Hover over a card to get\ndetailed info.'
  end,
  set = function (self, card)
    self.title = card.text
    self.body = card.description
  end,
})

local settingsButton = ui.card:extend({
  color = infoBox.color,
  borderColor = infoBox.borderColor,
  textColor = infoBox.textColor,
  width = infoBox.width,
  height = gameUi.styledBoxCard.height,
  margin = { 13, 12 },
  font = 'big',
  text = 'Settings',
  description = 'Configure the program.',
  clicked = function (self)
    settingsScreen.screen:show(screen)
  end,
})

local bakingColumn = gameUi.styledColumn:extend({
  left = 60,
  top = 60,
  cards = {
    cupcakes,
    pendingCleanup,
    gameUi.styledSpacerSymmetrical:extend(),
    morgan,
    alex,
    kitchen,
  }
})

local mainColumn = gameUi.styledColumn:extend({
  left = bakingColumn.left + gameUi.styledBoxCard.width + gameUi.columnSpacing,
  top = 60,
  cards = {
    discardPile,
    drawPile,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.handHeading,
    hand,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.mindsetHeading,
    mindset,
    gameUi.styledSpacerSymmetrical:extend(),
    endTurn,
    kitchenMinutes,
  }
})

local libraryColumn = gameUi.styledColumn:extend({
  left = mainColumn.left + gameUi.styledBoxCard.width + gameUi.columnSpacing,
  top = 60,
  cards = {
    hope,
    gameUi.styledSpacer:extend(),
    gameDeckBasics.libraryHeading,
    gameDeckCards.libraryColumn,
    gameUi.styledSpacerSymmetrical:extend(),
    infoBox,
    gameUi.styledSpacerSymmetrical:extend(),
    settingsButton,
  }
})

screen = ui.screen:extend({
  backgroundColor = colors.lightBackground,
  next = doneScreen.screen,
  shapes = { bakingColumn, mainColumn, libraryColumn },
  update = function (self, time)
    particleEngine.update(time)
    self:refresh()
  end,
  refresh = function (self)
    local mouseX, mouseY = resolutionEngine.getUnscaledMousePosition()
    ui.cursor:clear()
    infoBox:reset()
    for i, shape in ipairs(self.shapes) do
      shape:refresh()
      shape:checkHover(mouseX, mouseY, function (card)
        if card:isClickable() then
          ui.cursor:clickable()
        end
        if hasInfo(card) then
          infoBox:set(card)
        end
      end)
    end
  end,
  paint = function (self)
    particleEngine.paint()
    for i, shape in ipairs(self.shapes) do
      shape:paint()
    end
  end,
  mousepressed = function (self, x, y, button, istouch)
    self:refresh()
    local resetTargeting = ui.targeting:isSet()
    for i, shape in ipairs(self.shapes) do
      shape:mousepressed(x, y, button, istouch)
    end
    if resetTargeting and not ui.targeting.continue then
      ui.targeting:reset()
    end
    ui.targeting.continue = false
  end,
  start = function (self)
    particleEngine.reset()
    discardPile.cards = {
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.glimmerOfHope:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
      gameDeckCards.letItGo:extend(),
    }
    drawPile.cards = {}
    hand.cards = {}
    mindset.cards = {}
    kitchen.cards = {}
    bakingColumn:refresh()
    kitchen:startBatch(1)
    morgan.value = 0
    alex.value = 0
    cupcakes.value = 0
    endTurn.turnCounter = 18

    local seed = love.timer.getTime()
    print('seed', seed)
    math.randomseed(seed)
    mainColumn:refresh()
    drawPile:shuffle()
    startTurn()
  end,
})

return {
  screen = screen,
}
