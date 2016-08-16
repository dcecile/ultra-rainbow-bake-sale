local isActive = tonumber(os.getenv('DEBUG_URBS')) == 1

return {
  isActive = isActive,
}
