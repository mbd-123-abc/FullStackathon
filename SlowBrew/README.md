<!-- Mahika Bagri -->
<!-- August 2026 -->

## SlowBrew

**Version:** 1.0 (MVP)
**Contributors:** Mahika Bagri

Inspired by my first software engineering internship, **SlowBrew** is a productivity companion that helps developers build healthier work habits through intentional breaks. During my internship, I quickly realized how easy it was to spend hours staring at a screen without noticing the time. Between debugging, meetings, and chasing deadlines, stepping away from my computer often felt like I was losing momentum, even though taking breaks is essential for preventing burnout and maintaining long-term productivity.

SlowBrew reimagines break reminders as something users look forward to instead of dismissing. Rather than interrupting work with intrusive notifications, the application encourages intentional pauses through a cozy café-inspired experience where every completed work session earns a freshly brewed drink. By making breaks feel rewarding instead of disruptive, SlowBrew helps users recharge, return with renewed focus, and build healthier productivity habits over time.

---

### Motivation

During my first software engineering internship, I learned that one of the hardest parts of the job wasn't solving technical problems—it was remembering to step away from them. Long debugging sessions and continuous screen time often made hours disappear without realizing I hadn't moved, stretched, or rested my eyes.

Research consistently shows that regular breaks improve concentration, reduce fatigue, and help prevent burnout, yet many developers skip them because traditional break reminders feel like interruptions rather than encouragement.

SlowBrew was created to make breaks feel rewarding instead of disruptive. Rather than displaying another reminder that users instinctively close, the application creates a small moment of anticipation. Inspired by the comforting ritual of brewing coffee or tea, a cozy character walks onto the screen, prepares a warm cup of tea, and encourages users to step away while the beverage brews. The screen remains locked during the break, helping users fully disconnect before returning refreshed. Because real work isn't always predictable, users can also pause or skip breaks whenever necessary.

The project combines software engineering, behavioral psychology, and cozy game design to encourage healthier work habits while creating a workspace that feels calm, intentional, and sustainable.

---

### Table of Contents

<details>
<summary>Expand</summary>

