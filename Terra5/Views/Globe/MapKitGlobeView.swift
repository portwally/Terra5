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
        mapView.register(WeatherRadarAnnotationView.self, forAnnotationViewWithReuseIdentifier: WeatherRadarAnnotationView.identifier)
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
        context.coordinator.updateAnnotations(
            flights: appState.isLayerActive(.flights) ? appState.flights : [],
            satellites: appState.isLayerActive(.satellites) ? appState.satellites : [],
            earthquakes: appState.isLayerActive(.earthquakes) ? appState.earthquakes : [],
            weatherRadars: appState.isLayerActive(.weather) ? appState.weatherRadars : [],
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
    private var currentWeatherRadarIds: Set<String> = []
    private var currentCCTVIds: Set<String> = []

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
        weatherRadars: [WeatherRadar],
        cctvCameras: [CCTVCamera]
    ) {
        guard let mapView = mapView else { return }

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

        // Update weather radars
        let newWeatherRadarIds = Set(weatherRadars.map { $0.id })
        if newWeatherRadarIds != currentWeatherRadarIds {
            let oldWeatherAnnotations = mapView.annotations.compactMap { $0 as? WeatherRadarAnnotation }
            mapView.removeAnnotations(oldWeatherAnnotations)

            let weatherAnnotations = weatherRadars.map { WeatherRadarAnnotation(radar: $0) }
            mapView.addAnnotations(weatherAnnotations)

            currentWeatherRadarIds = newWeatherRadarIds
        }

        // Update CCTV cameras
        let newCCTVIds = Set(cctvCameras.map { $0.id })
        if newCCTVIds != currentCCTVIds {
            let oldCCTVAnnotations = mapView.annotations.compactMap { $0 as? CCTVAnnotation }
            mapView.removeAnnotations(oldCCTVAnnotations)

            let cctvAnnotations = cctvCameras.map { CCTVAnnotation(camera: $0) }
            mapView.addAnnotations(cctvAnnotations)

            currentCCTVIds = newCCTVIds
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

        if let weatherAnnotation = annotation as? WeatherRadarAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: WeatherRadarAnnotationView.identifier, for: annotation) as! WeatherRadarAnnotationView
            view.configure(with: weatherAnnotation.radar)
            return view
        }

        if let cctvAnnotation = annotation as? CCTVAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: CCTVAnnotationView.identifier, for: annotation) as! CCTVAnnotationView
            view.configure(with: cctvAnnotation.camera)
            return view
        }

        return nil
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

// MARK: - Weather Radar Annotation
class WeatherRadarAnnotation: NSObject, MKAnnotation {
    let radar: WeatherRadar

    init(radar: WeatherRadar) {
        self.radar = radar
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        radar.coordinate
    }

    var title: String? {
        "\(radar.stationId) - \(radar.name)"
    }

    var subtitle: String? {
        "\(radar.type.displayName) • \(radar.precipitationLevel.displayName)"
    }
}

class WeatherRadarAnnotationView: MKAnnotationView {
    static let identifier = "WeatherRadarAnnotation"

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
        frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }

    func configure(with radar: WeatherRadar) {
        let size: CGFloat = 24
        let precipColor = NSColor(Color(hex: radar.precipitationLevel.color))
        let statusColor = NSColor(Color(hex: radar.status.color))

        let radarImage = NSImage(size: NSSize(width: size, height: size))
        radarImage.lockFocus()

        let center = NSPoint(x: size / 2, y: size / 2)

        // Draw radar sweep circles
        for i in 1...3 {
            let radius = CGFloat(i) * (size / 7)
            let circleRect = NSRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            precipColor.withAlphaComponent(0.3 + Double(3 - i) * 0.15).setStroke()
            let circlePath = NSBezierPath(ovalIn: circleRect)
            circlePath.lineWidth = 1
            circlePath.stroke()
        }

        // Draw radar sweep line
        let sweepPath = NSBezierPath()
        sweepPath.move(to: center)
        sweepPath.line(to: NSPoint(x: center.x + size / 2 - 2, y: center.y + size / 4))
        precipColor.setStroke()
        sweepPath.lineWidth = 2
        sweepPath.stroke()

        // Draw center tower dot
        let towerSize: CGFloat = 6
        let towerRect = NSRect(
            x: center.x - towerSize / 2,
            y: center.y - towerSize / 2,
            width: towerSize,
            height: towerSize
        )
        statusColor.setFill()
        NSBezierPath(ovalIn: towerRect).fill()

        // Status indicator border
        statusColor.setStroke()
        let statusPath = NSBezierPath(ovalIn: towerRect)
        statusPath.lineWidth = 1.5
        statusPath.stroke()

        radarImage.unlockFocus()
        self.image = radarImage
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
    MapKitGlobeView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
