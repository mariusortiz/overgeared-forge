#!/usr/bin/env python3
"""Builds the backdrops of assets/lpc/backdrops from LPC tilesets.

    python3 tools/build_backdrops.py

Downloads two tilesets from OpenGameArt (kept in tools/.lpc_cache), then writes:

  forge.png        the workshop, without its fire (180 x 125, shown twice as large)
  forge_fire.png   the furnace: frame 0 cold, frames 1 to 3 burning (64 x 128 each)
  canyon.png, castle.png, temple.png   the expedition's three zones (180 x 200)

Needs Pillow and curl. Rectangles below are (x, y, width, height) in the tilesets.
"""

import io
import os
import subprocess
import zipfile

from PIL import Image, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".lpc_cache")
OUT = os.path.join(ROOT, "assets", "lpc", "backdrops")

SMITH_ZIP = "https://opengameart.org/sites/default/files/lpc-blacksmith.zip"
BASE_ZIP = "https://opengameart.org/sites/default/files/lpc_base_assets.zip"

# In blacksmith-smelter.png
FURNACE_FRAME = (64, 128)
BRICK_WALL = (640, 266, 128, 52)
ANVIL = (320, 408, 64, 40)
TROUGH = (446, 426, 36, 38)
WORKBENCH = (320, 480, 64, 64)
WEAPON_RACK = (384, 480, 64, 64)
# In castlefloors.png and dungeon.png
STONE_FLOOR = (64, 64, 32, 32)
COBBLES = (192, 192, 32, 32)
DUNGEON_BRICK = (32, 32, 32, 32)


def from_zip(url, inner_name):
    local = os.path.join(CACHE, os.path.basename(url))
    if not os.path.exists(local):
        os.makedirs(CACHE, exist_ok=True)
        subprocess.run(["curl", "-sfL", "-o", local, url], check=True)
    with zipfile.ZipFile(local) as archive:
        for name in archive.namelist():
            if name.endswith(inner_name) and "__MACOSX" not in name:
                return Image.open(io.BytesIO(archive.read(name))).convert("RGBA")
    raise SystemExit("%s not found in %s" % (inner_name, url))


def cut(sheet, rect):
    x, y, width, height = rect
    return sheet.crop((x, y, x + width, y + height))


def shade(image, brightness, tint=(255, 255, 255)):
    """Darkens an image and pulls it towards a colour."""
    out = ImageEnhance.Brightness(image).enhance(brightness)
    red, green, blue, alpha = out.split()
    red = red.point(lambda value: value * tint[0] // 255)
    green = green.point(lambda value: value * tint[1] // 255)
    blue = blue.point(lambda value: value * tint[2] // 255)
    return Image.merge("RGBA", (red, green, blue, alpha))


def tile(canvas, piece, box):
    left, top, right, bottom = box
    for y in range(top, bottom, piece.height):
        for x in range(left, right, piece.width):
            part = piece.crop((0, 0, min(piece.width, right - x), min(piece.height, bottom - y)))
            canvas.alpha_composite(part, (x, y))


def room(wall, floor, wall_height, size):
    canvas = Image.new("RGBA", size, (0, 0, 0, 255))
    tile(canvas, wall, (0, 0, size[0], wall_height))
    tile(canvas, floor, (0, wall_height, size[0], size[1]))
    # A dark line where the wall meets the floor.
    canvas.alpha_composite(Image.new("RGBA", (size[0], 3), (10, 8, 14, 200)), (0, wall_height - 1))
    return canvas


if __name__ == "__main__":
    smith = from_zip(SMITH_ZIP, "blacksmith-smelter.png")
    floors = from_zip(BASE_ZIP, "tiles/castlefloors.png")
    dungeon = from_zip(BASE_ZIP, "tiles/dungeon.png")
    os.makedirs(OUT, exist_ok=True)

    forge = room(shade(cut(smith, BRICK_WALL), 0.7, (225, 215, 255)), shade(cut(floors, COBBLES), 0.75, (255, 225, 205)), 80, (180, 125))
    forge.alpha_composite(shade(cut(smith, WORKBENCH), 0.85), (70, 24))
    forge.alpha_composite(shade(cut(smith, WEAPON_RACK), 0.85), (122, 24))
    forge.alpha_composite(cut(smith, ANVIL), (62, 78))
    forge.alpha_composite(cut(smith, TROUGH), (142, 84))
    forge.save(os.path.join(OUT, "forge.png"))

    fire = Image.new("RGBA", (FURNACE_FRAME[0] * 4, FURNACE_FRAME[1]), (0, 0, 0, 0))
    for frame in range(4):
        fire.alpha_composite(cut(smith, (frame * FURNACE_FRAME[0], 0) + FURNACE_FRAME), (frame * FURNACE_FRAME[0], 0))
    fire.save(os.path.join(OUT, "forge_fire.png"))

    zones = {
        "canyon": (shade(cut(dungeon, DUNGEON_BRICK), 0.8), shade(cut(floors, COBBLES), 0.7, (255, 215, 180))),
        "castle": (shade(cut(smith, BRICK_WALL), 0.75, (215, 225, 255)), shade(cut(floors, STONE_FLOOR), 0.75, (215, 225, 255))),
        "temple": (shade(cut(dungeon, DUNGEON_BRICK), 0.55, (200, 150, 255)), shade(cut(floors, STONE_FLOOR), 0.55, (210, 160, 255))),
    }
    for name, (wall, floor) in zones.items():
        room(wall, floor, 52, (180, 200)).save(os.path.join(OUT, name + ".png"))
    print("backdrops written to", OUT)
