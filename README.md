# Zig Raylib Tetris

Minimal but fully playable Tetris written in Zig with Raylib.

## Requirements

- Zig (0.15.x recommended)
- Raylib installed on your system (`raylib` available to the linker)

## Run

```bash
zig build run
```

## Controls

### Menu
- `Up` / `Down`: move selection
- `Enter`: confirm

### In game
- `A` / `Left`: move left
- `D` / `Right`: move right
- `W` / `Up`: rotate
- `S` / `Down`: soft drop
- `Space`: hard drop
- `R`: restart run
- `P`: pause/resume
- `M`: return to main menu

## Features

- Main menu + score screen
- 10x20 board with all 7 tetrominoes
- Gravity + soft/hard drop
- Rotation with simple wall-kick offsets
- Line clear scoring and level-based speed increase
- Line-clear flash animation before row removal
- Persistent local scores saved to `scores.txt` in the project folder
