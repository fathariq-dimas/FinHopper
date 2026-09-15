# Gameplay feedback assets

## Recorded sound effects

All current hop, splash, collision, and vehicle recordings are licensed CC0 1.0:
https://creativecommons.org/publicdomain/zero/1.0/

- `PondHopper/Resources/Sounds/hop.wav`: restored from the user-selected
  `pondhopper-feedback-v2/before-sounds/hop.wav` backup (ezwa water splash pack,
  cut and submitted by qubodup on OpenGameArt; public domain/CC0).
- `PondHopper/Resources/Sounds/splash.wav`: [Splash 2](https://freesound.org/people/lurpsis/sounds/444016/),
  by lurpsis. A rock thrown into a lake, recorded with Olympus LS-14.
- `PondHopper/Resources/Sounds/collision.wav`: [oof.wav](https://freesound.org/people/fotoshop/sounds/47356/),
  by fotoshop. The creator saying "Oof".
- `PondHopper/Resources/Sounds/vehiclePass.wav`: [Car passing by.wav](https://freesound.org/people/hinzebeat/sounds/171447/),
  by hinzebeat. A car passing from left to right.

Sources: hop uses the earlier ezwa pack; other recordings use public high-quality
MP3 previews linked by the source pages. Files are
converted to mono 44.1 kHz, 16-bit PCM WAV. No saturation or synthesized water/engine
layers are used. Splash, collision, and vehicle use peak normalization at 85%
full scale before short edge fades. Hop is restored byte-for-byte from its backup.

Edits in source time:

- Splash: full 1.539-second recording at original pitch; 3 ms attack and 30 ms release.
  Playback volume increased to 1.00 at the user’s request.
- Hop: restored 0.176-second backup without further processing; playback volume 0.30.
- Collision: full 0.244-second original-pitch vocal; 3 ms attack and 10 ms release.
- Vehicle: 0.8–3.0 seconds, preserving the approach and receding engine sound;
  160 ms attack and 350 ms release. The 2.3-second cooldown exceeds its 2.2-second duration.

Playback levels are set in `GameSoundEffect.volume`. Source pages and licenses
checked September 11, 2026. Splash and collision use the exact sources selected
by the user, replacing the previous Rock Splash 7 and unfa oof revisions.

## Drained pond

`PondHopper/Resources/PondSprites.spriteatlas/pond-drained.png` was generated with
the built-in imagegen tool, using `pond-idle-0.png` as the edit reference.
The original pond asset was preserved. Generated alpha transparency is retained.

Final prompt:

> Use case: precise-object-edit. Edit target: supplied pond game sprite. Create the completely drained version of this same pond for a 2D mobile game. Keep the exact canvas framing, pond oval outline and footprint, rock positions, bold dark outlines, simple bright cartoon shading, camera angle and generous transparent margins. Replace ALL cyan/blue water, reflections and bubbles with a clearly empty shallow concave basin of warm medium brown mud/earth, slightly darker inner back rim and a few subtle curved cracks. The two lily leaves rest flat on the dry basin, slightly wilted olive green. No water remains. Keep external background genuinely transparent alpha, no checkerboard, no text, no ground outside silhouette, no added objects. Output a single sprite matching the reference composition as closely as possible.

## Wet fish trail

`PondHopper/Resources/PondSprites.spriteatlas/wet-fish-trail.png` is a 512 x 512
RGBA sprite generated using built-in imagegen with `fish-flop-1.png` as the shape
reference. It represents the belly contact patch and a swept two-lobed tail mark,
without a face or an outline. It replaces the three procedural ellipses.

The generator baked in a checkerboard twice. With explicit user approval, local
AppKit processing extracted the blue chroma as alpha, removed all neutral background,
and recolored the remaining coverage as muted dark teal. The original generated
images are not bundled. Runtime flips match the fish orientation before the hop;
the four-mark cap, distance fade, lifetime, and pause behavior remain intact.

Generation prompt: single horizontal wet fish-body ground impression, broad belly
on the right, narrow tail neck and irregular two-lobed tail smear on the left;
subdued dark teal with soft broken edges, no actual fish, eyes, mouth, black outline,
white highlight, shadow, ground texture, or text; centered transparent square canvas.

Final imagegen edit prompt: remove all gray checkerboard and crumpled-paper texture;
preserve only the irregular blue belly-and-tail impression; smooth muted teal
#236779, subtly lighter soft edges, no background or shadow, genuine transparent PNG.
The requested transparency was completed by the approved local cleanup described above.

## Garden decorations

`garden-decorations.png` is the original transparent 4 × 4 sprite sheet supplied
by the user (latest sheet: codex-clipboard-cf5ae5aa-ab52-48f9-acab-02f0250d7730.png).
It replaces the earlier sheet and is bundled unchanged. Runtime texture regions
select its 16 grass, ground cover, flower, and leaf decorations. These replace the
procedural tufts, flower dots, and green patches. The ground is plain again;
decorative nodes have no physics body.

## Tutorial gesture icons

Tap and directional swipe SVGs are from [Tabler Icons](https://github.com/tabler/tabler-icons), MIT licensed. Original paths: `icons/outline/hand-click.svg`, `icons/outline/hand-move.svg`, and `icons/outline/swipe-{left,right,up,down}.svg`. The hand outlines are locally adapted into closed, filled silhouettes. Gesture paths use white with original rendering so SpriteKit preserves their solid color. License: `PondHopper/Resources/TablerIcons-LICENSE.txt`.

### FTUE replacement hands

Filled tap and pointing hands use Phosphor Icons (MIT): https://github.com/phosphor-icons/core/tree/main/assets/fill (hand-tap-fill.svg, hand-pointing-fill.svg). Fill changed to white. License: PondHopper/Resources/PhosphorIcons-LICENSE.txt. Direction arrows remain Tabler.
