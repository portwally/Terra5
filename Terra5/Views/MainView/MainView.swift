//
//  MainView.swift
//  Terra5
//
//  Primary layout container for WORLDVIEW interface
//

import SwiftUI

struct MainView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        ZStack {
            // Background
            Theme.background
                .ignoresSafeArea()

            // Main content
            HStack(spacing: 0) {
                // Collapsible sidebar
                if appState.isSidebarExpanded {
                    SidebarView()
                        .frame(width: 380)
                        .transition(.move(edge: .leading))
                }

                // Globe container with HUD overlay
                ZStack {
                    // Native MapKit Globe (no WebKit sandbox issues)
                    MapKitGlobeView()
                        .environmentObject(appState)

                    // PANOPTIC Detection overlay
                    if appState.isPanopticActive {
                        DetectionOverlayView(
                            detections: appState.currentDetections,
                            isActive: appState.isDetectionRunning
                        )
                    }

                    // HUD overlays
                    TacticalHUDView()
                        .environmentObject(appState)

                    // Visual mode overlay (scanlines for CRT, etc.)
                    VisualModeOverlay(mode: appState.visualMode)
                }
            }

            // Classification header (always on top)
            VStack(spacing: 0) {
                ClassificationHeader()
                    .environmentObject(appState)
                Spacer()
            }
        }
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.isSidebarExpanded.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .togglePanoptic)) { _ in
            appState.togglePanoptic()
        }
        .onReceive(NotificationCenter.default.publisher(for: .setVisualMode)) { notification in
            if let mode = notification.object as? VisualMode {
                appState.visualMode = mode
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .flyToCity)) { notification in
            if let city = notification.object as? CityPreset {
                appState.selectCity(city)
                appState.selectedLandmark = Landmark(
                    name: city.name,
                    latitude: city.latitude,
                    longitude: city.longitude
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleLayer)) { notification in
            if let layer = notification.object as? DataLayerType {
                appState.toggleLayer(layer)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshAllData)) { _ in
            appState.stopDataRefresh()
            appState.startDataRefresh()
        }
    }
}

// MARK: - Classification Header
struct ClassificationHeader: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // Classification marking
            Text(AppConfig.classificationText)
                .font(Typography.classificationFont)
                .foregroundColor(Theme.topSecret)
                .tracking(1)

            Spacer()

            // App name
            HStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                    .foregroundColor(Theme.accent)
                Text(AppConfig.appName)
                    .font(Typography.headerFont)
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            // Satellite designation & time
            HStack(spacing: 16) {
                Text(AppConfig.satelliteDesignation)
                    .font(Typography.classificationFont)
                    .foregroundColor(Theme.accent)

                Text(appState.recordingTimestamp)
                    .font(Typography.classificationFont)
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.background.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.border),
            alignment: .bottom
        )
    }
}

// MARK: - Tactical HUD View
struct TacticalHUDView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Corner brackets (decorative)
            CornerBrackets()

            // Top-right info panel
            VStack {
                HStack {
                    Spacer()
                    InfoPanel()
                        .environmentObject(appState)
                }
                Spacer()
            }
            .padding(.top, 50)
            .padding(.trailing, 16)

            // Bottom-left coordinates
            VStack {
                Spacer()
                HStack {
                    CoordinatesPanel()
                        .environmentObject(appState)
                    Spacer()
                }
            }
            .padding(.bottom, 16)
            .padding(.leading, 16)

            // Center crosshair
            CrosshairView()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Info Panel (Top Right)
