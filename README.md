# HeartLink

HeartLink is a Flutter-based fitness application focused on real-time heart rate monitoring and workout session tracking. It connects to Bluetooth Low Energy (BLE) heart rate sensors, visualizes heart rate zones during workouts, logs session history to Firebase, and supports multi-device workout sessions via peer-to-peer networking.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the App](#running-the-app)
  - [Wired (USB)](#wired-usb)
  - [Wireless via ADB Pairing](#wireless-via-adb-pairing)
- [Project Structure](#project-structure)

---

## Features

- Real-time heart rate monitoring via BLE sensors
- Heart rate zone visualization with radial gauges
- Workout session creation, tracking, and history
- Multi-device workout sessions using Nearby Connections
- Firebase authentication (Email/Password and Google Sign-In)
- Cloud Firestore with offline persistence
- Audio and haptic feedback during workouts

---

## Prerequisites

Ensure the following are installed before running the project:

| Tool | Version |
|---|---|
| Flutter SDK | `^3.x` (Dart `^3.7.0`) |
| Android Studio / Xcode | Latest stable |
| Android SDK / NDK | NDK `27.0.12077973` |
| Java | 11 |
| Firebase CLI | Latest (project already configured) |

Verify your Flutter setup:

```bash
flutter doctor
```

---

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/WesGitUF/WesHeartLink
   cd WesHeartLink
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase is pre-configured** — the project uses `heartlink-74a85`. No additional Firebase setup is required for development builds.

---

## Running the App

### Wired (USB)

Connect your Android or iOS device via USB cable with USB Debugging enabled.

**List connected devices:**

```bash
flutter devices
```

**Run on a specific device using its device ID:**

```bash
flutter run -d <device-id>
```

Example:

```bash
flutter run -d emulator-5554
flutter run -d R5CT103WXYZ
```

> On Android, enable **USB Debugging** in *Settings → Developer Options*. On iOS, trust the connected Mac from the device prompt.

---

### Wireless via ADB Pairing

Use ADB wireless pairing to run the app over Wi-Fi without a USB cable. Both your development machine and device must be on the **same Wi-Fi network**.

**Step 1 — Enable Wireless Debugging on the device**

Go to *Settings → Developer Options → Wireless Debugging* and toggle it on.

**Step 2 — Pair the device**

Tap **Pair device with pairing code** inside Wireless Debugging. The screen will show an IP address, port, and 6-digit pairing code.

Run:

```bash
adb pair <ip-address>:<pairing-port>
```

Enter the 6-digit pairing code when prompted.

Example:

```bash
adb pair 192.168.1.42:37000
# Enter pairing code: 123456
```

**Step 3 — Connect to the device**

After pairing, the Wireless Debugging screen shows a separate **IP address & port** for the connection. Run:

```bash
adb connect <ip-address>:<connection-port>
```

Example:

```bash
adb connect 192.168.1.42:42000
```

**Step 4 — Run the app wirelessly**

```bash
flutter devices
flutter run -d <device-id>
```

> The device ID for a wirelessly connected device typically looks like `192.168.1.42:42000`.

---

## Project Structure

```
lib/
├── main.dart                        # App entry point, Firebase init, routing
├── firebase_options.dart            # Auto-generated Firebase configuration
├── radial-gauge.dart                # Heart rate gauge widget
├── app/theme/                       # App theme (dark mode)
├── models/                          # Data models (HeartRateZone, etc.)
├── screens/
│   ├── auth/                        # Auth gate screen
│   ├── session/                     # Workout session screens
│   ├── heartratedial/               # Live HR visualization
│   ├── history/                     # Workout history & details
│   ├── home/                        # Home screen
│   ├── profile/                     # User profile
│   ├── splash/                      # Splash screen
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   └── max_hr_input_screen.dart
├── services/
│   ├── auth_service.dart            # Authentication logic
│   ├── workout_service.dart         # Workout CRUD
│   ├── session_service.dart         # Active session management
│   ├── nearby_stream_service.dart   # P2P multi-device sync
│   ├── active_workout_store.dart    # In-memory workout state
│   ├── workout_notification_service.dart
│   ├── workout_audio_settings.dart
│   ├── workout_haptic_settings.dart
│   └── battery_optimization.dart
├── shell/                           # App navigation shell
└── widgets/                         # Reusable UI components
```
