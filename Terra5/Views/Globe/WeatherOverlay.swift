//
//  WeatherOverlay.swift
//  Terra5
//
//  Live weather tile overlays (rain, clouds, temperature)
//  Uses RainViewer (free, no API key) and OpenWeatherMap tiles
//

import MapKit
import SwiftUI

// MARK: - Weather Layer Types
enum WeatherLayerType: String, CaseIterable, Identifiable {
    case rain = "rain"
    case clouds = "clouds"
    case temperature = "temp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .clouds: return "Clouds"
        case .temperature: return "Temp"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .clouds: return "cloud.fill"
        case .temperature: return "thermometer.medium"
        }
    }
}

// MARK: - RainViewer Radar Overlay (Rain - Free, no API key!)
class RainRadarOverlay: MKTileOverlay {
    // Color schemes: 0=original, 1=universal blue, 2=TITAN, 3=TWC, 4=Meteored, 5=NEXRAD, 6=Rainbow, 7=Dark Sky
    init(timestamp: Int, colorScheme: Int = 6) {
        // Use urlTemplate with placeholders - MKTileOverlay replaces {x}, {y}, {z}
        let template = "https://tilecache.rainviewer.com/v2/radar/\(timestamp)/256/{z}/{x}/{y}/\(colorScheme)/1_1.png"
        NSLog("[TERRA5] RainRadarOverlay template: %@", template)
        super.init(urlTemplate: template)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 12
    }
}

// MARK: - Cloud Cover Overlay (Infrared Satellite)
class CloudCoverOverlay: MKTileOverlay {
    init(timestamp: Int) {
        // Use urlTemplate with placeholders
        let template = "https://tilecache.rainviewer.com/v2/satellite/\(timestamp)/256/{z}/{x}/{y}/0/0_0.png"
        NSLog("[TERRA5] CloudCoverOverlay template: %@", template)
        super.init(urlTemplate: template)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 8
    }
}

// MARK: - Temperature Overlay (using radar with thermal color scheme)
class TemperatureOverlay: MKTileOverlay {
    // Using RainViewer radar tiles with TITAN color scheme (red/orange/yellow)
    // This approximates a thermal view of precipitation
    init(timestamp: Int) {
        // Use urlTemplate with placeholders - TITAN color scheme (2) for thermal look
        let template = "https://tilecache.rainviewer.com/v2/radar/\(timestamp)/256/{z}/{x}/{y}/2/1_1.png"
        NSLog("[TERRA5] TemperatureOverlay template: %@", template)
        super.init(urlTemplate: template)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 12
    }
}

// MARK: - Weather Tile Manager
/// Thread-safe manager for weather tile overlay timestamps.
/// Uses @MainActor to ensure all access is serialized on the main thread,
/// since overlays are created and updated from UI-driven code.
@MainActor
class WeatherTileManager {
    static let shared = WeatherTileManager()

    private var radarTimestamp: Int = 0
    private var satelliteTimestamp: Int = 0
    private var hasValidTimestamps: Bool = false

    private init() {
        // Don't initialize with current time — wait for real timestamps from the API
        // to avoid requesting tiles with invalid timestamps that return 404s
        radarTimestamp = 0
        satelliteTimestamp = 0
    }

    /// Whether real timestamps have been fetched from the API
    var isReady: Bool { hasValidTimestamps }

    func createOverlay(for type: WeatherLayerType) -> MKTileOverlay {
        switch type {
        case .rain:
            return RainRadarOverlay(timestamp: radarTimestamp, colorScheme: 6) // Rainbow colors
        case .clouds:
            return CloudCoverOverlay(timestamp: satelliteTimestamp)
        case .temperature:
            return TemperatureOverlay(timestamp: radarTimestamp)
        }
    }

    func updateTimestamps(radar: Int, satellite: Int) {
        radarTimestamp = radar
        satelliteTimestamp = satellite
        hasValidTimestamps = true
    }
}