struct InfoPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Recording indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.alert)
                    .frame(width: 8, height: 8)
                Text("REC")
                    .font(Typography.labelFont)
                    .foregroundColor(Theme.alert)
            }

            // Orbital info
            Group {
                HStack {
                    Text("ORB:")
                        .foregroundColor(Theme.textMuted)
                    Text("47639")
                        .foregroundColor(Theme.accent)
                }
                HStack {
                    Text("PASS:")
                        .foregroundColor(Theme.textMuted)
                    Text("DESC-179")
                        .foregroundColor(Theme.accent)
                }
            }
            .font(Typography.hudFont)

            Divider()
                .frame(width: 120)
                .background(Theme.border)

            // GSD & NIIRS
            HStack {
                Text("GSD:")
                    .foregroundColor(Theme.textMuted)
                Text(appState.gsdValue)
                    .foregroundColor(Theme.accent)
                Text("NIIRS:")
                    .foregroundColor(Theme.textMuted)
                Text(appState.niirsValue)
                    .foregroundColor(Theme.accent)
            }
            .font(Typography.hudFont)

            // Altitude
            HStack {
                Text("ALT:")
                    .foregroundColor(Theme.textMuted)
                Text("\(appState.formattedAltitude)M")
                    .foregroundColor(Theme.accent)
            }
            .font(Typography.hudFont)
        }
        .padding(12)
        .background(Theme.panelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Coordinates Panel (Bottom Left)
struct CoordinatesPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appState.mgrsCoordinates)
                .font(Typography.hudFont)
                .foregroundColor(Theme.accent)

            Text(appState.formattedCoordinates)
                .font(Typography.hudFont)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(8)
        .background(Theme.panelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Corner Brackets
struct CornerBrackets: View {
    var body: some View {
        GeometryReader { geometry in
            let bracketSize: CGFloat = 40
            let strokeWidth: CGFloat = 2

            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 20, y: 60))
                path.addLine(to: CGPoint(x: 20, y: 20))
                path.addLine(to: CGPoint(x: 60, y: 20))
            }
            .stroke(Theme.accent.opacity(0.5), lineWidth: strokeWidth)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: geometry.size.width - 60, y: 20))
                path.addLine(to: CGPoint(x: geometry.size.width - 20, y: 20))
                path.addLine(to: CGPoint(x: geometry.size.width - 20, y: 60))
            }
            .stroke(Theme.accent.opacity(0.5), lineWidth: strokeWidth)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 20, y: geometry.size.height - 60))
                path.addLine(to: CGPoint(x: 20, y: geometry.size.height - 20))
                path.addLine(to: CGPoint(x: 60, y: geometry.size.height - 20))
            }
            .stroke(Theme.accent.opacity(0.5), lineWidth: strokeWidth)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: geometry.size.width - 60, y: geometry.size.height - 20))
                path.addLine(to: CGPoint(x: geometry.size.width - 20, y: geometry.size.height - 20))
                path.addLine(to: CGPoint(x: geometry.size.width - 20, y: geometry.size.height - 60))
            }
            .stroke(Theme.accent.opacity(0.5), lineWidth: strokeWidth)
        }
    }
}

// MARK: - Crosshair View
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Theme.accent.opacity(0.3))
                .frame(width: 40, height: 1)

            // Vertical line
            Rectangle()
                .fill(Theme.accent.opacity(0.3))
                .frame(width: 1, height: 40)

            // Center dot
            Circle()
                .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Visual Mode Overlay
struct VisualModeOverlay: View {
    let mode: VisualMode

    var body: some View {
        ZStack {
            switch mode {
            case .normal:
                EmptyView()
            case .crt:
                CRTOverlay()
            case .nvg:
                NVGOverlay()
            case .flir:
                FLIROverlay()
            case .noir:
                NoirOverlay()
            case .snow:
                SnowOverlay()
            case .anime:
                AnimeOverlay()
            case .ai:
                AIOverlay()
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - CRT Overlay (green phosphor monitor)
struct CRTOverlay: View {
    var body: some View {
        ZStack {
            // Green tint
            Color.green.opacity(0.08)

            // Scanlines
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 3) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.2)))
                }
            }

            // Vignette effect
            RadialGradient(
                colors: [.clear, .black.opacity(0.4)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )

            // Subtle flicker animation
            CRTFlicker()
        }
    }
}

struct CRTFlicker: View {
    @State private var opacity: Double = 0

