# Annexe — Créer une clé SSH et l'associer à GitHub

Cette annexe explique comment créer une paire de clés SSH sur **votre poste** et déclarer la clé publique sur GitHub. C'est un prérequis à la mission 1 du TP.

> [!IMPORTANT]
> Toutes les commandes de cette annexe s'exécutent sur **votre poste Ubuntu Desktop**, jamais sur la VM. La raison est expliquée à la section « [Pourquoi jamais sur la VM ?](#pourquoi-jamais-sur-la-vm) ».

---

## 1. Le principe : une paire de clés

L'authentification par clé SSH repose sur **deux fichiers indissociables** :

| Fichier | Nom | Rôle | Se partage ? |
| --- | --- | --- | :---: |
| Clé **privée** | `id_ed25519` | Prouve votre identité. C'est votre secret. | ❌ **Jamais** |
| Clé **publique** | `id_ed25519.pub` | Se dépose sur les serveurs (ici GitHub). | ✅ Oui |

Le serveur détient votre clé publique. Lors de la connexion, il vous envoie un défi que **seule** la clé privée correspondante sait résoudre. Votre secret ne circule jamais sur le réseau.

> [!WARNING]
> **La clé privée ne quitte jamais la machine où elle a été générée.**
>
> On ne la copie pas sur une VM, on ne l'envoie pas par mail, on ne la met pas sur une clé USB, on ne la committe **jamais** dans un dépôt Git. Si elle fuite, celui qui la détient peut se faire passer pour vous.

---

## 2. Vérifier si vous avez déjà une clé

Sur votre poste, ouvrez un terminal (`Ctrl` + `Alt` + `T`) :

```bash
ls -l ~/.ssh/
```

Si vous voyez un couple `id_ed25519` / `id_ed25519.pub` (ou `id_rsa` / `id_rsa.pub`), vous avez déjà une clé : passez directement à l'étape 4.

Si le dossier n'existe pas ou est vide, continuez.

---

## 3. Générer la paire de clés

```bash
ssh-keygen -t ed25519 -C "votre.email@exemple.fr"
```

- `-t ed25519` : l'algorithme recommandé aujourd'hui (plus court et plus sûr que RSA).
- `-C` : un simple commentaire pour identifier la clé, mettez l'adresse de votre compte GitHub.

Trois questions vous sont posées :

