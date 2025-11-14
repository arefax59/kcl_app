# 🍎 Build iOS depuis Windows - Guide Rapide

## 🎯 Solution Recommandée : GitHub Actions

### Étapes rapides :

1. **Créez un compte GitHub** : [github.com](https://github.com)

2. **Créez un nouveau dépôt** (Private ou Public)

3. **Poussez votre code** :
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/VOTRE_USERNAME/kcl-app.git
   git push -u origin main
   ```

4. **Lancez le build** :
   - Allez dans **Actions** > **Build iOS**
   - Cliquez sur **"Run workflow"**
   - Choisissez **release**
   - Cliquez sur **"Run workflow"**

5. **Téléchargez l'IPA** :
   - Attendez 5-10 minutes
   - Cliquez sur le workflow terminé
   - Téléchargez l'artifact **"ios-release"**

### ⚠️ Important

L'IPA généré n'est **pas signé**. Pour l'installer sur iPhone :
- Utilisez **TestFlight** (nécessite un compte développeur Apple)
- Ou signez-le avec un certificat (nécessite un Mac ou service cloud)

---

## 📖 Guide Complet

Voir `BUILD_IOS_SANS_MAC.md` pour :
- Détails complets GitHub Actions
- Alternatives (Codemagic, AppCircle)
- Comment signer l'IPA
- Configuration TestFlight

---

## 🚀 Alternative : Services Cloud

- **Codemagic** : [codemagic.io](https://codemagic.io) - Spécialisé Flutter
- **AppCircle** : [appcircle.io](https://appcircle.io) - CI/CD mobile
- **Bitrise** : [bitrise.io](https://bitrise.io) - CI/CD généraliste

Tous offrent des plans gratuits pour commencer.

