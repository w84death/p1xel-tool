# P1Xel Editor

## About
Sprite editor for my MS-DOS game. Made in Zig and Raylib.

### Features

- Linux and Windows under 400KB binary
- Pixelart 16x16 sprite/tile editor
- Dawbringer's 16 color palette
- custom 4 color palette per tile
- 128 custom palettes
- 128 tile per tileset
- save/load custom palettes
- save/load tileset

### Screenshots

![menu window](media/alpha2-menu.png)

![edit window](media/alpha2-edit.png)

![tileset window](media/alpha2-tileset.png)

## Run
```
zig build run
```

## Build Small Binary

Host Linux -> Linux.
```
zig build \
  -Doptimize=ReleaseSmall \
  upx
```

Host Linux -> Windows
``` 
zig build \
  -Dtarget=x86_64-windows \
  -Doptimize=ReleaseSmall \
  upx
```
