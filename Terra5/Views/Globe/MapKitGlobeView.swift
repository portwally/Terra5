//
//  MapKitGlobeView.swift
//  Terra5
//
//  Native MapKit globe view with live data annotations
//

import SwiftUI
import MapKit

struct MapKitGlobeView: NSViewRepresentable {
    @EnvironmentObject var appState: AppState

    // Parameters for weather overlay (only works in 2D mode)
    let is2DMode: Bool
    let weatherActive: Bool
    let weatherLayerType: WeatherLayerType

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // Configure for satellite imagery
        mapView.mapType = .satelliteFlyover
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true

        // Show 3D buildings
        mapView.showsBuildings = true

        // Dark appearance
        mapView.appearance = NSAppearance(named: .darkAqua)

        // Set delegate
        mapView.delegate = context.coordinator

        // Register annotation views
        mapView.register(FlightAnnotationView.self, forAnnotationViewWithReuseIdentifier: FlightAnnotationView.identifier)
        mapView.register(SatelliteAnnotationView.self, forAnnotationViewWithReuseIdentifier: SatelliteAnnotationView.identifier)
        mapView.register(EarthquakeAnnotationView.self, forAnnotationViewWithReuseIdentifier: EarthquakeAnnotationView.identifier)
        mapView.register(CCTVAnnotationView.self, forAnnotationViewWithReuseIdentifier: CCTVAnnotationView.identifier)

        // Initial camera - Washington DC
        let camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369),
            fromDistance: 10_000_000,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: false)

        // Store reference
        context.coordinator.mapView = mapView

        // Notify ready and start data refresh
        DispatchQueue.main.async {
            appState.isGlobeReady = true
            appState.startDataRefresh()
            print("MapKit Globe ready!")
        }

        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Handle map mode switching (3D globe vs 2D flat)
        let targetMapType: MKMapType = is2DMode ? .satellite : .satelliteFlyover
        if mapView.mapType != targetMapType {
            mapView.mapType = targetMapType
            NSLog("[TERRA5] MapKit: Switched to %@ mode", is2DMode ? "2D satellite" : "3D globe")
        }

        // Handle weather overlay (works in both 2D and 3D modes)
        context.coordinator.updateWeatherOverlay(
            show: weatherActive,
            layerType: weatherLayerType,
            on: mapView
        )

        // Handle fly-to requests
        if let landmark = appState.selectedLandmark {
            let camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: landmark.latitude, longitude: landmark.longitude),
                fromDistance: landmark.zoomAltitude * 10,
                pitch: is2DMode ? 0 : 45,
                heading: 0
            )
            mapView.setCamera(camera, animated: true)

            DispatchQueue.main.async {
                appState.selectedLandmark = nil
            }
        }

        // Update annotations based on active layers and data
        context.coordinator.updateAnnotations(
            flights: appState.isLayerActive(.flights) ? appState.flights : [],
            satellites: appState.isLayerActive(.satellites) ? appState.satellites : [],
            earthquakes: appState.isLayerActive(.earthquakes) ? appState.earthquakes : [],
            cctvCameras: appState.isLayerActive(.cctv) ? appState.cctvCameras : []
        )
    }

    func makeCoordinator() -> MapKitCoordinator {
        MapKitCoordinator(appState: appState)
    }
}

// MARK: - Coordinator
class MapKitCoordinator: NSObject, MKMapViewDelegate {
    var appState: AppState
    weak var mapView: MKMapView?

    private var currentFlightIds: Set<String> = []
    private var currentSatelliteIds: Set<String> = []
    private var currentEarthquakeIds: Set<String> = []
    private var currentCCTVIds: Set<String> = []

    // Weather tile overlay (only used in 2D mode)
    private var weatherOverlay: MKTileOverlay?
    private var currentWeatherLayerType: WeatherLayerType?
    private var weatherTimestamp: Int = 0

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let center = mapView.centerCoordinate
        let camera = mapView.camera

