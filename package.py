#!/usr/bin/env python3
from pathlib import PurePath
from zipfile import ZipFile, ZIP_DEFLATED
import fnmatch
import functools
import glob
import itertools
import shutil
import versionNumber

def globAll(root, patterns):
  return itertools.chain.from_iterable(
    (glob.iglob(root + pattern) for pattern in patterns))

def zipLogger(method):
  @functools.wraps(method)
  def wrapper(name, *args, **kwds):
    print('Writing {0}'.format(name))
    method(name, *args, **kwds)
  return wrapper

def openCompressedZip(filename):
  zipFile = ZipFile(filename, mode = 'w', compression = ZIP_DEFLATED)
  zipFile.write = zipLogger(zipFile.write)
  zipFile.writestr = zipLogger(zipFile.writestr)
  return zipFile

def writeLocalFiles(zipFile, root, *patterns):
  for sourceName in globAll(root, patterns):
    zipFile.write(sourceName)

def buildVersionFile(version):
  return 'return {{ number = \'{0}\' }}'.format(version)

def writeLoveFile(basename, version):
  filename = '{0}.love'.format(basename)
  with openCompressedZip(filename) as gameLoveFile:
    writeLocalFiles(gameLoveFile, '', '*.lua', '*.txt', '*.mp3', '*.ttf')
    writeLocalFiles(gameLoveFile, 'lib/serpent/src/', '*.lua')
    gameLoveFile.writestr(
      'packagedVersionNumber.lua',
      buildVersionFile(version))
  print('Done {0}'.format(filename))

def buildExe(sourceFilename, sourceZipFile):
  sourceZipFilename = fnmatch.filter(sourceZipFile.namelist(), '*.exe')[0]
  gameExeFile = bytearray(sourceZipFile.read(sourceZipFilename))
  with open(sourceFilename, mode = 'rb') as sourceFile:
    gameExeFile.extend(sourceFile.read())
  return gameExeFile

def writeZippedFiles(destintationZipFile, sourceZipFile, pattern):
  for zippedFileName in fnmatch.filter(sourceZipFile.namelist(), pattern):
    destintationZipFile.writestr(
      PurePath(zippedFileName).name,
      sourceZipFile.read(zippedFileName))

def writeLoveMultiZipFile(basename):
  filename = '{0}-multi.zip'.format(basename)
  with openCompressedZip(filename) as gameZipFile:
    writeLocalFiles(gameZipFile, '', '*.love', '*.txt')
  print('Done {0}'.format(filename))

def writeLoveWin64ZipFile(basename):
  filename = '{0}-win64.zip'.format(basename)
  with openCompressedZip(filename) as gameZipFile:
    with ZipFile('love-win64.zip') as loveZipFile:
      gameZipFile.writestr(
        '{0}.exe'.format(basename),
        buildExe('{0}.love'.format(basename), loveZipFile))
      writeLocalFiles(gameZipFile, '', '*.txt')
      writeZippedFiles(gameZipFile, loveZipFile, '*.dll')
  print('Done {0}'.format(filename))

version = versionNumber.getVersionNumber()
writeLoveFile('ultra_rainbow_bake_sale', version)
writeLoveMultiZipFile('ultra_rainbow_bake_sale')
writeLoveWin64ZipFile('ultra_rainbow_bake_sale')
print('Built {0}'.format(version))
