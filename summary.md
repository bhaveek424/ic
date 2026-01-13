# Project Learning Summary

## Project Overview
This project is a macOS utility application designed to mirror a connected iPhone's screen into a translucent, always-on-top window on the user's desktop. It allows users to reference their iPhone screen (e.g., for testing apps or monitoring status) without obstructing the content behind it.

## Core Mechanism: QuickTime Mode
Direct screen capture of the iPhone via standard macOS APIs (`AVFoundation`) is currently blocked by system privacy restrictions. To bypass this, the app uses a clever workaround:
1.  **QuickTime Player:** The user opens QuickTime Player and starts a "New Movie Recording" of their iPhone.
2.  **ScreenCaptureKit:** The app uses `ScreenCaptureKit` to locate the specific QuickTime window showing the iPhone.
3.  **Mirroring:** The app captures this window and displays it within its own custom, frame-less, and translucent window.

## Key Features
*   **Translucent Window:** The main window is semi-transparent, allowing users to see background text. The default opacity is set to 60% (alpha 0.6).
*   **Phone Frame:** A visual bezel wraps the video feed to mimic the look of an iPhone 14 Pro/15.
*   **Agent App:** The app runs as a menu bar item (Agent) with no Dock icon (`LSUIElement` is true).
*   **Keyboard Shortcuts:**
    *   `Ctrl + Opt + Cmd + T`: Cycles transparency levels (30%, 50%, 70%, 90%).
    *   `Ctrl + Opt + Cmd + ↑/↓`: Increases or decreases opacity.
    *   `Ctrl + Opt + Cmd + H`: Toggles QuickTime capture mode.
    *   `Cmd + Q`: Quits the app.

## Recent Improvements
*   **Reduced Size:** The default window size was reduced from 390x844 to **300x650** (approx. 30% smaller) to improve visibility of background content.
*   **Increased Transparency:** Default alpha changed from 0.95 (mostly opaque) to **0.60** (more transparent).

## Technical Architecture
*   **Language:** Swift
*   **Frameworks:** SwiftUI, AppKit, AVFoundation, ScreenCaptureKit.
*   **Key Files:**
    *   `iphoneApp.swift`: Main entry point and menu bar setup.
    *   `QuickTimeCapture.swift`: Handles the logic for finding and capturing the QuickTime window.
    *   `WindowManager.swift`: Manages window sizing, positioning, and visibility.
    *   `iPhoneDetector.swift`: Uses `libimobiledevice` tools to detect physical device connections.
