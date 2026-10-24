#!/usr/bin/env python3
"""Generates the launcher icons from the app's own brand (dark plate, crimson bar, "EC" in Tajawal Black).

Developer tool: needs Pillow (`pip install pillow`). The generated files are committed under branding/android/res,
so building the app does not need Pillow; run this only to change the icon.

    python3 tool/make_icons.py
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "Tajawal-Black.ttf"
OUT = ROOT / "branding"
RES = OUT / "android" / "res"

BACKGROUND = (7, 9, 14, 255)  # #07090E, the app's dark canvas
PLATE = (17, 21, 30, 255)  # #11151E
LINE = (38, 47, 63, 255)
BRAND = (176, 48, 71, 255)  # #B03047
TEXT = (244, 247, 252, 255)

SCALE = 4  # draw big, then shrink, for smooth edges


def plate(size: int, plate_ratio: float) -> Image.Image:
    """The brand plate on a transparent square of `size` pixels. `plate_ratio` is the plate's share of the width."""
    big = size * SCALE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    width = int(big * plate_ratio)
    height = int(width * 0.72)
    left = (big - width) // 2
    top = (big - height) // 2
    radius = int(height * 0.24)
    border = max(2, int(big * 0.006))
    draw.rounded_rectangle((left, top, left + width, top + height), radius=radius, fill=LINE)
    draw.rounded_rectangle(
        (left + border, top + border, left + width - border, top + height - border),
        radius=radius - border,
        fill=PLATE,
    )

    # The crimson bar on the left edge of the plate, clipped to the plate's rounded corner.
    bar_width = int(width * 0.085)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (left + border, top + border, left + width - border, top + height - border), radius=radius - border, fill=255
    )
    bar = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(bar).rectangle((left, top, left + bar_width, top + height), fill=BRAND)
    img.paste(bar, (0, 0), Image.composite(bar.split()[3], Image.new("L", (big, big), 0), mask))

    font = ImageFont.truetype(str(FONT), int(height * 0.62))
    text = "EC"
    box = draw.textbbox((0, 0), text, font=font)
    text_w, text_h = box[2] - box[0], box[3] - box[1]
    text_x = left + bar_width + (width - bar_width - text_w) // 2 - box[0]
    text_y = top + (height - text_h) // 2 - box[1]
    draw.text((text_x, text_y), text, font=font, fill=TEXT)
    return img.resize((size, size), Image.LANCZOS)


def legacy_icon(size: int) -> Image.Image:
    """Square launcher icon with rounded corners (Android 7 and older)."""
    big = size * SCALE
    base = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(base).rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * 0.22), fill=BACKGROUND)
    base = base.resize((size, size), Image.LANCZOS)
    base.alpha_composite(plate(size, 0.78))
    return base


def main() -> None:
    RES.mkdir(parents=True, exist_ok=True)

    full = Image.new("RGBA", (1024, 1024), BACKGROUND)
    full.alpha_composite(plate(1024, 0.78))
    full.convert("RGB").save(OUT / "icon_1024.png")

    for folder, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
        target = RES / f"mipmap-{folder}"
        target.mkdir(parents=True, exist_ok=True)
        legacy_icon(size).save(target / "ic_launcher.png")

    # Adaptive icon (Android 8+): 108dp canvas, the visible area is the inner 72dp, so the plate stays inside 62%.
    drawable = RES / "drawable-xxxhdpi"
    drawable.mkdir(parents=True, exist_ok=True)
    plate(432, 0.60).save(drawable / "ic_launcher_foreground.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/euro_icon_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )

    values = RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "euro_colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="euro_icon_background">#07090E</color>\n'
        '    <color name="euro_launch_background">#07090E</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )

    for name in ("drawable", "drawable-v21"):
        folder = RES / name
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "launch_background.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <item android:drawable="@color/euro_launch_background"/>\n'
            "</layer-list>\n",
            encoding="utf-8",
        )
    print(f"icons written under {OUT}")


if __name__ == "__main__":
    main()
