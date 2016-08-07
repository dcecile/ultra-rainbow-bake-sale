# Ultra Rainbow Bake Sale

A singleplayer, deck-building, baking game (made with [LÖVE](http://love2d.org)).
What started originally as an idea for a [Sugar, Sweets, & Jam!](https://itch.io/jam/sugar-sweets-jam)
submission is now a playable alpha, with cards to acquire and use, and a baking system
to manage.

This GitHub page is for if you want to read or modify the game's source code, or take
a look at the the [open issues](https://github.com/dcecile/ultra-rainbow-bake-sale/issues).
If you just want to play the game, head over to its
[Itch.io homepage](https://dcecile.itch.io/ultra-rainbow-bake-sale), where it's available
for download on a pay-what-you-want basis.

## Getting started

### Prerequisites

This game's Git repository includes submodules. When first cloning the repository, use the
`--recursive` flag to make sure the submodules get initialized and updated properly.

The development environment requires Git, Python 3, and LÖVE.

The game also has a few binary dependencies, which need to be downloaded using the
[included](fetchDependencies.py) Python script:

```
./fetchDependencies.py
```

### Running

After setting those up,
you'll need to set a special debug environment variable and run `love` in your Git sandbox.
For example:

```
env DEBUG_URBS=1 love .
```

By running in debug mode, the game will skip the title screen, and will also calculate the
version number dynamically using Git.

### Packaging

To package the game, run the [included](package.py) Python script:

```
./package.py
```

This will zip up the binary dependencies and the Lua source files, together with a generated
version number, into a *.love* file. It also creates *.zip* files for multi-platform and
Windows 64-bit usage.

## Feedback

If you find any problems or you have a suggestion, I'd love to get an email or a GitHub issue
from you. You can email me at dancecile@gmail.com, and you can create GitHub issues
[online](https://github.com/dcecile/ultra-rainbow-bake-sale/issues/new).

I'm especially interested in getting feedback on the game concept, the game's usability, and
hearing about your personal experience playing the game.

I hope that I can use the feedback from the game's early players to help guide the development
of this basic alpha into compelling beta.

## License

This project is licensed under the MIT License. See the [license.txt](license.txt) file for details.
