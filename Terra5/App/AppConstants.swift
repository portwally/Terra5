//
//  AppConstants.swift
//  Terra5
//
//  WORLDVIEW-style geospatial intelligence platform
//

import SwiftUI

// MARK: - Theme Colors
enum Theme {
    // Primary colors from WORLDVIEW design
    static let background = Color(hex: "#0a0a0a")
    static let backgroundSecondary = Color(hex: "#111111")
    static let accent = Color(hex: "#00d4aa")
    static let accentDim = Color(hex: "#00d4aa").opacity(0.6)

    // Status colors
    static let warning = Color(hex: "#ffaa00")
    static let alert = Color(hex: "#ff3333")
    static let success = Color(hex: "#00ff88")

    // Text colors
    static let textPrimary = Color(hex: "#00ff88")
    static let textSecondary = Color(hex: "#66ffcc")
    static let textMuted = Color(hex: "#00d4aa").opacity(0.5)

    // UI elements
    static let gridLine = Color(hex: "#00d4aa").opacity(0.2)
    static let border = Color(hex: "#00d4aa").opacity(0.3)
    static let panelBackground = Color(hex: "#0a0a0a").opacity(0.85)

    // Classification colors
    static let topSecret = Color(hex: "#ff3333")
    static let classified = Color(hex: "#ffaa00")
}

// MARK: - Typography
enum Typography {
    static let hudFont = Font.custom("Menlo", size: 11)
    static let headerFont = Font.custom("Menlo", size: 13).weight(.bold)
    static let classificationFont = Font.custom("Menlo", size: 10).weight(.medium)
    static let labelFont = Font.custom("Menlo", size: 10)
    static let dataFont = Font.custom("Menlo", size: 12)
    static let titleFont = Font.custom("Menlo", size: 16).weight(.bold)
}

// MARK: - API Endpoints
enum APIEndpoints {
    static let openSky = "https://opensky-network.org/api/states/all"
    static let celestrak = "https://celestrak.org/NORAD/elements/gp.php"
    static let usgs = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
}

// MARK: - App Configuration
enum AppConfig {
    static let appName = "WORLDVIEW"
    static let appTagline = "NO PLACE LEFT BEHIND"
    static let classificationText = "TOP SECRET // SI-TK // NOFORN"
    static let satelliteDesignation = "KH11-4166 OPS-4117"

    // Update intervals (seconds)
    static let flightUpdateInterval: TimeInterval = 10
    static let satelliteUpdateInterval: TimeInterval = 60
    static let earthquakeUpdateInterval: TimeInterval = 300
}

// MARK: - City Presets
struct CityPreset: Identifiable, Hashable {
    /// Use the city name as a stable identifier so equality/persistence works across launches
    var id: String { name }
    let name: String
    let latitude: Double
    let longitude: Double
    let defaultAltitude: Double
    let landmarks: [Landmark]

