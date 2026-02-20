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
    private var timestamp: Int
    private var colorScheme: Int

    // Color schemes: 0=original, 1=universal blue, 2=TITAN, 3=TWC, 4=Meteored, 5=NEXRAD, 6=Rainbow, 7=Dark Sky
    init(timestamp: Int? = nil, colorScheme: Int = 6) {
        self.timestamp = timestamp ?? Int(Date().timeIntervalSince1970)
        self.colorScheme = colorScheme
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 12
    }

    func updateTimestamp(_ newTimestamp: Int) {
        self.timestamp = newTimestamp
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // RainViewer tile URL format (no API key required!)
        // https://tilecache.rainviewer.com/v2/radar/{timestamp}/{size}/{z}/{x}/{y}/{color}/{options}.png
        // options: 1_1 = smooth + snow
        let urlString = "https://tilecache.rainviewer.com/v2/radar/\(timestamp)/256/\(path.z)/\(path.x)/\(path.y)/\(colorScheme)/1_1.png"
        NSLog("[TERRA5] Rain tile URL: %@", urlString)
        return URL(string: urlString)!
    }
}

// MARK: - Cloud Cover Overlay (Infrared Satellite)
class CloudCoverOverlay: MKTileOverlay {
    private var timestamp: Int

    init(timestamp: Int? = nil) {
        self.timestamp = timestamp ?? Int(Date().timeIntervalSince1970)
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 8
    }

    func updateTimestamp(_ newTimestamp: Int) {
        self.timestamp = newTimestamp
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // RainViewer satellite IR tiles (shows cloud cover)
        let urlString = "https://tilecache.rainviewer.com/v2/satellite/\(timestamp)/256/\(path.z)/\(path.x)/\(path.y)/0/0_0.png"
        NSLog("[TERRA5] Cloud tile URL: %@", urlString)
        return URL(string: urlString)!
    }
}

// MARK: - Temperature Overlay (using radar with thermal color scheme)
class TemperatureOverlay: MKTileOverlay {
    // Using RainViewer radar tiles with TITAN color scheme (red/orange/yellow)
    // This approximates a thermal view of precipitation
    private var timestamp: Int

    init(timestamp: Int? = nil) {
        self.timestamp = timestamp ?? Int(Date().timeIntervalSince1970)
        super.init(urlTemplate: nil)
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 12
    }

    func updateTimestamp(_ newTimestamp: Int) {
        self.timestamp = newTimestamp
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // RainViewer radar with TITAN color scheme (2) - red/orange/yellow thermal look
        let urlString = "https://tilecache.rainviewer.com/v2/radar/\(timestamp)/256/\(path.z)/\(path.x)/\(path.y)/2/1_1.png"
        return URL(string: urlString)!
    }
}

// MARK: - Weather Tile Manager
class WeatherTileManager {
    static let shared = WeatherTileManager()

    private var radarTimestamp: Int = 0
    private var satelliteTimestamp: Int = 0

    private init() {
        // Initialize with current time
        radarTimestamp = Int(Date().timeIntervalSince1970)
        satelliteTimestamp = Int(Date().timeIntervalSince1970)
    }

    func createOverlay(for type: WeatherLayerType) -> MKTileOverlay {
        switch type {
        case .rain:
            return RainRadarOverlay(timestamp: radarTimestamp, colorScheme: 6) // Rainbow colors
        case .clouds:
            return CloudCoverOverlay(timestamp: satelliteTimestamp)
        case .temperature:
            return TemperatureOverlay()
        }
    }

    func updateTimestamps(radar: Int, satellite: Int) {
        radarTimestamp = radar
        satelliteTimestamp = satellite
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
        // Cache for 5 minutes
        if let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < 300,
           !radarTimestamps.isEmpty {
            return (radarTimestamps, satelliteTimestamps)
        }

        guard let url = URL(string: apiURL) else {
            throw WeatherRadarError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

        // Get radar frames
        radarTimestamps = response.radar.past.map { $0.time }

        // Get satellite frames
        if let infrared = response.satellite?.infrared {
            satelliteTimestamps = infrared.map { $0.time }
        }

        lastFetch = Date()

        NSLog("[TERRA5] WeatherRadar: Got %d radar frames, %d satellite frames", radarTimestamps.count, satelliteTimestamps.count)

        // Update the tile manager
        if let latestRadar = radarTimestamps.last,
           let latestSatellite = satelliteTimestamps.last {
            WeatherTileManager.shared.updateTimestamps(radar: latestRadar, satellite: latestSatellite)
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
