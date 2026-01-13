//
//  iphoneApp.swift
//  iphone
//
//  iPhone Screen Mirror - Main App Entry Point
//

import SwiftUI
import AppKit

@main
struct iPhoneMirrorApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use Settings scene as placeholder (won't show due to LSUIElement)
        Settings {
            EmptyView()
        }
    }
}

/// App delegate for handling app lifecycle and setting up the window
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var statusUpdateTask: Task<Void, Never>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupMainWindow()
        setupKeyboardShortcuts()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        statusUpdateTask?.cancel()
        Task { @MainActor in
            AVFoundationCapture.shared.stopCapture()
            WindowManager.shared.closeWindow()
        }
    }
    
    // MARK: - Setup
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone Mirror")
        }
        
        Task { @MainActor in
            self.updateMenu()
        }
        
        // Update menu periodically based on capture status
        statusUpdateTask = Task { @MainActor in
            for await _ in AVFoundationCapture.shared.$isDeviceConnected.values {
                self.updateMenu()
            }
        }
    }
    
    @MainActor
    private func updateMenu() {
        let menu = NSMenu()
        let capture = AVFoundationCapture.shared
        
        // Connection status
        let statusText: String
        if capture.isDeviceConnected {
            statusText = "🟢 \(capture.deviceName)"
        } else {
            statusText = "⚪ No iPhone Connected"
        }
        
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show/Hide window
        menu.addItem(NSMenuItem(title: "Show/Hide Window", action: #selector(toggleWindow), keyEquivalent: "h"))
        
        menu.addItem(NSMenuItem.separator())
        
        // Position submenu
        let positionMenu = NSMenu()
        positionMenu.addItem(NSMenuItem(title: "Left", action: #selector(moveLeft), keyEquivalent: ""))
        positionMenu.addItem(NSMenuItem(title: "Center", action: #selector(centerWindow), keyEquivalent: ""))
        positionMenu.addItem(NSMenuItem(title: "Right", action: #selector(moveRight), keyEquivalent: ""))
        
        let positionItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu
        menu.addItem(positionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Reconnect option
        menu.addItem(NSMenuItem(title: "Reconnect", action: #selector(reconnect), keyEquivalent: "r"))
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        self.statusItem?.menu = menu
    }
    
    private func setupMainWindow() {
        // Create the main content view
        let contentView = ContentView()
        
        // Show the window
        Task { @MainActor in
            WindowManager.shared.showWindow(with: contentView)
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Global keyboard shortcut for Command+Q to quit
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleWindow() {
        Task { @MainActor in
            WindowManager.shared.toggleVisibility()
        }
    }
    
    @objc private func moveLeft() {
        Task { @MainActor in
            WindowManager.shared.moveToLeft()
        }
    }
    
    @objc private func centerWindow() {
        Task { @MainActor in
            WindowManager.shared.centerWindow()
        }
    }
    
    @objc private func moveRight() {
        Task { @MainActor in
            WindowManager.shared.moveToRight()
        }
    }
    
    @objc private func reconnect() {
        Task { @MainActor in
            AVFoundationCapture.shared.stopCapture()
            AVFoundationCapture.shared.startCapture()
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
