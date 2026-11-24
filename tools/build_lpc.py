#!/usr/bin/env python3
"""Builds the characters of assets/lpc from the layers of the LPC character generator.

    python3 tools/build_lpc.py            # every character
    python3 tools/build_lpc.py grid orc   # only these

Each character is a stack of layers (body, head, hair, clothes...), every layer
optionally recoloured. The script downloads the layers it needs (kept in
tools/.lpc_cache), stacks them, and writes:

  assets/lpc/<name>.png   two rows of 64 px frames: row 0 facing right, row 1 facing left;
                          columns: idle, then slash, then hurt (see FRAMES below)
  CREDITS-LPC.md          the authors and licences of every layer used

Needs Pillow (pip install pillow) and curl. To add a character, add an entry to CHARACTERS;
layer paths are folders of
https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/tree/master/spritesheets
"""

import csv
import io
import os
import subprocess
import sys

from PIL import Image

REPO = "https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".lpc_cache")
OUT = os.path.join(ROOT, "assets", "lpc")

SIZE = 64
# Animation, number of frames kept. In the LPC sheets the rows are up, left, down, right;
# "hurt" has a single row.
FRAMES = [("idle", 2), ("slash", 6), ("hurt", 6)]
ROW_LEFT, ROW_RIGHT = 1, 3

# Recolouring ramps: (darkest, lightest) colour a layer's greys are mapped to.
BLACK = ((10, 10, 16), (95, 95, 115))
CHARCOAL = ((25, 25, 35), (120, 120, 140))
BROWN = ((40, 25, 15), (150, 110, 70))
RED = ((90, 10, 15), (220, 50, 50))
PURPLE = ((35, 12, 50), (150, 90, 180))
NIGHT = ((12, 8, 20), (70, 55, 95))
GREEN_SKIN = ((30, 60, 25), (150, 200, 110))
OLIVE_SKIN = ((45, 55, 25), (160, 170, 100))
PALE_SKIN = ((70, 70, 90), (225, 225, 240))
GOLD = ((110, 70, 10), (255, 225, 120))
BLUE = ((20, 35, 100), (130, 180, 255))
WHITE = ((110, 110, 130), (250, 250, 255))
BLOND = ((120, 80, 20), (255, 230, 130))

HUMAN = ["body/bodies/male", "head/heads/human/male"]

# name: list of layers, bottom first. A layer is a path, or (path, ramp).
# Every sheet has the same frames, so one can be drawn over another.
CHARACTERS = {
    # Grid as at the start of the story: white T-shirt, black trousers.
    "grid": HUMAN + [
        ("legs/pants/male", BLACK), ("feet/shoes/basic/male", BLACK),
        ("torso/clothes/shortsleeve/tshirt/male", WHITE),
        ("hair/messy1/adult", BLACK)],
    # Not a character: the armour alone, drawn over Grid when he wears a breastplate.
    # It stays grey so that the game can give it the colours of its material.
    "armor_plate": ["torso/armour/plate/male", "arms/armour/plate/male"],
    # Kesan Canyon
    "goblin": [("body/bodies/male", GREEN_SKIN), ("head/heads/goblin/adult", GREEN_SKIN),
        ("legs/pants/male", BROWN)],
    "skeleton": ["body/bodies/skeleton", "head/heads/skeleton/adult"],
    "orc": [("body/bodies/muscular", OLIVE_SKIN), ("head/heads/orc/male", OLIVE_SKIN),
        ("legs/pants/male", BROWN), ("feet/boots/basic/male", BLACK)],
    "orc_chief": [("cape/solid/bg", RED), ("body/bodies/muscular", OLIVE_SKIN), ("head/heads/orc/male", OLIVE_SKIN),
        ("legs/pants/male", BLACK), ("feet/boots/basic/male", BLACK), "hat/helmet/horned/adult"],
    # Earl Ashur's lands
    "soldier": HUMAN + [("legs/pants/male", BROWN), ("feet/boots/basic/male", BLACK),
        ("torso/clothes/longsleeve/longsleeve/male", RED), "torso/armour/leather/male", "hat/helmet/kettle/adult"],
    "mercenary": HUMAN + [("legs/pants/male", CHARCOAL), ("feet/boots/basic/male", BROWN),
        ("torso/clothes/longsleeve/longsleeve/male", BROWN), ("hat/cloth/bandana/adult", RED)],
    "knight": [("cape/solid/bg", RED)] + HUMAN + [
        "legs/armour/plate/male", "feet/armour/plate/male",
        ("torso/clothes/longsleeve/longsleeve/male", CHARCOAL), "torso/armour/plate/male",
        "arms/armour/plate/male", "hat/helmet/greathelm/male"],
    "captain": [("cape/solid/bg", BLUE)] + HUMAN + [
        ("legs/armour/plate/male", GOLD), ("feet/armour/plate/male", GOLD),
        ("torso/clothes/longsleeve/longsleeve/male", CHARCOAL), ("torso/armour/plate/male", GOLD),
        ("arms/armour/plate/male", GOLD), ("hat/helmet/armet/adult", GOLD)],
    # Yatan's temple
    "cultist": [("cape/solid/bg", PURPLE)] + HUMAN + [
        ("legs/pants/male", NIGHT), ("feet/boots/basic/male", NIGHT),
        ("torso/clothes/longsleeve/longsleeve/male", PURPLE), ("hat/cloth/hood/adult", PURPLE)],
    "zealot": [("cape/solid/bg", RED)] + HUMAN + [
        ("legs/pants/male", NIGHT), ("feet/boots/basic/male", NIGHT),
        ("torso/clothes/longsleeve/longsleeve/male", NIGHT), ("hat/cloth/hood/adult", RED)],
    "dark_priest": [("cape/tattered/bg", NIGHT), ("body/bodies/male", PALE_SKIN), ("head/heads/human/male_gaunt", PALE_SKIN),
        ("legs/pants/male", NIGHT), ("feet/boots/basic/male", NIGHT),
        ("torso/clothes/longsleeve/longsleeve/male", NIGHT), ("hat/cloth/hood/adult", NIGHT)],
    "malacus": [("cape/tattered/bg", PURPLE), ("body/bodies/male", PALE_SKIN), ("head/heads/human/male_gaunt", PALE_SKIN),
        ("legs/pants/male", NIGHT), ("feet/boots/basic/male", NIGHT),
        ("torso/clothes/longsleeve/longsleeve/male", NIGHT), ("torso/armour/leather/male", PURPLE),
        ("hair/long/adult", WHITE)],
    # Deeper: other players
    "rival": [("cape/solid/bg", WHITE)] + HUMAN + [
        ("legs/armour/plate/male", BLUE), ("feet/armour/plate/male", BLUE),
        ("torso/clothes/longsleeve/longsleeve/male", WHITE), ("torso/armour/plate/male", BLUE),
        ("arms/armour/plate/male", BLUE), ("hair/spiked/adult", BLOND)],
}

