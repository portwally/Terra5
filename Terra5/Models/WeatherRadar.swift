//
//  WeatherRadar.swift
//  Terra5
//
//  Weather radar station and precipitation data
//

import Foundation
import MapKit

struct WeatherRadar: Identifiable {
    let id: String
    let stationId: String
    let name: String
    let latitude: Double
    let longitude: Double
    let type: RadarType
    let status: RadarStatus
    let lastUpdate: Date?
    let precipitationLevel: PrecipitationLevel

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum RadarType: String {
        case nexrad = "NEXRAD"
        case tdwr = "TDWR"  // Terminal Doppler Weather Radar
        case asr = "ASR"    // Airport Surveillance Radar

        var displayName: String { rawValue }
    }

    enum RadarStatus: String {
        case active = "ACTIVE"
        case maintenance = "MAINT"
        case offline = "OFFLINE"

        var color: String {
            switch self {
            case .active: return "#00ff88"
            case .maintenance: return "#ffaa00"
            case .offline: return "#ff3333"
            }
        }
    }

    enum PrecipitationLevel: Int {
        case none = 0
        case light = 1
        case moderate = 2
        case heavy = 3
        case extreme = 4

        var color: String {
            switch self {
            case .none: return "#00d4aa"
            case .light: return "#00ff88"
            case .moderate: return "#ffff00"
            case .heavy: return "#ff6600"
            case .extreme: return "#ff0000"
            }
        }

        var displayName: String {
            switch self {
            case .none: return "Clear"
            case .light: return "Light"
            case .moderate: return "Moderate"
            case .heavy: return "Heavy"
            case .extreme: return "Extreme"
            }
        }
    }
}

// MARK: - Weather Alert
struct WeatherAlert: Identifiable {
    let id: String
    let type: AlertType
    let severity: Severity
    let headline: String
    let description: String
    let areas: [String]
    let effective: Date
    let expires: Date
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum AlertType: String {
        case tornado = "Tornado"
        case severeThunderstorm = "Severe Thunderstorm"
        case flood = "Flood"
        case winter = "Winter Storm"
        case heat = "Excessive Heat"
        case wind = "High Wind"
        case fire = "Fire Weather"
        case other = "Weather Alert"
    }

    enum Severity: String {
        case extreme = "Extreme"
        case severe = "Severe"
        case moderate = "Moderate"
        case minor = "Minor"
        case unknown = "Unknown"

        var color: String {
            switch self {
            case .extreme: return "#ff0000"
            case .severe: return "#ff6600"
            case .moderate: return "#ffaa00"
            case .minor: return "#ffff00"
            case .unknown: return "#00d4aa"
            }
        }
    }
}

// MARK: - NEXRAD Station Data
extension WeatherRadar {
    /// Major NEXRAD radar stations across the US
    static let nexradStations: [WeatherRadar] = [
        // East Coast
        WeatherRadar(id: "KLWX", stationId: "KLWX", name: "Sterling VA", latitude: 38.9753, longitude: -77.4778, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KDOX", stationId: "KDOX", name: "Dover AFB DE", latitude: 38.8257, longitude: -75.4400, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KOKX", stationId: "KOKX", name: "Brookhaven NY", latitude: 40.8656, longitude: -72.8639, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KDIX", stationId: "KDIX", name: "Philadelphia PA", latitude: 39.9472, longitude: -74.4111, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KBOX", stationId: "KBOX", name: "Boston MA", latitude: 41.9558, longitude: -71.1369, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),

        // Central US
        WeatherRadar(id: "KFWS", stationId: "KFWS", name: "Dallas/Ft Worth TX", latitude: 32.5731, longitude: -97.3031, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KEWX", stationId: "KEWX", name: "Austin/San Antonio TX", latitude: 29.7039, longitude: -98.0286, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KGRK", stationId: "KGRK", name: "Fort Hood TX", latitude: 30.7217, longitude: -97.3828, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KLOT", stationId: "KLOT", name: "Chicago IL", latitude: 41.6044, longitude: -88.0847, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KDTX", stationId: "KDTX", name: "Detroit MI", latitude: 42.6997, longitude: -83.4717, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),

        // West Coast
        WeatherRadar(id: "KMUX", stationId: "KMUX", name: "San Francisco CA", latitude: 37.1550, longitude: -121.8983, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KVTX", stationId: "KVTX", name: "Los Angeles CA", latitude: 34.4117, longitude: -119.1794, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KNKX", stationId: "KNKX", name: "San Diego CA", latitude: 32.9189, longitude: -117.0419, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KATX", stationId: "KATX", name: "Seattle WA", latitude: 48.1944, longitude: -122.4958, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KRTX", stationId: "KRTX", name: "Portland OR", latitude: 45.7150, longitude: -122.9656, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),

        // Southeast
        WeatherRadar(id: "KTLH", stationId: "KTLH", name: "Tallahassee FL", latitude: 30.3975, longitude: -84.3289, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KAMX", stationId: "KAMX", name: "Miami FL", latitude: 25.6111, longitude: -80.4128, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KTBW", stationId: "KTBW", name: "Tampa Bay FL", latitude: 27.7056, longitude: -82.4017, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KFFC", stationId: "KFFC", name: "Atlanta GA", latitude: 33.3636, longitude: -84.5658, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KMRX", stationId: "KMRX", name: "Knoxville TN", latitude: 36.1686, longitude: -83.4017, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),

        // Southwest
        WeatherRadar(id: "KPSR", stationId: "KPSR", name: "Phoenix AZ", latitude: 33.4372, longitude: -112.1619, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KESX", stationId: "KESX", name: "Las Vegas NV", latitude: 35.7011, longitude: -114.8914, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KABX", stationId: "KABX", name: "Albuquerque NM", latitude: 35.1497, longitude: -106.8239, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "KDEN", stationId: "KDEN", name: "Denver CO", latitude: 39.7867, longitude: -104.5458, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),

        // International (sample)
        WeatherRadar(id: "CYUL", stationId: "CYUL", name: "Montreal QC", latitude: 45.4706, longitude: -73.7408, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none),
        WeatherRadar(id: "CYYZ", stationId: "CYYZ", name: "Toronto ON", latitude: 43.6777, longitude: -79.6248, type: .nexrad, status: .active, lastUpdate: Date(), precipitationLevel: .none)
    ]
}
