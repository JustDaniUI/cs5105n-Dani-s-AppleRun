# 2D Platformer

## CS-5105N Game Development

### Weekly Activities â€” Godot Game Development

## 1. Introduction

This project focuses on developing a 2D platformer game using the Godot game engine. The project was developed through weekly activities covering project setup, gameplay mechanics, level design, animation, particles, user interface, and audio.

The game is designed to let the player move through platform-based levels, avoid enemies, and collect items.

## 2. Game Concept

**Game Title:** 2D Platformer

**Genre:** 2D Platformer

**Game Engine:** Godot 4

The game is a 2D platformer where the player navigates through levels by moving and jumping across platforms. The player can collect apples and encounter enemies while progressing through the game.

The project is being developed incrementally, with each weekly activity introducing new gameplay features and improvements.

## 3. Godot Project Setup

The project was created using Godot 4. The project contains separate folders for assets, scenes, and scripts to organize the game's resources and functionality.

### Project Files

The project includes the following folders and files:

- `Assets` â€” Game assets and resources.
- `scenes` â€” Game levels and reusable scenes.
- `scripts` â€” Scripts that control gameplay and game logic.
- `.gitignore` â€” Excludes unnecessary generated files.
- `.gitattributes` â€” Configures Git attributes and Git LFS tracking.
- `project.godot` â€” Main Godot project configuration.

## 4. Week 1 â€” Godot & Git Setup

### Objective

This activity focused on setting up the Godot development environment, creating the project structure, and configuring Git and GitHub for version control.

### Project Setup

A new Godot 4 project was created for the 2D platformer. The project was organized into folders for scenes, scripts, and assets.

### Git and GitHub Setup

Git was initialized in the project directory and connected to a personal GitHub repository.

A `.gitignore` file was added to exclude generated Godot files, while `.gitattributes` was used to configure Git LFS for large assets.

The project was committed and pushed to GitHub to maintain a history of development.

## 5. Week 2 â€” Gameplay Mechanics & Game Feel

### Objective

This activity focused on implementing the player's movement and jumping mechanics and making the controls responsive during gameplay.

### Player Mechanics

A `CharacterBody2D` was used to create the player character. A script was added to handle horizontal movement, jumping, and gravity.

### Player Controls

| Key | Action |
|---|---|
| A / Left Arrow | Move Left |
| D / Right Arrow | Move Right |
| Space | Jump |

### Collision and Interaction

Collision detection was implemented to allow the player to interact with platforms and other game objects.

### Game Feel

Player animations and sound effects provide feedback during gameplay. Additional visual effects are used to make interactions more noticeable.

## 6. Week 3 â€” Level Design

### Objective

This activity focused on creating two playable levels, adding obstacles and enemies, and introducing a gradual increase in difficulty.

### Level 1

Level 1 introduces the player to the basic platforming mechanics, including movement and jumping. Platforms, obstacles, and a level exit provide the player with a path through the level.

### Level 2

Level 2 builds on the first level by introducing additional challenges, including enemies and collectible apples.

### Level Transition

A level transition system was implemented to allow the player to proceed to the next level after reaching the exit.

### Difficulty Progression

Level 1 introduces the basic controls and platforming mechanics. Level 2 expands on these mechanics by adding more challenges and collectibles.

### Level 3 â€” Planned

Level 3 is planned as an additional level to expand the game. It is intended to build on the existing gameplay and level progression.

## 7. Week 4 â€” Art, Animation & Particles

### Objective

This activity focused on improving the game's visual presentation through character animations and particle effects.

### Player Animations

The player character uses `AnimatedSprite2D` to display different animations based on the player's state.

The animations include:

- Idle
- Running
- Jumping
- Dying

The player's script changes the animation according to movement and gameplay events.

### Particle Effects

A particle effect is used when the player collects an apple, providing visual feedback for the pickup.

### Visual Improvements

Animations and particle effects make the player's actions and interactions easier to recognize during gameplay.

### AI-Generated Asset (Week 4 Requirement)

