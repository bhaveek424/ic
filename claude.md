iPhone Screen Mirror App - Complete Requirements & Implementation Guide
Project Overview
Build a macOS application that displays iPhone screen content via USB connection in a translucent, non-interactive overlay window that is invisible to screen recording software.
Core Requirements
1. Display Requirements

Connection Type: USB-wired connection to iPhone (not wireless)
Window Style: Translucent, phone-shaped rectangular display
Window Shape: iPhone-like proportions (approximately 19.5:9 aspect ratio)
Transparency: Semi-transparent/translucent background with visible screen content
Size: Adjustable, but default to reasonable iPhone screen size (e.g., 390x844 points for iPhone 14 Pro size)

2. Interaction Requirements

Click-Through Behavior: Window must NOT register any mouse clicks/interactions
Non-Interactive: All clicks should pass through to applications behind the window
Display Only: Pure display functionality - no touch/click simulation on iPhone

3. Privacy & Security Requirements

Screen Recording Protection: Window content should NOT be visible in:

Screen recordings (QuickTime, OBS, etc.)
Screen sharing (Zoom, Teams, Meet, etc.)
Screenshot utilities
Window capture APIs


Confidential Content: Treat all displayed content as sensitive

4. App Visibility Requirements

No Dock Icon: App should not appear in the Dock
No Menu Bar (Optional): Minimal or no menu bar presence
Background Agent: Run as LSUIElement agent application
No Window Switcher: Should not appear in Cmd+Tab or Mission Control (if possible)
System Tray Only: Optional - small menu bar icon for quit/controls

5. Deployment Requirements

Local Use Only: App will run locally on developer's machine
No Distribution: No need for App Store or external distribution
Self-Signed: Can use development certificates
Hardcoded Paths OK: No need for user configuration if not necessary

Technical Implementation Specifications
Technology Stack
Primary Technologies

Language: Swift 5.9+
UI Framework: SwiftUI + AppKit (hybrid)
macOS Version: macOS 13.0+ (Ventura or later)
iPhone Capture: libimobiledevice library
Video Processing: AVFoundation or Metal for rendering

Required Dependencies
bash# Install via Homebrew
brew install libimobiledevice
brew install usbmuxd
brew install ffmpeg (optional, for format conversion)
Architecture Components
1. App Structure
iPhoneMirror/
├── App/
│   ├── iPhoneMirrorApp.swift          # Main app entry point
│   ├── AppDelegate.swift               # App lifecycle management
│   └── Info.plist                      # App configuration
├── Window/
│   ├── TranslucentWindowController.swift  # Custom NSWindow setup
│   ├── WindowManager.swift             # Window positioning & management
│   └── PhoneFrameView.swift           # iPhone-shaped frame UI
├── Capture/
│   ├── iPhoneScreenCapture.swift      # libimobiledevice wrapper
│   ├── VideoStreamManager.swift       # Handle video stream
│   └── FrameDecoder.swift             # Decode video frames
├── Display/
│   ├── VideoDisplayView.swift         # Render video content
│   └── MetalRenderer.swift            # Metal-based rendering (optional)
└── Utilities/
    ├── SecurityManager.swift          # Screen capture prevention
    └── ProcessWrapper.swift           # Wrap CLI tools
2. Info.plist Configuration
xml<key>LSUIElement</key>
<true/>

<key>LSBackgroundOnly</key>
<false/>

<key>NSSupportsAutomaticTermination</key>
<true/>

<key>NSSupportsSuddenTermination</key>
<false/>

<!-- USB Device Access -->
<key>com.apple.security.device.usb</key>
<true/>

<!-- Optional: If using network for discovery -->
<key>NSLocalNetworkUsageDescription</key>
<string>Used to discover iPhone on local network</string>
3. Window Configuration (Critical)
TranslucentWindowController Implementation:
swiftclass TranslucentWindow: NSWindow {
    
    required init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Transparency & Visual
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.alphaValue = 0.95
        
        // CRITICAL: Click-through behavior
        self.ignoresMouseEvents = true
        
        // CRITICAL: Screen capture prevention
        self.sharingType = .none
        
        // Window behavior
        self.level = .floating  // Stay on top
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]
        
        // Prevent from appearing in window switcher
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false
    }
}
Key Properties Explained:

ignoresMouseEvents = true → Makes window click-through
sharingType = .none → Prevents screen capture (best effort)
level = .floating → Keeps window on top of other windows
.nonactivatingPanel → Doesn't steal focus when displayed

4. iPhone Screen Capture Implementation
Approach: Use libimobiledevice to stream screen via USB
Command-line approach (simplest):
bash# Start streaming iPhone screen
idevicescreenshot --udid [DEVICE_UDID] -
Or for continuous streaming:
bash# Use QuickTime-like streaming
ffmpeg -f avfoundation -list_devices true -i ""
# Then capture the iPhone device
Swift Process Wrapper:
swiftclass iPhoneScreenCapture {
    private var process: Process?
    
    func startCapture() {
        process = Process()
        process?.executableURL = URL(fileURLWithPath: "/usr/local/bin/idevice_id")
        // Configure streaming pipeline
        process?.launch()
    }
    
    func stopCapture() {
        process?.terminate()
    }
}
Alternative: Direct Integration

Use Swift bindings for libimobiledevice
Call C library directly via bridging header
More complex but better control

5. Video Display
Option A: AVFoundation (Recommended for simplicity)
swiftimport AVFoundation

struct VideoDisplayView: NSViewRepresentable {
    let videoLayer: AVSampleBufferDisplayLayer
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer = videoLayer
        view.wantsLayer = true
        return view
    }
}
Option B: Metal (Better performance)
swiftimport MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    // Implement Metal rendering pipeline
    // Better for high frame rate, lower latency
}
Implementation Phases
Phase 1: Basic Window System (Day 1)
Goal: Get translucent, click-through window working
Tasks:

