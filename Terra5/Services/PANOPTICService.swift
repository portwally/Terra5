//
//  PANOPTICService.swift
//  Terra5
//
//  AI Object Detection service (simulated)
//  In production, this would use CoreML with YOLOv8 or similar
//

import Foundation
import CoreGraphics

actor PANOPTICService {
    static let shared = PANOPTICService()

    private init() {}

    // Detection categories
    enum DetectionCategory: String, CaseIterable {
        case vehicle = "VEHICLE"
        case aircraft = "AIRCRAFT"
        case vessel = "VESSEL"
        case building = "BUILDING"
        case person = "PERSON"
        case infrastructure = "INFRA"

        var color: String {
            switch self {
            case .vehicle: return "#00ff88"
            case .aircraft: return "#00d4aa"
            case .vessel: return "#0099ff"
            case .building: return "#ffaa00"
            case .person: return "#ff6600"
            case .infrastructure: return "#ff00ff"
            }
        }

        var icon: String {
            switch self {
            case .vehicle: return "car.fill"
            case .aircraft: return "airplane"
            case .vessel: return "ferry.fill"
            case .building: return "building.2.fill"
            case .person: return "person.fill"
            case .infrastructure: return "gearshape.fill"
            }
        }
    }

    // Detection result
    struct Detection: Identifiable {
        let id: String
        let category: DetectionCategory
        let confidence: Double
        let boundingBox: CGRect
        let timestamp: Date
        let trackId: String?

        var confidencePercent: String {
            String(format: "%.1f%%", confidence * 100)
        }

        var label: String {
            "\(category.rawValue) \(confidencePercent)"
        }
    }

    // Detection statistics
    struct DetectionStats {
        var totalDetections: Int = 0
        var detectionsByCategory: [DetectionCategory: Int] = [:]
        var averageConfidence: Double = 0
        var processingLatency: Double = 0 // milliseconds
        var framesProcessed: Int = 0

        var density: Double {
            // Detections per frame
            guard framesProcessed > 0 else { return 0 }
            return Double(totalDetections) / Double(framesProcessed)
        }
    }

    private var isProcessing = false
    private var stats = DetectionStats()

    /// Simulate AI detection on current view
    /// In production, this would analyze camera feed or satellite imagery
    func runDetection(
        latitude: Double,
        longitude: Double,
        altitude: Double
    ) async -> [Detection] {
        guard !isProcessing else { return [] }
        isProcessing = true

        let startTime = Date()

        // Simulate processing delay (50-150ms)
        let processingTime = Double.random(in: 50...150)
        try? await Task.sleep(nanoseconds: UInt64(processingTime * 1_000_000))

        // Generate simulated detections based on location
        var detections: [Detection] = []
        let detectionCount = Int.random(in: 3...15)

        for i in 0..<detectionCount {
            let category = DetectionCategory.allCases.randomElement() ?? .vehicle
            let confidence = Double.random(in: 0.65...0.99)

            // Generate bounding box (normalized coordinates 0-1)
            let boxWidth = CGFloat.random(in: 0.02...0.15)
            let boxHeight = CGFloat.random(in: 0.02...0.12)
            let boxX = CGFloat.random(in: 0...(1 - boxWidth))
            let boxY = CGFloat.random(in: 0...(1 - boxHeight))

            let detection = Detection(
                id: "DET-\(UUID().uuidString.prefix(8))",
                category: category,
                confidence: confidence,
                boundingBox: CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight),
                timestamp: Date(),
                trackId: "TRK-\(i + 1)"
            )
            detections.append(detection)
        }

        // Update stats
        let latency = Date().timeIntervalSince(startTime) * 1000
        stats.totalDetections += detections.count
        stats.processingLatency = latency
        stats.framesProcessed += 1

        for detection in detections {
            stats.detectionsByCategory[detection.category, default: 0] += 1
        }

        if !detections.isEmpty {
            stats.averageConfidence = detections.map { $0.confidence }.reduce(0, +) / Double(detections.count)
        }

        isProcessing = false

        print("PANOPTIC: Detected \(detections.count) objects in \(String(format: "%.1f", latency))ms")
        return detections
    }

    /// Get current detection statistics
    func getStats() -> DetectionStats {
        return stats
    }

    /// Reset detection statistics
    func resetStats() {
        stats = DetectionStats()
    }

    /// Check if detection is currently running
    func isDetectionRunning() -> Bool {
        return isProcessing
    }
}

// MARK: - Detection Overlay View
import SwiftUI

struct DetectionOverlayView: View {
    let detections: [PANOPTICService.Detection]
    let isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Detection bounding boxes
                ForEach(detections) { detection in
                    DetectionBox(
                        detection: detection,
                        containerSize: geometry.size
                    )
                }

                // Scanning line animation when active
                if isActive {
                    ScanningLine()
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct DetectionBox: View {
    let detection: PANOPTICService.Detection
    let containerSize: CGSize

    var body: some View {
        let rect = CGRect(
            x: detection.boundingBox.minX * containerSize.width,
            y: detection.boundingBox.minY * containerSize.height,
            width: detection.boundingBox.width * containerSize.width,
            height: detection.boundingBox.height * containerSize.height
        )

        ZStack(alignment: .topLeading) {
            // Bounding box
            Rectangle()
                .stroke(Color(hex: detection.category.color), lineWidth: 2)
                .frame(width: rect.width, height: rect.height)

            // Corner brackets
            CornerBracketsSmall(color: Color(hex: detection.category.color))
                .frame(width: rect.width, height: rect.height)

            // Label
            HStack(spacing: 4) {
                Image(systemName: detection.category.icon)
                    .font(.system(size: 8))
                Text(detection.label)
                    .font(.custom("Menlo", size: 8))
            }
            .foregroundColor(Color(hex: detection.category.color))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .offset(y: -16)
        }
        .position(x: rect.midX, y: rect.midY)
    }
}

struct CornerBracketsSmall: View {
    let color: Color
    let bracketLength: CGFloat = 8
    let bracketWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: bracketLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: bracketLength, y: 0))
            }
            .stroke(color, lineWidth: bracketWidth)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: width - bracketLength, y: 0))
                path.addLine(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: width, y: bracketLength))
            }
            .stroke(color, lineWidth: bracketWidth)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: height - bracketLength))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: bracketLength, y: height))
            }
            .stroke(color, lineWidth: bracketWidth)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: width - bracketLength, y: height))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: width, y: height - bracketLength))
            }
            .stroke(color, lineWidth: bracketWidth)
        }
    }
}

struct ScanningLine: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#00d4aa").opacity(0),
                            Color(hex: "#00d4aa").opacity(0.5),
                            Color(hex: "#00d4aa").opacity(0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 4)
                .offset(y: offset)
                .onAppear {
                    withAnimation(
                        .linear(duration: 2)
                        .repeatForever(autoreverses: false)
                    ) {
                        offset = geometry.size.height
                    }
                }
        }
    }
}

#Preview {
    DetectionOverlayView(
        detections: [
            PANOPTICService.Detection(
                id: "1",
                category: .vehicle,
                confidence: 0.95,
                boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.1, height: 0.08),
                timestamp: Date(),
                trackId: "TRK-1"
            ),
            PANOPTICService.Detection(
                id: "2",
                category: .aircraft,
                confidence: 0.88,
                boundingBox: CGRect(x: 0.5, y: 0.4, width: 0.15, height: 0.1),
                timestamp: Date(),
                trackId: "TRK-2"
            )
        ],
        isActive: true
    )
    .frame(width: 800, height: 600)
    .background(Color.black)
}