        Task { @MainActor in
            appState.cameraLatitude = center.latitude
            appState.cameraLongitude = center.longitude
            appState.cameraAltitude = camera.centerCoordinateDistance
            appState.cameraHeading = camera.heading
        }
    }

    func updateAnnotations(
        flights: [Flight],
        satellites: [Satellite],
        earthquakes: [Earthquake],
        cctvCameras: [CCTVCamera]
    ) {
        guard let mapView = mapView else {
            NSLog("[TERRA5] MapKit: mapView is nil!")
            return
        }

        // Update flights
        let newFlightIds = Set(flights.map { $0.id })
        if newFlightIds != currentFlightIds {
            let oldFlightAnnotations = mapView.annotations.compactMap { $0 as? FlightAnnotation }
            mapView.removeAnnotations(oldFlightAnnotations)

            let flightAnnotations = flights.map { FlightAnnotation(flight: $0) }
            mapView.addAnnotations(flightAnnotations)

            currentFlightIds = newFlightIds
        }

        // Update satellites
        let newSatelliteIds = Set(satellites.map { $0.id })
        if newSatelliteIds != currentSatelliteIds {
            let oldSatelliteAnnotations = mapView.annotations.compactMap { $0 as? SatelliteAnnotation }
            mapView.removeAnnotations(oldSatelliteAnnotations)

            let satelliteAnnotations = satellites.map { SatelliteAnnotation(satellite: $0) }
            mapView.addAnnotations(satelliteAnnotations)

            currentSatelliteIds = newSatelliteIds
        }

        // Update earthquakes
        let newEarthquakeIds = Set(earthquakes.map { $0.id })
        if newEarthquakeIds != currentEarthquakeIds {
            let oldEarthquakeAnnotations = mapView.annotations.compactMap { $0 as? EarthquakeAnnotation }
            mapView.removeAnnotations(oldEarthquakeAnnotations)

            let earthquakeAnnotations = earthquakes.map { EarthquakeAnnotation(earthquake: $0) }
            mapView.addAnnotations(earthquakeAnnotations)

            currentEarthquakeIds = newEarthquakeIds
        }

        // Update CCTV cameras
        let newCCTVIds = Set(cctvCameras.map { $0.id })
        if newCCTVIds != currentCCTVIds {
            NSLog("[TERRA5] MapKit: Adding %d CCTV annotations", cctvCameras.count)
            let oldCCTVAnnotations = mapView.annotations.compactMap { $0 as? CCTVAnnotation }
            mapView.removeAnnotations(oldCCTVAnnotations)

            let cctvAnnotations = cctvCameras.map { CCTVAnnotation(camera: $0) }
            mapView.addAnnotations(cctvAnnotations)

            currentCCTVIds = newCCTVIds
        }
    }

    // MARK: - Weather Overlay
    func updateWeatherOverlay(show: Bool, layerType: WeatherLayerType, on mapView: MKMapView) {
        // Remove overlay if weather disabled
        if !show {
            if let overlay = weatherOverlay {
                mapView.removeOverlay(overlay)
                weatherOverlay = nil
                currentWeatherLayerType = nil
                NSLog("[TERRA5] MapKit: Weather overlay removed")
            }
            return
        }

        // Check if we need to update the overlay
        if currentWeatherLayerType != layerType {
            NSLog("[TERRA5] MapKit: Layer change detected: %@ -> %@",
                  currentWeatherLayerType?.rawValue ?? "none", layerType.rawValue)

            // Remove ALL tile overlays to ensure clean state
            let allOverlays = mapView.overlays.filter { $0 is MKTileOverlay }
            if !allOverlays.isEmpty {
                mapView.removeOverlays(allOverlays)
                NSLog("[TERRA5] MapKit: Removed %d tile overlay(s)", allOverlays.count)
            }
            weatherOverlay = nil

            // Mark as updating to prevent race conditions
            currentWeatherLayerType = layerType

            // Fetch timestamp and add new overlay
            Task {
                // Get radar timestamps
                let radarTimestamps: [Int]
                do {
                    (radarTimestamps, _) = try await WeatherRadarService.shared.fetchTimestamps()
                } catch {
                    NSLog("[TERRA5] MapKit: Failed to fetch weather timestamps: %@", error.localizedDescription)
                    return
                }

                await MainActor.run {
                    guard let radarTs = radarTimestamps.last else {
                        NSLog("[TERRA5] MapKit: No radar timestamp available")
                        return
                    }

                    // Use custom tile overlay that generates unique URLs per layer type
                    // This ensures MapKit doesn't use cached tiles from a different layer
                    let overlay = WeatherTileOverlay(layerType: layerType, timestamp: radarTs)

                    mapView.addOverlay(overlay, level: .aboveLabels)
                    self.weatherOverlay = overlay
                    self.weatherTimestamp = radarTs

                    NSLog("[TERRA5] MapKit: Weather overlay added (%@) with timestamp %d, id: %@",
                          layerType.rawValue, radarTs, overlay.uniqueId)
                }
            }
        }
    }

    func flyTo(latitude: Double, longitude: Double, altitude: Double) {
        guard let mapView = mapView else { return }

        let camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            fromDistance: altitude,
            pitch: 45,
            heading: 0
        )
        mapView.setCamera(camera, animated: true)
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let flightAnnotation = annotation as? FlightAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: FlightAnnotationView.identifier, for: annotation) as! FlightAnnotationView
            view.configure(with: flightAnnotation.flight)
            return view
        }

        if let satelliteAnnotation = annotation as? SatelliteAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: SatelliteAnnotationView.identifier, for: annotation) as! SatelliteAnnotationView
            view.configure(with: satelliteAnnotation.satellite)
            return view
        }

        if let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: EarthquakeAnnotationView.identifier, for: annotation) as! EarthquakeAnnotationView
            view.configure(with: earthquakeAnnotation.earthquake)
            return view
        }

        if let cctvAnnotation = annotation as? CCTVAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: CCTVAnnotationView.identifier, for: annotation) as! CCTVAnnotationView
            view.configure(with: cctvAnnotation.camera)
            return view
        }

        return nil
    }

    // MARK: - Annotation Selection
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        if let cctvAnnotation = annotation as? CCTVAnnotation {
            let cam = cctvAnnotation.camera
            NSLog("[TERRA5-CCTV] Selected camera: %@ (%@) — feedUrl: %@", cam.id, cam.name, cam.feedUrl ?? "nil")
            // Open live stream popup for selected CCTV camera
            Task { @MainActor in
                appState.selectedCCTVCamera = cam
            }
            // Deselect to allow re-selection
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }

    // MARK: - Overlay Rendering
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
            renderer.alpha = 0.7
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

