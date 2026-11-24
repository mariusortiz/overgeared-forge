# Overgeared Forge

Jeu de forge et de collection en pixel art, pour navigateur et Android. Tu joues Grid, le forgeron : tu forges des armes en trois gestes, leur rareté dépend de ton adresse, et tu les testes dans la mine pour rapporter de meilleurs matériaux. Fait avec [Godot](https://godotengine.org) 4.7.

Jeu de fans gratuit et non officiel, inspiré de l'anime *Overgeared*. Voir [CREDITS.md](CREDITS.md).

## Tester le jeu

- Navigateur (ordinateur ou téléphone) : https://mariusortiz.github.io/overgeared-forge/
- APK Android : https://github.com/mariusortiz/overgeared-forge/releases/download/latest-debug/overgeared-forge-debug.apk

Les deux sont refaits à chaque push sur `main`.

## Comment on joue

**Forge.** Choisis un plan (épée, dague, lance, hache) et un matériau, puis :

1. **Chauffe** : maintiens appuyé pour faire monter la température, relâche pour la faire baisser, et reste dans la zone dorée.
2. **Martelage** : six coups ; touche quand le cercle blanc atteint l'anneau doré.
3. **Trempe** : touche quand le curseur passe dans la zone bleue.

La moyenne des trois gestes donne une note sur 100, et la note donne la rareté : Normal, Rare, Épique, Unique, Légendaire. Le matériau fixe la rareté maximale. L'orichalque bleu, forgé presque parfaitement, a une petite chance de donner une arme Mythique.

| Matériau | Élément | Rareté max | Où le trouver |
|---|---|---|---|
| Fer | Neutre | Épique | Tous les ennemis |
| Acier ardent | Feu | Unique | Chauves-souris |
| Givre-argent | Glace | Unique | Araignées |
| Orichalque bleu | Foudre | Légendaire | Le Cyclope |

**Mine.** Cinq vagues, un boss à la dernière. Grid porte jusqu'à trois armes. À chaque tour, il frappe tout seul à la fin du chrono ; avant, tu peux toucher l'arme en main pour lancer sa compétence, ou une autre arme pour en changer. Chaque ennemi craint un élément (le carré de couleur à côté de sa vie) : la bonne arme fait 50 % de dégâts en plus. Entre deux vagues, tu choisis un bonus. Une victoire fait monter la mine d'un niveau ; une défaite laisse la moitié du butin.

**Armes.** Équipe trois armes, fonds les autres pour récupérer un peu de matériau.

**Album.** Une case par plan et par matériau (16), avec la meilleure rareté forgée.

## Modifier le jeu

Tout le contenu est dans [data/catalog.gd](data/catalog.gd) : raretés, matériaux, plans, compétences, ennemis, vagues, bonus. Changer un chiffre ou ajouter une ligne suffit, le reste du jeu suit.

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

Les options (`--auto`, `--demo`, `--basic`, `--loop`, `--test`, `--capture=`) sont décrites en tête de `scripts/main.gd`. Avec `--auto`, le jeu joue seul et écrit une ligne `FORGE …` ou `COMBAT …` par résultat : c'est ce que vérifie le build.
