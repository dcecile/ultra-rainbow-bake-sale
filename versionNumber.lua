local debugMode = require('debugMode')

local number

if debugMode.isActive then
  local sourceDirectory = love.filesystem.getRealDirectory('versionNumber.py')
  local pythonCommand = sourceDirectory .. '/versionNumber.py'
  local pythonFile = io.popen(pythonCommand)
  number = pythonFile:read()
  if not number or not number:find('^%d+%.%d+.%d+%+?$') then
    error(string.format('invalid version %q', tostring(number)))
  end
  pythonFile:close()
else
  local packagedVersionNumber = require('packagedVersionNumber')
  number = packagedVersionNumber.number
end

return {
  number = number,
}
