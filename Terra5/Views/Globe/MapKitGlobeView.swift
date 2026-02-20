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

    // Explicit parameters to force SwiftUI to detect changes
    let selectedWeatherLayer: WeatherLayerType
    let weatherActive: Bool

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
        // Debug: check if weather/cctv data exists
        if appState.weatherRadars.count > 0 || appState.cctvCameras.count > 0 {
            print("[DEBUG] updateNSView: weather=\(appState.weatherRadars.count), cctv=\(appState.cctvCameras.count), weatherActive=\(appState.isLayerActive(.weather)), cctvActive=\(appState.isLayerActive(.cctv))")
        }

        // Handle fly-to requests
        if let landmark = appState.selectedLandmark {
            let camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: landmark.latitude, longitude: landmark.longitude),
                fromDistance: landmark.zoomAltitude * 10,
                pitch: 45,
                heading: 0
            )
            mapView.setCamera(camera, animated: true)

            DispatchQueue.main.async {
                appState.selectedLandmark = nil
            }
        }

        // Update annotations based on active layers and data
        // Use explicit parameters for weather to ensure SwiftUI detects changes
        context.coordinator.updateAnnotations(
            flights: appState.isLayerActive(.flights) ? appState.flights : [],
            satellites: appState.isLayerActive(.satellites) ? appState.satellites : [],
            earthquakes: appState.isLayerActive(.earthquakes) ? appState.earthquakes : [],
            showWeather: weatherActive,
            weatherLayerType: selectedWeatherLayer,
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

    // Weather tile overlays
    private var rainOverlay: RainRadarOverlay?
    private var cloudOverlay: CloudCoverOverlay?
    private var temperatureOverlay: TemperatureOverlay?
    private var currentWeatherLayerType: WeatherLayerType?

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
        showWeather: Bool,
        weatherLayerType: WeatherLayerType,
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

        // Update weather tile overlays
        updateWeatherOverlay(show: showWeather, layerType: weatherLayerType, on: mapView)

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

    private func updateWeatherOverlay(show: Bool, layerType: WeatherLayerType, on mapView: MKMapView) {
        // If weather is disabled, remove all overlays
        if !show {
            removeAllWeatherOverlays(from: mapView)
            currentWeatherLayerType = nil
            // Switch back to 3D satellite flyover
            if mapView.mapType != .satelliteFlyover {
                mapView.mapType = .satelliteFlyover
                NSLog("[TERRA5] MapKit: Switched back to satelliteFlyover mode")
            }
            return
        }

        // Switch to 2D satellite mode for weather overlays (3D doesn't support tile overlays well)
        if mapView.mapType != .satellite {
            mapView.mapType = .satellite
            NSLog("[TERRA5] MapKit: Switched to 2D satellite mode for weather overlay")
        }

        // If layer type changed, update the overlay
        if currentWeatherLayerType != layerType {
            NSLog("[TERRA5] MapKit: Switching weather layer to %@", layerType.rawValue)

            // Remove all existing weather overlays
            removeAllWeatherOverlays(from: mapView)

            // Add the selected overlay
            Task {
                NSLog("[TERRA5] MapKit: Fetching weather timestamps...")
                let radarTimestamp = await WeatherRadarService.shared.getLatestRadarTimestamp()
                let satelliteTimestamp = await WeatherRadarService.shared.getLatestSatelliteTimestamp()
                NSLog("[TERRA5] MapKit: Got timestamps - radar: %d, satellite: %d", radarTimestamp, satelliteTimestamp)

                // Check for valid timestamps
                guard radarTimestamp > 0 else {
                    NSLog("[TERRA5] MapKit: ERROR - Invalid radar timestamp, cannot add overlay")
                    return
                }

                await MainActor.run {
                    switch layerType {
                    case .rain:
                        let rain = RainRadarOverlay(timestamp: radarTimestamp, colorScheme: 6)
                        mapView.addOverlay(rain, level: .aboveRoads)
                        self.rainOverlay = rain
                        NSLog("[TERRA5] MapKit: Rain overlay added (timestamp: %d)", radarTimestamp)

                    case .clouds:
                        let effectiveTimestamp = satelliteTimestamp > 0 ? satelliteTimestamp : radarTimestamp
                        let clouds = CloudCoverOverlay(timestamp: effectiveTimestamp)
                        mapView.addOverlay(clouds, level: .aboveRoads)
                        self.cloudOverlay = clouds
                        NSLog("[TERRA5] MapKit: Cloud overlay added (timestamp: %d)", effectiveTimestamp)

                    case .temperature:
                        let temp = TemperatureOverlay(timestamp: radarTimestamp)
                        mapView.addOverlay(temp, level: .aboveRoads)
                        self.temperatureOverlay = temp
                        NSLog("[TERRA5] MapKit: Temperature overlay added (timestamp: %d)", radarTimestamp)
                    }

                    self.currentWeatherLayerType = layerType
                }
            }
        }
    }

    private func removeAllWeatherOverlays(from mapView: MKMapView) {
        if let rain = rainOverlay {
            mapView.removeOverlay(rain)
            rainOverlay = nil
        }
        if let clouds = cloudOverlay {
            mapView.removeOverlay(clouds)
            cloudOverlay = nil
        }
        if let temp = temperatureOverlay {
            mapView.removeOverlay(temp)
            temperatureOverlay = nil
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

    // MARK: - Overlay Rendering
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        NSLog("[TERRA5] MapKit: rendererFor overlay called, type: %@", String(describing: type(of: overlay)))
        if let tileOverlay = overlay as? MKTileOverlay {
            NSLog("[TERRA5] MapKit: Creating tile overlay renderer")
            let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
            renderer.alpha = 0.7  // Semi-transparent
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
        let rotatedImage = NSImage(size: rotatedSize)

        rotatedImage.lockFocus()
        let transform = NSAffineTransform()
        transform.translateX(by: rotatedSize.width / 2, yBy: rotatedSize.height / 2)
        transform.rotate(byDegrees: degrees - 90) // Adjust for airplane icon orientation
        transform.translateX(by: -rotatedSize.width / 2, yBy: -rotatedSize.height / 2)
        transform.concat()
        image.draw(in: NSRect(origin: .zero, size: rotatedSize))
        rotatedImage.unlockFocus()

        return rotatedImage
    }

    private func tintImage(_ image: NSImage, color: NSColor) -> NSImage {
        let tintedImage = image.copy() as! NSImage
        tintedImage.lockFocus()
        color.set()
        NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        return tintedImage
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

        // Draw custom satellite icon
        let satelliteImage = NSImage(size: NSSize(width: size, height: size))
        satelliteImage.lockFocus()

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

        satelliteImage.unlockFocus()
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

        // Create seismic wave icon
        let earthquakeImage = NSImage(size: NSSize(width: baseSize, height: baseSize))
        earthquakeImage.lockFocus()

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

        earthquakeImage.unlockFocus()
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
        let size: CGFloat = 18
        let statusColor = NSColor(Color(hex: camera.status.color))

        let cctvImage = NSImage(size: NSSize(width: size, height: size))
        cctvImage.lockFocus()

        let center = NSPoint(x: size / 2, y: size / 2)

        // Draw camera body
        let bodyWidth: CGFloat = 10
        let bodyHeight: CGFloat = 7
        let bodyRect = NSRect(
            x: center.x - bodyWidth / 2,
            y: center.y - bodyHeight / 2,
            width: bodyWidth,
            height: bodyHeight
        )
        statusColor.withAlphaComponent(0.8).setFill()
        NSBezierPath(roundedRect: bodyRect, xRadius: 2, yRadius: 2).fill()

        // Draw lens
        let lensSize: CGFloat = 4
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
        mountPath.line(to: NSPoint(x: center.x, y: center.y - bodyHeight / 2 - 4))
        statusColor.setStroke()
        mountPath.lineWidth = 2
        mountPath.stroke()

        // Recording indicator (red dot for recording status)
        if camera.status == .recording {
            let recSize: CGFloat = 3
            let recRect = NSRect(
                x: center.x - bodyWidth / 2 + 2,
                y: center.y + bodyHeight / 2 - recSize - 1,
                width: recSize,
                height: recSize
            )
            NSColor.red.setFill()
            NSBezierPath(ovalIn: recRect).fill()
        }

        cctvImage.unlockFocus()
        self.image = cctvImage
    }
}

#Preview {
    MapKitGlobeView(selectedWeatherLayer: .rain, weatherActive: false)
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
