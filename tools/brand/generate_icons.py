"""Generates every app icon from the wordmark.

The mark is the T of docs/brand/wordmark.png, lifted from the logo rather than
redrawn, so the icon and the logo cannot drift apart. Run this instead of
editing the PNGs by hand:

    python tools/brand/generate_icons.py

Deliberately dependency-free beyond Pillow, which is already what the project
uses to look at images; adding a Flutter icon package to run once would be a
build-time dependency for a file that changes yearly.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
WORDMARK = ROOT / "docs" / "brand" / "wordmark.png"
MOBILE = ROOT / "mobile"

TEAL = (45, 149, 131)
WHITE = (255, 255, 255, 255)

# The T inside the wordmark, cropped to its ink.
GLYPH_BOX = (117, 95, 208, 204)

# How much of the tile's height the glyph takes. Chosen by eye at 48px, which
# is the size that decides whether an icon works.
GLYPH_FILL = 0.52

# iOS applies its own mask; Android's legacy launcher does not.
IOS_CORNER = 0.0
ANDROID_CORNER = 0.2237

# An adaptive icon is drawn on a 108dp canvas of which only the central 72dp is
# guaranteed to be visible: the launcher crops the rest to whatever shape the
# device uses. The glyph is scaled to sit inside that safe circle.
ADAPTIVE_SAFE = 72 / 108

RENDER = 2048


def glyph(height: int, colour=WHITE) -> Image.Image:
    source = Image.open(WORDMARK).convert("RGBA").crop(GLYPH_BOX)
    tinted = Image.new("RGBA", source.size, colour)
    tinted.putalpha(source.split()[3])
    width = max(1, round(height * source.size[0] / source.size[1]))
    return tinted.resize((width, height), Image.LANCZOS)


def rounded_mask(size: int, ratio: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * ratio), fill=255
    )
    return mask


def tile(size: int, *, corner: float, fill: float = GLYPH_FILL) -> Image.Image:
    """The icon, rendered large and downsampled: Pillow does not antialias."""
    canvas = Image.new("RGBA", (RENDER, RENDER), TEAL + (255,))
    mark = glyph(int(RENDER * fill))
    canvas.alpha_composite(mark, ((RENDER - mark.size[0]) // 2, (RENDER - mark.size[1]) // 2))
    if corner:
        canvas.putalpha(rounded_mask(RENDER, corner))
    return canvas.resize((size, size), Image.LANCZOS)


def foreground(size: int) -> Image.Image:
    """The adaptive-icon foreground: the glyph alone, on transparency.

    Doubles as the monochrome layer for themed icons, which is why it is a
    white silhouette and not a coloured picture.
    """
    canvas = Image.new("RGBA", (RENDER, RENDER), (0, 0, 0, 0))
    mark = glyph(int(RENDER * GLYPH_FILL * ADAPTIVE_SAFE))
    canvas.alpha_composite(mark, ((RENDER - mark.size[0]) // 2, (RENDER - mark.size[1]) // 2))
    return canvas.resize((size, size), Image.LANCZOS)


ANDROID_DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

BACKGROUND_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#2D9583</color>
</resources>
"""


def write_android() -> list[Path]:
    written = []
    res = MOBILE / "android" / "app" / "src" / "main" / "res"
    for density, (legacy, adaptive) in ANDROID_DENSITIES.items():
        folder = res / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy_path = folder / "ic_launcher.png"
        tile(legacy, corner=ANDROID_CORNER).save(legacy_path)
        fg_path = folder / "ic_launcher_foreground.png"
        foreground(adaptive).save(fg_path)
        written += [legacy_path, fg_path]

    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML, encoding="utf-8")
    (res / "values" / "ic_launcher_background.xml").write_text(BACKGROUND_XML, encoding="utf-8")
    written += [anydpi / "ic_launcher.xml", res / "values" / "ic_launcher_background.xml"]
    return written


def write_ios() -> list[Path]:
    """iOS icons carry no alpha and no rounded corners: the system masks them,
    and an icon that rounds itself ends up rounded twice."""
    appicon = MOBILE / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text(encoding="utf-8"))
    written = []
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        scale = int(entry["scale"].rstrip("x"))
        size = round(float(entry["size"].split("x")[0]) * scale)
        path = appicon / filename
        tile(size, corner=IOS_CORNER).convert("RGB").save(path)
        written.append(path)
    return written


def write_shared() -> list[Path]:
    """The store-sized icon for the README, and the glyph the app draws in its
    own login screen."""
    store = ROOT / "docs" / "brand" / "icon.png"
    tile(1024, corner=ANDROID_CORNER).save(store)

    mark = MOBILE / "assets" / "brand" / "mark.png"
    mark.parent.mkdir(parents=True, exist_ok=True)
    glyph(512).save(mark)
    return [store, mark]


if __name__ == "__main__":
    for path in write_android() + write_ios() + write_shared():
        print(path.relative_to(ROOT))
