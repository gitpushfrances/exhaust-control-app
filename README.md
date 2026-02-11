# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones.

---

## 📱 Project Overview

### **What It Does:**
- 🔗 **Bluetooth Control:** Connects to motorcycle exhaust controller hardware
- 📍 **GPS Automation:** Automatically closes exhaust when entering restricted areas
- 🗺️ **Zone Management:** Add and manage noise-restricted zones
- 📊 **Statistics:** Track trips, auto-closures, and usage patterns
- 👤 **User Accounts:** Firebase authentication and cloud sync

### **Technology Stack:**
- **Frontend:** Flutter 3.10+
- **Backend:** Firebase (Auth, Firestore)
- **Hardware:** Bluetooth Low Energy (BLE)
- **Maps:** OpenStreetMap (planned)
- **State Management:** Provider

---

## 🎯 Current Status: 55% Complete

### ✅ **Completed Features:**
- [x] User authentication (login/signup)
- [x] Professional UI with custom components
- [x] 4-tab navigation system (Home, Map, Stats, Profile)
- [x] Permission system (Bluetooth, GPS)
- [x] Beautiful dialogs and animations
- [x] Statistics dashboard
- [x] Restricted area model with GPS detection

### 🔄 **In Progress:**
- [ ] ReWatch logo integration (80% complete)

### ⏸️ **Planned:**
- [ ] Real Bluetooth device scanning
- [ ] Hardware connection and control
- [ ] Live GPS tracking
- [ ] OpenStreetMap integration
- [ ] Automatic exhaust control logic

---

## 🚀 Getting Started

### **Prerequisites:**
```bash
Flutter SDK: >=3.10.8
Dart SDK: >=3.0.0
Android Studio / Xcode
Firebase project configured
```

### **Installation:**

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/exhaust_controller_app.git
cd exhaust_controller_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Add logo asset** (if available)
```bash
# Place your logo file here:
assets/images/logo.png
```

4. **Generate app icons** (after adding logo)
```bash
flutter pub run flutter_launcher_icons
```

5. **Configure Firebase**
```bash
# Add your google-services.json to android/app/
# Add your GoogleService-Info.plist to ios/Runner/
```

6. **Run the app**
```bash
flutter run
```

---

## 📦 Dependencies

### **Core Packages:**
```yaml
firebase_core: ^4.4.0          # Firebase initialization
firebase_auth: ^6.1.4          # User authentication
cloud_firestore: ^6.1.2        # Database
provider: ^6.1.5+1             # State management
```

### **Hardware Integration:**
```yaml
flutter_blue_plus: ^2.1.0      # Bluetooth connectivity
geolocator: ^14.0.2            # GPS location
permission_handler: ^12.0.1    # Permission management
```

### **UI/UX:**
```yaml
font_awesome_flutter: ^10.7.0  # Professional icons
awesome_dialog: ^3.2.1         # Beautiful dialogs
flutter_svg: ^2.0.10           # SVG support
lottie: ^3.1.2                 # Smooth animations
```

### **Development:**
```yaml
flutter_launcher_icons: ^0.14.1  # App icon generation
```

---

## 🏗️ Project Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   └── restricted_area.dart     # GPS zone model
├── providers/                   # State management
│   ├── auth_provider.dart       # Authentication state
│   ├── bluetooth_provider.dart  # Bluetooth state
│   ├── exhaust_provider.dart    # Exhaust control state
│   └── restricted_areas_provider.dart  # GPS zones state
├── screens/                     # UI screens
│   ├── splash_screen.dart       # Splash with permissions
│   ├── login_screen.dart        # User login
│   ├── signup_screen.dart       # User registration
│   ├── main_navigation_screen.dart  # Bottom navigation
│   ├── dashboard_screen.dart    # Home tab
│   ├── map_screen.dart          # Map tab
│   ├── stats_screen.dart        # Statistics tab
│   └── profile_screen.dart      # Profile tab
├── services/                    # Business logic
│   ├── auth_service.dart        # Firebase auth
│   └── firestore_service.dart   # Database operations
├── utils/                       # Utilities
│   ├── app_colors.dart          # Color system
│   ├── app_text_styles.dart     # Typography
│   └── permission_handler.dart  # Permission management
└── widgets/                     # Reusable widgets
    ├── custom_button.dart       # Button component
    ├── custom_text_field.dart   # Input component
    └── bluetooth_connection_modal.dart  # BT modal

