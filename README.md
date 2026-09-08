# Punchbound

An original 2D action-combat game, built incrementally in Godot 4.

## Current milestone: player movement

Open `project.godot` in Godot and press F6 with `scenes/arena.tscn` open,
or F5 to run the project. Move with A/D or Left/Right; jump with Space.
The placeholder arena has solid floor/walls, immediate horizontal movement,
80 ms coyote time and a 100 ms jump buffer. Attacks are the next milestone.

## Environment audit — 2026-09-08

- Host: Windows. macOS remains a target; no macOS execution has been verified.
- Existing remote commit: `035fd6e` on `main`, containing only README and a
  Node-oriented `.gitignore`. No existing scenes, scripts, assets or project settings.
- Local workspace initially contained an empty Git repository with no remote.
  Work continues from the remote commit on `codex/milestone-1-movement`.
- Steam engine: `4.7.2.stable.steam.ed1daf0bf`.
- Executable: `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.
  It is usable by absolute path, but was not found on PATH.
- Matching export templates are installed under the engine's
  `editor_data/export_templates/4.7.2.stable`, including Windows and macOS.
- New project uses the Compatibility renderer, no external dependencies,
  InputMap actions, and a scaling canvas with an anchored instruction panel.
- Git requires a command-scoped `safe.directory` override in the Codex sandbox
  because its Windows account differs from the workspace owner. No global Git
  trust settings were changed.
- The sandbox blocked the portable engine's editor-cache/settings writes.
  An authorized run outside the sandbox imported successfully with no errors.

## Checks

Using the installed engine executable as `godot`:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/movement_check.gd
godot --path . --quit-after 120
```

The movement check exits nonzero on failure and covers settling on the floor,
left/right movement, immediate stopping, jump, prevention of double jump,
landing and wall containment. It passed on the audited Windows installation.
Editor import and a graphical OpenGL launch also completed without reported
errors. Manual feel testing, resizing checks and macOS validation remain.

## Next step

Playtest movement first, then add one attack with explicit startup, active and
recovery timing. Keep enemies, waves, progression and final art for later milestones.
