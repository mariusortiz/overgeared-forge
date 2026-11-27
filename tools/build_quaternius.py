#!/usr/bin/env python3
"""Builds assets/quaternius from the free packs of Quaternius (CC0).

Copies the models the game uses and shrinks their pictures (the packs come
with 2K and 4K textures, far too heavy for a phone).

The packs are read from tools/.quaternius_cache, one folder per pack:
  outfits/                    Modular Character Outfits - Fantasy (Standard), glTF "Outfits"
  universal_base_characters/  Universal Base Characters (Standard)
  universal_animation_library/UAL1.glb
  fantasty_props_megakit/     Fantasy Props MegaKit (Standard), glTF
  nature/                     Ultimate Stylized Nature, FBX and Textures together
  modular_dungeon_1/, modular_dungeon_pack/, medieval_village_pack/, rpg_items_pack/   GLB
They come from quaternius.com (or itch.io); README.md says where copies are kept.

Needs Pillow.  Run:  python3 tools/build_quaternius.py
"""
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".quaternius_cache"
OUT = ROOT / "assets" / "quaternius"

# Pictures are shrunk to this size at most, by folder; bark needs less than faces.
SIZES = {"characters": 1024, "base": 1024, "hair": 512, "props": 1024, "nature": 512}

NATURE = ["NormalTree_1", "NormalTree_2", "NormalTree_3", "NormalTree_4", "NormalTree_5", "PineTree_1", "PineTree_2",
          "PineTree_3", "PineTree_4", "PineTree_5", "BirchTree_1", "BirchTree_2", "BirchTree_3", "DeadTree_1",
          "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5", "DeadTree_6", "Bush", "Bush_Large", "Bush_Small",
          "Bush_Flowers", "Grass_Large", "Grass_Small", "Flower_1_Clump", "Flower_2_Clump", "Plant_1", "Plant_2",
          "Rock_1", "Rock_2", "Rock_3", "Rock_4", "Rock_5"]
NATURE_PICTURES = ["NormalTree_Bark", "NormalTree_Bark_Normal", "NormalTree_Leaves", "PineTree_Bark", "PineTree_Bark_Normal",
                   "PineTree_Leaves", "BirchTree_Bark", "BirchTree_Bark_Normal", "BirchTree_Leaves", "Bush_Leaves",
                   "Flowers", "Grass", "Rocks", "Rocks_Desert", "Rocks_Dark_Green"]
GLB = {
    "modular_dungeon_1": ["Arch", "Arch_bars", "Banner", "Banner_wall", "Barrel", "Barrel2", "Bucket", "Chair", "Chest",
                          "Chest_Gold", "Cobweb", "Coin_Pile", "Column", "Column2", "Crate", "Decorative_Wall",
                          "Floor_Modular", "Pedestal", "Pedestal2", "Skull", "Statue_Horse", "Sword_WallMount",
                          "Table_Big", "Table_Small", "Torch", "Vase", "Wall_Modular", "WallCover_Modular", "Woodfire"],
    "modular_dungeon_pack": ["Bones", "Bones2", "Candelabrum_tall", "Column_Broken", "Column_Broken2", "Entrance",
                             "ModularStoneWall", "Rock1", "Rock2", "Rock3", "Torch_wall", "WallRocks", "Carpet"],
    "medieval_village_pack": ["Bag", "Bags", "Barrel", "Bell_Tower", "Bench_1", "Blacksmith", "Bonfire_Lit", "Cart",
                              "Cauldron", "Crate", "Fence", "Hay", "House_1", "House_2", "House_3", "Inn",
                              "MarketStand_1", "Rock_1", "Rock_2", "Stable", "Well"],
    "rpg_items_pack": ["Armor_Metal", "Sword", "Sword_big", "Dagger", "Axe_Double", "Axe_small", "Hammer_Double",
                       "Crystal1", "Crystal2", "Crystal3", "Gold_Ingots", "Chest_Ingots", "Skull"],
}


def put(source: Path, folder: str) -> None:
    (OUT / folder).mkdir(parents=True, exist_ok=True)
    target = OUT / folder / source.name
    if source.suffix == ".png":
        picture = Image.open(source)
        if picture.mode not in ("RGB", "RGBA"):
            picture = picture.convert("RGBA" if "A" in picture.mode or picture.mode == "P" else "RGB")
        limit = SIZES[folder]
        # The pictures of relief and shine need less detail than the colours.
        if any(word in source.name for word in ("Normal", "ORM", "Roughness")):
            limit //= 2
        if max(picture.size) > limit:
            picture = picture.resize((limit, limit), Image.LANCZOS)
        picture.save(target, optimize=True)
    else:
        shutil.copy(source, target)


def main() -> None:
    for file in sorted((CACHE / "outfits").iterdir()):
        put(file, "characters")
    base = CACHE / "universal_base_characters"
    for file in sorted((base / "Base Characters").iterdir()):
        if not file.name.endswith("_png.png"):
            put(file, "base")
    for name in ["Hair_SimpleParted", "Hair_Buzzed", "Hair_Long", "Hair_Buns", "Hair_Beard"]:
        for ending in [".gltf", ".bin"]:
            put(base / "Hairstyles" / "Rigged" / (name + ending), "hair")
    for file in sorted((base / "Hairstyles" / "Rigged").glob("*.png")):
        put(file, "hair")
    (OUT / "animations").mkdir(parents=True, exist_ok=True)
    shutil.copy(CACHE / "universal_animation_library" / "UAL1.glb", OUT / "animations" / "UAL1.glb")
    for file in sorted((CACHE / "fantasty_props_megakit").iterdir()):
        if file.suffix != ".txt":
            put(file, "props")
    for name in NATURE:
        put(CACHE / "nature" / (name + ".fbx"), "nature")
    for name in NATURE_PICTURES:
        put(CACHE / "nature" / (name + ".png"), "nature")
    for pack, names in GLB.items():
        for name in names:
            (OUT / pack).mkdir(parents=True, exist_ok=True)
            shutil.copy(CACHE / pack / (name + ".glb"), OUT / pack / (name + ".glb"))
    files = [f for f in OUT.rglob("*") if f.is_file() and f.suffix != ".import"]
    print("assets/quaternius: %d files, %.1f MB" % (len(files), sum(f.stat().st_size for f in files) / 1e6))


if __name__ == "__main__":
    main()
