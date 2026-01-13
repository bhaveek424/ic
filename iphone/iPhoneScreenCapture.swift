//
//  iPhoneScreenCapture.swift
//  iphone
//
//  Captures iPhone screen content using libimobiledevice
//

import Foundation
import AppKit
import Combine

/// Capture error types
enum CaptureError: Error, LocalizedError {
    case developerModeRequired
    case deviceLocked
    case noDevice
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .developerModeRequired:
            return "Developer Mode required. Enable in iPhone Settings > Privacy & Security > Developer Mode"
        case .deviceLocked:
            return "iPhone is locked. Please unlock your device."
        case .noDevice:
            return "No iPhone connected"
        case .unknown(let msg):
            return msg
        }
    }
}

/// Manages iPhone screen capture via libimobiledevice
@MainActor
class iPhoneScreenCapture: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentFrame: NSImage?
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var fps: Double = 0
    @Published private(set) var lastError: CaptureError?
    
    // MARK: - Private Properties
    
    private var captureTask: Task<Void, Never>?
    private var frameCount: Int = 0
    private var lastFPSUpdate: Date = Date()
    private var consecutiveErrors: Int = 0
    
    /// Target frames per second
    private var targetFPS: Double = 10
    
    /// Interval between frame captures in nanoseconds
    private var captureInterval: UInt64 {
        UInt64(1_000_000_000 / targetFPS)
    }
    
    // MARK: - Singleton
    
    static let shared = iPhoneScreenCapture()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start capturing screen frames
    func startCapture(for deviceUDID: String) {
        guard !isCapturing else { return }
        
        isCapturing = true
        frameCount = 0
        consecutiveErrors = 0
        lastFPSUpdate = Date()
        lastError = nil
        
        captureTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.captureFrame(deviceUDID: deviceUDID)
                try? await Task.sleep(nanoseconds: self?.captureInterval ?? 100_000_000)
            }
        }
    }
    
    /// Stop capturing
    func stopCapture() {
        captureTask?.cancel()
        captureTask = nil
        isCapturing = false
        fps = 0
    }
    
    /// Set target frame rate
    func setTargetFPS(_ fps: Double) {
        targetFPS = max(1, min(30, fps))
    }
    
    // MARK: - Private Methods
    
    private func captureFrame(deviceUDID: String) async {
        // Create temp file for screenshot
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        do {
            // Capture screenshot using idevicescreenshot (correct command name)
            _ = try await ProcessWrapper.execute(
                command: "idevicescreenshot",
                arguments: ["-u", deviceUDID, tempURL.path],
                timeout: 3
            )
            
            // Load the captured image
            if let image = NSImage(contentsOf: tempURL) {
                self.currentFrame = image
                self.lastError = nil
                self.consecutiveErrors = 0
                updateFPS()
            }
            
        } catch let error as ProcessWrapper.ProcessError {
            consecutiveErrors += 1
            
            // Parse the error to give user helpful feedback
            if case .executionFailed(let output, _) = error {
                if output.contains("Invalid service") || output.contains("Developer disk image") {
                    lastError = .developerModeRequired
                } else if output.contains("locked") {
                    lastError = .deviceLocked
                } else {
                    lastError = .unknown(output)
                }
            }
            
            // If too many consecutive errors, slow down polling
            if consecutiveErrors > 10 {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Slow to 2 second intervals
            }
            
        } catch {
            consecutiveErrors += 1
        }
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    private func updateFPS() {
        frameCount += 1
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSUpdate)
        
        if elapsed >= 1.0 {
            fps = Double(frameCount) / elapsed
            frameCount = 0
            lastFPSUpdate = now
        }
    }
}

