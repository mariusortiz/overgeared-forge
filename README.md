# Overgeared Forge

Jeu de forge et de collection en pixel art, pour navigateur et Android. Tu joues Grid, le forgeron : tu forges des armes en trois gestes, leur rareté dépend de ton adresse, et tu pars en expédition avec pour rapporter de meilleurs matériaux. Fait avec [Godot](https://godotengine.org) 4.7.

Jeu de fans gratuit et non officiel, inspiré de l'anime *Overgeared*. Voir [CREDITS.md](CREDITS.md).

## Tester le jeu

- Navigateur (ordinateur ou téléphone) : https://mariusortiz.github.io/overgeared-forge/
- APK Android : https://github.com/mariusortiz/overgeared-forge/releases/download/latest-debug/overgeared-forge-debug.apk

Les deux sont refaits à chaque push sur `main`.

## Comment on joue

On commence avec 6 fer et deux plans (épée, dague). Tout le reste se gagne en expédition.

**Forge.** Choisis un plan et un matériau (3 unités par objet), puis :

1. **Chauffe** : maintiens appuyé pour faire monter la température, relâche pour la faire baisser, et reste dans la zone dorée.
2. **Martelage** : six coups ; touche quand le cercle blanc atteint l'anneau doré.
3. **Trempe** : touche quand le curseur passe dans la zone bleue.

Chaque geste ne démarre que lorsqu'on appuie sur GO, et la chauffe n'est notée qu'une fois la zone dorée atteinte.

La moyenne des trois gestes donne une note sur 100. La rareté dépend de cette note et du geste le moins réussi : un seul geste raté suffit à manquer les hautes raretés.

| Rareté | Note | Geste le moins réussi |
|---|---|---|
| Rare | 55 | |
| Épique | 72 | au moins 50 |
| Unique | 84 | au moins 65 |
| Légendaire | 93 | au moins 80 |

La note bouge de 4 points au hasard, et le matériau fixe la rareté maximale. L'orichalque bleu, forgé à 96 ou plus sans geste sous 90, a une chance sur cinq de donner un objet Mythique. À rareté égale, une meilleure note donne un objet un peu plus fort ; elle est affichée dans l'inventaire.

| Matériau | Élément | Rareté max | Où le trouver |
|---|---|---|---|
| Fer | Neutre | Épique | Dès la première étape |
| Acier ardent, Givre-argent, Pierre d'orage | Feu, Glace, Foudre | Unique | Un peu dès le début, surtout à partir de l'étape 6 |
| Mithril | Neutre | Légendaire | À partir de l'étape 6, surtout après la 11 |
| Orichalque bleu | Foudre | Légendaire | À partir de l'étape 11 |

**Expédition.** Chaque étape est un combat, de plus en plus dur, avec un boss toutes les 5 étapes. Grid porte jusqu'à trois armes et une armure. À chaque tour, il frappe tout seul à la fin du chrono ; avant, tu peux toucher l'arme en main pour lancer sa compétence, ou une autre arme pour en changer. Chaque ennemi craint un élément (le carré de couleur au bout de sa barre de vie) : la bonne arme fait 50 % de dégâts en plus.

| Étapes | Zone | Ennemis | Boss |
|---|---|---|---|
| 1 à 5 | Canyon de Kesan | Gobelin, squelette, orc | Chef orc |
| 6 à 10 | Terres du comte Ashur | Soldat, mercenaire, chevalier | Capitaine d'Ashur |
| 11 à 15 | Temple de Yatan | Adepte, fanatique, prêtre noir | Malacus |
| 16 et plus | Profondeurs | Joueur rival et les plus forts des zones précédentes | Les trois boss, à tour de rôle |

Chaque ennemi battu laisse un matériau, meilleur à mesure qu'on avance. Après chaque étape, il faut choisir :

- **continuer** avec un bonus (potion, aiguisage ou renfort) pour ramasser davantage ;
- **rentrer** et garder tout le butin porté.

Si Grid est battu, le butin porté est perdu. Chaque boss battu donne un nouveau plan (lance, bouclier, hache, plastron, marteau, faux), gardé quoi qu'il arrive, et permet de repartir directement de l'étape suivante.

**Inventaire.** Grid garde 8 objets au plus, équipés compris, et un de plus par boss battu (jusqu'à 14). Quand l'inventaire est plein, il faut fondre un objet avant de forger. Fondre rend des matériaux, meilleurs si l'objet est rare :

| Rareté de l'objet fondu | Ce qu'on récupère |
|---|---|
| Normal, Rare | 1 unité de son matériau |
| Épique | 2 unités de son matériau |
| Unique | 1 unité de son matériau et 1 d'un matériau supérieur |
| Légendaire, Mythique | 1 unité de son matériau et 2 d'un matériau supérieur |

Le matériau supérieur des trois élémentaires est le mithril, celui du mithril est l'orichalque bleu. Chaque objet affiche ce que sa fonte rendrait.

**Joyaux.** Chaque boss battu lâche un joyau, et les autres ennemis en lâchent un de rang C de temps en temps. Comme les matériaux, ils sont perdus si Grid est battu avant de rentrer. Ils ne prennent pas de place dans l'inventaire.

| Joyau | Rang C | Rang B | Rang S |
|---|---|---|---|
| Rubis | +8 % d'attaque | +15 % | +25 % |
| Saphir | +10 PV | +20 PV | +35 PV |
| Émeraude | +3 PV par ennemi battu | +6 PV | +10 PV |

Le rang dépend de la zone du boss : C dans le canyon, B possible chez le comte Ashur, S possible à partir du temple de Yatan. Un objet Rare ou Épique a un emplacement, un Unique deux, un Légendaire ou un Mythique trois ; un objet Normal n'en a pas. Le bouton Sertir de l'inventaire pose ou retire les joyaux librement, et fondre un objet les rend. Les joyaux de tout ce que Grid porte s'additionnent.

Équipe trois armes et une armure. Ce que Grid équipe se voit sur lui : il commence en T-shirt blanc, porte le plastron ou le bouclier forgé (aux couleurs de son matériau), garde ses deux autres armes dans le dos en expédition, et les accroche au mur de l'atelier. Sans arme, Grid se bat avec son marteau de forge : on n'est jamais bloqué.

**Album.** Une case par plan et par matériau (48), avec la meilleure rareté forgée.

## Modifier le jeu

Tout le contenu est dans [data/catalog.gd](data/catalog.gd) : raretés, matériaux, plans, compétences, ennemis, zones, butin par zone, bonus. Les sons sont nommés par ce qui se passe (`hammer`, `hurt`, `rarity_4`…) dans [scripts/sfx.gd](scripts/sfx.gd) : une ligne par son. Changer un chiffre ou ajouter une ligne suffit, le reste du jeu suit.

| Fichier | Rôle |
|---|---|
| `scripts/forge.gd`, `scripts/forge_stage.gd` | Les trois gestes et l'atelier |
| `scripts/combat.gd` | L'expédition |
| `scripts/actor.gd` | Un personnage animé, avec son arme en main |
| `scripts/armory.gd`, `scripts/album.gd` | L'inventaire et l'album |
| `scripts/save.gd` | La sauvegarde (`user://save.json`) |
| `scripts/ui.gd` | Couleurs, boutons, images d'armes |

## Personnages et décors

Les personnages viennent du [générateur de personnages LPC](https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/) : chacun est une pile de couches (corps, tête, coiffure, vêtements) recolorées. Pour en modifier un ou en ajouter, change la liste `CHARACTERS` de [tools/build_lpc.py](tools/build_lpc.py), puis :

```sh
python3 tools/build_lpc.py          # refait assets/lpc/*.png et CREDITS-LPC.md
python3 tools/build_backdrops.py    # refait les décors de assets/lpc/backdrops
```

Il faut Python avec Pillow, et `curl`. Un nouvel ennemi se déclare ensuite dans `ENEMIES` de `data/catalog.gd`, avec le nom de son image et celui de l'arme qu'il tient.

## Lancer et vérifier

```sh
godot --path .                                     # jouer
godot --path . -- --test --demo --screen=album     # ouvrir un écran avec des armes d'exemple
godot --headless --path . --fixed-fps 60 --quit-after 3600 -- --test --basic --auto --screen=combat
```

Les options (`--auto`, `--deep`, `--demo`, `--mid`, `--basic`, `--floor=`, `--test`, `--capture=`) sont décrites en tête de `scripts/main.gd`. Avec `--auto`, le jeu joue seul et écrit une ligne `FORGE …` ou `MINE …` par résultat : c'est ce que vérifie le build.
