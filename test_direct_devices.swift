#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO
import Foundation

print("Testing direct device access...")

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

// Try to get devices by iterating through all possible devices
let devices = AVCaptureDevice.devices()
print("Found \(devices.count) devices using AVCaptureDevice.devices():")

for (index, device) in devices.enumerated() {
    print("[\(index)] \(device.localizedName) - \(device.uniqueID)")
    
    if device.localizedName.contains("Desk View") {
        print("-> Found Desk View device!")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            print("-> Successfully created input for Desk View")
        } catch {
            print("-> Failed to create input: \(error)")
        }
    }
}