#!/usr/bin/env python3
import shutil
import urllib.request

def downloadFile(source, destination):
  with open(destination, 'wb') as destinationFile:
    with urllib.request.urlopen(source) as http:
      print('Downloading {0}'.format(source))
      shutil.copyfileobj(http, destinationFile)

# LOVE
downloadFile(
    'https://bitbucket.org/rude/love/downloads/love-0.10.1-win64.zip',
    'love-win64.zip')

# Music
downloadFile(
    'http://www.bensound.com/royalty-free-music?download=anewbeginning',
    'bensound-anewbeginning.mp3')

# Fonts
downloadFile(
  'https://github.com/google/fonts/raw/master/apache/robotocondensed/RobotoCondensed-Regular.ttf',
  'RobotoCondensed-Regular.ttf')
downloadFile(
  'https://github.com/google/fonts/raw/master/apache/robotocondensed/RobotoCondensed-Light.ttf',
  'RobotoCondensed-Light.ttf')
