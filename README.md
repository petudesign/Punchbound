# Punchbound

An original 2D action-combat game, built incrementally in Godot 4.

## Current milestone: first opponent combat test

Open `project.godot` in Godot and press F6 with `scenes/arena.tscn` open,
or F5 to run the project.

| Action | Key |
| --- | --- |
| Turn + directional punch | A/D or Left/Right (press punches; player stays centered) |
| Jump | W / Up (Space also works) |
| Uppercut | Hold S / Down, then press jump while grounded |
| Crouch / duck high punches | Hold S or Down |
| Restart | R, or the button after death |

The player stays anchored in the center. The supplied player poses are stored
under `assets/player/` and currently drive idle, jump, uppercut, punch and crouch
visual states. They are user-provided placeholder art for this prototype; the
combat collision shapes remain separate from the image bounds.

The player sprite is bottom-anchored to the arena floor and scaled to sit in
the same visual range as the placeholder enemies. The earlier oversized,
floating appearance came from centering a tall source image instead of aligning
its alpha bounds to the feet.

The first two encounters have one
melee opponent, alternating sides; subsequent encounters have at most two,
one from each side. Each enemy takes three punches. Enemies approach, telegraph a
high punch in yellow, attack, and recover. Punch during their wind-up to
interrupt, duck under their strike, or use movement to avoid it. Crouching
also permits a low directional punch. Jumping from crouch triggers an uppercut
that launches the target upward, with longer recovery than a normal punch.
Landing on an enemy's head interrupts and stuns it for 0.45 seconds without
damage. Remaining on its head does not refresh the stun. A cyan ring indicates
stun. Enemies can still be passed from the side and below.

Hits apply damage, knockback, stun, a white flash and brief local hitstop.
The player has a short damage grace period to prevent simultaneous enemies
from stacking hits. The HUD shows health and defeated enemies. This is a
combat feel test, not a full wave, score or progression system. All current
enemy attacks are high, so crouching is intentionally strong in this test.

Movement retains immediate horizontal response, 80 ms coyote time and a
100 ms jump buffer; punches have a 150 ms input buffer. Attack timing and
damage live in `data/attacks/`; the shared combat component owns deliberately
sized hit/hurt shapes independently of the placeholder body art. Actors do
not physically block each other from the side. Enemy bodies use Godot's
[one-way collision](https://docs.godotengine.org/en/stable/classes/class_collisionshape2d.html#class-collisionshape2d-property-one-way-collision)
for head landings; damage still uses separate hit/hurt shapes.

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
restart, enemy approach and replacement after defeat. It also covers directional
input, normal jump versus crouch uppercut, launch, head landing without damage,
stun expiry while standing on a head, side passage and no automatic repeated
punches from holding a direction. Both checks passed.
Editor import and a graphical OpenGL launch also completed without reported
errors; the combat view was captured and visually inspected. Manual combat
feel testing, resizing checks and macOS validation remain. The user has
already confirmed the original movement feels responsive.

## Next step

Playtest against enemies: is punch range understandable, is the yellow
wind-up readable, and can you reliably duck and counter? Tune those before
adding content. Test directional punches, crouch uppercut and head landings
together: do their timing and uses feel clear? Gear is deferred until the
core combat is proven. Prefer a small number of playstyle tradeoffs over
stat inflation if gear later becomes useful. Final art, progression, Steam
integration and mobile UI remain deferred.
