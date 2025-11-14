# 🚀 Générer l'IPA iOS Maintenant - Guide Pas à Pas

## ⚡ Méthode Rapide : GitHub Actions

### Étape 1 : Installer Git (si pas déjà fait)
Téléchargez Git : https://git-scm.com/download/win

### Étape 2 : Créer un compte GitHub
1. Allez sur https://github.com
2. Créez un compte (gratuit)
3. Confirmez votre email

### Étape 3 : Créer un nouveau dépôt
1. Cliquez sur le **"+"** en haut à droite > **"New repository"**
2. Nommez-le : `kcl-app` (ou autre nom)
3. Choisissez **Private** (pour garder votre code privé)
4. **NE COCHEZ PAS** "Add a README file"
5. Cliquez sur **"Create repository"**

### Étape 4 : Initialiser Git dans votre projet
Ouvrez PowerShell ou CMD dans le dossier de votre projet et exécutez :

```bash
# Initialiser Git
git init

# Ajouter tous les fichiers
git add .

# Créer le premier commit
git commit -m "Initial commit - KCL App"

# Ajouter le dépôt distant (remplacez VOTRE_USERNAME par votre nom d'utilisateur GitHub)
git remote add origin https://github.com/VOTRE_USERNAME/kcl-app.git

# Pousser le code
git branch -M main
git push -u origin main
```

**⚠️ Important :** Remplacez `VOTRE_USERNAME` par votre vrai nom d'utilisateur GitHub !

### Étape 5 : Lancer le build iOS
1. Allez sur votre dépôt GitHub : `https://github.com/VOTRE_USERNAME/kcl-app`
2. Cliquez sur l'onglet **"Actions"** (en haut)
3. Si c'est la première fois, cliquez sur **"I understand my workflows, go ahead and enable them"**
4. Dans le menu de gauche, cliquez sur **"Build iOS"**
5. Cliquez sur le bouton **"Run workflow"** (à droite)
6. Dans le menu déroulant, choisissez :
   - **Build type** : `release` (pour production)
7. Cliquez sur le bouton vert **"Run workflow"**

### Étape 6 : Attendre le build
- Le build prendra **5-10 minutes**
- Vous verrez une barre de progression
- Attendez que le statut passe à **✅ vert**

### Étape 7 : Télécharger l'IPA
1. Une fois le build terminé (✅ vert), cliquez dessus
2. Faites défiler jusqu'à la section **"Artifacts"**
3. Cliquez sur **"ios-release"** (ou "ios-debug" si vous avez choisi debug)
4. Le fichier ZIP se téléchargera automatiquement
5. Extrayez le ZIP pour obtenir l'IPA

### Étape 8 : Utiliser l'IPA
L'IPA généré n'est **pas signé**. Pour l'installer sur iPhone :

**Option A : TestFlight (Recommandé)**
1. Créez un compte sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Créez une nouvelle app
3. Téléversez l'IPA via Transporter (Mac) ou Xcode (Mac)
4. Distribuez via TestFlight

**Option B : Signer l'IPA**
- Utilisez un service cloud comme Codemagic qui peut signer automatiquement
- Ou utilisez un Mac pour signer avec Xcode

---

## 🆘 Dépannage

### Erreur : "Repository not found"
- Vérifiez que vous avez bien créé le dépôt sur GitHub
- Vérifiez que l'URL du remote est correcte

### Erreur : "Authentication failed"
- GitHub peut demander un token d'authentification
- Créez un Personal Access Token : Settings > Developer settings > Personal access tokens
- Utilisez-le comme mot de passe lors du push

### Le workflow ne s'affiche pas
- Vérifiez que le fichier `.github/workflows/build_ios.yml` est bien dans votre projet
- Vérifiez que vous l'avez bien poussé sur GitHub

### Le build échoue
- Vérifiez les logs dans l'onglet Actions
- Assurez-vous que `pubspec.yaml` est correct
- Vérifiez que toutes les dépendances sont valides

---

## 📝 Commandes Rapides

```bash
# Vérifier si Git est installé
git --version

# Vérifier le statut
git status

# Voir les remotes
git remote -v

# Si vous devez changer l'URL du remote
git remote set-url origin https://github.com/VOTRE_USERNAME/kcl-app.git
```

---

## ✅ Checklist

- [ ] Git installé
- [ ] Compte GitHub créé
- [ ] Dépôt GitHub créé
- [ ] Code poussé sur GitHub
- [ ] Workflow "Build iOS" lancé
- [ ] Build terminé avec succès
- [ ] IPA téléchargé

---

## 🎯 Résultat Attendu

Vous obtiendrez un fichier `kcl_app_release.ipa` que vous pourrez :
- Télécharger sur votre PC
- Téléverser sur TestFlight
- Distribuer à vos utilisateurs

---

**Besoin d'aide ?** Consultez `BUILD_IOS_SANS_MAC.md` pour plus de détails.

