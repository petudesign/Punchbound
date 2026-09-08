# Punchbound

An original 2D action-combat game, built incrementally in Godot 4.

## Current milestone: first opponent combat test

Open `project.godot` in Godot and press F6 with `scenes/arena.tscn` open,
or F5 to run the project.

| Action | Key |
| --- | --- |
| Move | A/D or Left/Right |
| Jump | Space |
| Punch in facing direction | J (press for each punch) |
| Crouch / duck high punches | Hold S or Down |
| Restart | R, or the button after death |

The first two encounters have one melee opponent; subsequent encounters have
at most two. Each enemy takes three punches. Enemies approach, telegraph a
high punch in yellow, attack, and recover. Punch during their wind-up to
interrupt, duck under their strike, or use movement to avoid it. Crouching
also permits a low punch; crouch-to-jump uppercut is deliberately deferred.

Hits apply damage, knockback, stun, a white flash and brief local hitstop.
The player has a short damage grace period to prevent simultaneous enemies
from stacking hits. The HUD shows health and defeated enemies. This is a
combat feel test, not a full wave, score or progression system. All current
enemy attacks are high, so crouching is intentionally strong in this test.

Movement retains immediate horizontal response, 80 ms coyote time and a
100 ms jump buffer; punches have a 150 ms input buffer. Attack timing and
damage live in `data/attacks/`; the shared combat component owns deliberately
sized hit/hurt shapes independently of the placeholder body art. Actors do
not physically block each other in this prototype.

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
godot --headless --path . --script res://tests/combat_check.gd
godot --path . --quit-after 120
```

The movement check exits nonzero on failure and covers settling on the floor,
left/right movement, immediate stopping, jump, prevention of double jump,
landing and wall containment. It passed on the audited Windows installation.
The combat check covers startup/active timing, one hit per swing, directional
misses, knockback/hitstop, crouch evasion, player damage/grace period, death,
restart, enemy approach and replacement after defeat. Both checks passed.
Editor import and a graphical OpenGL launch also completed without reported
errors; the combat view was captured and visually inspected. Manual combat
feel testing, resizing checks and macOS validation remain. The user has
already confirmed the original movement feels responsive.

## Next step

Playtest against enemies: is punch range understandable, is the yellow
wind-up readable, and can you reliably duck and counter? Tune those before
adding content. A crouch → jump + punch uppercut is the next requested attack
idea; it should have a distinct purpose and recovery cost. Final art,
progression, Steam integration and mobile UI remain deferred.
