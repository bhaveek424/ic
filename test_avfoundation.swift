#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO
import AppKit

print("Testing AVFoundation iPhone capture...")

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

print("Screen capture devices enabled: \(result == 0)")

// Discover devices
let discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external],
    mediaType: .video,
    position: .unspecified
)

let devices = discoverySession.devices
print("Found \(devices.count) external devices:")

for device in devices {
    print("  - \(device.localizedName) (ID: \(device.uniqueID))")
    
    if device.localizedName.lowercased().contains("iphone") {
        print("    -> This is an iPhone!")
        
        // Try to create input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            print("    -> Successfully created device input")
        } catch {
            print("    -> Failed to create input: \(error)")
        }
    }
}