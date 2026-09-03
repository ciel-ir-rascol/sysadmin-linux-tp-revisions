#!/bin/bash
#
# check-tp.sh — Verification automatique du TP de revisions 1CIEL-IR
# A executer SUR LA VM, en root : sudo ./check-tp.sh
#

SCORE=0
TOTAL=0

VERT="\033[0;32m"
ROUGE="\033[0;31m"
JAUNE="\033[0;33m"
GRAS="\033[1m"
RAZ="\033[0m"

titre() {
    echo
    echo -e "${GRAS}=== $1 ===${RAZ}"
}

# ok <description> <commande...>  -> +1 point si la commande reussit
ok() {
    local desc="$1"; shift
    TOTAL=$((TOTAL + 1))
    if "$@" >/dev/null 2>&1; then
        echo -e "  [${VERT}OK${RAZ}]     $desc"
        SCORE=$((SCORE + 1))
    else
        echo -e "  [${ROUGE}ECHEC${RAZ}]  $desc"
    fi
}

# pas_ok <description> <commande...>  -> +1 point si la commande ECHOUE
pas_ok() {
    local desc="$1"; shift
    TOTAL=$((TOTAL + 1))
    if "$@" >/dev/null 2>&1; then
        echo -e "  [${ROUGE}ECHEC${RAZ}]  $desc"
    else
        echo -e "  [${VERT}OK${RAZ}]     $desc"
        SCORE=$((SCORE + 1))
    fi
}

# groupe_existe <groupe>
groupe_existe() { getent group "$1" >/dev/null; }

# user_existe <user>
user_existe() { id "$1" >/dev/null 2>&1; }

# user_dans_groupe <user> <groupe>
user_dans_groupe() { id -nG "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"; }

# perms <chemin> <octal> <proprietaire> <groupe>
perms() {
    local chemin="$1" attendu="$2" prop="$3" grp="$4"
    [ -e "$chemin" ] || return 1
    local reel
    reel=$(stat -c '%a %U %G' "$chemin") || return 1
    [ "$reel" = "$attendu $prop $grp" ]
}

# contenu_conforme <repertoire> <octal> <proprietaire> <groupe>
# verifie que le repertoire n'est pas vide et que TOUS ses fichiers sont conformes
contenu_conforme() {
    local rep="$1" attendu="$2" prop="$3" grp="$4"
    [ -d "$rep" ] || return 1
    local nb
    nb=$(find "$rep" -type f | wc -l)
    [ "$nb" -gt 0 ] || return 1
    local mauvais
    mauvais=$(find "$rep" -type f ! \( -perm "$attendu" -user "$prop" -group "$grp" \) | wc -l)
    [ "$mauvais" -eq 0 ]
}

echo -e "${GRAS}"
echo "###############################################################"
echo "#   TP de revisions Linux - 1CIEL-IR - Verification           #"
echo "###############################################################"
echo -e "${RAZ}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${ROUGE}Ce script doit etre lance avec sudo : sudo ./check-tp.sh${RAZ}"
    exit 1
fi

# --------------------------------------------------------------------
titre "Mission 4 - Groupes"
for g in gaulois druides guerriers bardes romains; do
    ok "groupe $g existe" groupe_existe "$g"
done

titre "Mission 4 - Utilisateurs"
for u in asterix obelix panoramix assurancetourix jules; do
    ok "utilisateur $u existe" user_existe "$u"
done

titre "Mission 4 - Appartenance aux groupes"
ok "asterix dans gaulois"            user_dans_groupe asterix gaulois
ok "asterix dans guerriers"          user_dans_groupe asterix guerriers
ok "asterix dans sudo"               user_dans_groupe asterix sudo
ok "obelix dans gaulois"             user_dans_groupe obelix gaulois
ok "obelix dans guerriers"           user_dans_groupe obelix guerriers
ok "panoramix dans gaulois"          user_dans_groupe panoramix gaulois
ok "panoramix dans druides"          user_dans_groupe panoramix druides
ok "panoramix dans sudo"             user_dans_groupe panoramix sudo
ok "assurancetourix dans gaulois"    user_dans_groupe assurancetourix gaulois
ok "assurancetourix dans bardes"     user_dans_groupe assurancetourix bardes
ok "jules dans romains"              user_dans_groupe jules romains
pas_ok "jules PAS dans sudo"         user_dans_groupe jules sudo

