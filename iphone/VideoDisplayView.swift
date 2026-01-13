//
//  VideoDisplayView.swift
//  iphone
//
//  Displays captured video frames from iPhone screen
//

import SwiftUI
import AppKit

/// SwiftUI view that displays captured iPhone screen frames
struct VideoDisplayView: View {
    
    @ObservedObject var screenCapture: iPhoneScreenCapture
    
    var body: some View {
        GeometryReader { geometry in
            if let frame = screenCapture.currentFrame {
                Image(nsImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                // Placeholder when no frame available
                Color.black
            }
        }
    }
}

/// NSView-based display for higher performance (alternative to SwiftUI)
class VideoDisplayNSView: NSView {
    
    private var imageLayer: CALayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.contentsGravity = .resizeAspect
    }
    
    func updateFrame(_ image: NSImage) {
        DispatchQueue.main.async { [weak self] in
            self?.layer?.contents = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
    }
    
    func clear() {
        layer?.contents = nil
    }
}

/// NSViewRepresentable wrapper for VideoDisplayNSView
struct VideoDisplayNSViewRepresentable: NSViewRepresentable {
    
    let image: NSImage?
    
    func makeNSView(context: Context) -> VideoDisplayNSView {
        VideoDisplayNSView(frame: .zero)
    }
    
    func updateNSView(_ nsView: VideoDisplayNSView, context: Context) {
        if let image = image {
            nsView.updateFrame(image)
        } else {
            nsView.clear()
        }
    }
}

// MARK: - Preview

#Preview {
    VideoDisplayView(screenCapture: iPhoneScreenCapture.shared)
        .frame(width: 390, height: 844)
        .background(Color.black)
}
