//
//  AVFoundationCapture.swift
//  iphone
//
//  Native AVFoundation-based iPhone screen capture via USB
//  Works with iOS 17+ unlike libimobiledevice
//

import AVFoundation
import AppKit
import CoreMediaIO
@preconcurrency import AVFoundation

/// Native macOS screen capture using AVFoundation
/// This captures the iPhone screen the same way QuickTime does
@MainActor
class AVFoundationCapture: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentFrame: NSImage?
    @Published private(set) var isCapturing: Bool = false
    @Published private(set) var isDeviceConnected: Bool = false
    @Published private(set) var deviceName: String = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var waitingForScreenDevice: Bool = false
    
    // MARK: - Private Properties
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentDevice: AVCaptureDevice?
    private let captureQueue = DispatchQueue(label: "com.iphone.capture", qos: .userInteractive)
    
    // MARK: - Singleton
    
    static let shared = AVFoundationCapture()
    
    private override init() {
        super.init()
        enableScreenCaptureDevices()
        setupDeviceNotifications()
    }
    
    // MARK: - Setup
    
    /// Enable iOS device capture (required for macOS to see iOS devices as capture sources)
    private func enableScreenCaptureDevices() {
        // This enables iOS devices to appear as capture devices
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var allow: UInt32 = 1
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let result = CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0,
            nil,
            dataSize,
            &allow
        )
        
        if result != kCMIOHardwareNoError {
            print("DEBUG: Error enabling screen capture devices: \(result)")
        } else {
            print("DEBUG: Successfully enabled screen capture devices")
        }
    }
    
    /// Setup notifications for device connection/disconnection
    private func setupDeviceNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceConnected(_:)),
            name: .AVCaptureDeviceWasConnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceDisconnected(_:)),
            name: .AVCaptureDeviceWasDisconnected,
            object: nil
        )
        
        // Check for already connected devices
        Task {
            await checkForConnectedDevices()
        }
    }
    
    // MARK: - Device Discovery
    