// MARK: - Flight Annotation
class FlightAnnotation: NSObject, MKAnnotation {
    let flight: Flight

    init(flight: Flight) {
        self.flight = flight
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        flight.coordinate
    }

    var title: String? {
        flight.displayCallsign
    }

    var subtitle: String? {
        "\(flight.altitudeFeet) ft • \(flight.speedKnots) kts"
    }
}

class FlightAnnotationView: MKAnnotationView {
    static let identifier = "FlightAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        canShowCallout = true
        frame = CGRect(x: 0, y: 0, width: 20, height: 20)
    }

    func configure(with flight: Flight) {
        // Create airplane icon
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let image = NSImage(systemSymbolName: "airplane", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)

        // Rotate based on heading
        if let image = image {
            let rotatedImage = rotateImage(image, byDegrees: CGFloat(flight.heading))
            self.image = tintImage(rotatedImage, color: NSColor(Color(hex: "#00d4aa")))
        }
    }

    private func rotateImage(_ image: NSImage, byDegrees degrees: CGFloat) -> NSImage {
        let rotatedSize = image.size
        return NSImage(size: rotatedSize, flipped: false) { _ in
            let transform = NSAffineTransform()
            transform.translateX(by: rotatedSize.width / 2, yBy: rotatedSize.height / 2)
            transform.rotate(byDegrees: degrees - 90) // Adjust for airplane icon orientation
            transform.translateX(by: -rotatedSize.width / 2, yBy: -rotatedSize.height / 2)
            transform.concat()
            image.draw(in: NSRect(origin: .zero, size: rotatedSize))
            return true
        }
    }

    private func tintImage(_ image: NSImage, color: NSColor) -> NSImage {
        return NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}

// MARK: - Satellite Annotation
class SatelliteAnnotation: NSObject, MKAnnotation {
    let satellite: Satellite

    init(satellite: Satellite) {
        self.satellite = satellite
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        satellite.coordinate
    }

    var title: String? {
        satellite.name
    }

    var subtitle: String? {
        satellite.altitudeFormatted
    }
}

