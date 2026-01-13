//
//  ProcessWrapper.swift
//  iphone
//
//  Utility for executing CLI commands (libimobiledevice tools)
//

import Foundation

/// Async wrapper for executing shell commands
actor ProcessWrapper {
    
    enum ProcessError: Error, LocalizedError {
        case commandNotFound(String)
        case executionFailed(String, Int32)
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .commandNotFound(let command):
                return "Command not found: \(command). Make sure libimobiledevice is installed via: brew install libimobiledevice"
            case .executionFailed(let output, let code):
                return "Command failed with exit code \(code): \(output)"
            case .timeout:
                return "Command execution timed out"
            }
        }
    }
    
    /// Execute a command and return the output
    static func execute(
        command: String,
        arguments: [String] = [],
        timeout: TimeInterval = 10
    ) async throws -> String {
        
        // Check if command exists
        let commandPath = try await findCommand(command)
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: commandPath)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            // Timeout handling
            let timeoutWorkItem = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
            
            process.terminationHandler = { _ in
                timeoutWorkItem.cancel()
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    let combinedOutput = output.isEmpty ? errorOutput : output
                    continuation.resume(throwing: ProcessError.executionFailed(combinedOutput, process.terminationStatus))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Find the full path of a command
    private static func findCommand(_ command: String) async throws -> String {
        // Common paths where Homebrew installs binaries
        let searchPaths = [
            "/opt/homebrew/bin/\(command)",      // Apple Silicon Homebrew
            "/usr/local/bin/\(command)",          // Intel Homebrew
            "/usr/bin/\(command)",                // System
            "/bin/\(command)"                     // System
        ]
        
        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        throw ProcessError.commandNotFound(command)
    }
    
    /// Stream output from a long-running command
    static func stream(
        command: String,
        arguments: [String] = [],
        onOutput: @escaping (String) -> Void
    ) async throws -> Process {
        
        let commandPath = try await findCommand(command)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: commandPath)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                onOutput(output)
            }
        }
        
        try process.run()
        return process
    }
}
