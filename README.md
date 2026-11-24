# Overgeared Forge

Jeu de forge et de collection en pixel art, pour navigateur et Android. Tu joues Grid, le forgeron : tu forges des armes en trois gestes, leur rareté dépend de ton adresse, et tu les testes dans la mine pour rapporter de meilleurs matériaux. Fait avec [Godot](https://godotengine.org) 4.7.

Jeu de fans gratuit et non officiel, inspiré de l'anime *Overgeared*. Voir [CREDITS.md](CREDITS.md).

## Tester le jeu

- Navigateur (ordinateur ou téléphone) : https://mariusortiz.github.io/overgeared-forge/
- APK Android : https://github.com/mariusortiz/overgeared-forge/releases/download/latest-debug/overgeared-forge-debug.apk

Les deux sont refaits à chaque push sur `main`.

## Comment on joue

On commence avec 6 fer et deux plans (épée, dague). Tout le reste se gagne dans la mine.

**Forge.** Choisis un plan et un matériau (3 unités par objet), puis :

1. **Chauffe** : maintiens appuyé pour faire monter la température, relâche pour la faire baisser, et reste dans la zone dorée.
2. **Martelage** : six coups ; touche quand le cercle blanc atteint l'anneau doré.
3. **Trempe** : touche quand le curseur passe dans la zone bleue.

La moyenne des trois gestes donne une note sur 100, et la note donne la rareté : Normal, Rare, Épique, Unique, Légendaire. Le matériau fixe la rareté maximale. L'orichalque bleu, forgé presque parfaitement, a une petite chance de donner un objet Mythique.

| Matériau | Élément | Rareté max | Où le trouver |
|---|---|---|---|
| Fer | Neutre | Épique | Dès le premier étage |
| Acier ardent, Givre-argent, Pierre d'orage | Feu, Glace, Foudre | Unique | Un peu dès le début, surtout à partir de l'étage 6 |
| Mithril | Neutre | Légendaire | À partir de l'étage 6, surtout après le 11 |
| Orichalque bleu | Foudre | Légendaire | À partir de l'étage 11 |

**Mine.** Chaque étage est un combat, de plus en plus dur, avec un boss tous les 5 étages. Grid porte jusqu'à trois armes et une armure. À chaque tour, il frappe tout seul à la fin du chrono ; avant, tu peux toucher l'arme en main pour lancer sa compétence, ou une autre arme pour en changer. Chaque ennemi craint un élément (le carré de couleur à côté de sa vie) : la bonne arme fait 50 % de dégâts en plus.

Chaque ennemi battu laisse un matériau, meilleur en profondeur. Après chaque étage, il faut choisir :

- **descendre** avec un bonus (potion, aiguisage ou renfort) pour ramasser davantage ;
- **remonter** et garder tout le butin porté.

Si Grid est battu, le butin porté est perdu. Chaque boss battu donne un nouveau plan (lance, bouclier, hache, plastron, marteau, faux), gardé quoi qu'il arrive, et ouvre une entrée directe à l'étage suivant.

**Armes.** Équipe trois armes et une armure, fonds le reste pour récupérer un peu de matériau. Sans arme, Grid se bat avec son marteau de forge : on n'est jamais bloqué.

**Album.** Une case par plan et par matériau (48), avec la meilleure rareté forgée.

## Modifier le jeu

Tout le contenu est dans [data/catalog.gd](data/catalog.gd) : raretés, matériaux, plans, compétences, ennemis, butin par profondeur, bonus. Les sons sont nommés par ce qui se passe (`hammer`, `hurt`, `rarity_4`…) dans [scripts/sfx.gd](scripts/sfx.gd) : une ligne par son. Changer un chiffre ou ajouter une ligne suffit, le reste du jeu suit.

| Fichier | Rôle |
|---|---|
| `scripts/forge.gd`, `scripts/forge_stage.gd` | Les trois gestes et l'atelier |
| `scripts/combat.gd` | La mine |
| `scripts/armory.gd`, `scripts/album.gd` | Les armes et l'album |
| `scripts/save.gd` | La sauvegarde (`user://save.json`) |
| `scripts/ui.gd` | Couleurs, boutons, images d'armes |

## Lancer et vérifier

```sh
godot --path .                                     # jouer
godot --path . -- --test --demo --screen=album     # ouvrir un écran avec des armes d'exemple
godot --headless --path . --fixed-fps 60 --quit-after 3600 -- --test --basic --auto --screen=combat
```

Les options (`--auto`, `--deep`, `--demo`, `--mid`, `--basic`, `--floor=`, `--test`, `--capture=`) sont décrites en tête de `scripts/main.gd`. Avec `--auto`, le jeu joue seul et écrit une ligne `FORGE …` ou `MINE …` par résultat : c'est ce que vérifie le build.
