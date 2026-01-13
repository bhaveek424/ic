//
//  TranslucentWindow.swift
//  iphone
//
//  iPhone Screen Mirror - Translucent overlay window
//

import AppKit
import SwiftUI

/// A custom NSWindow that is translucent, click-through, and invisible to screen recording
class TranslucentWindow: NSPanel {
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        configureWindow()
    }
    
    private func configureWindow() {
        // TRANSPARENCY & VISUAL
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        alphaValue = 0.4  // More translucent (was 0.95, now 0.6 - lower is more transparent)
        
        // CRITICAL: Click-through behavior - all clicks pass to apps behind
        ignoresMouseEvents = true
        
        // CRITICAL: Screen capture prevention - window won't appear in recordings
        sharingType = .none
        
        // WINDOW BEHAVIOR
        level = .floating  // Stay on top of other windows
        collectionBehavior = [
            .canJoinAllSpaces,      // Visible on all virtual desktops
            .stationary,            // Stays in place during Mission Control
            .fullScreenAuxiliary    // Works alongside fullscreen apps
        ]
        
        // Prevent from appearing in window switcher and don't hide on deactivate
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        
        // Additional security/privacy settings
        isExcludedFromWindowsMenu = true
        animationBehavior = .none
        
        // Title bar settings (for borderless window)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }
    
    /// Allow the window to become key for keyboard shortcuts, but not mouse
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    /// Override to ensure mouse events are truly ignored
    override func sendEvent(_ event: NSEvent) {
        // Only process keyboard events, ignore all mouse events
        switch event.type {
        case .keyDown, .keyUp, .flagsChanged:
            super.sendEvent(event)
        default:
            // Let mouse events pass through completely
            break
        }
    }
}

/// WindowController for managing the translucent window
class TranslucentWindowController: NSWindowController {
    
    convenience init<Content: View>(rootView: Content, frame: NSRect) {
        let window = TranslucentWindow(contentRect: frame)
        
        // Create hosting view for SwiftUI content
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func updatePosition(to point: NSPoint) {
        window?.setFrameOrigin(point)
    }
    
    func updateSize(to size: NSSize) {
        guard let window = window else { return }
        var frame = window.frame
        frame.size = size
        window.setFrame(frame, display: true, animate: false)
    }
}
