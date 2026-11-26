#!/usr/bin/env python3
"""Builds assets/kaykit from the KayKit packs (Kay Lousberg, CC0).

- copies the character, weapon and scenery models the game uses;
- writes one recoloured palette picture per character of the game (SKINS).

The packs are fetched once into tools/.kaykit_cache. Needs git and Pillow.
Run:  python3 tools/build_kaykit.py
"""
import shutil
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".kaykit_cache"
OUT = ROOT / "assets" / "kaykit"
PACKS = {
    "adventurers": ("KayKit-Character-Pack-Adventures-1.0", "addons/kaykit_character_pack_adventures"),
    "skeletons": ("KayKit-Character-Pack-Skeletons-1.0", "addons/kaykit_character_pack_skeletons"),
    "dungeon": ("KayKit-Dungeon-Remastered-1.0", "addons/kaykit_dungeon_remastered"),
    "medieval": ("KayKit-Medieval-Hexagon-Pack-1.0", "addons/kaykit_medieval_hexagon_pack"),
}

CHARACTERS = {
    "adventurers": ["Rogue", "Rogue_Hooded", "Knight", "Barbarian", "Mage"],
    "skeletons": ["Skeleton_Minion", "Skeleton_Mage"],
}
WEAPONS = {
    "adventurers": ["sword_1handed", "sword_2handed", "dagger", "axe_1handed", "axe_2handed", "staff", "shield_round"],
    "skeletons": ["Skeleton_Blade", "Skeleton_Staff"],
}
DUNGEON = [
    "floor_tile_large", "floor_wood_large", "floor_dirt_large", "wall", "wall_arched", "wall_window_closed",
    "wall_shelves", "wall_cracked", "wall_broken", "pillar", "pillar_decorated", "column", "torch_mounted",
    "barrel_large", "barrel_small_stack", "crates_stacked", "box_large", "table_medium", "shelf_large",
    "keg", "rubble_half", "banner_shield_red", "chest_gold", "trunk_large_A", "stool", "candle_triple",
]
MEDIEVAL = {
    "decoration/nature": ["mountain_A", "mountain_B", "mountain_C", "rock_single_A", "rock_single_B", "rock_single_C",
                          "rock_single_D", "rock_single_E", "hill_single_A", "hill_single_B", "tree_single_A",
                          "tree_single_B", "trees_A_large", "trees_B_large", "trees_A_medium", "cloud_big", "cloud_small"],
    "decoration/props": ["tent", "flag_red", "weaponrack", "crate_A_big", "barrel", "sack", "target", "wheelbarrow"],
    "buildings/red": ["building_castle_red", "building_tower_A_red", "building_barracks_red"],
    "buildings/neutral": ["wall_straight", "fence_wood_straight", "fence_stone_straight"],
}

# A palette picture is a grid of 8 x 4 swatches (128 x 256 pixels each); a
# skin repaints some of them, keeping each swatch's own shading.
# skin: [palette picture, {(row, column): colour}]
SKIN, HAIR = (0, 0), (0, 1)
SKINS = {
    "grid": ["rogue", {(1, 1): "f4f4ef", (1, 0): "d9dadf", (1, 7): "2b2b33", HAIR: "6b4226"}],
    "grid_armor": ["knight", {HAIR: "6b4226"}],
    "goblin": ["rogue", {SKIN: "86b84e", (1, 1): "7a5230", (1, 0): "4a3524"}],
    "mercenary": ["rogue", {}],
    "cultist": ["rogue", {(1, 1): "5b2a7a", (1, 0): "2a1838", SKIN: "d9c9c0"}],
    "orc": ["barbarian", {SKIN: "6f9a45"}],
    "orc_chief": ["barbarian", {SKIN: "587f3a", (0, 7): "8a2222"}],
    "soldier": ["knight", {(1, 0): "3b5fa8"}],
    "knight": ["knight", {(0, 3): "5d6275", (1, 0): "5b2a7a"}],
    "rival": ["knight", {(0, 3): "e3b341", (1, 0): "2f6fb5"}],
    "captain": ["knight", {(0, 3): "e3b341", (1, 0): "f1efe6"}],
    "zealot": ["mage", {(1, 0): "a82a2a", (1, 1): "7a1c1c"}],
    "dark_priest": ["mage", {(1, 0): "2b2633", (1, 1): "1d1a24", SKIN: "b9c2c9"}],
    "skeleton": ["skeleton", {}],
    "malacus": ["skeleton", {}],
}
PALETTES = {
    "rogue": ("adventurers", "rogue_texture.png"), "knight": ("adventurers", "knight_texture.png"),
    "barbarian": ("adventurers", "barbarian_texture.png"), "mage": ("adventurers", "mage_texture.png"),
    "skeleton": ("skeletons", "skeleton_texture.png"),
}


def pack(name: str) -> Path:
    repo, inner = PACKS[name]
    if not (CACHE / repo).exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "clone", "-q", "--depth", "1", f"https://github.com/KayKit-Game-Assets/{repo}.git"], cwd=CACHE, check=True)
    return CACHE / repo / inner


def copy(source: Path, folder: str) -> None:
    (OUT / folder).mkdir(parents=True, exist_ok=True)
    shutil.copy(source, OUT / folder / source.name)


def repaint(picture: Image.Image, cell: tuple, colour: str) -> None:
    """Gives a swatch a new colour, as light or dark as it was at each pixel."""
    row, column = cell
    box = (column * 128, row * 256, column * 128 + 128, row * 256 + 256)
    swatch = picture.crop(box).convert("L")
    brightest = max(swatch.getdata()) or 1
    target = tuple(int(colour[i:i + 2], 16) for i in (0, 2, 4))
    shaded = Image.new("RGBA", swatch.size)
    shaded.putdata([tuple(int(channel * (0.25 + 0.75 * value / brightest)) for channel in target) + (255,) for value in swatch.getdata()])
    picture.paste(shaded, box)


def main() -> None:
    for name, files in CHARACTERS.items():
        for file in files:
            copy(pack(name) / "Characters" / "gltf" / f"{file}.glb", "characters")
    for name, files in WEAPONS.items():
        folder = pack(name) / "Assets" / "gltf"
        for file in files:
            copy(folder / f"{file}.gltf", "weapons")
            copy(folder / f"{file}.bin", "weapons")
        for texture in folder.glob("*_texture.png"):
            copy(texture, "weapons")
    for file in DUNGEON:
        folder = pack("dungeon") / "Assets" / "gltf"
        source = folder / f"{file}.gltf.glb"
        copy(source if source.exists() else folder / f"{file}.glb", "props")
    for folder, files in MEDIEVAL.items():
        source = pack("medieval") / "Assets" / "gltf" / folder
        for file in files:
            copy(source / f"{file}.gltf", "props")
            copy(source / f"{file}.bin", "props")
        copy(source / "hexagons_medieval.png", "props")
    (OUT / "skins").mkdir(parents=True, exist_ok=True)
    for skin, (palette, cells) in SKINS.items():
        name, file = PALETTES[palette]
        picture = Image.open(pack(name) / "Textures" / file).convert("RGBA")
        for cell, colour in cells.items():
            repaint(picture, cell, colour)
        picture.save(OUT / "skins" / f"{skin}.png")
    print("assets/kaykit:", sum(1 for _ in OUT.rglob("*") if _.is_file()), "files")


if __name__ == "__main__":
    main()