- [SlowBrew](#slowbrew)
  - [Motivation](#motivation)
  - [Roadmap](#roadmap)
- [User Guide](#user-guide)
  - [Why Use SlowBrew?](#why-use-slowbrew)
  - [Core Features (MVP)](#core-features-mvp)
  - [Building from Command Line](#building-from-command-line)
  - [Demo](#Demo)
  - [Feedback Form](#feedback-form)
- [Developer Guide](#developer-guide)
  - [Tech Stack](#tech-stack)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Layout](#layout)
  - [Architecture](#architecture)
  - [Design Philosophy](#design-philosophy)
  - [Contributing](#contributing)
  - [Bug Reports](#bug-reports)
- [Contact](#contact)
  - [Socials](#socials)

</details>

---

### Roadmap

- [x] macOS menu bar application
- [x] Configurable work and break intervals
- [x] Pixel-art character animations
- [x] Tea brewing sequence
- [x] Full-screen break overlay
- [x] Pause functionality
- [x] Skip break functionality
- [x] Launch at Login
- [x] Multi-display support
- [x] Do Not Disturb awareness
- [x] Sleep/Wake handling
- [ ] Complete animation assets
- [ ] Sound effects
- [ ] Localization
- [ ] Expanded testing
- [ ] Multiple café companions
- [ ] Custom break themes
- [ ] Productivity analytics
- [ ] Apple Health integration
- [ ] Calendar awareness
- [ ] iCloud synchronization

---

## User Guide

### Why Use SlowBrew?

- **Mindful Productivity** — Build healthier work habits without relying on disruptive notifications.
- **Encourages Real Breaks** — A temporary screen lock removes the temptation to continue working.
- **Cozy Experience** — Pixel-art animations transform breaks into something users genuinely anticipate.
- **Fully Customizable** — Adjust work intervals, break duration, and reminder frequency.
- **Built for Developers** — Designed around the realities of long coding sessions and deep focus.
- **Respects Your Workflow** — Pause or skip breaks whenever work requires flexibility.

---

### Core Features (MVP)

* **Cozy Break Ritual** — A pixel-art café companion walks onto the screen, brews a warm cup of tea, and creates a calming ritual that encourages users to step away from their workspace.
* **Screen Lock** — Temporarily locks the screen during break sessions, helping users disconnect from work and resist the temptation to "just finish one more thing."
* **Customizable Work Sessions** — Configure work and break intervals to match your preferred productivity rhythm, whether using the Pomodoro Technique or a personalized schedule.
* **Pause & Skip Controls** — Pause the timer or skip individual breaks when deadlines or meetings require uninterrupted focus.
* **Native macOS Experience** — Runs seamlessly as a lightweight menu bar application, integrating naturally into the macOS desktop without disrupting your workflow.
* **Handcrafted Pixel Animations** — Frame-by-frame character animations transform routine break reminders into an engaging, cozy experience that users can look forward to.

---

### Building from Command Line

You can build and run SlowBrew without Xcode using Swift Package Manager:

> **Note:** These commands assume you are already in the `SlowBrew` project directory.

**Release Build (Optimized)**
```bash
swift build -c release
.build/x86_64-apple-macosx/release/Slowbrew
```

**Create macOS App Bundle**
```bash
# Build release version
swift build -c release

# Create app bundle structure
mkdir -p Slowbrew.app/Contents/MacOS
mkdir -p Slowbrew.app/Contents/Resources

# Copy executable and resources
cp .build/x86_64-apple-macosx/release/Slowbrew Slowbrew.app/Contents/MacOS/
cp -R .build/x86_64-apple-macosx/release/Slowbrew_Slowbrew.bundle Slowbrew.app/Contents/Resources/

# Create Info.plist
cat > Slowbrew.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Slowbrew</string>
    <key>CFBundleIdentifier</key>
    <string>com.slowbrew.app</string>
    <key>CFBundleName</key>
    <string>Slowbrew</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
```

Now you can double-click `Slowbrew.app` or move it to `/Applications`!

---

### Demo

* [Loom Demo](https://www.loom.com/share/b0a35377514a4c79a19c0b4e05898ffd)

---

### Feedback Form

* [UI/UX Feedback Form]([https://forms.gle/q3XGMWAPSceWJqf8A](https://forms.gle/5MkAqVbuuW9aNJWG7))

---

## Developer Guide

### Tech Stack

**Frontend**
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) — native macOS user interface
- [AppKit](https://developer.apple.com/documentation/appkit) — system-level window and menu bar integration
- [Lottie](https://github.com/airbnb/lottie-ios) *(optional)* — animation support

**System Integration**
- macOS Menu Bar Application
- Launch at Login
- Multi-Display Support
- Full-Screen Overlay
- Native Notification Center

**Development**
- [Xcode](https://developer.apple.com/xcode/) — IDE
- [Swift](https://developer.apple.com/swift/) — programming language

---

### Prerequisites

Before running SlowBrew, install:

- macOS Sonoma (or later)
- Xcode 16+
- Swift 6+
- Git

---

### Installation

**Clone Repository**

```bash
git clone --filter=blob:none --sparse https://github.com/mbd-123-abc/FullStackathon.git
cd FullStackathon
git sparse-checkout set SlowBrew

cd SlowBrew
```

---

**Open the Project**

```bash
open Package.swift
```

or open the project manually using Xcode.

---

**Run the Application**

```bash
swift-run SlowBrew
```

```
⌘ + R
```

SlowBrew will launch as a native menu bar application.

---

### Layout

```text
SlowBrew/
├── SlowBrewApp.swift         # Application entry point
├── Views/
│   ├── MenuBar/
│   ├── BreakOverlay/
│   ├── Settings/
│   └── Components/
├── Models/
│   ├── Timer/
│   ├── Preferences/
│   └── Character/
├── Services/
│   ├── TimerService/
│   ├── NotificationService/
│   ├── ScreenLock/
│   └── Animation/
├── Assets/
│   ├── CharacterSprites/
│   ├── TeaAnimations/
│   ├── Icons/
│   └── Sounds/
└── Resources/
```

---

### Architecture

SlowBrew follows a modular architecture where each system has a single responsibility.

**Timer Engine**

Responsible for scheduling work sessions, break intervals, pausing timers, and skipping breaks while maintaining synchronization with the user interface.

**Break Manager**

Coordinates the complete break experience by displaying the overlay, locking interaction with the desktop, playing animations, and restoring the workspace after the break finishes.

**Character Animation**

Controls the café companion's lifecycle:

- Walk onto the screen
- Brew tea
- Wait while the tea steeps
- Walk off screen

Each animation sequence is built using frame-based sprite animations.

**Menu Bar Controller**

Provides quick access to:

- Start timer
- Pause timer
- Skip break
- Open settings
- Quit application

without interrupting the user's workflow.

---

### Design Philosophy

SlowBrew was designed around one simple principle:

> **Rest should be part of productivity—not a reward for finishing it.**

Unlike traditional break reminders that rely on notifications users instinctively dismiss, SlowBrew creates a small ritual that gently encourages stepping away from work. Every interaction—from the cozy animations to the temporary screen lock—is intended to reduce burnout while preserving deep focus throughout the day.

---

### Contributing

Contributions are welcome.

1. Fork the repository.

2. Create a feature branch.

```bash
git checkout -b feature/amazing-feature
```

3. Commit your changes.

```bash
git commit -m "Add amazing feature"
```

4. Push your branch.

```bash
git push origin feature/amazing-feature
```

5. Open a Pull Request.

Please include screenshots or recordings for any UI-related changes.

---

### Bug Reports

If you encounter a bug, please create a GitHub Issue including:

- macOS version
- Device model
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots or screen recordings

---

## Contact

### Socials

* [LinkedIn](www.linkedin.com/in/mahika-bagri)
* [Email](mahika13.3@gmail.com)
* [Discord](https://discord.com/users/697914065418321961)