    var body: some View {
        Color.green.opacity(opacity * 0.03)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - NVG Overlay (night vision green)
struct NVGOverlay: View {
    @State private var noiseOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Strong green tint
            Color(red: 0, green: 0.4, blue: 0.1).opacity(0.35)
                .blendMode(.overlay)

            // Green color multiply
            Color(red: 0.2, green: 1.0, blue: 0.3).opacity(0.25)
                .blendMode(.multiply)

            // Noise grain
            NVGNoise(offset: noiseOffset)

            // Vignette (stronger for NVG)
            RadialGradient(
                colors: [.clear, .black.opacity(0.6)],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )

            // Circular scope overlay
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: 500, height: 500)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.05).repeatForever(autoreverses: false)) {
                noiseOffset = 100
            }
        }
    }
}

struct NVGNoise: View {
    let offset: CGFloat

    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height / 200) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(Path(rect), with: .color(.white.opacity(Double.random(in: 0...0.15))))
            }
        }
    }
}

// MARK: - FLIR Overlay (thermal imaging)
struct FLIROverlay: View {
    var body: some View {
        ZStack {
            // Thermal color shift (inverted + warm tones)
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0, blue: 0.3).opacity(0.3),
                    Color(red: 0.5, green: 0, blue: 0.5).opacity(0.2),
                    Color(red: 1.0, green: 0.5, blue: 0).opacity(0.15),
                    Color(red: 1.0, green: 1.0, blue: 0).opacity(0.1)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .blendMode(.overlay)

            // Heat signature highlight
            Color(red: 1.0, green: 0.3, blue: 0).opacity(0.1)
                .blendMode(.screen)

            // FLIR UI elements
            FLIRGrid()

            // Temperature scale
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FLIRScale()
                        .padding(20)
                }
            }
        }
    }
}

struct FLIRGrid: View {
    var body: some View {
        Canvas { context, size in
            // Draw grid lines
            let spacing: CGFloat = 50
            for x in stride(from: 0, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
            }
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
            }
        }
    }
}

struct FLIRScale: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("°C")
                .font(.system(size: 9, design: .monospaced))
            LinearGradient(
                colors: [.yellow, .orange, .red, .purple, .blue],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 12, height: 80)
            .cornerRadius(2)
            HStack {
                Text("40").font(.system(size: 8, design: .monospaced))
                Spacer()
            }
            .frame(width: 30)
            Spacer().frame(height: 60)
            HStack {
                Text("-20").font(.system(size: 8, design: .monospaced))
                Spacer()
            }
            .frame(width: 30)
        }
        .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Noir Overlay (black & white film)
struct NoirOverlay: View {
    var body: some View {
        ZStack {
            // Desaturation via color blend
            Color.gray.opacity(0.5)
                .blendMode(.saturation)

            // High contrast
            Color.black.opacity(0.15)
                .blendMode(.multiply)

            // Film grain
            FilmGrain()

            // Vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.5)],
                center: .center,
                startRadius: 200,
                endRadius: 550
            )
        }
    }
}

struct FilmGrain: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height / 400) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                let gray = Double.random(in: 0...1)
                context.fill(Path(rect), with: .color(Color(white: gray, opacity: 0.08)))
            }
        }
    }
}

// MARK: - Snow Overlay (cold/winter cam)
struct SnowOverlay: View {
    var body: some View {
        ZStack {
            // Blue tint
            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2)
                .blendMode(.overlay)

            // Desaturation
            Color.gray.opacity(0.3)
                .blendMode(.saturation)

            // Cold highlight
            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.1)
                .blendMode(.screen)

            // Frost vignette
            RadialGradient(
                colors: [.clear, Color(red: 0.8, green: 0.9, blue: 1.0).opacity(0.3)],
                center: .center,
                startRadius: 300,
                endRadius: 600
            )
        }
    }
}

// MARK: - Anime Overlay (stylized)
struct AnimeOverlay: View {
    var body: some View {
        ZStack {
            // Boost saturation feel
            Color(red: 1.0, green: 0.95, blue: 0.9).opacity(0.1)
                .blendMode(.overlay)

            // Subtle edge glow
            AnimeGlow()

            // Speed lines in corners
            AnimeSpeedLines()
        }
    }
}