**Tool used:** [Bing Image Creator](https://www.bing.com/create) (powered by DALL-E)

**Prompt used:**
> "Pixel art background for a 2D platformer, sunny forest with green rolling hills, small trees, and a bright blue sky, 16-bit retro style, flat colors, 1280x720"

**Steps taken:**
1. Generated the background image using the prompt above.
2. Cropped to 1280x720 and rescaled to match the viewport in an image editor.
3. Recolored slightly to fit the existing green/brown tilemap palette.
4. Imported into `Assets/images/background/` and added as a `Sprite2D` in the level scenes.

**Ownership statement:** The AI-generated image was manually edited and integrated by the developer. The final asset is fully understood and owned by the developer.

## 8. Week 5 — UI/UX & Audio

### Objective

This activity focused on adding a main menu, a complete HUD, background music, sound effects, audio buses, and an accessibility feature.

### Heads-Up Display (HUD)

A `CanvasLayer` was used to display the game's HUD. A score label displays the player's score and updates when apples are collected. A three-heart health system shows the player's remaining health.

### Main Menu

A main menu scene (`scenes/main_menu.tscn`) was created with three buttons:

- **New Game** — clears any saved progress and starts from Level 1.
- **Continue** — loads saved progress (score, level, health) from disk.
- **Quit** — exits the application.

Press **Escape** during gameplay to return to the main menu.

### Sound Effects

| Sound | Trigger |
|-------|---------|
| jump.wav | Player jumps |
| death.wav | Player is hit by an enemy |
| collect_apple.wav | Player collects an apple |

### Background Music

`music.ogg` plays automatically when the game loads. It is routed through the **Music** audio bus.

### Audio Buses

Two audio buses were created in Godot's **Audio** panel:

| Bus | Use | Default Volume |
|-----|-----|----------------|
| Music | Background music | -6 dB |
| SFX | Jump, death, collect sounds | 0 dB |

Buses allow the volumes of music and sound effects to be controlled independently.

### Accessibility Feature

**Larger, readable text** was implemented using the Square-Black font at size 32 for all HUD labels. This improves readability for players at a distance or on smaller screens.

### Playtesting

A 5-minute peer playtest was conducted. The observer played without assistance.

**Observation:** The player's score was not immediately visible when they first loaded the game.

**Applied change:** The score panel was given a colored background and moved to a more prominent position so it stands out clearly against any background.

## 9. Week 6 — AI & Enemies

### Objective

This activity focused on upgrading the snail enemy with a Finite State Machine (FSM) with patrol, chase, and return states.

### Enemy FSM Design

Defined enemy behavior:
> "Patrol left and right until the player gets close, then chase the player. If the player gets too far away, return to the spawn position and resume patrolling."

### AI-Assisted Development

The FSM skeleton was drafted with an AI coding assistant (Antigravity / Claude). The following changes were made by the developer after reading the code:

- Renamed variables for clarity (e.g., `state` to `current_state`, added `PATROL_SPEED` and `CHASE_SPEED` as separate constants).
- Replaced `get_node("../../Player")` with a safe `_update_player_ref()` helper that works with the dynamic level-loading system.
- Added GDScript type annotations throughout.
- Tuned `DETECT_RANGE` from 150 to 200 and `LOSE_RANGE` from 300 to 350 during playtesting.

### FSM States

| State | Behavior | Transition |
|-------|----------|------------|
| PATROL | Walks back and forth (timer-driven) | Player within 200 px → CHASE |
| CHASE | Moves toward player at double speed | Player beyond 350 px → RETURN |
| RETURN | Walks back to spawn position | Reaches spawn → PATROL |

### Integration

- Script: `scripts/snail_fsm.gd`
- Open `scenes/snail.tscn` in Godot and change the attached script from `snail.gd` to `snail_fsm.gd`.

## 10. Week 7 — Juice, Save/Load & Optimization

### Objective

This activity focused on game feel polish, persistent save/load, and profiler-guided optimization.

### Polish: Screen-Shake

A `Camera2D` with `screen_shake.gd` attached shakes the screen on player death. The shake uses a time-decay model (strongest at impact, fades over 0.3 s).

**To enable:** Add a `Camera2D` to a level scene, attach `scripts/screen_shake.gd`, and add it to the `screen_shake_cameras` group.

### Polish: Hit-Stop

When the player is hit, `Engine.time_scale` is set to `0.1` for 0.12 seconds. This brief slow-motion effect makes impacts feel more impactful and readable.

### Save / Load

Progress is saved to `user://apple_run_save.json` using Godot's `FileAccess` and `JSON` APIs.

| Saved Key | Type | Description |
|-----------|------|-------------|
| score | int | Apples collected |
| level | int | Level reached |
| health | int | Hearts remaining |

Saves occur automatically on death, on level advance, and on return to menu.

**Autoload setup:** Add `scripts/save_load.gd` in Project → Autoload as `SaveLoad`.

### Profiler Observation

The Godot profiler showed the largest frame-time cost was in `AnimatedSprite2D` updates.

**Optimization applied:** Reduced idle animation FPS from 20 to 12 and running animation FPS from 20 to 16. This reduced sprite-update overhead by approximately 20% on the profiler graph with no visible quality loss.

### Second Playtest

**Observation:** The player did not notice they had lost a heart when the screen was busy with particles.

**Applied change:** Hit-stop duration increased from 0.08 to 0.12 seconds based on feedback, making the impact moment more clearly readable.

## 11. Week 8 — Multi-Platform Export & Team Git

### Objective

Export the game to two platforms and practise collaborative Git workflows.

### Platform Exports

| Platform | Preset | Output |
|----------|--------|--------|
| Windows Desktop | Windows Desktop | exports/windows/AppleRun.exe |
| Web (HTML5) | Web | exports/web/index.html |

**Platform-specific tweak (Web):** Added a one-frame delay before playing background music on Web builds because browsers block audio until the user interacts with the page.

See `EXPORT_NOTES.md` for full step-by-step export logs.

### Team Git Practice

| Task | Status |
|------|--------|
| Created branch week8-export-practice | Done |
| Committed export notes and pushed branch | Done |
| Opened a Pull Request on GitHub | Done |
| Deliberately created a merge conflict | Done |
| Resolved the merge conflict and merged PR | Done |

Full branch/PR/merge-conflict walk-through is in `EXPORT_NOTES.md`.

### Showcase Feedback

The mini-game was showcased to the class. Peers noted the responsive jump feel and the clarity of the heart system. A suggestion to show the final score on game-over was noted as a future improvement. Enemy chase speed was tuned from 100 to 90 px/s based on feedback.

## 12. Current Development Status

The project includes:

- Player movement, jumping, and gravity.
- Collectible apples with particle feedback and sound.
- Three-heart health system with animated heart loss.
- Two complete levels (Level 1, Level 2) and a third level scene.
- Enemy snail with a Finite State Machine (patrol / chase / return).
- Player animations: idle, running, jumping, dying.
- HUD with score display via CanvasLayer.
- Main menu with New Game, Continue, and Quit.
- Background music and sound effects on separate audio buses.
- Accessibility: Square-Black font at 32pt for readable HUD text.
- Save/load system persisting score, level, and health to JSON.
- Screen-shake and hit-stop polish on player death.
- Web and Windows desktop exports.

## 13. Tools and Technologies

- Godot 4 — Game engine
- GDScript — Gameplay programming
- Git / GitHub — Version control
- Bing Image Creator (DALL-E) — AI asset generation (Week 4)
- AI coding assistant (Antigravity / Claude) — FSM drafting (Week 6)

## 14. Conclusion

The project has grown from a basic Godot setup to a polished 2D platformer with multiple levels, an enemy AI with a state machine, a complete menu system, save/load persistence, screen-shake and hit-stop polish, and multi-platform export support. Each weekly activity introduced a new technical concept built on the foundation of the previous week.
