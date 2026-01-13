#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO
import Foundation

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

print("Screen capture devices enabled: \(result == kCMIOHardwareNoError)")

// Find iPhone Camera device
let discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.continuityCamera, .external, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
)

let iosDevices = discoverySession.devices.filter { device in
    device.localizedName.lowercased().contains("iphone")
}

guard let cameraDevice = iosDevices.first else {
    print("❌ No iPhone found")
    exit(1)
}

print("\n📱 Found: \(cameraDevice.localizedName)")
print("   Model: \(cameraDevice.modelID)")
print("   Formats: \(cameraDevice.formats.count)")

// Try to create a capture session with the camera
print("\n🔧 Attempting to create capture session...")

let session = AVCaptureSession()
session.sessionPreset = .high

do {
    let input = try AVCaptureDeviceInput(device: cameraDevice)
    
    if session.canAddInput(input) {
        session.addInput(input)
        print("✅ Successfully added camera input")
        
        // Try to start the session
        session.startRunning()
        print("✅ Session started running")
        
        // Wait a moment
        sleep(2)
        
        print("\n📊 Session status:")
        print("   Running: \(session.isRunning)")
        print("   Interrupted: \(session.isInterrupted)")
        
        session.stopRunning()
        print("\n✅ Test completed - Camera device works")
        
    } else {
        print("❌ Cannot add input to session")
    }
    
} catch {
    let nsError = error as NSError
    print("\n❌ Error creating input:")
    print("   Domain: \(nsError.domain)")
    print("   Code: \(nsError.code)")
    print("   Description: \(error.localizedDescription)")
    
    if nsError.code == -11852 {
        print("\n⚠️  AUTHORIZATION REQUIRED!")
        print("   This is the SCREEN device that needs iPhone authorization.")
        print("   Look at your iPhone for a prompt to Allow access.")
    }
}