    static let presets: [CityPreset] = [
        CityPreset(
            name: "Washington DC",
            latitude: 38.9072,
            longitude: -77.0369,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "US Capitol", latitude: 38.8899, longitude: -77.0091),
                Landmark(name: "Washington Monument", latitude: 38.8895, longitude: -77.0353),
                Landmark(name: "Lincoln Memorial", latitude: 38.8893, longitude: -77.0502),
                Landmark(name: "Pentagon", latitude: 38.8719, longitude: -77.0563),
                Landmark(name: "Jefferson Memorial", latitude: 38.8814, longitude: -77.0365)
            ]
        ),
        CityPreset(
            name: "Austin",
            latitude: 30.2672,
            longitude: -97.7431,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Texas State Capitol", latitude: 30.2747, longitude: -97.7404),
                Landmark(name: "Frost Bank Tower", latitude: 30.2659, longitude: -97.7428),
                Landmark(name: "Pennybacker Bridge", latitude: 30.3455, longitude: -97.7891),
                Landmark(name: "UT Tower", latitude: 30.2862, longitude: -97.7394)
            ]
        ),
        CityPreset(
            name: "San Francisco",
            latitude: 37.7749,
            longitude: -122.4194,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Golden Gate Bridge", latitude: 37.8199, longitude: -122.4783),
                Landmark(name: "Alcatraz", latitude: 37.8267, longitude: -122.4230),
                Landmark(name: "Transamerica Pyramid", latitude: 37.7952, longitude: -122.4028)
            ]
        ),
        CityPreset(
            name: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Empire State Building", latitude: 40.7484, longitude: -73.9857),
                Landmark(name: "Statue of Liberty", latitude: 40.6892, longitude: -74.0445),
                Landmark(name: "Central Park", latitude: 40.7829, longitude: -73.9654)
            ]
        ),
        CityPreset(
            name: "London",
            latitude: 51.5074,
            longitude: -0.1278,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Tower Bridge", latitude: 51.5055, longitude: -0.0754),
                Landmark(name: "The Shard", latitude: 51.5045, longitude: -0.0865),
                Landmark(name: "Big Ben / Parliament", latitude: 51.5007, longitude: -0.1246),
                Landmark(name: "St. Paul's Cathedral", latitude: 51.5138, longitude: -0.0984),
                Landmark(name: "The Gherkin", latitude: 51.5145, longitude: -0.0803)
            ]
        ),
        CityPreset(
            name: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Tokyo Tower", latitude: 35.6586, longitude: 139.7454),
                Landmark(name: "Tokyo Skytree", latitude: 35.7101, longitude: 139.8107),
                Landmark(name: "Imperial Palace", latitude: 35.6852, longitude: 139.7528)
            ]
        ),
        CityPreset(
            name: "Paris",
            latitude: 48.8566,
            longitude: 2.3522,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Eiffel Tower", latitude: 48.8584, longitude: 2.2945),
                Landmark(name: "Arc de Triomphe", latitude: 48.8738, longitude: 2.2950),
                Landmark(name: "Notre-Dame", latitude: 48.8530, longitude: 2.3499)
            ]
        ),
        CityPreset(
            name: "Dubai",
            latitude: 25.2048,
            longitude: 55.2708,
            defaultAltitude: 50000,
            landmarks: [
                Landmark(name: "Burj Khalifa", latitude: 25.1972, longitude: 55.2744),
                Landmark(name: "Palm Jumeirah", latitude: 25.1124, longitude: 55.1390),
                Landmark(name: "Burj Al Arab", latitude: 25.1412, longitude: 55.1853)
            ]
        )
    ]
}

struct Landmark: Identifiable, Hashable {
    /// Use the landmark name as a stable identifier
    var id: String { name }
    let name: String
    let latitude: Double
    let longitude: Double
    let zoomAltitude: Double = 5000
}

// MARK: - Visual Modes
enum VisualMode: String, CaseIterable, Identifiable {
    case normal = "normal"
    case crt = "crt"
    case nvg = "nvg"
    case flir = "flir"
    case anime = "anime"
    case noir = "noir"
    case snow = "snow"
    case ai = "ai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .crt: return "CRT"
        case .nvg: return "NVG"
        case .flir: return "FLIR"
        case .anime: return "Anime"
        case .noir: return "Noir"
        case .snow: return "Snow"
        case .ai: return "AI"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "eye"
        case .crt: return "tv"
        case .nvg: return "moon.fill"
        case .flir: return "flame"
        case .anime: return "paintbrush"
        case .noir: return "circle.lefthalf.filled"
        case .snow: return "snowflake"
        case .ai: return "brain"
        }
    }
}

// MARK: - Data Layer Types
enum DataLayerType: String, CaseIterable, Identifiable {
    case flights = "flights"
    case satellites = "satellites"
    case earthquakes = "earthquakes"
    case traffic = "traffic"
    case weather = "weather"
    case cctv = "cctv"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flights: return "Live Flights"
        case .satellites: return "Satellites"
        case .earthquakes: return "Earthquakes (24h)"
        case .traffic: return "Street Traffic"
        case .weather: return "Weather Radar"
        case .cctv: return "CCTV Cameras"
        }
    }

    var icon: String {
        switch self {
        case .flights: return "airplane"
        case .satellites: return "antenna.radiowaves.left.and.right"
        case .earthquakes: return "waveform.path.ecg"
        case .traffic: return "car.fill"
        case .weather: return "cloud.rain"
        case .cctv: return "video.fill"
        }
    }

    var dataSource: String {
        switch self {
        case .flights: return "OpenSky Network"
        case .satellites: return "CelesTrak"
        case .earthquakes: return "USGS"
        case .traffic: return "OpenStreetMap"
        case .weather: return "RainViewer / NASA"
        case .cctv: return "insecam.org"
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Opaque black as fallback
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