struct AnimeGlow: View {
    var body: some View {
        ZStack {
            // Bloom effect simulation
            RadialGradient(
                colors: [.white.opacity(0.05), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
        }
    }
}

struct AnimeSpeedLines: View {
    var body: some View {
        Canvas { context, size in
            // Draw speed lines from corners
            for i in 0..<20 {
                let angle = Double(i) * 0.1 - 1.0
                var path = Path()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 80 * cos(angle), y: 80 * sin(angle)))
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 1)
            }
        }
    }
}

// MARK: - AI Overlay (detection mode)
struct AIOverlay: View {
    @State private var scanY: CGFloat = 0

    var body: some View {
        ZStack {
            // Cyan tint
            Color(red: 0, green: 0.8, blue: 1.0).opacity(0.08)

            // Scanning line
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Theme.accent.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 4)
                    .offset(y: scanY)
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            scanY = geo.size.height
                        }
                    }
            }

            // Grid overlay
            AIGrid()

            // Corner targeting brackets
            AITargetingBrackets()
        }
    }
}

struct AIGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            for x in stride(from: 0, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Theme.accent.opacity(0.1)), lineWidth: 0.5)
            }
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Theme.accent.opacity(0.1)), lineWidth: 0.5)
            }
        }
    }
}

struct AITargetingBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let size: CGFloat = 100
            let offset: CGFloat = 50

            // Simulated detection boxes
            ForEach(0..<3, id: \.self) { i in
                let x = CGFloat.random(in: offset...(geo.size.width - size - offset))
                let y = CGFloat.random(in: offset...(geo.size.height - size - offset))

                AIDetectionBox()
                    .frame(width: size, height: size)
                    .position(x: x + size/2, y: y + size/2)
            }
        }
    }
}

struct AIDetectionBox: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        ZStack {
            // Corner brackets
            Rectangle()
                .stroke(Theme.accent, lineWidth: 2)
                .opacity(opacity)

            // Label
            VStack {
                HStack {
                    Text("TRACKING")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Theme.accent)
                        .opacity(opacity)
                    Spacer()
                }
                Spacer()
            }
            .padding(4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                opacity = 0.8
            }
        }
    }
}

// MARK: - Placeholder Sidebar
struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DATA LAYERS")
                    .font(Typography.headerFont)
                    .foregroundColor(Theme.accent)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isSidebarExpanded = false
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Theme.backgroundSecondary)

            // Data layer toggles
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(DataLayerType.allCases) { layer in
                        DataLayerToggleRow(layer: layer)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()
                .background(Theme.border)

            // City presets
            VStack(alignment: .leading, spacing: 8) {
                Text("LOCATIONS")
                    .font(Typography.labelFont)
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // City buttons in wrapped grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(CityPreset.presets) { city in
                        CityButton(city: city)
                    }
                }
                .padding(.horizontal)

                // Landmarks for current city
                if !appState.currentCity.landmarks.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 6)
                    ], spacing: 6) {
                        ForEach(appState.currentCity.landmarks) { landmark in
                            LandmarkButton(landmark: landmark)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)

            Divider()
                .background(Theme.border)

            // Visual modes
            VStack(alignment: .leading, spacing: 8) {
                Text("STYLE PRESETS")
                    .font(Typography.labelFont)
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal)
                    .padding(.top, 8)

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(VisualMode.allCases) { mode in
                        VisualModeButton(mode: mode)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()
                .background(Theme.border)

            // PANOPTIC AI Detection
            VStack(alignment: .leading, spacing: 8) {
                Text("AI DETECTION")
                    .font(Typography.labelFont)
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal)
                    .padding(.top, 8)

                PANOPTICToggle()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            Spacer()
        }
        .background(Theme.background)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Theme.border),
            alignment: .trailing
        )
    }
}

// MARK: - Data Layer Toggle Row
struct DataLayerToggleRow: View {
    @EnvironmentObject var appState: AppState
    let layer: DataLayerType

    var isActive: Bool {
        appState.isLayerActive(layer)
    }

