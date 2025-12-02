
# MirrorScreen Pro

Application Flutter professionnelle de screen mirroring permettant d'afficher l'écran de votre téléphone sur une télévision via WiFi.

## 🎯 Fonctionnalités

* **Mirroring en temps réel** : Diffusion de l'écran à 30 FPS
* **Qualité ajustable** : Contrôle de la qualité de 10% à 100%
* **Connexion WiFi** : Aucun câble nécessaire
* **QR Code** : Connexion rapide via scan
* **Statistiques en direct** : FPS, débit, durée, nombre d'images
* **Interface moderne** : Design élégant avec animations fluides
* **Arrière-plan** : Fonctionne même quand l'app est en arrière-plan

## 🏗️ Architecture

L'application suit une architecture Clean Architecture avec:

### Domain Layer

* **Entities** : `ConnectionInfo`, `MirroringStats`
* **Repositories** : Interfaces abstraites
* **Use Cases** : `StartMirroring`, `StopMirroring`, `GetConnectionInfo`

### Data Layer

* **Data Sources** : `ScreenCaptureSource`, `NetworkSource`
* **Repository Implementation** : `MirroringRepositoryImpl`

### Presentation Layer

* **BLoC** : Gestion d'état avec `flutter_bloc`
* **Pages** : Interface utilisateur
* **Widgets** : Composants réutilisables

### Core

* **Services** : `WebSocketService`, `ScreenCaptureService`, `PermissionService`
* **Dependency Injection** : `get_it`
* **Theme** : Configuration du design

## 📦 Installation

### Prérequis

* Flutter SDK 3.0+
* Dart 3.0+
* Android Studio / Xcode

### Étapes

1. Clonez le repository :

```bash
git clone https://github.com/votre-repo/mirror_screen.git
cd mirror_screen
```

2. Installez les dépendances :

```bash
flutter pub get
```

3. Lancez l'application :

```bash
flutter run
```

## 🔧 Configuration Android

### Permissions requises

Les permissions suivantes sont automatiquement demandées :

* `INTERNET` : Connexion réseau
* `ACCESS_WIFI_STATE` : État du WiFi
* `ACCESS_NETWORK_STATE` : État du réseau
* `FOREGROUND_SERVICE` : Service en arrière-plan
* `RECORD_DISPLAY` : Capture d'écran

### Code natif

Le code Kotlin dans `MainActivity.kt` utilise l'API MediaProjection pour capturer l'écran.

## 🎨 Personnalisation

### Thème

Modifiez `lib/core/theme/app_theme.dart` pour personnaliser :

* Couleurs primaires et secondaires
* Police de caractères
* Styles des composants

### Qualité par défaut

Dans `lib/presentation/widgets/control_panel.dart` :

```dart
double _quality = 70; // Modifiez cette valeur (10-100)
```

### FPS

Dans `lib/data/repositories/mirroring_repository_impl.dart` :

```dart
await screenCaptureSource.startCapture(
  fps: 30, // Modifiez cette valeur
  quality: quality,
);
```

## 📱 Utilisation

1. **Lancez l'application** sur votre téléphone
2. **Connectez-vous au même WiFi** que votre TV/décodeur
3. **Scannez le QR code** affiché ou entrez l'URL manuellement
4. **Appuyez sur "Démarrer"** pour commencer le mirroring
5. **Consultez les statistiques** en temps réel

## 🔌 Côté Récepteur (TV/Décodeur)

Vous devez créer une application récepteur qui :

1. Se connecte au WebSocket à l'adresse affichée
2. Reçoit les frames JPEG via WebSocket
3. Les affiche à l'écran

Exemple en HTML/JavaScript :

```javascript
const ws = new WebSocket('ws://[IP]:8080');
ws.binaryType = 'arraybuffer';

ws.onmessage = (event) => {
  const blob = new Blob([event.data], { type: 'image/jpeg' });
  const url = URL.createObjectURL(blob);
  document.getElementById('screen').src = url;
};
```

## 🛠️ Dépendances principales

* `flutter_bloc` : Gestion d'état
* `get_it` : Injection de dépendances
* `web_socket_channel` : Communication WebSocket
* `network_info_plus` : Informations réseau
* `qr_flutter` : Génération QR codes
* `google_fonts` : Polices personnalisées
* `flutter_animate` : Animations

## 📝 Bonnes pratiques implémentées

✅ **Separation of Concerns** : Couches Domain/Data/Presentation distinctes

✅ **Dependency Injection** : via GetIt

✅ **Repository Pattern** : Abstraction des sources de données

✅ **BLoC Pattern** : Gestion d'état prévisible

✅ **Use Cases** : Logique métier isolée

✅ **Error Handling** : Gestion complète des erreurs

✅ **Stream Management** : Gestion propre des flux de données

✅ **Responsive Design** : Interface adaptative

✅ **Clean Code** : Code lisible et maintenable

## 🐛 Résolution de problèmes

### L'écran ne se capture pas

* Vérifiez que les permissions sont accordées
* Redémarrez l'application
* Vérifiez la version Android (5.0+ requis)

### Connexion impossible

* Vérifiez que le téléphone et la TV sont sur le même réseau WiFi
* Désactivez les pare-feu
* Vérifiez que le port 8080 n'est pas bloqué

### Performances faibles

* Réduisez la qualité dans les paramètres
* Fermez les applications en arrière-plan
* Vérifiez la qualité de votre connexion WiFi

## 📄 Licence

MIT License - Voir le fichier LICENSE pour plus de détails

## 👥 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 🙏 Remerciements

* Flutter team pour l'excellent framework
* La communauté open source pour les packages utilisés
