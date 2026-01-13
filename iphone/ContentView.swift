//
//  ContentView.swift
//  iphone
//
//  Main content view with phone frame and video display
//

import SwiftUI
import AppKit

/// Main content view that displays the iPhone mirror
struct ContentView: View {

    @StateObject private var quickTimeCapture = QuickTimeCapture.shared

    var body: some View {
        PhoneFrameView {
            ZStack {
                // Video display layer - Always use QuickTime
                if let frame = quickTimeCapture.currentFrame {
                    Image(nsImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .onAppear {
                            print("DEBUG: Displaying frame with size: \(frame.size)")
                        }
                } else {
                    Color.black
                        .onAppear {
                            print("DEBUG: No frame available, showing black")
                        }
                }

                // Status overlay
                statusOverlay
            }
        }
        .onAppear {
            print("DEBUG: ContentView appeared, starting QuickTime capture")
            Task {
                await quickTimeCapture.startCapture()
            }
            setupKeyboardShortcuts()
        }
        .onDisappear {
            print("DEBUG: ContentView disappeared, stopping capture")
            Task {
                await quickTimeCapture.stopCapture()
            }
        }
    }
    
    // MARK: - Status Overlay
    
    @ViewBuilder
    private var statusOverlay: some View {
        let hasFrame = quickTimeCapture.currentFrame != nil

        if let error = quickTimeCapture.errorMessage {
            // Show error
            ErrorOverlay(message: error)
                .onAppear {
                    print("DEBUG: Showing error overlay: \(error)")
                }
        } else if !hasFrame {
            // Waiting for frames from QuickTime
            ConnectingOverlay()
                .onAppear {
                    print("DEBUG: Showing connecting overlay")
                }
        } else {
            // Capturing successfully - show QuickTime mode indicator in debug
            #if DEBUG
            VStack {
                HStack {
                    Text("QuickTime Mode • Transparency: Ctrl+Opt+Cmd+T / ↑↓")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.7))
                        .padding(4)
                    Spacer()
                }
                Spacer()
            }
            .allowsHitTesting(false)
            .onAppear {
                print("DEBUG: Successfully capturing and displaying frames from QuickTime")
            }
            #else
            EmptyView()
            #endif
        }
    }

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        // Listen for keyboard shortcuts
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

            // Control + Option + Command + T - Adjust transparency
            if flags.contains([.control, .option, .command]) && key == "t" {
                print("DEBUG: Keyboard shortcut triggered - adjusting transparency")
                self.adjustTransparency()
                return nil
            }

            // Control + Option + Command + Up Arrow - Increase opacity (less transparent)
            if flags.contains([.control, .option, .command]) && event.keyCode == 126 { // Up arrow
                print("DEBUG: Keyboard shortcut triggered - increase opacity")
                self.changeOpacity(by: 0.1)
                return nil
            }

            // Control + Option + Command + Down Arrow - Decrease opacity (more transparent)
            if flags.contains([.control, .option, .command]) && event.keyCode == 125 { // Down arrow
                print("DEBUG: Keyboard shortcut triggered - decrease opacity")
                self.changeOpacity(by: -0.1)
                return nil
            }

            return event
        }
    }

    private func adjustTransparency() {
        guard let window = NSApp.windows.first else { return }
        // Cycle through transparency levels: 0.3, 0.5, 0.7, 0.9
        let currentAlpha = window.alphaValue
        let newAlpha: CGFloat
        if currentAlpha <= 0.3 {
            newAlpha = 0.5
        } else if currentAlpha <= 0.5 {
            newAlpha = 0.7
        } else if currentAlpha <= 0.7 {
            newAlpha = 0.9
        } else {
            newAlpha = 0.3
        }
        window.alphaValue = newAlpha
        print("DEBUG: Window transparency set to \(Int(newAlpha * 100))%")
    }

    private func changeOpacity(by delta: CGFloat) {
        guard let window = NSApp.windows.first else { return }
        let newAlpha = max(0.1, min(1.0, window.alphaValue + delta))
        window.alphaValue = newAlpha
        print("DEBUG: Window opacity: \(Int(newAlpha * 100))%")
    }
}

/// Error display overlay
struct ErrorOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 390, height: 844)
}
