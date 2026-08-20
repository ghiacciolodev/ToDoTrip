# Brand assets

| File | What it is |
|---|---|
| `wordmark.png` | The "ToDoTrip" lettering, teal on a transparent background. Shown at the top of the repository README. |
| `icon.png` | The app icon at 1024px: the wordmark's T, white on the brand teal. |
| `01-trips.png` … `09-sign-in.png` | Screenshots, numbered in the order the repository README shows them. |

## The app icon

`icon.png` is not drawn by hand and should not be edited directly. It is
generated from `wordmark.png`, along with every Android density, both
adaptive-icon layers and the whole iOS set:

```bash
python tools/brand/generate_icons.py
```

Lifting the glyph out of the wordmark rather than redrawing it is what keeps
the launcher icon and the logo from drifting apart. Change the wordmark, run
the script again, and everything follows.

## The screenshots

Numbered so the folder carries the intended order and the README is not the
only place that knows it. They are stored at 720px wide and displayed at 200:
enough for a high-density screen, a fifth of the bytes of the originals off the
phone.