class SatelliteAnnotationView: MKAnnotationView {
    static let identifier = "SatelliteAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        canShowCallout = true
        frame = CGRect(x: 0, y: 0, width: 20, height: 20)
    }

    func configure(with satellite: Satellite) {
        let size: CGFloat = 20
        let color = NSColor(Color(hex: "#ffaa00"))

        // Draw custom satellite icon using modern drawing handler
        let satelliteImage = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            // Main body (center rectangle)
            let bodyWidth: CGFloat = 6
            let bodyHeight: CGFloat = 4
            let bodyRect = NSRect(
                x: (size - bodyWidth) / 2,
                y: (size - bodyHeight) / 2,
                width: bodyWidth,
                height: bodyHeight
            )
            color.setFill()
            NSBezierPath(roundedRect: bodyRect, xRadius: 1, yRadius: 1).fill()

            // Left solar panel
            let panelWidth: CGFloat = 5
            let panelHeight: CGFloat = 8
            let leftPanel = NSRect(
                x: (size - bodyWidth) / 2 - panelWidth - 1,
                y: (size - panelHeight) / 2,
                width: panelWidth,
                height: panelHeight
            )
            color.withAlphaComponent(0.8).setFill()
            NSBezierPath(rect: leftPanel).fill()
            color.setStroke()
            let leftPath = NSBezierPath(rect: leftPanel)
            leftPath.lineWidth = 0.5
            leftPath.stroke()

            // Right solar panel
            let rightPanel = NSRect(
                x: (size + bodyWidth) / 2 + 1,
                y: (size - panelHeight) / 2,
                width: panelWidth,
                height: panelHeight
            )
            color.withAlphaComponent(0.8).setFill()
            NSBezierPath(rect: rightPanel).fill()
            let rightPath = NSBezierPath(rect: rightPanel)
            rightPath.lineWidth = 0.5
            rightPath.stroke()

            // Antenna
            let antennaPath = NSBezierPath()
            antennaPath.move(to: NSPoint(x: size / 2, y: (size + bodyHeight) / 2))
            antennaPath.line(to: NSPoint(x: size / 2, y: (size + bodyHeight) / 2 + 3))
            antennaPath.lineWidth = 1
            color.setStroke()
            antennaPath.stroke()

            // Antenna dish
            let dishSize: CGFloat = 3
            let dishRect = NSRect(
                x: size / 2 - dishSize / 2,
                y: (size + bodyHeight) / 2 + 2,
                width: dishSize,
                height: dishSize
            )
            color.setFill()
            NSBezierPath(ovalIn: dishRect).fill()

            return true
        }
        self.image = satelliteImage
    }
}

// MARK: - Earthquake Annotation
class EarthquakeAnnotation: NSObject, MKAnnotation {
    let earthquake: Earthquake

    init(earthquake: Earthquake) {
        self.earthquake = earthquake
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        earthquake.coordinate
    }

    var title: String? {
        earthquake.formattedMagnitude
    }

    var subtitle: String? {
        earthquake.place
    }
}

class EarthquakeAnnotationView: MKAnnotationView {
    static let identifier = "EarthquakeAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        canShowCallout = true
    }

    func configure(with earthquake: Earthquake) {
        // Size based on magnitude (larger for bigger earthquakes)
        let baseSize = CGFloat(max(16, min(40, earthquake.magnitude * 5)))
        frame = CGRect(x: 0, y: 0, width: baseSize, height: baseSize)

        // Color based on magnitude
        let color: NSColor
        switch earthquake.magnitude {
        case ..<3:
            color = NSColor(Color(hex: "#00ff88"))
        case 3..<5:
            color = NSColor(Color(hex: "#ffaa00"))
        case 5..<7:
            color = NSColor(Color(hex: "#ff6600"))
        default:
            color = NSColor(Color(hex: "#ff3333"))
        }

        // Create seismic wave icon using modern drawing handler
        let earthquakeImage = NSImage(size: NSSize(width: baseSize, height: baseSize), flipped: false) { _ in
            let center = NSPoint(x: baseSize / 2, y: baseSize / 2)

            // Draw concentric circles (seismic waves)
            let numRings = 3
            for i in 0..<numRings {
                let ringRadius = baseSize / 2 - CGFloat(i) * (baseSize / 8)
                let opacity = 0.3 + Double(numRings - i) * 0.2

                let ringRect = NSRect(
                    x: center.x - ringRadius,
                    y: center.y - ringRadius,
                    width: ringRadius * 2,
                    height: ringRadius * 2
                )

                color.withAlphaComponent(opacity).setStroke()
                let ringPath = NSBezierPath(ovalIn: ringRect)
                ringPath.lineWidth = 1.5
                ringPath.stroke()
            }

            // Draw center epicenter dot
            let epicenterSize: CGFloat = baseSize / 4
            let epicenterRect = NSRect(
                x: center.x - epicenterSize / 2,
                y: center.y - epicenterSize / 2,
                width: epicenterSize,
                height: epicenterSize
            )
            color.setFill()
            NSBezierPath(ovalIn: epicenterRect).fill()

            // Draw seismic wave lines (like a zigzag)
            let wavePath = NSBezierPath()
            let waveWidth = baseSize * 0.6
            let waveHeight: CGFloat = 4
            let startX = center.x - waveWidth / 2
            let startY = center.y - baseSize / 3

            wavePath.move(to: NSPoint(x: startX, y: startY))
            let segments = 6
            for j in 0..<segments {
                let x = startX + CGFloat(j + 1) * (waveWidth / CGFloat(segments))
                let y = startY + (j % 2 == 0 ? waveHeight : -waveHeight)
                wavePath.line(to: NSPoint(x: x, y: y))
            }

            color.setStroke()
            wavePath.lineWidth = 1.5
            wavePath.stroke()

            return true
        }
        self.image = earthquakeImage
    }
}

