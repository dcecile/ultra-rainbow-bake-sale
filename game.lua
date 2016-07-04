local colors = require('colors')
local cupcakeScreen = require('cupcakeScreen')
local extraScreens = require('extraScreens')
local proto = require('proto')
local rectangleEngine = require('rectangleEngine')
local textEngine = require('textEngine')
local ui = require('ui')

local styledColumn = ui.column:extend({
  margin = 10
})

local boxCard = ui.card:extend({
  paint = function (self)
    local borderColor = self.borderColor
    local color = self.color
    local highlight = false

    if ui.targeting:isSet() then
      if ui.targeting:isSource(self) then
        highlight = true
        color = self.untargetableColor
      elseif ui.targeting:isSelected(self) then
        highlight = true
        borderColor = self.selectedBorderColor
      elseif not ui.targeting:isTargetable(self) then
        color = self.untargetableColor
      end
    end

    if highlight then
      rectangleEngine.paintPadded(
        self.highlightColor, self.left, self.top, self.width, self.height, 3)
    end

    rectangleEngine.paintPadded(
      borderColor, self.left, self.top, self.width, self.height, 1)
    rectangleEngine.paint(
      color, self.left, self.top, self.width, self.height)

    textEngine.paint(
      self.textColor,
      self.font,
      self.text,
      self.left + self.margin[1],
      self.top + self.margin[2])

    local boxColors = self:getBoxColors()
    local boxValue = self:getBoxValue()
    local boxWidth = 50
    local boxLeft = self.left + self.width - boxWidth
    rectangleEngine.paint(
      boxColors.background, boxLeft, self.top, boxWidth, self.height)
    rectangleEngine.paint(
      boxColors.foreground, boxLeft - 1, self.top, 1, self.height)
    local boxText = textEngine.getTextObject(self.font, tostring(boxValue))
    textEngine.paintTextObject(
      boxColors.foreground,
      boxText,
      math.floor(boxLeft + boxWidth / 2 - boxText:getWidth() / 2),
      self.top + self.margin[2])
  end,
})

local styledBoxCard = boxCard:extend({
  color = colors.card,
  borderColor = colors.text,
  textColor = colors.text,
  highlightColor = colors.highlightColor,
  selectedBorderColor = colors.selectedBorderColor,
  untargetableColor = colors.untargetableColor,
  width = 300,
  height = 50,
  margin = { 13, 12 },
  font = 'big',
})

local styledSpacer = ui.spacer:extend({
  width = styledBoxCard.width,
  margin = { 20, 6, 1 },
  color = colors.spacer,
})

local styledSpacerSymmetrical = styledSpacer:extend({
  margin = { styledSpacer.margin[1], styledSpacer.margin[2], styledSpacer.margin[2] },
})

local styledHeading = ui.heading:extend({
  height = 20,
  width = styledBoxCard.width,
  color = colors.heading,
  font = 'small',
})

local styledPile = styledBoxCard:extend({
  remove = ui.column.remove,
  insert = ui.column.insert,
  textColor = colors.cardPile.foreground,
  borderColor = colors.cardPile.foreground,
  getBoxColors = function (self)
    return colors.cardPile
  end,
  getBoxValue = function (self)
    return #self.cards
  end,
})

local discardPile = styledPile:extend({
  text = 'Discard pile',
  description =
    'Used and acquired cards\n'
    .. 'go here.',
})