| Question | Que répondre |
| --- | --- |
| `Enter file in which to save the key` | **Entrée** (accepte le chemin par défaut `~/.ssh/id_ed25519`) |
| `Enter passphrase` | Une phrase de passe, ou **Entrée** pour aucune (voir l'encadré ci-dessous) |
| `Enter same passphrase again` | La même chose |

> [!NOTE]
> **Faut-il mettre une phrase de passe ?**
>
> Elle chiffre votre clé privée sur le disque : même volée, elle reste inutilisable sans cette phrase. C'est la bonne pratique.
>
> En contrepartie, elle vous sera demandée à chaque utilisation de la clé — sauf si vous utilisez `ssh-agent` (étape 5), qui la retient pour la durée de votre session. **Sur les postes du lycée, partagés entre plusieurs personnes, mettez-en une.**

Vérifiez le résultat :

```bash
ls -l ~/.ssh/
```

Vous devez voir les deux fichiers. Notez leurs permissions : `600` pour la clé privée (lecture/écriture pour vous seul) — SSH **refuse** de fonctionner si elle est lisible par d'autres.

---

## 4. Déclarer la clé publique sur GitHub

### 4.1 — Afficher la clé publique

```bash
cat ~/.ssh/id_ed25519.pub
```

Vous obtenez **une seule ligne** de cette forme :

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... votre.email@exemple.fr
```

Sélectionnez-la **entièrement** (de `ssh-ed25519` jusqu'à la fin) et copiez-la.

> [!WARNING]
> Vérifiez que vous affichez bien le fichier **`.pub`**. Si la sortie commence par `-----BEGIN OPENSSH PRIVATE KEY-----`, vous êtes en train d'afficher votre clé **privée** : n'en copiez rien nulle part.

### 4.2 — L'ajouter au compte GitHub

1. Connectez-vous à [github.com](https://github.com).
2. Cliquez sur votre avatar (en haut à droite) → **Settings**.
3. Dans le menu de gauche : **SSH and GPG keys**.
4. Bouton **New SSH key**.
5. Remplissez :
   - **Title** : un nom qui identifie la machine, par exemple `Poste D116-10`
   - **Key type** : `Authentication Key`
   - **Key** : collez la ligne copiée à l'étape 4.1
6. Cliquez sur **Add SSH key**.

### 4.3 — Tester la connexion

```bash
ssh -T git@github.com
```

À la première connexion, SSH demande de confirmer l'empreinte du serveur : répondez `yes`.

Réponse attendue :

```text
Hi VOTRE_PSEUDO! You've successfully authenticated, but GitHub does not provide shell access.
```

> [!NOTE]
> Le message « does not provide shell access » est **normal** : GitHub n'est pas un serveur sur lequel on ouvre une session, il n'accepte que les opérations Git. Voir votre pseudo affiché signifie que l'authentification fonctionne.

---

## 5. `ssh-agent` : ne pas retaper sa phrase de passe

`ssh-agent` garde votre clé déverrouillée en mémoire pour la durée de la session.

```bash
# Démarrer l'agent (souvent déjà lancé par la session graphique)
eval "$(ssh-agent -s)"

# Ajouter votre clé (la phrase de passe est demandée une fois)
ssh-add ~/.ssh/id_ed25519

# Vérifier les clés chargées
ssh-add -l
```

C'est aussi ce qui rend possible le **transfert d'agent** décrit à la section suivante.

---

## 6. Travailler depuis la VM : le transfert d'agent (`ssh -A`)

Dans ce TP, vous clonez votre dépôt **depuis la VM**. Or votre clé privée est sur votre **poste**, et elle doit y rester.

La solution est le **transfert d'agent** (*agent forwarding*) : la VM emprunte l'agent de votre poste pour s'authentifier auprès de GitHub, sans jamais recevoir la clé elle-même.

```bash
# Depuis votre poste, connectez-vous à la VM avec l'option -A
ssh -A etudiant@ADRESSE_IP_DE_LA_VM
```

Une fois sur la VM, vérifiez que le transfert fonctionne :

```bash
ssh-add -l          # doit lister votre clé
ssh -T git@github.com   # doit afficher "Hi VOTRE_PSEUDO!"
```

Vous pouvez alors cloner en SSH depuis la VM :

```bash
git clone git@github.com:VOTRE_PSEUDO/sysadmin-linux-tp-revisions.git
```

### Ce qui se passe réellement

```text
  Votre poste                          La VM                        GitHub
  ┌────────────────┐                ┌──────────┐                 ┌────────┐
  │ clé privée 🔑  │                │          │                 │        │
  │ ssh-agent      │◄───────────────┤ git push ├────────────────►│  clé   │
  └────────────────┘   le défi      └──────────┘   authentifié   │publique│
                       revient au                                 └────────┘
                       poste pour
                       être signé

  La clé privée ne quitte JAMAIS le poste.
```

> [!WARNING]
> **N'utilisez `-A` que vers des machines de confiance.**
>
> Pendant la connexion, l'administrateur de la machine distante peut se servir de votre agent pour s'authentifier en votre nom. Ici, la VM est la vôtre : c'est sans risque. Ne le faites pas vers un serveur inconnu.

### <a name="pourquoi-jamais-sur-la-vm"></a>Pourquoi ne pas simplement copier la clé privée sur la VM ?

C'est tentant, et c'est une mauvaise habitude à ne pas prendre :

- **La VM est jetable.** Elle est importée, réinitialisée, parfois partagée. Votre clé y survivrait à votre insu.
- **Elle multiplie les copies de votre secret.** Une clé privée sur plusieurs machines, c'est autant d'occasions de fuite, et aucun moyen de savoir laquelle a fuité.
- **Le dépôt est cloné sur la VM.** Un `git add .` malheureux, et votre clé privée part sur GitHub, publiquement.
- **Vous n'en avez pas besoin** : `ssh -A` résout le problème proprement.

Générer une **seconde** clé, propre à la VM, serait acceptable techniquement — mais inutile ici, et cela vous ferait gérer deux clés au lieu d'une.

---

## 7. En cas de problème

| Symptôme | Cause probable | Solution |
| --- | --- | --- |
| `Permission denied (publickey)` depuis le poste | Clé non déclarée sur GitHub, ou pas la bonne | Refaire l'étape 4, vérifier avec `ssh -T git@github.com` |
| `Permission denied (publickey)` depuis la VM | Connexion faite **sans** `-A` | Se déconnecter, refaire `ssh -A etudiant@IP_VM` |
| `ssh-add -l` répond `Could not open a connection to your authentication agent` | Agent non démarré | `eval "$(ssh-agent -s)"` puis `ssh-add ~/.ssh/id_ed25519` |
| `ssh-add -l` répond `The agent has no identities` | Clé non chargée dans l'agent | `ssh-add ~/.ssh/id_ed25519` sur le **poste** |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` | Permissions trop ouvertes | `chmod 600 ~/.ssh/id_ed25519` |
| `git push` demande un identifiant et un mot de passe | Le dépôt est cloné en **HTTPS**, pas en SSH | Voir ci-dessous |

### Convertir un clone HTTPS en SSH

Si vous avez cloné par erreur en HTTPS, inutile de tout refaire :

```bash
# Vérifier l'URL actuelle
git remote -v

# La remplacer par l'URL SSH
git remote set-url origin git@github.com:VOTRE_PSEUDO/sysadmin-linux-tp-revisions.git

# Vérifier
git remote -v
```

### Reconnaître les deux formats d'URL

| Protocole | Forme de l'URL |
| --- | --- |
| SSH ✅ | `git@github.com:PSEUDO/depot.git` |
| HTTPS ❌ | `https://github.com/PSEUDO/depot.git` |

Sur GitHub, le bouton vert **Code** propose les deux : pensez à sélectionner l'onglet **SSH**.
