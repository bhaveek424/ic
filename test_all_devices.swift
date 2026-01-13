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

CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &property,
    0,
    nil,
    dataSize,
    &allow
)

print("Testing all device types...")

// Try different discovery approaches
let deviceTypes: [AVCaptureDevice.DeviceType] = [
    .builtInWideAngleCamera,
    .external,
    .continuityCamera
]

var allDevices: [AVCaptureDevice] = []

// Try with empty device types to get ALL devices
let discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [],
    mediaType: .video,
    position: .unspecified
)

allDevices = discoverySession.devices
print("Empty device types found \(allDevices.count) devices")

// Also try nil media type to get everything
if #available(macOS 12.0, *) {
    let allMediaSession = AVCaptureDevice.DiscoverySession(
        deviceTypes: deviceTypes,
        mediaType: nil,
        position: .unspecified
    )
    
    let allMediaDevices = allMediaSession.devices
    print("All media types found \(allMediaDevices.count) devices")
    
    for device in allMediaDevices {
        if !allDevices.contains(where: { $0.uniqueID == device.uniqueID }) {
            allDevices.append(device)
        }
    }
}

print("\nAll unique devices (\(allDevices.count)):")
for device in allDevices {
    print("  - \(device.localizedName)")
}

// Now filter for iPhone
let iphoneDevices = allDevices.filter { device in
    let name = device.localizedName.lowercased()
    return name.contains("iphone") || name.contains("ipad")
}

print("\niPhone devices (\(iphoneDevices.count)):")
for device in iphoneDevices {
    print("  - \(device.localizedName) (ID: \(device.uniqueID))")
}