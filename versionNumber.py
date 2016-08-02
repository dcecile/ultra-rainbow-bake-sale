#!/usr/bin/env python3
from pathlib import PurePath
import subprocess

def getProcessOutput(command):
  process = subprocess.run(
    command,
    stdout = subprocess.PIPE,
    universal_newlines = True,
    check = True)
  return process.stdout.strip()

def getVersionNumber():
  sourceDirectory = str(PurePath(__file__).parent)
  gitRevListCommand = (
    [ 'git', '-C', sourceDirectory, 'rev-list', '--count', 'HEAD'])
  buildNumber = int(getProcessOutput(gitRevListCommand)) - 1
  gitStatusCommand = (
    [ 'git', '-C', sourceDirectory, 'status', '--short'])
  modified = '+' if getProcessOutput(gitStatusCommand) else ''
  return '0.1.{0}{1}'.format(buildNumber, modified)

if __name__ == '__main__':
  print(getVersionNumber())