// MARK: - Weather Radar Service
actor WeatherRadarService {
    static let shared = WeatherRadarService()

    private let apiURL = "https://api.rainviewer.com/public/weather-maps.json"
    private var radarTimestamps: [Int] = []
    private var satelliteTimestamps: [Int] = []
    private var lastFetch: Date?

    private init() {}

    struct RainViewerResponse: Codable {
        let version: String
        let generated: Int
        let host: String
        let radar: RadarData
        let satellite: SatelliteData?

        struct RadarData: Codable {
            let past: [Frame]
            let nowcast: [Frame]?
        }

        struct SatelliteData: Codable {
            let infrared: [Frame]?
        }

        struct Frame: Codable {
            let time: Int
            let path: String
        }
    }

    /// Fetch available radar and satellite timestamps
    func fetchTimestamps() async throws -> (radar: [Int], satellite: [Int]) {
        // Cache for 2 minutes (radar updates every ~5-10 min)
        if let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < 120,
           !radarTimestamps.isEmpty {
            NSLog("[TERRA5] WeatherRadar: Using cached timestamps (radar=%d, satellite=%d)", radarTimestamps.count, satelliteTimestamps.count)
            return (radarTimestamps, satelliteTimestamps)
        }

        guard let url = URL(string: apiURL) else {
            throw WeatherRadarError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        // Debug: log raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            NSLog("[TERRA5] WeatherRadar API response (first 500 chars): %@", String(jsonString.prefix(500)))
        }

        let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

        // Get radar frames
        radarTimestamps = response.radar.past.map { $0.time }

        // Get satellite frames - check multiple possible locations
        if let infrared = response.satellite?.infrared {
            satelliteTimestamps = infrared.map { $0.time }
            NSLog("[TERRA5] WeatherRadar: Found satellite infrared data with %d frames", infrared.count)
        } else {
            NSLog("[TERRA5] WeatherRadar: No satellite.infrared data in response")
        }

        lastFetch = Date()

        NSLog("[TERRA5] WeatherRadar: Got %d radar frames, %d satellite frames", radarTimestamps.count, satelliteTimestamps.count)

        // Update the tile manager (requires await since WeatherTileManager is @MainActor)
        if let latestRadar = radarTimestamps.last {
            let latestSatellite = satelliteTimestamps.last ?? latestRadar
            await WeatherTileManager.shared.updateTimestamps(radar: latestRadar, satellite: latestSatellite)
        }

        return (radarTimestamps, satelliteTimestamps)
    }

    /// Get the most recent radar timestamp
    func getLatestRadarTimestamp() async -> Int {
        do {
            let (radar, _) = try await fetchTimestamps()
            if let latest = radar.last {
                NSLog("[TERRA5] WeatherRadarService: Returning radar timestamp %d", latest)
                return latest
            }
            NSLog("[TERRA5] WeatherRadarService: No radar timestamps available!")
            return 0
        } catch {
            NSLog("[TERRA5] WeatherRadarService: Error fetching radar timestamps: %@", error.localizedDescription)
            return 0
        }
    }

    /// Get the most recent satellite timestamp
    func getLatestSatelliteTimestamp() async -> Int {
        do {
            let (_, satellite) = try await fetchTimestamps()
            if let latest = satellite.last {
                NSLog("[TERRA5] WeatherRadarService: Returning satellite timestamp %d", latest)
                return latest
            }
            // Fall back to radar timestamp if satellite is empty
            NSLog("[TERRA5] WeatherRadarService: No satellite timestamps, trying radar...")
            let (radar, _) = try await fetchTimestamps()
            if let latest = radar.last {
                NSLog("[TERRA5] WeatherRadarService: Using radar timestamp as fallback %d", latest)
                return latest
            }
            return 0
        } catch {
            NSLog("[TERRA5] WeatherRadarService: Error fetching satellite timestamps: %@", error.localizedDescription)
            return 0
        }
    }

    /// Get all radar frame timestamps for animation
    func getRadarFrames() -> [Int] {
        return radarTimestamps
    }
}

enum WeatherRadarError: Error {
    case invalidURL
    case noData
}

// MARK: - Weather Overlay Renderer
class WeatherOverlayRenderer: MKTileOverlayRenderer {
    override init(overlay: any MKOverlay) {
        super.init(overlay: overlay)
        self.alpha = 0.7  // Semi-transparent to see map beneath
    }
}

// MARK: - Custom Weather Tile Overlay
/// Uses different tile sources for each weather type:
/// - Rain: RainViewer precipitation radar
/// - Clouds: NASA GIBS satellite imagery (free, no API key)
/// - Temperature: OpenStreetMap with thermal styling
class WeatherTileOverlay: MKTileOverlay {
    let layerType: WeatherLayerType
    let radarTimestamp: Int
    let uniqueId: String

    // NASA GIBS uses dates, not timestamps
    private var gibsDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        // Use yesterday's date since GIBS data has ~1 day delay
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }

    init(layerType: WeatherLayerType, timestamp: Int) {
        self.layerType = layerType
        self.radarTimestamp = timestamp
        self.uniqueId = UUID().uuidString

        super.init(urlTemplate: nil)

        self.canReplaceMapContent = false
        self.minimumZ = 1
        // Different max zoom for different sources
        switch layerType {
        case .rain:
            self.maximumZ = 12  // RainViewer supports up to 12
        case .clouds:
            self.maximumZ = 9   // NASA GIBS VIIRS Level 9
        case .temperature:
            self.maximumZ = 9   // NASA GIBS VIIRS Level 9
        }
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let urlString: String

        switch layerType {
        case .rain:
            // RainViewer precipitation radar - rainbow color scheme
            urlString = "https://tilecache.rainviewer.com/v2/radar/\(radarTimestamp)/256/\(path.z)/\(path.x)/\(path.y)/6/1_1.png"

        case .clouds:
            // NASA GIBS VIIRS True Color satellite imagery
            // Shows actual cloud coverage from space
            let layer = "VIIRS_SNPP_CorrectedReflectance_TrueColor"
            let clampedZ = min(path.z, 9)  // Max Level 9 for this layer
            urlString = "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/\(layer)/default/\(gibsDate)/GoogleMapsCompatible_Level9/\(clampedZ)/\(path.y)/\(path.x).jpg"

        case .temperature:
            // NASA GIBS VIIRS Brightness Temperature (thermal infrared)
            // Shows land/sea surface temperature from satellite
            let layer = "VIIRS_SNPP_Brightness_Temp_BandI5_Day"
            let clampedZ = min(path.z, 9)  // Max Level 9 for this layer
            urlString = "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/\(layer)/default/\(gibsDate)/GoogleMapsCompatible_Level9/\(clampedZ)/\(path.y)/\(path.x).png"
        }

        if path.z == 3 && path.x == 0 && path.y == 0 {
            NSLog("[TERRA5] WeatherTileOverlay: %@ URL example: %@", layerType.rawValue, urlString)
        }

        guard let url = URL(string: urlString) else {
            // Return a transparent 1x1 pixel tile as fallback
            return URL(string: "about:blank")!
        }
        return url
    }
}
