# 🍎 Générer l'application iOS sans Mac

Puisque vous développez uniquement sous Windows, voici plusieurs méthodes pour générer l'IPA iOS sans avoir de Mac.

## 🚀 Méthode 1 : GitHub Actions (Gratuit - Recommandé)

GitHub Actions permet de build iOS automatiquement sur un Mac virtuel dans le cloud.

### Étape 1 : Créer un compte GitHub (si vous n'en avez pas)
1. Allez sur [github.com](https://github.com)
2. Créez un compte gratuit

### Étape 2 : Créer un dépôt
1. Cliquez sur **"New repository"**
2. Nommez-le (ex: `kcl-app`)
3. Choisissez **Private** (pour garder votre code privé)
4. Cliquez sur **"Create repository"**

### Étape 3 : Pousser votre code
```bash
# Dans votre projet
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/VOTRE_USERNAME/kcl-app.git
git push -u origin main
```

### Étape 4 : Configurer le workflow
1. Le fichier `.github/workflows/build_ios.yml` est déjà créé dans votre projet
2. Poussez-le sur GitHub :
```bash
git add .github/workflows/build_ios.yml
git commit -m "Add iOS build workflow"
git push
```

### Étape 5 : Lancer le build
1. Allez sur votre dépôt GitHub
2. Cliquez sur l'onglet **"Actions"**
3. Sélectionnez **"Build iOS"** dans le menu de gauche
4. Cliquez sur **"Run workflow"**
5. Choisissez **release** ou **debug**
6. Cliquez sur **"Run workflow"**

### Étape 6 : Télécharger l'IPA
1. Attendez la fin du build (5-10 minutes)
2. Cliquez sur le workflow terminé
3. Dans la section **"Artifacts"**, cliquez sur **"ios-release"**
4. Téléchargez le fichier ZIP
5. Extrayez l'IPA

**⚠️ Note :** L'IPA généré ne sera **pas signé**. Pour l'installer sur un iPhone, vous devrez :
- Soit le signer avec un certificat Apple (nécessite un compte développeur)
- Soit utiliser TestFlight (voir ci-dessous)

---

## 🎯 Méthode 2 : Codemagic (Gratuit jusqu'à 500 min/mois)

Codemagic est un service spécialisé dans le build d'applications Flutter.

### Étape 1 : Créer un compte
1. Allez sur [codemagic.io](https://codemagic.io)
2. Créez un compte avec GitHub

### Étape 2 : Ajouter votre application
1. Cliquez sur **"Add application"**
2. Sélectionnez votre dépôt GitHub
3. Choisissez **Flutter** comme type

### Étape 3 : Configurer le build iOS
1. Dans les paramètres, activez **iOS**
2. Configurez votre certificat de signature (si vous en avez un)
3. Cliquez sur **"Start new build"**

### Étape 4 : Télécharger l'IPA
1. Attendez la fin du build
2. Téléchargez l'IPA depuis l'interface

---

## 📱 Méthode 3 : AppCircle (Gratuit)

AppCircle est un autre service de CI/CD pour mobile.

1. Allez sur [appcircle.io](https://appcircle.io)
2. Créez un compte
3. Connectez votre dépôt GitHub
4. Configurez le build iOS
5. Lancez le build

---

## 🔐 Signer l'IPA pour l'installation

### Option A : TestFlight (Recommandé - Gratuit)

1. **Créer un compte App Store Connect** :
   - Allez sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Créez un compte développeur (99$/an) ou utilisez un compte existant

2. **Créer une nouvelle app** :
   - Cliquez sur **"My Apps"** > **"+"**
   - Remplissez les informations

3. **Téléverser l'IPA** :
   - Utilisez **Transporter** (Mac) ou **Xcode** (Mac)
   - Ou utilisez un service cloud qui peut signer automatiquement

4. **Ajouter des testeurs** :
   - Allez dans **TestFlight**
   - Ajoutez les emails des testeurs
   - Ils recevront une invitation

### Option B : Signer avec un certificat (Complexe)

Pour signer l'IPA sans Mac, vous pouvez utiliser :
- **AppSigner** (nécessite un Mac)
- **fastlane** (nécessite un Mac)
- Services cloud comme **Codemagic** ou **AppCircle** qui gèrent la signature

---

## 🛠️ Configuration requise pour GitHub Actions

Le fichier `.github/workflows/build_ios.yml` est déjà configuré. Il :
- ✅ Build automatiquement l'IPA
- ✅ Le télécharge comme artifact
- ✅ Crée une release GitHub (optionnel)

### Personnaliser le workflow

Si vous voulez modifier le workflow, éditez `.github/workflows/build_ios.yml` :

```yaml
# Changer la version de Flutter
flutter-version: '3.24.0'  # Modifiez selon vos besoins

# Ajouter la signature (nécessite des secrets GitHub)
# Voir la documentation GitHub Actions pour plus d'infos
```

---

## 📦 Structure après build

Après le build GitHub Actions, vous aurez :
```
releases/
└── kcl_app_release.ipa  (ou kcl_app_debug.ipa)
```

---

## 🚨 Limitations

1. **IPA non signé** : L'IPA généré par GitHub Actions n'est pas signé
   - Solution : Utilisez TestFlight ou un service qui gère la signature

2. **Temps de build** : 5-10 minutes par build
   - Solution : C'est normal, le Mac virtuel doit être démarré

3. **Limite GitHub Actions** : 2000 minutes/mois gratuites
   - Solution : Suffisant pour plusieurs builds

---

## 💡 Recommandation

**Pour un usage simple** :
1. Utilisez **GitHub Actions** (gratuit, facile)
2. Téléversez l'IPA sur **TestFlight** via un Mac emprunté ou un service cloud
3. Distribuez via TestFlight (gratuit, jusqu'à 10 000 testeurs)

**Pour un usage professionnel** :
1. Utilisez **Codemagic** (meilleure intégration Flutter)
2. Configurez la signature automatique
3. Distribuez via TestFlight ou App Store

---

## 📞 Support

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation Codemagic](https://docs.codemagic.io)
- [Documentation Flutter iOS](https://flutter.dev/docs/deployment/ios)

---

## ⚡ Quick Start

1. **Créez un dépôt GitHub**
2. **Poussez votre code** :
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/VOTRE_USERNAME/kcl-app.git
   git push -u origin main
   ```
3. **Allez dans Actions** > **Build iOS** > **Run workflow**
4. **Téléchargez l'IPA** depuis les Artifacts

C'est tout ! 🎉

