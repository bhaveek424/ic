//
//  QuickTimeCapture.swift
//  iphone
//
//  Captures iPhone screen via QuickTime Player (which already has authorization)
//

import AppKit
import AVFoundation
import ScreenCaptureKit

/// Captures iPhone screen by using QuickTime Player as intermediary
@MainActor
class QuickTimeCapture: NSObject, ObservableObject {

    @Published private(set) var currentFrame: NSImage?
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var errorMessage: String?

    private var captureTimer: Timer?
    private var quickTimeWindow: SCWindow?
    private var stream: SCStream?

    static let shared = QuickTimeCapture()

    private override init() {
        super.init()
    }

    /// Start capturing via QuickTime
    func startCapture() async {
        print("DEBUG: Starting QuickTime-based capture...")

        // Step 1: Launch QuickTime if not running
        let quickTimeApp = NSWorkspace.shared.runningApplications.first { app in
            app.bundleIdentifier == "com.apple.QuickTimePlayerX"
        }

        if quickTimeApp == nil {
            print("DEBUG: Launching QuickTime Player...")
            if let quickTimeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.QuickTimePlayerX") {
                do {
                    let _ = try NSWorkspace.shared.launchApplication(at: quickTimeURL, options: [.withoutActivation], configuration: [:])
                    // Wait for QuickTime to launch
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    errorMessage = "Failed to launch QuickTime: \(error.localizedDescription)"
                    return
                }
            }
        }

        // Step 2: Find QuickTime's window showing iPhone
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

            print("DEBUG: Found \(content.windows.count) total windows")

            // Debug: List all QuickTime windows
            let allQuickTimeWindows = content.windows.filter { window in
                window.owningApplication?.bundleIdentifier == "com.apple.QuickTimePlayerX"
            }

            print("DEBUG: Found \(allQuickTimeWindows.count) QuickTime windows:")
            for (index, window) in allQuickTimeWindows.enumerated() {
                print("DEBUG:   [\(index)] Title: '\(window.title ?? "no title")', Size: \(window.frame.size)")
            }

            // Find QuickTime windows - use the largest window (likely the movie recording)
            let quickTimeWindows = allQuickTimeWindows.filter { window in
                // Filter for substantial windows (not tiny control panels)
                let hasSize = window.frame.width > 200 && window.frame.height > 200

                // Check if title suggests it's a movie/recording window
                let title = window.title?.lowercased() ?? ""
                let hasRelevantTitle = title.contains("iphone") ||
                                      title.contains("bhaveek") ||
                                      title.contains("movie") ||
                                      title.isEmpty  // QuickTime movie windows sometimes have no title

                return hasSize && hasRelevantTitle
            }.sorted { $0.frame.height > $1.frame.height }  // Use tallest window first

            if let window = quickTimeWindows.first {
                print("DEBUG: ✓ Using QuickTime window: '\(window.title ?? "untitled")' (size: \(window.frame.size))")
                quickTimeWindow = window

                // Start capturing this window
                try await startWindowCapture(window: window)

            } else {
                print("DEBUG: ❌ No suitable QuickTime window found")
                print("DEBUG: All QuickTime windows:")
                for window in allQuickTimeWindows {
                    print("DEBUG:    - '\(window.title ?? "no title")' (size: \(window.frame.width)x\(window.frame.height))")
                }

                let windowList = allQuickTimeWindows.map { "\($0.title ?? "untitled") (\(Int($0.frame.width))x\(Int($0.frame.height)))" }.joined(separator: ", ")
                errorMessage = "QuickTime not showing iPhone.\n\nFound QuickTime windows: \(windowList.isEmpty ? "none" : windowList)\n\nPlease:\n1. Open QuickTime Player\n2. File → New Movie Recording\n3. Select your iPhone from the dropdown\n4. Restart this app"
                print("DEBUG: Error message set: \(errorMessage ?? "")")
            }

        } catch {
            errorMessage = "Screen capture error: \(error.localizedDescription)"
            print("DEBUG: Error: \(error)")
        }
    }

    /// Capture a specific window
    private func startWindowCapture(window: SCWindow) async throws {
        // Check screen recording permission first
        let canRecord = CGPreflightScreenCaptureAccess()
        if !canRecord {
            print("DEBUG: ⚠️  Screen recording permission not granted!")
            errorMessage = "Screen Recording Permission Required\n\n1. Open System Settings\n2. Privacy & Security → Screen Recording\n3. Enable this app\n4. Restart the app"

            // Request permission
            CGRequestScreenCaptureAccess()
            return
        }

        print("DEBUG: Screen recording permission granted ✓")

        let filter = SCContentFilter(desktopIndependentWindow: window)

        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width) * 2  // Retina
        config.height = Int(window.frame.height) * 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)  // 30 FPS
        config.queueDepth = 3

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)

        // Add output
        print("DEBUG: Adding stream output...")
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)

        print("DEBUG: Starting capture stream...")
        try await stream.startCapture()

        self.stream = stream
        isCapturing = true
        errorMessage = nil

        print("DEBUG: ✓ Started capturing QuickTime window successfully")
    }

    func stopCapture() async {
        if let stream = stream {
            try? await stream.stopCapture()
        }
        stream = nil
        isCapturing = false
    }
}

// MARK: - SCStreamOutput

extension QuickTimeCapture: SCStreamOutput {

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else {
            print("DEBUG: Received non-screen output type: \(type)")
            return
        }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("DEBUG: No image buffer in sample")
            return
        }

        print("DEBUG: Received frame from QuickTime - size: \(CVPixelBufferGetWidth(imageBuffer))x\(CVPixelBufferGetHeight(imageBuffer))")

        // Convert to NSImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("DEBUG: Failed to create CGImage")
            return
        }

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(
            width: CGFloat(CVPixelBufferGetWidth(imageBuffer)),
            height: CGFloat(CVPixelBufferGetHeight(imageBuffer))
        ))

        Task { @MainActor in
            self.currentFrame = nsImage
            print("DEBUG: ✓ Updated currentFrame in QuickTime mode")
        }
    }
}
