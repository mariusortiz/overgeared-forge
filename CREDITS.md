# Crédits

Les licences ne sont pas toutes les mêmes : les modèles 3D et les sons sont dans le domaine public (CC0), la police est sous OFL, et les images LPC demandent de citer leurs auteurs et de garder la même licence.

## Modèles 3D (Quaternius)

Tout ce qui est en 3D dans le jeu vient des packs gratuits de [Quaternius](https://quaternius.com), sous licence CC0 :

| Contenu | Pack | Emplacement |
|---|---|---|
| Tenues des personnages | Modular Character Outfits - Fantasy (version gratuite) | `assets/quaternius/characters/` |
| Têtes et coiffures | Universal Base Characters (version gratuite) | `assets/quaternius/base/`, `assets/quaternius/hair/` |
| Animations | Universal Animation Library | `assets/quaternius/animations/` |
| Armes, bouclier, coffre | Fantasy Props MegaKit (version gratuite) | `assets/quaternius/props/` |
| Arbres, buissons, fleurs, rochers | Ultimate Stylized Nature | `assets/quaternius/nature/` |
| Temple, forge | Modular Dungeon, Updated Modular Dungeon | `assets/quaternius/modular_dungeon_*/` |
| Village | Medieval Village | `assets/quaternius/medieval_village_pack/` |
| Plastron, cristaux, lingots | Ultimate RPG Items | `assets/quaternius/rpg_items_pack/` |

Les textures ont été réduites par `tools/build_quaternius.py`. La lance, la faux, le bâton, le fourneau et l'enclume sont des formes simples construites par le jeu, et les textures de sol (`assets/quaternius/ground/`) sont dessinées par `tools/gallery/grounds.gd`. Les images d'armes des menus (`assets/icons/`) sont des rendus des modèles.

## Anciens modèles 3D (KayKit)

Les modèles de [Kay Lousberg](https://www.kaylousberg.com) (CC0) dans `assets/kaykit/` ne sont plus affichés par le jeu.

## Anciennes images en pixel art (LPC)

Ces images ne sont plus affichées par le jeu, sauf l'icône ; elles restent dans le dépôt avec leurs crédits.

Les personnages de `assets/lpc/` sont assemblés à partir du [Universal LPC Spritesheet Character Generator](https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator). La liste complète des auteurs, couche par couche, est dans [CREDITS-LPC.md](CREDITS-LPC.md). Ces images dérivées sont distribuées sous CC-BY-SA 3.0 (ou GPL 3.0).

Les décors de `assets/lpc/backdrops/` et l'icône sont composés à partir de :

| Contenu | Pack | Auteur | Licence |
|---|---|---|---|
| Forge, enclume, établi, râtelier, bac de trempe, mur de briques | [[LPC] Blacksmith Workshop](https://opengameart.org/content/lpc-blacksmith) | bluecarrot16 | OGA-BY 3.0, CC-BY 3.0+, GPL 2.0+ |
| Sols de pierre | [LPC Base Assets](https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles), `castlefloors.png` | Daniel Armstrong (HughSpectrum) | CC-BY-SA 3.0, GPL 3.0 |
| Mur du canyon et du temple | [LPC Base Assets](https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles), `dungeon.png` | Lanea Zimmerman (Sharm) | CC-BY-SA 3.0, GPL 3.0, OGA-BY 3.0 |

Les décors dérivés sont distribués sous CC-BY-SA 3.0.

## Armes, sons, police

| Contenu | Pack | Auteur | Licence | Emplacement |
|---|---|---|---|---|
| Armes du joueur et des ennemis | [Idylwild's Arsenal](https://opengameart.org/content/idylwilds-arsenal) | Idylwild | CC0 | `assets/weapons/` |
| Plastron | [CC0 Torso Wear Icons](https://opengameart.org/content/cc0-torso-wear-icons) | 7Soul1 | CC0 | `assets/weapons/plate.png` |
| Bouclier | [CC0 Shield Icons](https://opengameart.org/content/cc0-shield-icons) | 7Soul1 | CC0 | `assets/weapons/shield.png` |
| Sons de l'interface, de la forge et du combat | [Interface Sounds](https://opengameart.org/content/interface-sounds) | Kenney | CC0 | `assets/audio/` |
| Mélodies des raretés et du retour d'expédition | [85 short music jingles](https://opengameart.org/content/85-short-music-jingles) | Kenney | CC0 | `assets/audio/jingles_*` |
| Police de l'interface | [Jersey 15](https://fonts.google.com/specimen/Jersey+15) | The Soft Type Project Authors | OFL 1.1 | `assets/fonts/` |

Le plastron et le bouclier ont reçu le même contour que les armes, pour porter la couleur de rareté. Les couleurs des armes (matériau, rareté, métal chauffé) sont appliquées par le jeu (`assets/weapon.gdshader`) sur les images d'origine.

## Overgeared

Overgeared Forge est un jeu de fans, gratuit et non officiel. *Overgeared* (템빨) est un roman de Park Saenal, adapté en webtoon par REDICE Studio et en anime par J.C.Staff ; les noms repris de cette œuvre appartiennent à leurs ayants droit. Le jeu n'utilise aucune image, musique ni voix du roman, du webtoon ou de l'anime.
