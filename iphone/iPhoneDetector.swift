//
//  iPhoneDetector.swift
//  iphone
//
//  Detects connected iPhones via USB using libimobiledevice
//

import Foundation
import Combine

/// Represents a connected iPhone device
struct iPhoneDevice: Identifiable, Equatable {
    let id: String  // UDID
    var name: String
    var model: String
    var productType: String
    var iOSVersion: String
    
    init(udid: String) {
        self.id = udid
        self.name = "iPhone"
        self.model = "Unknown"
        self.productType = "Unknown"
        self.iOSVersion = "Unknown"
    }
}

/// Connection status for the detector
enum ConnectionStatus: Equatable {
    case disconnected
    case searching
    case connected(iPhoneDevice)
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.searching, .searching): return true
        case (.connected(let l), .connected(let r)): return l == r
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}

/// Detects connected iPhones via USB
@MainActor
class iPhoneDetector: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var status: ConnectionStatus = .disconnected
    @Published private(set) var device: iPhoneDevice?
    
    // MARK: - Private Properties
    
    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 2.0
    
    // MARK: - Singleton
    
    static let shared = iPhoneDetector()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start polling for device connections
    func startPolling() {
        stopPolling()
        
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkForDevices()
                try? await Task.sleep(nanoseconds: UInt64(2_000_000_000)) // 2 seconds
            }
        }
    }
    
    /// Stop polling for devices
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    /// Manually trigger a device check
    func checkNow() {
        Task {
            await checkForDevices()
        }
    }
    
    // MARK: - Private Methods
    
    private func checkForDevices() async {
        status = .searching
        
        do {
            // Get list of connected device UDIDs
            let output = try await ProcessWrapper.execute(command: "idevice_id", arguments: ["-l"])
            
            let udids = output
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if let firstUDID = udids.first {
                // Device connected - get device info
                var device = iPhoneDevice(udid: firstUDID)
                device = await fetchDeviceInfo(for: device)
                
                self.device = device
                self.status = .connected(device)
            } else {
                // No device connected
                self.device = nil
                self.status = .disconnected
            }
            
        } catch let error as ProcessWrapper.ProcessError {
            // If command not found, show appropriate error
            if case .commandNotFound = error {
                self.status = .error("libimobiledevice not installed")
            } else {
                // Other errors likely mean no device connected
                self.device = nil
                self.status = .disconnected
            }
        } catch {
            self.device = nil
            self.status = .disconnected
        }
    }
    
    private func fetchDeviceInfo(for device: iPhoneDevice) async -> iPhoneDevice {
        var updatedDevice = device
        
        do {
            // Get device name
            let nameOutput = try await ProcessWrapper.execute(
                command: "ideviceinfo",
                arguments: ["-u", device.id, "-k", "DeviceName"]
            )
            updatedDevice.name = nameOutput.isEmpty ? "iPhone" : nameOutput
            
            // Get product type
            let productOutput = try await ProcessWrapper.execute(
                command: "ideviceinfo",
                arguments: ["-u", device.id, "-k", "ProductType"]
            )
            updatedDevice.productType = productOutput
            updatedDevice.model = mapProductTypeToModel(productOutput)
            
            // Get iOS version
            let versionOutput = try await ProcessWrapper.execute(
                command: "ideviceinfo",
                arguments: ["-u", device.id, "-k", "ProductVersion"]
            )
            updatedDevice.iOSVersion = versionOutput
            
        } catch {
            // Keep default values on error
        }
        
        return updatedDevice
    }
    
    /// Map product type to human-readable model name
    private func mapProductTypeToModel(_ productType: String) -> String {
        let modelMap: [String: String] = [
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone15,4": "iPhone 15",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone14,7": "iPhone 14",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",
        ]
        
        return modelMap[productType] ?? productType
    }
}
