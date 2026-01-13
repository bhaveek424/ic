//
//  PhoneFrameView.swift
//  iphone
//
//  iPhone-shaped frame view for the screen mirror overlay
//

import SwiftUI

/// A view that renders iPhone content without any bezel or decorations
struct PhoneFrameView<Content: View>: View {

    let content: Content

    /// Slight corner radius for subtle edge smoothing
    private let cornerRadius: CGFloat = 10

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // Just show the content with minimal rounded corners
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Dynamic Island visual element
struct DynamicIslandView: View {
    var body: some View {
        Capsule()
            .fill(Color.black)
            .overlay(
                Capsule()
                    .strokeBorder(Color(white: 0.2), lineWidth: 0.5)
            )
    }
}

/// Placeholder content when no device is connected
struct NoDeviceOverlay: View {
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 16) {
                Image(systemName: "iphone.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("No iPhone Connected")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Connect your iPhone via USB cable")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
    }
}

/// Connecting status overlay
struct ConnectingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Connecting...")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview("Phone Frame") {
    PhoneFrameView {
        Color.blue
    }
    .frame(width: 390, height: 844)
    .background(Color.gray.opacity(0.3))
}

#Preview("No Device") {
    PhoneFrameView {
        NoDeviceOverlay()
    }
    .frame(width: 390, height: 844)
    .background(Color.gray.opacity(0.3))
}