android/
└── app/src/main/
    └── AndroidManifest.xml      # Android permissions

assets/
└── images/
    └── logo.png                 # App logo (add this)

docs/
├── CHANGELOG.md                 # Version history
├── PROGRESS.md                  # Development progress
└── INSTALLATION_GUIDE.md        # Setup instructions
```

---

## 🎨 Features Breakdown

### **1. Authentication System**
- Email/password registration
- Secure Firebase authentication
- Session persistence
- Error handling

### **2. Dashboard (Home Tab)**
- Bluetooth connection status
- Manual exhaust control
- Quick stats overview
- Connection management

### **3. Map Tab**
- Restricted area management
- Add/edit/delete zones
- GPS-based area detection
- Visual zone display (planned)

### **4. Statistics Tab**
- Total trips taken
- Auto-closures performed
- Time saved
- Recent activity timeline
- Weekly usage chart

### **5. Profile Tab**
- User account information
- App settings
- Logout functionality
- About section

### **6. Permission System**
- Smart Bluetooth permission (Android 12+ support)
- GPS location permission
- Beautiful permission dialogs
- Graceful error handling
- Settings deep link

---

## 🔐 Permissions Required

### **Android:**
```xml
<!-- Bluetooth (Legacy - Android <12) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Bluetooth (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location (GPS Automation) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Internet (Firebase) -->
<uses-permission android:name="android.permission.INTERNET" />
```

### **iOS:**
```xml
<!-- Not yet configured - iOS support pending -->
```

---

## 🧪 Testing

### **Manual Testing Completed:**
- ✅ Login/signup flow
- ✅ Navigation between tabs
- ✅ Permission request flow
- ✅ Splash screen animation
- ✅ Dashboard UI
- ✅ Stats screen display

### **Pending Tests:**
- ⏳ Bluetooth device scanning
- ⏳ Hardware connection
- ⏳ GPS location tracking
- ⏳ Automatic exhaust control
- ⏳ Background location

---

## 📚 Documentation

### **Available Docs:**
- [CHANGELOG.md](./CHANGELOG.md) - Version history and changes
- [PROGRESS.md](./PROGRESS.md) - Development progress tracker
- [INSTALLATION_GUIDE.md](./INSTALLATION_GUIDE.md) - Setup instructions (pending)

### **API Documentation:**
- Firebase Auth: https://firebase.google.com/docs/auth
- Cloud Firestore: https://firebase.google.com/docs/firestore
- Flutter Blue Plus: https://pub.dev/packages/flutter_blue_plus
- Geolocator: https://pub.dev/packages/geolocator

---

## 🎯 Roadmap

### **Phase 4: Bluetooth Integration** (Next - Feb 14-16)
- Real device scanning
- Pairing and connection
- Send control commands
- Status monitoring

### **Phase 5: GPS Tracking** (Feb 16-18)
- Real-time location tracking
- Geofencing setup
- Area entry/exit detection
- Background location

### **Phase 6: Map Integration** (Feb 18-20)
- OpenStreetMap integration
- Visual zone display
- User location marker
- Map controls

### **Phase 7: Core Automation** (Feb 20-23)
- Automatic valve control
- Area-based switching
- Notification system
- History tracking

---

## 🤝 Contributing

This is a capstone project. Contributions are welcome for:
- Bug fixes
- UI improvements
- Documentation
- Testing

---

## 📄 License

This project is created for educational purposes as part of a capstone project.

---

## 👨‍💻 Author

**Development Team**  
Capstone Project 2026

---

## 🙏 Acknowledgments

- Flutter team for excellent framework
- Firebase for backend services
- OpenStreetMap for mapping (planned)
- Flutter community for packages

---

## 📞 Support

For questions or issues:
1. Check [CHANGELOG.md](./CHANGELOG.md) for known issues
2. Review [PROGRESS.md](./PROGRESS.md) for feature status
3. Open an issue on GitHub

---

**Last Updated:** February 11, 2026  
**Version:** 0.3.0  
**Status:** Active Development