    var count: Int {
        switch layer {
        case .flights: return appState.flightCount
        case .satellites: return appState.satelliteCount
        case .earthquakes: return appState.earthquakeCount
        case .weather: return appState.weatherRadarCount
        case .cctv: return appState.cctvCount
        case .traffic: return 0
        }
    }

    var lastUpdate: String {
        let date: Date?
        switch layer {
        case .flights: date = appState.flightsLastUpdate
        case .satellites: date = appState.satellitesLastUpdate
        case .earthquakes: date = appState.earthquakesLastUpdate
        case .weather: date = appState.weatherLastUpdate
        case .cctv: date = appState.cctvLastUpdate
        case .traffic: date = nil
        }

        guard let date = date else { return "never" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else {
            return "\(Int(interval / 60))m ago"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: layer.icon)
                .foregroundColor(isActive ? Theme.accent : Theme.textMuted)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(layer.displayName)
                    .font(Typography.labelFont)
                    .foregroundColor(isActive ? Theme.textPrimary : Theme.textMuted)

                Text("\(layer.dataSource) · \(lastUpdate)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }

            Spacer()

            if count > 0 {
                Text(formatCount(count))
                    .font(Typography.hudFont)
                    .foregroundColor(Theme.accent)
            }

            Toggle("", isOn: Binding(
                get: { isActive },
                set: { _ in appState.toggleLayer(layer) }
            ))
            .toggleStyle(TacticalToggleStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isActive ? Theme.accent.opacity(0.1) : Color.clear)
    }

    func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Tactical Toggle Style
struct TacticalToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            Text(configuration.isOn ? "ON" : "OFF")
                .font(Typography.labelFont)
                .foregroundColor(configuration.isOn ? Theme.accent : Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(configuration.isOn ? Theme.accent : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - City Button
struct CityButton: View {
    @EnvironmentObject var appState: AppState
    let city: CityPreset

    var isSelected: Bool {
        appState.currentCity.id == city.id
    }

    var body: some View {
        Button(action: {
            appState.selectCity(city)
            appState.selectedLandmark = Landmark(
                name: city.name,
                latitude: city.latitude,
                longitude: city.longitude
            )
        }) {
            Text(city.name)
                .font(Typography.labelFont)
                .foregroundColor(isSelected ? Theme.background : Theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Theme.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.accent, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Landmark Button
struct LandmarkButton: View {
    @EnvironmentObject var appState: AppState
    let landmark: Landmark

    var body: some View {
        Button(action: {
            appState.selectLandmark(landmark)
        }) {
            Text(landmark.name)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visual Mode Button
struct VisualModeButton: View {
    @EnvironmentObject var appState: AppState
    let mode: VisualMode

    var isSelected: Bool {
        appState.visualMode == mode
    }

    var body: some View {
        Button(action: {
            appState.visualMode = mode
        }) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16))
                Text(mode.displayName)
                    .font(.system(size: 9, design: .monospaced))
            }
            .foregroundColor(isSelected ? Theme.background : Theme.accent)
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Theme.accent : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.accent.opacity(isSelected ? 0 : 1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PANOPTIC Toggle
struct PANOPTICToggle: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Main toggle button
            Button(action: {
                appState.togglePanoptic()
            }) {
                HStack {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.system(size: 16))
                    Text("PANOPTIC")
                        .font(Typography.labelFont)
                    Spacer()
                    Text(appState.isPanopticActive ? "ACTIVE" : "STANDBY")
                        .font(Typography.labelFont)
                }
                .foregroundColor(appState.isPanopticActive ? Theme.background : Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(appState.isPanopticActive ? Theme.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.accent, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Detection stats when active
            if appState.isPanopticActive {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DETECTIONS")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Text("\(appState.detectionCount)")
                            .font(Typography.dataFont)
                            .foregroundColor(Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LATENCY")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Text(String(format: "%.0fms", appState.detectionLatency))
                            .font(Typography.dataFont)
                            .foregroundColor(Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("DENSITY")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Text(String(format: "%.1f/f", appState.detectionDensity))
                            .font(Typography.dataFont)
                            .foregroundColor(Theme.accent)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
