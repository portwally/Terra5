//
//  AppState.swift
//  Terra5
//
//  Global application state with persistence
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Settings Keys
    private enum SettingsKey {
        static let visualMode = "terra5.visualMode"
        static let sidebarExpanded = "terra5.sidebarExpanded"
        static let activeLayers = "terra5.activeLayers"
        static let lastCityIndex = "terra5.lastCityIndex"
        static let lastLatitude = "terra5.lastLatitude"
        static let lastLongitude = "terra5.lastLongitude"
        static let lastAltitude = "terra5.lastAltitude"
    }

    // MARK: - Visual State
    @Published var visualMode: VisualMode = .normal {
        didSet { saveSettings() }
    }
    @Published var isSidebarExpanded: Bool = true {
        didSet { saveSettings() }
    }
    @Published var isPanopticActive: Bool = false

    // MARK: - Data Layers
    @Published var activeLayers: Set<DataLayerType> = [] {
        didSet { saveSettings() }
    }

    // MARK: - Weather Layer Selection
    @Published var selectedWeatherLayer: WeatherLayerType = .rain

    // MARK: - Map Mode (3D Globe vs 2D Map)
    @Published var is2DMapMode: Bool = false

    // MARK: - Location State
    @Published var currentCity: CityPreset = CityPreset.presets[0] {
        didSet { saveSettings() }
    }
    @Published var selectedLandmark: Landmark?

    // MARK: - Initialization
    init() {
        loadSettings()
    }

    // MARK: - Camera State (updated from MapKit)
    @Published var cameraLatitude: Double = 38.9072
    @Published var cameraLongitude: Double = -77.0369
    @Published var cameraAltitude: Double = 10_000_000
    @Published var cameraHeading: Double = 0

    // MARK: - Live Data Arrays
    @Published var flights: [Flight] = []
    @Published var satellites: [Satellite] = []
    @Published var earthquakes: [Earthquake] = []
    @Published var weatherRadars: [WeatherRadar] = []
    @Published var weatherAlerts: [WeatherAlert] = []
    @Published var cctvCameras: [CCTVCamera] = []

    // MARK: - Data Counts (computed)
    var flightCount: Int { flights.count }
    var satelliteCount: Int { satellites.count }
    var earthquakeCount: Int { earthquakes.count }
    var weatherRadarCount: Int { weatherRadars.count }
    var weatherAlertCount: Int { weatherAlerts.count }
    var cctvCount: Int { cctvCameras.count }

    // MARK: - Timestamps
    @Published var flightsLastUpdate: Date?
    @Published var satellitesLastUpdate: Date?
    @Published var earthquakesLastUpdate: Date?
    @Published var weatherLastUpdate: Date?
    @Published var cctvLastUpdate: Date?

    // MARK: - Loading States
    @Published var isLoadingFlights: Bool = false
    @Published var isLoadingSatellites: Bool = false
    @Published var isLoadingEarthquakes: Bool = false
    @Published var isLoadingWeather: Bool = false
    @Published var isLoadingCCTV: Bool = false
    @Published var isWeatherDataReady: Bool = false

    // MARK: - Error States
    @Published var flightsError: String?
    @Published var satellitesError: String?
    @Published var earthquakesError: String?
    @Published var weatherError: String?
    @Published var cctvError: String?

    // MARK: - Globe Ready State
    @Published var isGlobeReady: Bool = false

    // MARK: - Detection State
    @Published var detectionCount: Int = 0
    @Published var detectionDensity: Double = 0
    @Published var detectionLatency: Double = 0
    @Published var currentDetections: [PANOPTICService.Detection] = []
    @Published var isDetectionRunning: Bool = false

    private var detectionTimer: Timer?

    func startDetection() {
        guard isPanopticActive else { return }
        isDetectionRunning = true

        // Run detection every 2 seconds
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.runDetection()
            }
        }

        // Initial detection
        Task {
            await runDetection()
        }
    }

    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
        isDetectionRunning = false
        currentDetections = []
        detectionCount = 0
        detectionDensity = 0
        detectionLatency = 0
    }

    private func runDetection() async {
        let detections = await PANOPTICService.shared.runDetection(
            latitude: cameraLatitude,
            longitude: cameraLongitude,
            altitude: cameraAltitude
        )

        currentDetections = detections
        detectionCount = detections.count

        let stats = await PANOPTICService.shared.getStats()
        detectionDensity = stats.density
        detectionLatency = stats.processingLatency
    }

    func togglePanoptic() {
        isPanopticActive.toggle()
        if isPanopticActive {
            startDetection()
        } else {
            stopDetection()
        }
    }

    // MARK: - Data Manager
    private var dataManager: DataManager?

    func startDataRefresh() {
        dataManager = DataManager(appState: self)
        dataManager?.startRefreshing()
    }

    func stopDataRefresh() {
        dataManager?.stopRefreshing()
    }

    // MARK: - Methods
    func toggleLayer(_ layer: DataLayerType) {
        NSLog("[TERRA5] toggleLayer: %@, currently active: %d", layer.rawValue, activeLayers.contains(layer) ? 1 : 0)
        if activeLayers.contains(layer) {
            activeLayers.remove(layer)
            // Clear data when layer is disabled
            clearLayerData(layer)
            NSLog("[TERRA5] Layer %@ disabled", layer.rawValue)
        } else {
            activeLayers.insert(layer)
            NSLog("[TERRA5] Layer %@ enabled, fetching data...", layer.rawValue)
            // Immediately fetch data when layer is enabled
            fetchLayerData(layer)
        }
    }

    private func clearLayerData(_ layer: DataLayerType) {
        switch layer {
        case .flights:
            flights = []
        case .satellites:
            satellites = []
        case .earthquakes:
            earthquakes = []
        case .weather:
            weatherRadars = []
            weatherAlerts = []
        case .cctv:
            cctvCameras = []
        case .traffic:
            break
        }
    }

    private func fetchLayerData(_ layer: DataLayerType) {
        NSLog("[TERRA5] fetchLayerData: %@, dataManager exists: %d", layer.rawValue, dataManager != nil ? 1 : 0)
        guard let dataManager = dataManager else {
            NSLog("[TERRA5] ERROR: DataManager not available for layer fetch!")
            return
        }

        Task {
            NSLog("[TERRA5] Starting fetch task for %@", layer.rawValue)
            switch layer {
            case .flights:
                await dataManager.refreshFlights()
            case .satellites:
                await dataManager.refreshSatellites()
            case .earthquakes:
                await dataManager.refreshEarthquakes()
            case .weather:
                NSLog("[TERRA5] Calling dataManager.refreshWeather()")
                await dataManager.refreshWeather()
                NSLog("[TERRA5] Weather fetch complete, count: %d", self.weatherRadars.count)
            case .cctv:
                NSLog("[TERRA5] Calling dataManager.refreshCCTV()")
                await dataManager.refreshCCTV()
                NSLog("[TERRA5] CCTV fetch complete, count: %d", self.cctvCameras.count)
            case .traffic:
                NSLog("[TERRA5] Traffic layer not implemented")
            }
            NSLog("[TERRA5] Task completed for %@", layer.rawValue)
        }
    }

    func isLayerActive(_ layer: DataLayerType) -> Bool {
        activeLayers.contains(layer)
    }

    func selectCity(_ city: CityPreset) {
        currentCity = city
        selectedLandmark = nil
    }

    func selectLandmark(_ landmark: Landmark) {
        selectedLandmark = landmark
    }

    // MARK: - Computed Properties
    var formattedAltitude: String {
        if cameraAltitude >= 1_000_000 {
            return String(format: "%.1fM", cameraAltitude / 1_000_000)
        } else if cameraAltitude >= 1000 {
            return String(format: "%.1fK", cameraAltitude / 1000)
        } else {
            return String(format: "%.0f", cameraAltitude)
        }
    }

    var formattedCoordinates: String {
        let latDir = cameraLatitude >= 0 ? "N" : "S"
        let lonDir = cameraLongitude >= 0 ? "E" : "W"
        return String(format: "%.4f°%@ %.4f°%@",
                     abs(cameraLatitude), latDir,
                     abs(cameraLongitude), lonDir)
    }

    var mgrsCoordinates: String {
        // Simplified MGRS-style display
        return String(format: "MGRS: %02d%@ %05d %05d",
                     Int((cameraLongitude + 180) / 6) + 1,
                     mgrsLatitudeBand,
                     Int(abs(cameraLongitude).truncatingRemainder(dividingBy: 6) * 100000 / 6),
                     Int(abs(cameraLatitude).truncatingRemainder(dividingBy: 8) * 100000 / 8))
    }

    private var mgrsLatitudeBand: String {
        let bands = "CDEFGHJKLMNPQRSTUVWX"
        let index = min(max(Int((cameraLatitude + 80) / 8), 0), bands.count - 1)
        return String(bands[bands.index(bands.startIndex, offsetBy: index)])
    }

    var gsdValue: String {
        // Ground Sample Distance - varies with altitude
        let gsd = cameraAltitude * 0.00001 // Simplified calculation
        if gsd >= 1 {
            return String(format: "%.2fM", gsd)
        } else {
            return String(format: "%.2fcm", gsd * 100)
        }
    }

    var niirsValue: String {
        // NIIRS rating (simplified - higher is better, lower altitude = higher rating)
        let rating = max(0, min(9, 9 - log10(cameraAltitude / 1000)))
        return String(format: "%.1f", rating)
    }

    var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date()) + "Z"
    }

    var recordingTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return "REC " + formatter.string(from: Date()) + "Z"
    }

    // MARK: - Settings Persistence
    private func saveSettings() {
        let defaults = UserDefaults.standard

        // Visual mode
        defaults.set(visualMode.rawValue, forKey: SettingsKey.visualMode)

        // Sidebar state
        defaults.set(isSidebarExpanded, forKey: SettingsKey.sidebarExpanded)

        // Active layers
        let layerStrings = activeLayers.map { $0.rawValue }
        defaults.set(layerStrings, forKey: SettingsKey.activeLayers)

        // Current city (store index)
        if let cityIndex = CityPreset.presets.firstIndex(where: { $0.id == currentCity.id }) {
            defaults.set(cityIndex, forKey: SettingsKey.lastCityIndex)
        }

        // Camera position (save periodically)
        defaults.set(cameraLatitude, forKey: SettingsKey.lastLatitude)
        defaults.set(cameraLongitude, forKey: SettingsKey.lastLongitude)
        defaults.set(cameraAltitude, forKey: SettingsKey.lastAltitude)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        // Visual mode
        if let modeString = defaults.string(forKey: SettingsKey.visualMode),
           let mode = VisualMode(rawValue: modeString) {
            visualMode = mode
        }

        // Sidebar state
        if defaults.object(forKey: SettingsKey.sidebarExpanded) != nil {
            isSidebarExpanded = defaults.bool(forKey: SettingsKey.sidebarExpanded)
        }

        // Active layers
        if let layerStrings = defaults.stringArray(forKey: SettingsKey.activeLayers) {
            let layers = layerStrings.compactMap { DataLayerType(rawValue: $0) }
            if !layers.isEmpty {
                activeLayers = Set(layers)
            }
        }

        // Current city
        let cityIndex = defaults.integer(forKey: SettingsKey.lastCityIndex)
        if cityIndex >= 0 && cityIndex < CityPreset.presets.count {
            currentCity = CityPreset.presets[cityIndex]
        }

        // Camera position
        if defaults.object(forKey: SettingsKey.lastLatitude) != nil {
            cameraLatitude = defaults.double(forKey: SettingsKey.lastLatitude)
            cameraLongitude = defaults.double(forKey: SettingsKey.lastLongitude)
            cameraAltitude = defaults.double(forKey: SettingsKey.lastAltitude)

            // Ensure valid altitude
            if cameraAltitude < 1000 {
                cameraAltitude = 10_000_000
            }
        }

        print("Settings loaded: mode=\(visualMode.displayName), layers=\(activeLayers.count), city=\(currentCity.name)")
    }

    /// Save camera position (called less frequently to reduce writes)
    func saveCameraPosition() {
        let defaults = UserDefaults.standard
        defaults.set(cameraLatitude, forKey: SettingsKey.lastLatitude)
        defaults.set(cameraLongitude, forKey: SettingsKey.lastLongitude)
        defaults.set(cameraAltitude, forKey: SettingsKey.lastAltitude)
    }

    /// Reset all settings to defaults
    func resetSettings() {
        visualMode = .normal
        isSidebarExpanded = true
        activeLayers = []
        currentCity = CityPreset.presets[0]
        cameraLatitude = 38.9072
        cameraLongitude = -77.0369
        cameraAltitude = 10_000_000

        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: SettingsKey.visualMode)
        defaults.removeObject(forKey: SettingsKey.sidebarExpanded)
        defaults.removeObject(forKey: SettingsKey.activeLayers)
        defaults.removeObject(forKey: SettingsKey.lastCityIndex)
        defaults.removeObject(forKey: SettingsKey.lastLatitude)
        defaults.removeObject(forKey: SettingsKey.lastLongitude)
        defaults.removeObject(forKey: SettingsKey.lastAltitude)

        print("Settings reset to defaults")
    }
}
