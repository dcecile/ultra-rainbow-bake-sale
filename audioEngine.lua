local music = nil

local function startMusic()
  if not isMusicMuted then
    if not music then
      music = love.audio.newSource('bensound-anewbeginning.mp3')
      music:setVolume(0.3)
      music:setLooping(true)
    end
    love.audio.play(music)
  end
end

local function stopMusic()
  if music and music:isPlaying() then
    love.audio.stop(music)
  end
end

return {
  startMusic = startMusic,
  stopMusic = stopMusic,
}
