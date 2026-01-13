#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO
import AppKit
import Foundation

print("Testing live iPhone capture...")

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

// Find iPhone
let discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.continuityCamera, .external],
    mediaType: .video,
    position: .unspecified
)

guard let device = discoverySession.devices.first(where: { 
    $0.localizedName.lowercased().contains("iphone") 
}) else {
    print("No iPhone found!")
    exit(1)
}

print("Found iPhone: \(device.localizedName)")

// Setup capture session
let session = AVCaptureSession()
session.sessionPreset = .high

do {
    let input = try AVCaptureDeviceInput(device: device)
    session.addInput(input)
    
    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    
    class CaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var frameCount = 0
        let semaphore = DispatchSemaphore(value: 0)
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            frameCount += 1
            print("Received frame \(frameCount)")
            
            if frameCount >= 5 {
                semaphore.signal()
            }
        }
    }
    
    let delegate = CaptureDelegate()
    output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "capture"))
    
    session.addOutput(output)
    session.startRunning()
    
    print("Capturing... (waiting for 5 frames)")
    delegate.semaphore.wait()
    
    session.stopRunning()
    print("Success! Captured \(delegate.frameCount) frames")
    
} catch {
    print("Error: \(error)")
}