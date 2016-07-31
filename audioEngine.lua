local music = nil

local musicVolume = 0.3

local function startMusic()
  if not music then
    music = love.audio.newSource('bensound-anewbeginning.mp3')
    music:setVolume(musicVolume)
    music:setLooping(true)
  end
  love.audio.play(music)
end

local function stopMusic()
  if music and music:isPlaying() then
    love.audio.stop(music)
  end
end

local function getMusicIsOn()
  return musicVolume > 0
end

local function setMusicIsOn(on)
  if on then
    musicVolume = 0.3
  else
    musicVolume = 0
  end
  if music then
    print('setMusicIsOn', musicVolume)
    music:setVolume(musicVolume)
  end
end

return {
  startMusic = startMusic,
  stopMusic = stopMusic,
  getMusicIsOn = getMusicIsOn,
  setMusicIsOn = setMusicIsOn,
}
