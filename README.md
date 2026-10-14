<p align="center">
  <h1 align="center">📱 Universal Remote</h1>
  <p align="center"><b>A feature-rich, cross-platform Smart IR Remote application built with Flutter.</b></p>
  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-3.9+-blue.svg" alt="Flutter">
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg" alt="Platform">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  </p>
</p>

---

## ✨ Overview

**Universal Remote** is an advanced Flutter application designed to turn your mobile device into a powerful universal remote control. Supporting over 1,600+ pre-indexed IR database remotes (TV, AC, STB, Audio, DVD, etc.), custom remote designing, hardware IR emission, and audio jack aux waveform transmission, it provides a seamless remote control experience.

---

## 🚀 Key Features

- **1,600+ Pre-Indexed IR Remotes**: Browse and control TVs, Air Conditioners, Set-Top Boxes, Soundbars, and DVD players across popular brands (Samsung, LG, Sony, Panasonic, Philips, etc.) and custom categories.
- **Instant Remote Loading & Caching**: Fast background parsing with local `SharedPreferences` caching and splash screen pre-loading so all remotes open instantly with zero lag.
- **Saved Remotes Persistence**: Save your favorite remotes to "My Remotes" for quick access; persists securely across app restarts.
- **Settings & Dark Mode Persistence**: Full support for Light and Dark themes, Hardware vs. Audio Aux transmission modes, and adjustable blaster transmission speeds—all safely cached in local storage.
- **Remote Designer with Live Interactive Preview**: Build custom remotes with a fully interactive remote layout preview on the side (or in a popup test modal), letting you tap and test buttons in real time.
- **Standard IR & Pronto Hex Support**: Seamless toggle between Standard IR hex codes (`0xE0E040BF`) and Pronto Hex codes (`0000 006D 0012 ...`) during button creation and editing.
- **Edit & Shake Mode for Saved Remotes**: Toggle Edit Mode on any saved remote to trigger a wiggling button animation, edit button properties, test signals, add new buttons, or delete existing ones.
- **Dual Transmission Modes**: Built-in support for hardware IR blasters as well as headphone jack / audio aux waveform generation.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter (Dart)
- **XML Parsing**: `xml` for parsing `irplus` remote configuration XMLs.
- **Local Storage**: `shared_preferences` for persisting user settings and saved remotes.
- **Audio Generation**: `audioplayers` for audio aux IR tone transmission.
- **UI & Graphics**: Material Design 3, `flutter_svg` for brand logos.

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK (^3.9.0 or higher)
- Android Studio / VS Code with Flutter & Dart plugins.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/AcrNischal/Universal-Remote.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Universal Remote
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---
