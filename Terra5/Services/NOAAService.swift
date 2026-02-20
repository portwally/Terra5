//
//  NOAAService.swift
//  Terra5
//
//  Service for fetching NOAA weather radar and alert data
//

import Foundation

actor NOAAService {
    static let shared = NOAAService()

    // NOAA Weather API endpoints
    private let alertsURL = "https://api.weather.gov/alerts/active"
    private let radarStatusURL = "https://api.weather.gov/radar/stations"

    private init() {}

    /// Fetch all NEXRAD radar stations with current status
    func fetchRadarStations() async throws -> [WeatherRadar] {
        // For now, return static NEXRAD stations with simulated precipitation
        // In production, this would fetch from NOAA's radar API
        var stations = WeatherRadar.nexradStations

        // Simulate some precipitation activity
        for i in stations.indices {
            // Randomly assign precipitation levels for demo
            let randomLevel = Int.random(in: 0...10)
            let precipLevel: WeatherRadar.PrecipitationLevel
            switch randomLevel {
            case 0...6: precipLevel = .none
            case 7...8: precipLevel = .light
            case 9: precipLevel = .moderate
            default: precipLevel = .heavy
            }

            stations[i] = WeatherRadar(
                id: stations[i].id,
                stationId: stations[i].stationId,
                name: stations[i].name,
                latitude: stations[i].latitude,
                longitude: stations[i].longitude,
                type: stations[i].type,
                status: stations[i].status,
                lastUpdate: Date(),
                precipitationLevel: precipLevel
            )
        }

        print("NOAAService: Loaded \(stations.count) radar stations")
        return stations
    }

    /// Fetch active weather alerts
    func fetchWeatherAlerts() async throws -> [WeatherAlert] {
        guard let url = URL(string: alertsURL) else {
            throw NOAAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        request.setValue("Terra5/1.0 (contact@example.com)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NOAAError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let alertResponse = try decoder.decode(NOAAAlertResponse.self, from: data)
            let alerts = alertResponse.features.compactMap { feature -> WeatherAlert? in
                guard let geometry = feature.geometry,
                      let coordinates = geometry.coordinates?.first?.first else {
                    return nil
                }

                let props = feature.properties
                let alertType = parseAlertType(props.event ?? "")
                let severity = parseSeverity(props.severity ?? "")

                return WeatherAlert(
                    id: feature.id ?? UUID().uuidString,
                    type: alertType,
                    severity: severity,
                    headline: props.headline ?? "Weather Alert",
                    description: props.description ?? "",
                    areas: props.areaDesc?.components(separatedBy: "; ") ?? [],
                    effective: props.effective ?? Date(),
                    expires: props.expires ?? Date().addingTimeInterval(3600),
                    latitude: coordinates[1],
                    longitude: coordinates[0]
                )
            }

            print("NOAAService: Fetched \(alerts.count) weather alerts")
            return alerts
        } catch {
            print("NOAAService: Alert parsing error: \(error)")
            // Return empty array on parsing failure
            return []
        }
    }

    private func parseAlertType(_ event: String) -> WeatherAlert.AlertType {
        let lowercased = event.lowercased()
        if lowercased.contains("tornado") { return .tornado }
        if lowercased.contains("thunderstorm") { return .severeThunderstorm }
        if lowercased.contains("flood") { return .flood }
        if lowercased.contains("winter") || lowercased.contains("snow") || lowercased.contains("ice") { return .winter }
        if lowercased.contains("heat") { return .heat }
        if lowercased.contains("wind") { return .wind }
        if lowercased.contains("fire") { return .fire }
        return .other
    }

    private func parseSeverity(_ severity: String) -> WeatherAlert.Severity {
        switch severity.lowercased() {
        case "extreme": return .extreme
        case "severe": return .severe
        case "moderate": return .moderate
        case "minor": return .minor
        default: return .unknown
        }
    }
}

// MARK: - NOAA API Response Models
struct NOAAAlertResponse: Codable {
    let features: [NOAAAlertFeature]
}

struct NOAAAlertFeature: Codable {
    let id: String?
    let geometry: NOAAGeometry?
    let properties: NOAAAlertProperties
}

struct NOAAGeometry: Codable {
    let type: String?
    let coordinates: [[[Double]]]?
}

struct NOAAAlertProperties: Codable {
    let event: String?
    let severity: String?
    let headline: String?
    let description: String?
    let areaDesc: String?
    let effective: Date?
    let expires: Date?
}

// MARK: - Errors
enum NOAAError: LocalizedError {
    case invalidURL
    case invalidResponse
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid NOAA API URL"
        case .invalidResponse: return "Invalid response from NOAA"
        case .parsingError: return "Failed to parse weather data"
        }
    }
}
