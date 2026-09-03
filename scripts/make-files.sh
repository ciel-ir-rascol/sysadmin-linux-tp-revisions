#!/bin/bash
#
# make-files.sh — Genere l'arborescence des parchemins du village
#
# A lancer depuis la racine du depot clone sur la VM :
#     ./scripts/make-files.sh
#
# Cree un dossier "parchemins/" contenant les fichiers a repartir
# dans les repertoires du village (mission 5).
#
set -e

# On se place a la racine du depot, quel que soit l'endroit d'ou le script est appele
RACINE=$(cd "$(dirname "$0")/.." && pwd)
CIBLE="$RACINE/parchemins"

if [ -e "$CIBLE" ]; then
    echo "Le dossier 'parchemins' existe deja."
    read -p "Le regenerer (son contenu actuel sera perdu) ? [o/N] " reponse
    case "$reponse" in
        [oO]|[oO][uU][iI]) rm -rf "$CIBLE" ;;
        *) echo "Abandon, rien n'a ete modifie." ; exit 0 ;;
    esac
fi

mkdir -p "$CIBLE"/{place,potion,armes,chants,romain}

ecrire() { printf '%s\n' "$2" > "$CIBLE/$1"; }

ecrire place/menu-banquet.txt       "Sangliers roties, cervoise, poisson (frais de preference)."
ecrire place/liste-villageois.txt   "Abraracourcix, Bonemine, Ordralfabetix, Cetautomatix, Agecanonix."
ecrire place/annonces.txt           "Reunion du village apres la chasse aux sangliers."

ecrire potion/recette-secrete.txt   "Gui coupe avec une serpe d or, poisson pas trop frais, carottes, sel."
ecrire potion/stock-ingredients.txt "Gui : 3 branches. Carottes : 12. Homard : 1 (facultatif)."
ecrire potion/interdictions.txt     "NE JAMAIS servir de potion a Obelix. Il est tombe dedans etant petit."

ecrire armes/inventaire.txt         "12 epees, 8 boucliers, 30 casques romains recuperes."
ecrire armes/menhirs.txt            "Livraison de menhirs : 4 modeles disponibles."

ecrire chants/repertoire.txt        "Chansons d Assurancetourix. A ne pas interpreter pendant le banquet."
ecrire chants/lyre.txt              "Notice d accordage de la lyre."

ecrire romain/ordre-de-mission.txt  "Camp de Babaorum : renforcer les patrouilles autour du village."
ecrire romain/effectifs.txt         "Legionnaires : 80. Moral : bas. Blesses par des menhirs : 34."

echo
echo "Arborescence generee dans : $CIBLE"
echo
if command -v tree >/dev/null 2>&1; then
    tree "$CIBLE"
else
    ls -R "$CIBLE"
fi
echo
echo "Vous pouvez maintenant repartir ces fichiers (mission 5)."
