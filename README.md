
# MirrorScreen Pro - Application de Screen Mirroring

Application Flutter professionnelle pour diffuser l'écran de votre téléphone sur une TV/décodeur via WiFi avec découverte automatique des appareils.

## 🌟 Fonctionnalités

* ✅ **Découverte automatique** des appareils compatibles (TV, Chromecast, Miracast, DLNA)
* ✅ **Connexion directe** sans QR code ni application tierce
* ✅ **Adaptation automatique** de la résolution selon l'écran cible
* ✅ **Support multi-protocoles** : DLNA, Chromecast, Miracast
* ✅ **Qualité adaptative** selon la bande passante
* ✅ **Interface moderne** avec animations fluides
* ✅ **Statistiques en temps réel** (FPS, débit, qualité)

## 📋 Prérequis

* Flutter SDK ≥ 3.0.0
* Android SDK ≥ 21 (Android 5.0 Lollipop)
* Un appareil compatible : Smart TV, Chromecast, Miracast ou DLNA

## 🚀 Installation

### 1. Cloner le projet

```bash
git clone <repository-url>
cd malobab-screenmirroring
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configuration Android

Ajoutez les permissions suivantes dans `android/app/src/main/AndroidManifest.xml` (déjà incluses) :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECORD_DISPLAY"/>
```

### 4. Configuration native (Important)

Le fichier `MainActivity.kt` contient déjà l'implémentation de la capture d'écran via `MediaProjection`.

**Vérifications importantes :**

* Assurez-vous que les versions de Gradle sont correctes
* Kotlin version : 2.2.20
* Android Gradle Plugin : 8.11.1

## 🏗️ Architecture

```
lib/
├── core/
│   ├── di/                      # Injection de dépendances
│   ├── services/                # Services principaux
│   │   ├── device_discovery_service.dart    # Découverte appareils
│   │   ├── mirroring_service.dart           # Service mirroring
│   │   └── permission_service.dart          # Gestion permissions
│   └── theme/                   # Thème de l'application
├── data/                        # Couche données
├── domain/
│   ├── entities/                # Entités métier
│   │   └── discovered_device.dart
│   └── repositories/            # Interfaces repositories
└── presentation/
    ├── bloc/                    # Gestion d'état
    │   ├── device_discovery/    # BLoC découverte
    │   └── mirroring/           # BLoC mirroring
    ├── pages/
    │   ├── home_page.dart       # Page principale
    │   └── device_list_page.dart # Liste appareils
    └── widgets/                 # Composants UI
```

## 🔧 Utilisation

### 1. Démarrage de l'application

```bash
flutter run
```

### 2. Workflow utilisateur

1. **Lancez l'application** sur votre téléphone
2. **Appuyez sur "Rechercher des appareils"**
   * L'application scanne automatiquement le réseau WiFi
   * Les appareils compatibles s'affichent avec leurs caractéristiques
3. **Sélectionnez votre TV/décodeur**
   * Un simple tap sur l'appareil le sélectionne
   * Les informations de l'appareil s'affichent
4. **Ajustez les paramètres** (optionnel)
   * Qualité : 10-100%
   * Qualité adaptative : ajustement automatique
5. **Appuyez sur "Démarrer le mirroring"**
   * Une permission Android sera demandée
   * Le streaming commence automatiquement

## 🎯 Protocoles supportés

### DLNA (Digital Living Network Alliance)

* **Port** : Variable (généralement 8080)
* **Service mDNS** : `_dlna._tcp`
* Compatible avec la majorité des Smart TV

### Chromecast

* **Port** : 8008, 8009
* **Service mDNS** : `_googlecast._tcp`
* Qualité optimale pour streaming

### Miracast

* **Port** : Variable
* **Service mDNS** : `_miracast._tcp`
* Standard WiFi Direct pour mirroring

### Smart TV génériques

* **Ports** : 8008, 8009, 9080, 7000, 55000
* Détection par scan réseau

## 📊 Adaptation de la résolution

L'application adapte automatiquement la résolution selon l'écran cible :

| Résolution écran  | Résolution envoyée | FPS   |
| ------------------- | -------------------- | ----- |
| 4K (3840x2160)      | 3840x2160            | 60    |
| Full HD (1920x1080) | 1920x1080            | 30    |
| HD (1280x720)       | 1280x720             | 30    |
| Autre               | Résolution native   | 24-30 |

## 🛠️ Dépannage

### Aucun appareil détecté

1. **Vérifiez votre réseau WiFi**
   * Téléphone et TV sur le même réseau
   * Pas de réseau invité (Guest Network)
2. **Redémarrez votre TV/décodeur**
   * Certains appareils nécessitent un redémarrage
3. **Activez les fonctionnalités de mirroring**
   * Smart View (Samsung)
   * Screen Mirroring (LG, Sony)
   * Cast (Android TV)

### Qualité de streaming faible

1. **Rapprochez-vous du routeur WiFi**
2. **Réduisez la qualité** dans les paramètres
3. **Activez la qualité adaptative**
4. **Fermez les autres applications** consommant de la bande passante

### Permission refusée

1. Allez dans **Paramètres Android > Apps > MirrorScreen Pro**
2. Accordez toutes les permissions demandées
3. Relancez l'application

## 🔐 Permissions requises

| Permission           | Utilisation                           |
| -------------------- | ------------------------------------- |
| INTERNET             | Communication réseau                 |
| ACCESS_WIFI_STATE    | Détection réseau WiFi               |
| ACCESS_NETWORK_STATE | État de la connexion                 |
| FOREGROUND_SERVICE   | Service de mirroring en arrière-plan |
| WAKE_LOCK            | Éviter la mise en veille             |
| RECORD_DISPLAY       | Capture de l'écran                   |

## 📱 Compatibilité

### Téléphones

* Android 5.0 (API 21) et supérieur
* iOS : Non supporté (limitations système)

### Appareils récepteurs

* ✅ Smart TV Samsung (2016+)
* ✅ Smart TV LG (2017+)
* ✅ Android TV
* ✅ Chromecast (toutes versions)
* ✅ Amazon Fire TV
* ✅ Apple TV (via AirPlay)
* ✅ Tout appareil DLNA/UPnP

## 🎨 Personnalisation

### Thème

Modifiez `lib/core/theme/app_theme.dart` pour personnaliser :

* Couleurs primaires/secondaires
* Typographie
* Styles de boutons
* Animations

### Qualité par défaut

Ajustez dans `lib/presentation/widgets/control_panel.dart` :

```dart
double _quality = 70; // 10-100
bool _adaptiveQuality = true;
```

## 📝 Notes importantes

1. **Latence** : Une latence de 50-200ms est normale
2. **Applications protégées** : Netflix, Amazon Prime, etc. peuvent bloquer la capture
3. **Performances** : Dépendent de votre WiFi et de l'appareil
4. **Batterie** : Le mirroring consomme beaucoup d'énergie

## 🚧 Limitations connues

* La capture d'écran ne fonctionne pas avec du contenu DRM protégé
* Certaines applications bancaires bloquent la capture
* Le son n'est pas transmis (limitation Android)

## 📄 Licence

Ce projet est sous licence MIT.

## 👥 Support

Pour tout problème ou question :

1. Consultez la section Dépannage
2. Vérifiez les Issues GitHub
3. Créez une nouvelle Issue avec les détails

## 🔄 Mises à jour futures

* [ ] Support audio via Bluetooth
* [ ] Enregistrement des sessions
* [ ] Support multi-appareils simultanés
* [ ] Mode picture-in-picture
* [ ] Contrôle à distance du téléphone

---

**Développé avec ❤️ en Flutter**
