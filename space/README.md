# A Nameless 3D Polygonal Software Renderer & Rasterizer

**Copyright (c) 2025-2026 Joe King**  
Licensed under the MIT License.  
*See [LICENSE](../LICENSE) file or https://opensource.org/licenses/MIT for details.*

>"It's six degrees of raw freedom!"  
> — *Jimmy, 34 (Grand Rivers, KY)*

## Recommended build:

    fbc64 main.bas -w all -gen gcc -O 3 -Wc -march=native

## Controls

| Key          | Description                                                       |
|--------------|-------------------------------------------------------------------|
| Number Row 1 | Enter [**Free Fly Mode**](#free-fly-mode)                         |
| Number Row 2 | Enter [**Spaceship Chase View Mode**](#spaceship-chase-view-mode) |
| Number Row 3 | Enter [**Random Camera View Mode**](#random-camera-view-mode)     |
| ESC          | End Program                                                       |
| F1           | Toggle debug Info                                                 |
| F2           | Toggle solid polygon render mode                                  |
| F3           | Toggle/cycle wireframe modes                                      |
| F4           | Toggle orientation-only view for objects                          |
| F5           | Toggle between affine and perspective-correct texture mapping     |

## Free Fly Mode

| Key          | Description                                            |
|--------------|--------------------------------------------------------|
| Arrow keys   | Look (pitch and yaw)                                   |
| Q,E          | Roll left, roll right                                  |
| W,S,A,D      | Move forward, move backward, strafe-left, strafe-right |
| SPACE/LSHIFT | Move up, move down                                     |
| Left mouse   | Hold and move mouse to look around (pitch and yaw)     |
| Right mouse  | Hold and move mouse to look around (pitch and roll)    |

## Spaceship Chase View Mode

| Key          | Description                                               |
|--------------|-----------------------------------------------------------|
| Arrow keys   | Turn (pitch and yaw)                                      |
| Q,E          | Roll left, roll right                                     |
| W,S,A,D      | Speed up, slow down or reverse, strafe left, strafe right |
| SPACE/LSHIFT | Hover up, hover down                                      |
| TAB          | Cycle between different chase views                       |

## Random Camera View Mode

| Key          | Description                               |
|--------------|-------------------------------------------|
| TAB          | Cycle target object                       |
| Left mouse   | Hold and move mouse to control view angle |
| Mouse wheel  | Zoom in/out                               |
| Number Row 3 | Reset view                                |