Create new macOS app project in Xcode
Configure Info.plist with LSUIElement
Implement TranslucentWindow class
Create phone-shaped frame with rounded corners
Test click-through behavior
Test screen capture prevention (try recording with QuickTime)
Verify no dock icon appears

Validation:

 App launches with no dock icon
 Window appears as translucent overlay
 Clicks pass through to apps behind
 Window doesn't appear in screen recordings

Phase 2: iPhone Detection (Day 2)
Goal: Detect connected iPhone via USB
Tasks:

Install libimobiledevice dependencies
Create ProcessWrapper for CLI tools
Implement device detection (idevice_id -l)
Get device UDID and info
Handle connection/disconnection events
Add status indicator (optional menu bar icon)

Validation:

 App detects iPhone when plugged in
 Shows device name/model
 Handles unplug gracefully

Phase 3: Screen Capture (Day 3-4)
Goal: Capture and display iPhone screen
Tasks:

Research best libimobiledevice streaming method
Implement screen capture pipeline
Configure video format (H.264, resolution, FPS)
Handle video stream in Swift
Test latency and performance
Add error handling for capture failures

Validation:

 iPhone screen appears in window
 Acceptable latency (<100ms ideal)
 Stable streaming without crashes
 Handles iPhone lock/unlock

Phase 4: Video Rendering (Day 4-5)
Goal: Display video stream in translucent window
Tasks:

Choose rendering approach (AVFoundation vs Metal)
Implement video decoder
Render frames in translucent window
Maintain aspect ratio
Add window resize handling
Optimize for performance (60fps target)

Validation:

 Smooth video playback
 Proper aspect ratio
 No visual artifacts
 Low CPU usage (<20% on modern Mac)

Phase 5: Polish & Security (Day 6-7)
Goal: Finalize security and usability features
Tasks:

Test screen capture prevention thoroughly
Add window positioning memory
Implement graceful error messages
Add keyboard shortcuts (Cmd+Q to quit)
Optional: Add menu bar icon for controls
Code signing for local use
Create simple launch script

Validation:

 Screen recording truly blocks content
 App survives system sleep/wake
 Easy to launch and quit
 No crashes in normal use

Security Considerations
Screen Capture Prevention Techniques

NSWindow.sharingType = .none (Primary)

Tells system not to include window in screen captures
Works with most recording software
Not foolproof but best native option


Window Level Management

Keep window at .floating or higher level
Makes it harder for capture tools to target


Additional Hardening (Optional)

Mark window as secure content
Use private APIs if needed (for local use only)
Consider DRM-like techniques (complex)


Known Limitations

Cannot prevent camera pointed at screen
Some advanced capture tools may still work
Physical security remains important



Testing Checklist
Functional Testing

 Window appears on launch
 Window is translucent
 Clicks pass through to background apps
 iPhone detection works reliably
 Screen content displays correctly
 Video is smooth (target: 30-60fps)
 App quits cleanly

Security Testing

 QuickTime Screen Recording (should not capture)
 Screenshot (Cmd+Shift+4) (should not capture)
 OBS Studio screen capture (should not capture)
 Zoom/Teams screen sharing (should not capture)
 Third-party screenshot tools (should not capture)

Usability Testing

 No dock icon visible
 No unwanted menu bar items
 Easy to quit (Cmd+Q or menu bar icon)
 Window survives display changes
 Handles iPhone disconnect gracefully
 Low resource usage

Edge Cases

 Multiple iPhones connected (handle or error?)
 iPhone locked/unlocked during streaming
 Mac going to sleep with stream active
 Display resolution changes
 External monitor connected/disconnected

Build & Run Instructions
Prerequisites
bash# Install Xcode 15+ from App Store
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install libimobiledevice
brew install usbmuxd
Build Steps

Open project in Xcode
Select "My Mac" as target
Build (Cmd+B)
Run (Cmd+R)
Connect iPhone via USB
Trust computer on iPhone if prompted

Manual Code Signing (for local use)

Xcode → Project Settings → Signing & Capabilities
Select "Sign to Run Locally"
Choose your Apple Developer account (free account works)
Build and run

Known Limitations & Tradeoffs

USB Connection Required

Wireless would require iOS companion app
USB is simpler and more reliable


Screen Capture Prevention

Not 100% foolproof
Best-effort using native APIs
Advanced tools may still capture


No Interaction

Window is display-only
Cannot control iPhone from Mac
This is by design per requirements


Single iPhone Support

Designed for one device at a time
Multiple devices would need UI for selection


Performance

Video streaming is CPU-intensive
May affect battery on laptop
Target modern Mac (M1+ or Intel 2018+)



Future Enhancements (Optional)

 Window position/size persistence
 Hotkey to show/hide window
 Brightness adjustment for translucency
 Recording of iPhone screen to file
 Multiple device support
 Custom frame styles (different iPhone models)
 Picture-in-picture mode

Support & Troubleshooting
Common Issues
Issue: iPhone not detected

Solution: Ensure iTunes/Finder can see device first
Check USB cable is data-capable (not charge-only)
Trust computer on iPhone

Issue: Black screen in window

Solution: Check iPhone is unlocked
Verify libimobiledevice is working (idevice_id -l)
Restart app and reconnect iPhone

Issue: Window appears in screen recordings

Solution: sharingType = .none may not work with all tools
This is a known limitation
Consider additional obfuscation techniques

Issue: High CPU usage

Solution: Reduce frame rate in capture settings
Use Metal rendering instead of AVFoundation
Check for memory leaks in video pipeline
