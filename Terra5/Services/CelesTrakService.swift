//
//  CelesTrakService.swift
//  Terra5
//
//  Service for fetching satellite TLE data from CelesTrak
//

import Foundation

actor CelesTrakService {
    static let shared = CelesTrakService()

    private let baseURL = "https://celestrak.org/NORAD/elements/gp.php"

    private init() {}

    enum SatelliteGroup: String, CaseIterable {
        case stations = "stations"           // Space stations (ISS, Tiangong)
        case visualSats = "visual"           // Brightest satellites
        case activeGeo = "geo"               // Geostationary satellites
        case starlinkGen1 = "starlink"       // Starlink satellites
        case oneweb = "oneweb"               // OneWeb constellation
        case gpsOps = "gps-ops"              // GPS operational
        case glonassOps = "glo-ops"          // GLONASS operational
        case galileo = "galileo"             // Galileo constellation
        case beidou = "beidou"               // BeiDou constellation
        case weather = "weather"             // Weather satellites
        case noaaOps = "noaa"                // NOAA satellites
        case earthResources = "resource"     // Earth resources
        case searchRescue = "sarsat"         // Search & rescue
        case spaceDebris = "1982-092"        // Cosmos 1408 debris (example)

        var displayName: String {
            switch self {
            case .stations: return "Space Stations"
            case .visualSats: return "Brightest"
            case .activeGeo: return "Geostationary"
            case .starlinkGen1: return "Starlink"
            case .oneweb: return "OneWeb"
            case .gpsOps: return "GPS"
            case .glonassOps: return "GLONASS"
            case .galileo: return "Galileo"
            case .beidou: return "BeiDou"
            case .weather: return "Weather"
            case .noaaOps: return "NOAA"
            case .earthResources: return "Earth Resources"
            case .searchRescue: return "Search & Rescue"
            case .spaceDebris: return "Space Debris"
            }
        }
    }

    /// Fetch satellites by group
    func fetchSatellites(group: SatelliteGroup) async throws -> [Satellite] {
        let urlString = "\(baseURL)?GROUP=\(group.rawValue)&FORMAT=TLE"
        print("[DEBUG] CelesTrak: fetching \(group.displayName) from \(urlString)")

        guard let url = URL(string: urlString) else {
            print("[DEBUG] CelesTrak: invalid URL")
            throw CelesTrakError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        print("[DEBUG] CelesTrak: received \(data.count) bytes")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[DEBUG] CelesTrak: invalid response type")
            throw CelesTrakError.invalidResponse
        }

        print("[DEBUG] CelesTrak: HTTP status \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            throw CelesTrakError.httpError(httpResponse.statusCode)
        }

        guard let tleData = String(data: data, encoding: .utf8) else {
            print("[DEBUG] CelesTrak: failed to decode as UTF8")
            throw CelesTrakError.parsingError
        }

        var satellites = Satellite.parseMultiple(from: tleData)
        print("CelesTrak: parsed \(satellites.count) satellites from \(group.displayName)")

        // Update positions
        for i in satellites.indices {
            satellites[i].updatePosition()
        }

        return satellites
    }

    /// Fetch a single satellite by NORAD ID
    func fetchSatellite(noradId: String) async throws -> Satellite? {
        let urlString = "\(baseURL)?CATNR=\(noradId)&FORMAT=TLE"

        guard let url = URL(string: urlString) else {
            throw CelesTrakError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CelesTrakError.invalidResponse
        }

        guard let tleData = String(data: data, encoding: .utf8) else {
            throw CelesTrakError.parsingError
        }

        var satellite = Satellite.from(tle: tleData)
        satellite?.updatePosition()

        return satellite
    }

    /// Fetch multiple satellite groups concurrently for faster loading
    func fetchSatellites(groups: [SatelliteGroup]) async throws -> [Satellite] {
        return try await withThrowingTaskGroup(of: [Satellite].self) { taskGroup in
            for group in groups {
                taskGroup.addTask {
                    do {
                        return try await self.fetchSatellites(group: group)
                    } catch {
                        NSLog("[TERRA5] CelesTrak: Failed to fetch %@: %@", group.displayName, error.localizedDescription)
                        return []
                    }
                }
            }

            var allSatellites: [Satellite] = []
            for try await satellites in taskGroup {
                allSatellites.append(contentsOf: satellites)
            }
            return allSatellites
        }
    }
}

enum CelesTrakError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .parsingError:
            return "Failed to parse TLE data"
        }
    }
}
