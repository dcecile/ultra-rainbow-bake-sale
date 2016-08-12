local cupcakeScreen = require('cupcakeScreen')
local gameKitchenBasics = require('gameKitchenBasics')
local gameUi = require('gameUi')

local batch = gameKitchenBasics.batch
local cupcakes = gameKitchenBasics.cupcakes
local kitchenAction = gameKitchenBasics.kitchenAction

local function make(number, precedingBatch)
  local newBatch = batch:extend({
    number = number,
  })

  newBatch.active = gameUi.styledColumn:extend({
    minHeight = gameUi.styledBoxCard.height * 2 + gameUi.styledColumn.margin * 1,
    cards = {},
  })
  newBatch.cards = {
    gameUi.styledSpacer:extend(),
    gameUi.styledHeading:extend({
      text = 'Cupcakes batch #' .. newBatch.number,
      description =
        'Follow the recipe by com-\n'
        .. 'pleting all of these tasks.\n'
        .. 'Some tasks are harder and\n'
        .. 'need more hope than\n'
        .. 'others.',
    }),
    newBatch.active,
  }
  newBatch.actions = {}

  local function add(properties)
    local card = kitchenAction:extend(properties)
    card.batch = newBatch
    if not card.isHidden then
      table.insert(newBatch.actions, card)
    end
    return card
  end

  local measureDry = add({
    text = 'Measure dry',
    description =
      'Morgan and Alex are keen\n'
      .. 'to start, but this task needs\n'
      .. '1 hope. Measure out the\n'
      .. 'flours, sugars, salts, spices,\n'
      .. 'and rising agents.',
    runCost = 1,
    depends = {},
  })
  local measureWet = add({
    text = 'Measure wet',
    description =
      'Morgan and Alex are keen\n'
      .. 'to start, but this task needs\n'
      .. '1 hope. Measure out the\n'
      .. 'milk and oil. Don’t forget\n'
      .. 'vanilla.',
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
    depends = { pour, (precedingBatch or {}).takeOut },
    run = function (self)
      kitchenAction.run(self)
      newBatch.activeTimer = function ()
        bakeTimer.runCost = bakeTimer.runCost - 1
        if bakeTimer.runCost == 0 then
          bakeTimer:run()
        elseif bakeTimer.runCost == -1 then
          newBatch.activeTimer = nil
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
      newBatch.activeTimer = nil
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
      cupcakeScreen.screen:show()
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
    newBatch.active:remove(takeOut)
    if not makeIcing.isDone then
      makeIcing.isDone = true
      newBatch.active:remove(makeIcing)
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

  newBatch.takeOut = takeOut

  return newBatch
end

return {
  make = make,
}