/// Find connected iOS devices (iPhone/iPad)
    func discoverIOSDevices() -> [AVCaptureDevice] {
        // Try different device types that might include iOS devices
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .continuityCamera,
            .external,
            .builtInWideAngleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        let allDevices = discoverySession.devices
        print("DEBUG: Found \(allDevices.count) total video devices")
        
        // Filter for iOS devices (they have "iPhone" or "iPad" in their name)
        let iosDevices = allDevices.filter { device in
            let name = device.localizedName.lowercased()
            print("DEBUG: Found device: \(device.localizedName) (ID: \(device.uniqueID))")
            return name.contains("iphone") || name.contains("ipad")
        }

        // Sort devices: prefer screen devices over camera devices
        // Screen devices have Model ID "iOS Device" and only 1 format
        // Camera devices have Model ID like "iPhone18,1" and many formats
        let sortedDevices = iosDevices.sorted { device1, device2 in
            let name1 = device1.localizedName.lowercased()
            let name2 = device2.localizedName.lowercased()

            // Screen device has fewer formats (1) vs camera (8+)
            let isScreen1 = device1.formats.count <= 2
            let isScreen2 = device2.formats.count <= 2

            // Prefer screen device
            if isScreen1 != isScreen2 {
                return isScreen1  // Screen device comes first
            }

            // If both are same type, prefer device without "Camera" in name
            let hasCamera1 = name1.contains("camera")
            let hasCamera2 = name2.contains("camera")

            if hasCamera1 != hasCamera2 {
                return !hasCamera1  // Non-camera (screen) comes first
            }

            // Otherwise sort alphabetically
            return name1 < name2
        }

        print("DEBUG: Found \(sortedDevices.count) iOS devices")
        for (index, device) in sortedDevices.enumerated() {
            print("DEBUG: Device \(index): \(device.localizedName), Formats: \(device.formats.count), Model: \(device.modelID)")
        }
        return sortedDevices
    }
    
    /// Check for already connected devices on launch
    private func checkForConnectedDevices() async {
        let devices = discoverIOSDevices()
        if let device = devices.first {
            print("DEBUG: Auto-connecting to \(device.localizedName)")
            await MainActor.run {
                self.currentDevice = device
                self.deviceName = device.localizedName
                self.isDeviceConnected = true
                self.errorMessage = nil
            }
        } else {
            print("DEBUG: No devices found on launch")
        }
    }
    
    // MARK: - Capture Control
    
    /// Start capturing from the connected iOS device
    func startCapture() {
        guard !isCapturing else { return }

        print("DEBUG: Starting capture...")

        // Find iOS device
        let devices = discoverIOSDevices()

        // Filter for screen devices only (not camera)
        let screenDevices = devices.filter { device in
            let isScreen = device.formats.count <= 2 && !device.localizedName.lowercased().contains("camera")
            return isScreen
        }

        let deviceToUse = currentDevice ?? screenDevices.first ?? devices.first

        guard let device = deviceToUse else {
            errorMessage = "No iPhone screen found.\n\nPlease unplug and replug your iPhone."
            print("DEBUG: No iOS device found")
            return
        }

        // Check if it's a camera device (not screen)
        let isCamera = device.formats.count > 2 || device.localizedName.lowercased().contains("camera")
        if isCamera {
            waitingForScreenDevice = true
            errorMessage = "Waiting for screen device...\n\nPlease UNPLUG and REPLUG your iPhone\nto enable screen sharing."
            print("DEBUG: ⚠️  Only found camera device, not screen. Waiting for unplug/replug...")
            print("DEBUG: ⚠️  Device: \(device.localizedName), Formats: \(device.formats.count)")
            return
        }

        // Found screen device!
        waitingForScreenDevice = false
        
        currentDevice = device
        deviceName = device.localizedName
        isDeviceConnected = true
        
        // Setup capture session
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        do {
            // Add video input from iOS device
            print("DEBUG: Attempting to create input for device: \(device.localizedName)")
            print("DEBUG: Device ID: \(device.uniqueID)")
            print("DEBUG: Device Model: \(device.modelID)")
            print("DEBUG: Device Connected: \(device.isConnected)")
            print("DEBUG: Device Suspended: \(device.isSuspended)")
            print("DEBUG: Device Formats: \(device.formats.count)")
            
            let input = try AVCaptureDeviceInput(device: device)
            print("DEBUG: Successfully created device input")
            
            if session.canAddInput(input) {
                session.addInput(input)
                print("DEBUG: Successfully added input to session")
            } else {
                errorMessage = "Cannot add device input to session. Device may be in use by another app."
                print("DEBUG: Cannot add input to session")
                print("DEBUG: Session inputs: \(session.inputs)")
                print("DEBUG: Device isConnected: \(device.isConnected)")
                print("DEBUG: Device isInUseByAnotherApplication: \(device.isInUseByAnotherApplication)")
                return
            }
            
            // Add video output
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: captureQueue)
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                errorMessage = "Cannot add video output"
                return
            }
            
            self.captureSession = session
            self.videoOutput = output
            
            // Start capture on background thread
            captureQueue.async { [weak self, session] in
                session.startRunning()
                print("DEBUG: Capture session started running")
                DispatchQueue.main.async {
                    print("DEBUG: Session.isRunning = \(session.isRunning)")
                }
            }
            
            isCapturing = true
            errorMessage = nil
            print("DEBUG: Capture setup completed successfully")
            
        } catch {
            print("DEBUG: Detailed capture error: \(error)")
            let nsError = error as NSError
            print("DEBUG: Error Domain: \(nsError.domain), Code: \(nsError.code)")
            print("DEBUG: User Info: \(nsError.userInfo)")

            // Check for authorization error (code -11852)
            if nsError.domain == "AVFoundationErrorDomain" && nsError.code == -11852 {
                errorMessage = "Authorization Blocked by iPhone\n\nYour iPhone denied access.\n\nTo fix:\n1. Unplug iPhone\n2. iPhone Settings → General\n   → Transfer or Reset iPhone\n   → Reset → Reset Location & Privacy\n3. Reconnect and try again"
                print("DEBUG: ⚠️  AUTHORIZATION DENIED BY iPHONE!")
                print("DEBUG: ⚠️  iPhone has blocked this app. Need to reset privacy on iPhone.")
                print("DEBUG: ⚠️  Alternative: Create a release build instead of debug build")
            } else {
                errorMessage = "Failed to start capture: \(error.localizedDescription)"
            }
        }
    }
    
    /// Stop capturing
    func stopCapture() {
        captureQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
        captureSession = nil
        videoOutput = nil
        isCapturing = false
    }
    
    // MARK: - Notifications
    
    @objc private func deviceConnected(_ notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice else { return }

        let name = device.localizedName.lowercased()
        let isScreen = device.formats.count <= 2 && !name.contains("camera")

        print("DEBUG: Device connected notification: \(device.localizedName)")
        print("DEBUG:   Model: \(device.modelID), Formats: \(device.formats.count), Is Screen: \(isScreen)")

        if name.contains("iphone") || name.contains("ipad") {
            // Only switch devices if:
            // 1. No current device, OR
            // 2. New device is a screen device and current is not
            let shouldSwitch = currentDevice == nil || (isScreen && !(currentDevice?.formats.count ?? 99 <= 2))

            if shouldSwitch {
                print("DEBUG: Switching to iOS device: \(device.localizedName)")
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    // Stop current capture if running
                    if self.isCapturing {
                        self.stopCapture()
                    }

                    self.currentDevice = device
                    self.deviceName = device.localizedName
                    self.isDeviceConnected = true
                    self.errorMessage = nil

                    // Auto-start capture when device connects
                    self.startCapture()
                }
            } else {
                print("DEBUG: Ignoring device (current device is preferred)")
            }
        }
    }
    
    @objc private func deviceDisconnected(_ notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice else { return }
        
        if device == currentDevice {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.stopCapture()
                self.currentDevice = nil
                self.deviceName = ""
                self.isDeviceConnected = false
                self.currentFrame = nil
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension AVFoundationCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            print("DEBUG: No image buffer in sample")
            return 
        }
        
        // Convert CVPixelBuffer to NSImage
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
        
        print("DEBUG: Successfully captured frame: \(nsImage.size)")
        
        // Update on main thread
        Task { @MainActor in
            self.currentFrame = nsImage
            print("DEBUG: Updated currentFrame with size: \(nsImage.size)")
        }
    }
    
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frame dropped - this is normal under load
    }
}