used = {}


def download(url):
    """The bytes at a URL, empty when it does not exist. curl is used because
    Python often lacks the system's certificates on macOS."""
    return subprocess.run(["curl", "-sfL", url], capture_output=True).stdout


def fetch(path):
    """Returns the image at spritesheets/<path>, or None when the generator has none."""
    local = os.path.join(CACHE, path.replace("/", "__"))
    if not os.path.exists(local):
        os.makedirs(CACHE, exist_ok=True)
        with open(local, "wb") as file:
            file.write(download(REPO + "spritesheets/" + path))
    if os.path.getsize(local) == 0:
        return None
    return Image.open(local).convert("RGBA")


def recolour(image, ramp):
    dark, light = ramp
    out = image.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            level = (0.299 * r + 0.587 * g + 0.114 * b) / 255
            if level < 0.12:
                continue  # outlines stay black
            pixels[x, y] = tuple(int(dark[i] + (light[i] - dark[i]) * level) for i in range(3)) + (a,)
    return out


def build(name, layers):
    width = sum(count for _, count in FRAMES) * SIZE
    sheet = Image.new("RGBA", (width, SIZE * 2), (0, 0, 0, 0))
    column = 0
    for animation, count in FRAMES:
        for layer in layers:
            path, ramp = layer if isinstance(layer, tuple) else (layer, None)
            file = "%s/%s.png" % (path, animation)
            image = fetch(file)
            if image is None:
                print("  %s: no %s for %s, layer left out" % (name, animation, path))
                continue
            used[file] = True
            if ramp:
                image = recolour(image, ramp)
            for out_row, source_row in enumerate([ROW_RIGHT, ROW_LEFT]):
                # A sheet with a single row (hurt) serves both directions.
                top = source_row * SIZE if image.height > SIZE else 0
                strip = image.crop((0, top, count * SIZE, top + SIZE))
                sheet.alpha_composite(strip, (column * SIZE, out_row * SIZE))
        column += count
    os.makedirs(OUT, exist_ok=True)
    sheet.save(os.path.join(OUT, name + ".png"))
    print("built", name)


def write_credits():
    rows = list(csv.DictReader(io.StringIO(download(REPO + "CREDITS.csv").decode("utf-8"))))
    by_file = {row["filename"].strip(): row for row in rows}
    groups = {}
    for file in sorted(used):
        row = by_file.get(file)
        if row is None:
            print("  no credit line for", file)
            continue
        folder = os.path.dirname(file)
        key = (row["authors"].strip(), row["licenses"].strip(), row["urls"].strip())
        groups.setdefault(key, set()).add(folder)
    lines = [
        "# Crédits des personnages (LPC)",
        "",
        "Les personnages de `assets/lpc/` sont assemblés par `tools/build_lpc.py` à partir des couches du",
        "[Universal LPC Spritesheet Character Generator](https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator),",
        "recolorées. Ces images dérivées sont distribuées sous CC-BY-SA 3.0 (ou GPL 3.0), comme les couches d'origine.",
        "",
        "Fichier généré : ne pas le modifier à la main.",
        "",
    ]
    for (authors, licences, urls), folders in sorted(groups.items(), key=lambda item: sorted(item[1])[0]):
        lines.append("## " + ", ".join("`%s`" % folder for folder in sorted(folders)))
        lines.append("")
        lines.append("- Auteurs : " + authors)
        lines.append("- Licences : " + licences)
        for url in urls.replace(",", "\n").split():
            lines.append("- " + url)
        lines.append("")
    with open(os.path.join(ROOT, "CREDITS-LPC.md"), "w", encoding="utf-8") as file:
        file.write("\n".join(lines))
    print("wrote CREDITS-LPC.md")


if __name__ == "__main__":
    wanted = sys.argv[1:] or list(CHARACTERS)
    for name in wanted:
        build(name, CHARACTERS[name])
    if not sys.argv[1:]:
        write_credits()
