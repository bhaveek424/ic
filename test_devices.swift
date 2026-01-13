#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO

// Enable iOS device capture
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

print("Enable screen capture devices result: \(result == kCMIOHardwareNoError ? "SUCCESS" : "FAILED: \(result)")")
print("")

// Discover all video devices
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

print("Found \(allDevices.count) total video devices:\n")

for (index, device) in allDevices.enumerated() {
    print("Device \(index + 1):")
    print("  Name: \(device.localizedName)")
    print("  ID: \(device.uniqueID)")
    print("  Model: \(device.modelID)")
    print("  Type: \(device.deviceType.rawValue)")
    print("  Connected: \(device.isConnected)")
    print("  Suspended: \(device.isSuspended)")
    print("  In use: \(device.isInUseByAnotherApplication)")
    print("  Formats: \(device.formats.count)")

    // Try to create input
    do {
        let input = try AVCaptureDeviceInput(device: device)
        print("  ✓ Can create AVCaptureDeviceInput")
    } catch {
        print("  ✗ Cannot create AVCaptureDeviceInput: \(error)")
    }

    print("")
}

// Filter for iOS devices
let iosDevices = allDevices.filter { device in
    let name = device.localizedName.lowercased()
    return name.contains("iphone") || name.contains("ipad")
}

print("\nFound \(iosDevices.count) iOS devices")

// Look for screen devices specifically
let screenDevices = iosDevices.filter { device in
    let name = device.localizedName.lowercased()
    return name.contains("screen")
}

print("Found \(screenDevices.count) iOS SCREEN devices")

if let device = iosDevices.first {
    print("Will use: \(device.localizedName)")
    if screenDevices.isEmpty {
        print("\n⚠️  WARNING: No screen device found!")
        print("Only found camera device. Screen mirroring may not work.")
        print("\nTo fix:")
        print("1. Open QuickTime Player")
        print("2. File → New Movie Recording")
        print("3. Select '\(device.localizedName) Screen' from dropdown")
    }
}
