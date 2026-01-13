//
//  WindowManager.swift
//  iphone
//
//  Manages the translucent overlay window lifecycle and positioning
//

import AppKit
import SwiftUI

/// Manages the main translucent window for iPhone screen display
@MainActor
class WindowManager: ObservableObject {
    
    // MARK: - Properties
    
    private var windowController: TranslucentWindowController?
    
    /// iPhone 14 Pro-like aspect ratio (19.5:9)
    private let aspectRatio: CGFloat = 19.5 / 9.0

    /// Default window size (smaller for better visibility of background text)
    /// Reduced from 390x844 to 300x650 (about 30% smaller)
    private let defaultSize = NSSize(width: 300, height: 650)
    
    /// Current window visibility state
    @Published private(set) var isVisible: Bool = false
    
    // MARK: - Singleton
    
    static let shared = WindowManager()
    
    private init() {}
    
    // MARK: - Window Management
    
    /// Create and show the translucent overlay window
    func showWindow<Content: View>(with content: Content) {
        if windowController != nil {
            windowController?.show()
            isVisible = true
            return
        }
        
        let frame = calculateInitialFrame()
        windowController = TranslucentWindowController(rootView: content, frame: frame)
        windowController?.show()
        isVisible = true
    }
    
    /// Hide the window
    func hideWindow() {
        windowController?.hide()
        isVisible = false
    }
    
    /// Toggle window visibility
    func toggleVisibility() {
        if isVisible {
            hideWindow()
        } else {
            windowController?.show()
            isVisible = true
        }
    }
    
    /// Close and release the window
    func closeWindow() {
        windowController?.close()
        windowController = nil
        isVisible = false
    }
    
    // MARK: - Positioning
    
    /// Calculate the initial frame for the window (right side of main screen)
    private func calculateInitialFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: defaultSize)
        }
        
        let screenFrame = screen.visibleFrame
        
        // Position on right side of screen with some padding
        let padding: CGFloat = 40
        let x = screenFrame.maxX - defaultSize.width - padding
        let y = screenFrame.midY - defaultSize.height / 2
        
        return NSRect(origin: NSPoint(x: x, y: y), size: defaultSize)
    }
    
    /// Center the window on screen
    func centerWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = windowController?.window?.frame.size ?? defaultSize
        
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2
        
        windowController?.updatePosition(to: NSPoint(x: x, y: y))
    }
    
    /// Move window to left side of screen
    func moveToLeft() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let padding: CGFloat = 40
        let windowSize = windowController?.window?.frame.size ?? defaultSize
        
        let x = screenFrame.minX + padding
        let y = screenFrame.midY - windowSize.height / 2
        
        windowController?.updatePosition(to: NSPoint(x: x, y: y))
    }
    
    /// Move window to right side of screen
    func moveToRight() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let padding: CGFloat = 40
        let windowSize = windowController?.window?.frame.size ?? defaultSize
        
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.midY - windowSize.height / 2
        
        windowController?.updatePosition(to: NSPoint(x: x, y: y))
    }
    
    // MARK: - Sizing
    
    /// Scale the window while maintaining aspect ratio
    func scale(to percentage: CGFloat) {
        let scaledWidth = defaultSize.width * percentage
        let scaledHeight = scaledWidth * aspectRatio
        windowController?.updateSize(to: NSSize(width: scaledWidth, height: scaledHeight))
    }
    
    /// Reset window to default size
    func resetSize() {
        windowController?.updateSize(to: defaultSize)
    }
}