# --------------------------------------------------------------------
titre "Mission 5 - Repertoires, proprietaires et permissions"
ok "/village/place        775 asterix:gaulois"          perms /village/place  775 asterix gaulois
ok "/village/huttes       750 asterix:gaulois"          perms /village/huttes 750 asterix gaulois
ok "/village/potion       750 panoramix:druides"        perms /village/potion 750 panoramix druides
ok "/village/armes        770 obelix:guerriers"         perms /village/armes  770 obelix guerriers
ok "/village/chants       754 assurancetourix:bardes"   perms /village/chants 754 assurancetourix bardes
ok "/camp-romain          750 jules:romains"            perms /camp-romain    750 jules romains

titre "Mission 5 - Contenu des repertoires (recursivite)"
ok "/village/place  : fichiers presents et conformes"   contenu_conforme /village/place  775 asterix gaulois
ok "/village/potion : fichiers presents et conformes"   contenu_conforme /village/potion 750 panoramix druides
ok "/village/armes  : fichiers presents et conformes"   contenu_conforme /village/armes  770 obelix guerriers
ok "/village/chants : fichiers presents et conformes"   contenu_conforme /village/chants 754 assurancetourix bardes
ok "/camp-romain    : fichiers presents et conformes"   contenu_conforme /camp-romain    750 jules romains

# --------------------------------------------------------------------
titre "Mission 6 - Reseau"

IFACE=$(ip -o -4 route show default | awk '{print $5}' | head -1)
IP_CIDR=$(ip -o -4 addr show dev "$IFACE" 2>/dev/null | awk '{print $4}' | head -1)
GW=$(ip -o -4 route show default | awk '{print $3}' | head -1)
DNS=$(resolvectl dns "$IFACE" 2>/dev/null | awk -F': ' '{print $2}' | tr -d ' ')

echo "  Interface : ${IFACE:-inconnue}"
echo "  Adresse   : ${IP_CIDR:-aucune}"
echo "  Passerelle: ${GW:-aucune}"
echo "  DNS       : ${DNS:-aucun}"
echo

# adresse statique attendue : 192.168.{116|117}.2XX/24
ok "adresse en 192.168.116.2XX/24 ou 192.168.117.2XX/24" \
    grep -qE '^192\.168\.11[67]\.2[0-9]{2}/24$' <<< "$IP_CIDR"

# la passerelle doit etre .254 dans le MEME sous-reseau que l'adresse
SALLE=$(cut -d. -f3 <<< "$IP_CIDR")
ok "passerelle = 192.168.$SALLE.254" \
    test "$GW" = "192.168.$SALLE.254"

ok "DNS = 192.168.100.10"          grep -q '192\.168\.100\.10' <<< "$DNS"
ok "DHCP desactive dans netplan"   grep -rqE 'dhcp4:[[:space:]]*(false|no)' /etc/netplan/
ok "passerelle joignable (ping)"   ping -c 2 -W 2 "$GW"

titre "Mission 6 - Utilisateur pigeon"
ok "utilisateur pigeon existe"     user_existe pigeon
pas_ok "pigeon PAS dans sudo"      user_dans_groupe pigeon sudo
ok "serveur SSH actif"             systemctl is-active --quiet ssh

# --------------------------------------------------------------------
echo
echo -e "${GRAS}###############################################################${RAZ}"
if [ "$SCORE" -eq "$TOTAL" ]; then
    COULEUR=$VERT
elif [ "$SCORE" -ge $((TOTAL * 2 / 3)) ]; then
    COULEUR=$JAUNE
else
    COULEUR=$ROUGE
fi
echo -e "${GRAS}   RESULTAT : ${COULEUR}$SCORE / $TOTAL${RAZ}${GRAS} verifications reussies${RAZ}"
echo -e "${GRAS}###############################################################${RAZ}"
echo

if [ "$SCORE" -ne "$TOTAL" ]; then
    echo "Reprenez les points marques [ECHEC] ci-dessus."
    exit 1
fi
echo "Felicitations, appelez l'enseignant pour la validation !"