// MARK: - CCTV Annotation
class CCTVAnnotation: NSObject, MKAnnotation {
    let camera: CCTVCamera

    init(camera: CCTVCamera) {
        self.camera = camera
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        camera.coordinate
    }

    var title: String? {
        camera.name
    }

    var subtitle: String? {
        "\(camera.id) • \(camera.statusIndicator)"
    }
}

class CCTVAnnotationView: MKAnnotationView {
    static let identifier = "CCTVAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        canShowCallout = true
        frame = CGRect(x: 0, y: 0, width: 18, height: 18)
    }

    func configure(with camera: CCTVCamera) {
        let hasStream = camera.feedUrl != nil && !(camera.feedUrl?.isEmpty ?? true)
        let size: CGFloat = hasStream ? 22 : 16
        let statusColor: NSColor = hasStream
            ? NSColor(red: 0.0, green: 0.83, blue: 0.67, alpha: 1.0) // bright teal for live
            : NSColor(Color(hex: camera.status.color)).withAlphaComponent(0.5) // dimmer for no-stream

        // Draw CCTV icon using modern drawing handler
        let cctvImage = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let center = NSPoint(x: size / 2, y: size / 2)

            // Glow ring for cameras with live streams
            if hasStream {
                let glowSize: CGFloat = size - 2
                let glowRect = NSRect(
                    x: center.x - glowSize / 2,
                    y: center.y - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                )
                statusColor.withAlphaComponent(0.2).setFill()
                NSBezierPath(ovalIn: glowRect).fill()
                statusColor.withAlphaComponent(0.5).setStroke()
                let glowPath = NSBezierPath(ovalIn: glowRect)
                glowPath.lineWidth = 1.0
                glowPath.stroke()
            }

            // Draw camera body
            let bodyWidth: CGFloat = hasStream ? 11 : 9
            let bodyHeight: CGFloat = hasStream ? 8 : 6
            let bodyRect = NSRect(
                x: center.x - bodyWidth / 2,
                y: center.y - bodyHeight / 2,
                width: bodyWidth,
                height: bodyHeight
            )
            statusColor.withAlphaComponent(hasStream ? 0.9 : 0.6).setFill()
            NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2).fill()

            // Draw lens
            let lensSize: CGFloat = hasStream ? 4 : 3
            let lensRect = NSRect(
                x: center.x + bodyWidth / 2 - 2,
                y: center.y - lensSize / 2,
                width: lensSize,
                height: lensSize
            )
            statusColor.setFill()
            NSBezierPath(ovalIn: lensRect).fill()

            // Draw mount
            let mountPath = NSBezierPath()
            mountPath.move(to: NSPoint(x: center.x, y: center.y - bodyHeight / 2))
            mountPath.line(to: NSPoint(x: center.x, y: center.y - bodyHeight / 2 - 3))
            statusColor.setStroke()
            mountPath.lineWidth = hasStream ? 2 : 1.5
            mountPath.stroke()

            // Live stream indicator (green dot) instead of just recording indicator
            if hasStream {
                let dotSize: CGFloat = 4
                let dotRect = NSRect(
                    x: center.x - bodyWidth / 2 + 1,
                    y: center.y + bodyHeight / 2 - dotSize,
                    width: dotSize,
                    height: dotSize
                )
                NSColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0).setFill()
                NSBezierPath(ovalIn: dotRect).fill()
            }

            return true
        }
        self.image = cctvImage
        frame = CGRect(x: 0, y: 0, width: size, height: size)
    }
}

#Preview {
    MapKitGlobeView(is2DMode: false, weatherActive: false, weatherLayerType: .rain)
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