local drawPile = styledPile:extend({
  text = 'Draw pile',
  description =
    'These are the cards that\n'
    .. 'will be drawn next. When\n'
    .. 'empty, the discard pile is\n'
    .. 'taken and shuffled.',
  shuffle = function (self)
    local newCards = {}
    while #self.cards > 0 do
      local nextIndex = math.random(#self.cards)
      local nextCard = table.remove(self.cards, nextIndex)
      table.insert(newCards, nextCard)
    end
    self.cards = newCards
  end,
  drawMany = function (self, drawCards)
    for i = 1, drawCards do
      if #self.cards > 0 then
        self.cards[1]:moveToHand()
      elseif #discardPile.cards > 0 then
        while #discardPile.cards > 0 do
          discardPile.cards[1]:moveToDraw()
        end
        self:shuffle()
        self.cards[1]:moveToHand()
      end
    end
  end,
  cards = {},
})

local styledDeckCardColumn = styledColumn:extend({
  cards = {},
  minHeight = styledBoxCard.height * 5 + styledColumn.margin * 4,
  maxCards = 5,
  tryDiscard = function (self, number, source, block)
    if number <= 0 then
      block()
    else
      ui.targeting:set({
        source = source,
        isTargetable = function (card)
          return card.column == self and card ~= source
        end,
        target = function (card)
          ui.targeting:toggleSelected(card)
          if #ui.targeting.selected == number then
            for i, selectedCard in ipairs(ui.targeting.selected) do
              selectedCard:moveToDiscard()
            end
            ui.targeting:reset()
            block()
          else
            ui.targeting.continue = true
          end
        end,
      })
    end
  end,
  tryDiscardToMax = function (self, modifier, source, block)
    self:tryDiscard(#self.cards + modifier - self.maxCards, source, block)
  end,
})

local handHeading = styledHeading:extend({
  text = 'Hand',
  description =
    'Current thoughts, feelings,\n'
    .. 'and ideas ready for action.\n'
    .. 'Click a card to pay hope\n'
    .. 'and use.',
})

local hand = styledDeckCardColumn:extend()

local mindsetHeading = styledHeading:extend({
  text = 'Mindset',
  description =
    'Persistent philosophies\n'
    .. 'and paradigms. Click a\n'
    .. 'card to pay hope and use.\n'
    .. 'New mindsets need one\n'
    .. 'turn to get established.',
})

local mindset = styledDeckCardColumn:extend()

local hope = styledBoxCard:extend({
  text = 'Hope',
  description =
    'Build up and find hope.\n'
    .. 'Use it to do good things,\n'
    .. 'or just things.',
  value = 0,
  add = function (self, value)
    self.value = self.value + value
  end,
  pay = function (self, cost)
    self.value = self.value - cost
  end,
  tryPay = function (self, cost, block)
    if self.value >= cost then
      self.value = self.value - cost
      block()
    end
  end,
  borderColor = colors.hope.foreground,
  textColor = colors.hope.foreground,
  getBoxColors = function (self)
    return colors.hope
  end,
  getBoxValue = function (self)
    return self.value
  end,
})

local cupcakes = styledBoxCard:extend({
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

local kitchen
local morgan
local alex

local kitchenAction = styledBoxCard:extend({
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
      kitchen:remove(self)
    end
  end,
})

local start = kitchenAction:extend({
  text = 'Start',
  description =
    'They say that the first\n'
    .. 'step is always the hardest.',
  runCost = 4,
  depends = {},
  takeOut = nil,
  decorate = nil,
  run = function (self)
    local function add(properties)
      local card = kitchenAction:extend(properties)
      if not card.isHidden then
        table.insert(kitchen.actions, card)
      end
      return card
    end
    local measureDry = add({
      text = 'Measure dry',
      description =
        'Measure out the flours,\n'
        .. 'sugars, salts, spices, and\n'
        .. 'rising agents.',
      runCost = 1,
      depends = { self },
    })
    local measureWet = add({
      text = 'Measure wet',
      description =
        'Measure out the milk and\n'
        .. 'oil. Don’t forget vanilla.',
      runCost = 1,
      depends = { measureDry },
    })
    local mixDry = add({
      text = 'Mix dry',
      description =
        'Sift to avoid packing. Mix\n'
        .. 'well. The fun is getting\n'
        .. 'started.',
      runCost = 1,
      depends = { measureDry },
    })

    local mixAll = add({
      text = 'Mix together',
      description =
        'Pour into the well. Mix only\n'
        .. 'until dry ingredients are\n'
        .. 'moistened. Basically done.',
      runCost = 2,
      depends = { mixDry, measureWet },
    })
    local pour = add({
      text = 'Pour batter',
      description =
        'Fill each cupcake liner\n'
        .. 'about three quarters full.\n'
        .. 'The journey is the\n'
        .. 'destination.',
      runCost = 4,
      depends = { mixAll, self.takeOut },
    })
    local bakeTimer = add({
      text = 'Bake timer',
      runCost = 4,
      depends = {},
      isHidden = true,
    })
    local putInOven = add({
      text = 'Put in oven',
      description =
        'In it goes. Hopefully the\n'
        .. 'portions are correct. Be\n'
        .. 'patient, and accept the\n'
        .. 'flow of time.',
      runCost = 6,
      depends = { pour },
      run = function (self)
        kitchenAction.run(self)
        kitchen.activeTimer = function ()
          bakeTimer.runCost = bakeTimer.runCost - 1
          if bakeTimer.runCost == 0 then
            bakeTimer:run()
            kitchen.activeTimer = nil
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
      depends = { makeIcing, takeOut, self.decorate },
      run = function (self)
        kitchenAction.run(self)
        cupcakes.value = cupcakes.value + 12
        currentScreen = cupcakeScreen.screen
      end,
    })
    local nextGatherIngedients = add({
      text = self.text,
      description = self.description,
      runCost = self.runCost,
      depends = { makeIcing },
      takeOut = takeOut,
      decorate = decorate,
      run = self.run,
    })
    kitchenAction.run(self)
  end,
})

local kitchenHeading = styledHeading:extend({
  text = 'Kitchen',
  description =
    'Follow the recipe. Some\n'
    .. 'tasks are harder than\n'
    .. 'others. Morgan and Alex\n'
    .. 'are keen to start.',
})

kitchen = styledColumn:extend({
  activeTimer = nil,
  tick = function (self)
    if self.activeTimer then
      self.activeTimer()
    end
    local newActions = {}
    for i, action in ipairs(kitchen.actions) do
      local ready = true
      for j, depend in ipairs(action.depends) do
        if not depend.isDone then
          ready = false
          break
        end
      end
      if ready then
        kitchen:insert(action)
      else
        table.insert(newActions, action)
      end
    end
    self.actions = newActions
  end,
})

local playerCard = styledBoxCard:extend({
  value = 0,
  isBusy = false,
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
      for i, card in ipairs(kitchen.cards) do
        if hope.value >= card.runCost then
          return true
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

local libraryHeading = styledHeading:extend({
  text = 'Library',
  description =
    'New techniques to learn\n'
    .. 'and try out. Click a card\n'
    .. 'to pay hope and aquire.',
})

local libraryCard = styledBoxCard:extend({
  clicked = function (self)
    hope:tryPay(self.card.buyCost, function ()
      local newCard = self.card:extend()
      discardPile:insert(newCard)
    end)
  end,
  make = function (self, card)
    return self:extend({
      card = card,
      text = card.text,
      description = card.description,
    })
  end,
  refresh = function (self)
    if self:isClickable() then
      self.boxColors = colors.hope
      self.textColor = colors.hope.foreground
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  isClickable = function (self)
    return hope.value >= self.card.buyCost
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.card.buyCost
  end,
})

local deckCard = styledBoxCard:extend({
  column = discardPile,
  clicked = function (self)
    local cost = self.cost
    if self:isClickable() then
      self:action(function ()
        hope:pay(cost)
      end)
    end
  end,
  isClickable = function (self)
    return self.action
      and not self.delay
      and hope.value >= self.cost
  end,
  moveToDraw = function (self)
    self.column:remove(self)
    drawPile:insert(self)
    self.column = drawPile
    self.action = nil
    self.cost = nil
    self.delay = false
  end,
  moveToHand = function (self)
    self.column:remove(self)
    hand:insert(self)
    self.column = hand
    self.action = self.play
    self.cost = self.playCost
    self.delay = false
  end,
  tryMoveToMindset = function (self, block)
    mindset:tryDiscardToMax(1, self, function ()
      self.column:remove(self)
      mindset:insert(self)
      self.column = mindset
      self.action = self.activate
      self.cost = self.activateCost
      self.delay = true
      block()
    end)
  end,
  moveToDiscard = function (self)
    self.column:remove(self)
    discardPile:insert(self)
    self.column = discardPile
    self.action = nil
    self.cost = nil
    self.delay = false
  end,
  remove = function (self)
    self.column:remove(self)
  end,
  refresh = function (self)
    if self.cost and hope.value >= self.cost and not self.delay then
      self.boxColors = colors.hope
      self.textColor = colors.text
    else
      self.boxColors = colors.hopeDisabled
      self.textColor = colors.disabledText
    end
  end,
  getBoxColors = function (self)
    return self.boxColors
  end,
  getBoxValue = function (self)
    return self.cost
  end,
})

local hopeFeeling = deckCard:extend({
  playCost = 0,
  play = function (self, pay)
    hope:add(self.buyCost)
    self:moveToDiscard()
    pay()
  end,
})

local glimmerOfHope = hopeFeeling:extend({
  text = 'Glimmer of hope',
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 1 hope.',
  buyCost = 1,
})

local feelingOfHope = hopeFeeling:extend({
  text = 'Feeling of hope',
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 2 hope.',
  buyCost = 2,
})

local visionOfHope = hopeFeeling:extend({
  text = 'Vision of hope',
  description =
    'Fundamental source of\n'
    .. 'hope. Play and discard\n'
    .. 'to gain 4 hope.',
  buyCost = 4,
})

local hopeMindset = deckCard:extend({
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    hope:add(self.playCost)
    self.delay = true
    pay()
  end,
})

local youreNotAlone = hopeMindset:extend({
  text = 'You’re not alone',
  description =
    'Continual source of hope.\n'
    .. 'Play this mindset, then\n'
    .. 'activate to gain 1 hope.',
  buyCost = 1,
  playCost = 1,
})

local itGetsBetter = hopeMindset:extend({
  text = 'It gets better',
  description =
    'Continual source of hope.\n'
    .. 'Play this mindset, then\n'
    .. 'activate to gain 4 hope.',
  buyCost = 4,
  playCost = 4,
})

local ennui = deckCard:extend({
  text = 'Ennui',
  description =
    'Boredom. Enervation.\n'
    .. 'Un-motivation. Fatigue.\n'
    .. 'Cannot be played.',
  playCost = math.huge,
  getBoxValue = function (self)
    return '∞'
  end,
})

local curiosity = deckCard:extend({
  play = function (self, pay)
    local cardsToDraw = math.min(
      self.playCost + 1,
      #drawPile.cards + #discardPile.cards)
    hand:tryDiscardToMax(cardsToDraw - 1, self, function ()
      drawPile:drawMany(cardsToDraw)
      self:moveToDiscard()
      pay()
    end)
  end,
})

local mildCuriosity = curiosity:extend({
  text = 'Mild curiosity',
  description =
    'Don’t be afraid of the\n'
    .. 'unknown. Play and discard\n'
    .. 'to draw 2 cards.',
  buyCost = 1,
  playCost = 1,
})

local intenseCuriosity = curiosity:extend({
  text = 'Intense curiosity',
  description =
    'Don’t be afraid of the\n'
    .. 'unknown. Play and discard\n'
    .. 'to draw 4 cards.',
  buyCost = 3,
  playCost = 3,
})

local letItGo = deckCard:extend({
  text = 'Let it go',
  description =
    'Be present. Let go. Play\n'
    .. 'this mindset, then activate\n'
    .. 'and discard. Return one\n'
    .. 'card to the library, and\n'
    .. 'draw a new card.',
  buyCost = 1,
  playCost = 1,
  activateCost = 0,
  play = function (self, pay)
    self:tryMoveToMindset(function ()
      pay()
    end)
  end,
  activate = function (self, pay)
    ui.targeting:set({
      source = self,
      isTargetable = function (card)
        return card.column == hand
      end,
      target = function (card)
        card:remove()
        drawPile:drawMany(1)
        self:moveToDiscard()
        ui.targeting:reset()
        pay()
      end,
    })
  end,
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

local endTurn = styledBoxCard:extend({
  text = 'End turn',
  description =
    'When there’s nothing left\n'
    .. 'to do, click to finish the\n'
    .. 'turn. Cards in hand will be\n'
    .. 'discarded and new ones\n'
    .. 'drawn.',
  clicked = function (self)
    if self.turnCounter == 0 then
      extraScreens.doneScreen.totalCupcakes = cupcakes.value
      currentScreen = extraScreens.doneScreen
    else
      self.turnCounter = self.turnCounter - 1
      discardPile:insert(ennui:extend())
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

local kitchenMinutes = styledBoxCard:extend({
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
  margin = styledBoxCard.margin,
  width = styledBoxCard.width,
  height = 320,
  refresh = function (self)
    self.left = cupcakes.left
    self.top = kitchenMinutes.top + kitchenMinutes.height - self.height
  end,
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

local bakingColumn = styledColumn:extend({
  left = 60,
  top = 60,
  cards = {
    cupcakes,
    styledSpacerSymmetrical:extend(),
    morgan,
    alex,
    styledSpacer:extend(),
    kitchenHeading,
    kitchen,
  }
})

local mainColumn = styledColumn:extend({
  left = bakingColumn.left + styledBoxCard.width + 70,
  top = 60,
  cards = {
    discardPile,
    drawPile,
    styledSpacer:extend(),
    handHeading,
    hand,
    styledSpacer:extend(),
    mindsetHeading,
    mindset,
    styledSpacerSymmetrical:extend(),
    endTurn,
    kitchenMinutes,
  }
})

local libraryColumn = styledColumn:extend({
  left = mainColumn.left + styledBoxCard.width + 70,
  top = 60,
  cards = {
    hope,
    styledSpacer:extend(),
    libraryHeading,
    libraryCard:make(feelingOfHope),
    libraryCard:make(visionOfHope),
    libraryCard:make(mildCuriosity),
    libraryCard:make(intenseCuriosity),
    libraryCard:make(youreNotAlone),
    libraryCard:make(itGetsBetter),
  }
})

local screen = {
  color = colors.lightBackground,
  shapes = { bakingColumn, mainColumn, libraryColumn, infoBox },
  refresh = function (self)
    local mouseX, mouseY = love.mouse.getPosition()
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
    self:refresh()
    love.graphics.setBackgroundColor(self.color)
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
    discardPile.cards = {
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      glimmerOfHope:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
      letItGo:extend(),
    }
    drawPile.cards = {}
    hand.cards = {}
    mindset.cards = {}
    kitchen.cards = { start:extend() }
    kitchen.actions = {}
    cupcakes.value = 0
    endTurn.turnCounter = 18

    local seed = love.timer.getTime()
    print('seed', seed)
    math.randomseed(seed)
    self:refresh()
    drawPile:shuffle()
    startTurn()
  end,
}

cupcakeScreen.screen.gameScreen = screen

return {
  screen = screen
}
