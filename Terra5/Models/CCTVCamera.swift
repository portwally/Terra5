//
//  CCTVCamera.swift
//  Terra5
//
//  CCTV surveillance camera markers
//

import Foundation
import MapKit

struct CCTVCamera: Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let type: CameraType
    let status: CameraStatus
    let feedUrl: String?
    let city: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CameraType: String {
        case traffic = "TRAFFIC"
        case security = "SECURITY"
        case publicSpace = "PUBLIC"
        case infrastructure = "INFRA"
        case port = "PORT"
        case airport = "AIRPORT"

        var displayName: String {
            switch self {
            case .traffic: return "Traffic Cam"
            case .security: return "Security"
            case .publicSpace: return "Public Space"
            case .infrastructure: return "Infrastructure"
            case .port: return "Port/Harbor"
            case .airport: return "Airport"
            }
        }

        var icon: String {
            switch self {
            case .traffic: return "car.fill"
            case .security: return "lock.shield"
            case .publicSpace: return "person.3.fill"
            case .infrastructure: return "building.2"
            case .port: return "ferry"
            case .airport: return "airplane.departure"
            }
        }
    }

    enum CameraStatus: String {
        case online = "ONLINE"
        case offline = "OFFLINE"
        case maintenance = "MAINT"
        case recording = "REC"

        var color: String {
            switch self {
            case .online, .recording: return "#00ff88"
            case .maintenance: return "#ffaa00"
            case .offline: return "#ff3333"
            }
        }
    }

    var statusIndicator: String {
        switch status {
        case .recording: return "● REC"
        case .online: return "● LIVE"
        case .offline: return "○ OFF"
        case .maintenance: return "◐ MAINT"
        }
    }
}

// MARK: - Sample Camera Networks
extension CCTVCamera {
    /// Generate camera network for a city
    static func generateCameras(for city: CityPreset, count: Int = 15) -> [CCTVCamera] {
        var cameras: [CCTVCamera] = []
        let types: [CameraType] = [.traffic, .traffic, .traffic, .security, .publicSpace, .infrastructure]
        let statuses: [CameraStatus] = [.online, .online, .online, .online, .recording, .maintenance, .offline]

        // Generate cameras around city center and landmarks
        for i in 0..<count {
            let offsetLat = Double.random(in: -0.05...0.05)
            let offsetLon = Double.random(in: -0.05...0.05)

            let camera = CCTVCamera(
                id: "\(city.name.prefix(3).uppercased())-CAM-\(String(format: "%03d", i + 1))",
                name: "\(city.name) Camera \(i + 1)",
                latitude: city.latitude + offsetLat,
                longitude: city.longitude + offsetLon,
                type: types[i % types.count],
                status: statuses[Int.random(in: 0..<statuses.count)],
                feedUrl: nil,
                city: city.name
            )
            cameras.append(camera)
        }

        // Add cameras near landmarks
        for landmark in city.landmarks.prefix(5) {
            let camera = CCTVCamera(
                id: "\(city.name.prefix(3).uppercased())-LMK-\(landmark.name.prefix(4).uppercased())",
                name: "\(landmark.name) Cam",
                latitude: landmark.latitude + Double.random(in: -0.001...0.001),
                longitude: landmark.longitude + Double.random(in: -0.001...0.001),
                type: .security,
                status: .recording,
                feedUrl: nil,
                city: city.name
            )
            cameras.append(camera)
        }

        return cameras
    }

    /// Sample cameras for major cities
    static let sampleCameras: [CCTVCamera] = {
        var allCameras: [CCTVCamera] = []

        // Washington DC cameras
        allCameras.append(contentsOf: [
            CCTVCamera(id: "DC-CAM-001", name: "Capitol Hill NW", latitude: 38.8899, longitude: -77.0091, type: .security, status: .recording, feedUrl: nil, city: "Washington DC"),
            CCTVCamera(id: "DC-CAM-002", name: "National Mall East", latitude: 38.8893, longitude: -77.0230, type: .publicSpace, status: .online, feedUrl: nil, city: "Washington DC"),
            CCTVCamera(id: "DC-CAM-003", name: "K Street Corridor", latitude: 38.9022, longitude: -77.0369, type: .traffic, status: .online, feedUrl: nil, city: "Washington DC"),
            CCTVCamera(id: "DC-CAM-004", name: "Georgetown", latitude: 38.9076, longitude: -77.0723, type: .traffic, status: .online, feedUrl: nil, city: "Washington DC"),
            CCTVCamera(id: "DC-CAM-005", name: "Pentagon Access", latitude: 38.8719, longitude: -77.0563, type: .security, status: .recording, feedUrl: nil, city: "Washington DC"),
        ])

        // New York cameras
        allCameras.append(contentsOf: [
            CCTVCamera(id: "NYC-CAM-001", name: "Times Square", latitude: 40.7580, longitude: -73.9855, type: .publicSpace, status: .recording, feedUrl: nil, city: "New York"),
            CCTVCamera(id: "NYC-CAM-002", name: "Grand Central", latitude: 40.7527, longitude: -73.9772, type: .infrastructure, status: .online, feedUrl: nil, city: "New York"),
            CCTVCamera(id: "NYC-CAM-003", name: "Brooklyn Bridge", latitude: 40.7061, longitude: -73.9969, type: .infrastructure, status: .online, feedUrl: nil, city: "New York"),
            CCTVCamera(id: "NYC-CAM-004", name: "Wall Street", latitude: 40.7074, longitude: -74.0113, type: .security, status: .recording, feedUrl: nil, city: "New York"),
            CCTVCamera(id: "NYC-CAM-005", name: "JFK Terminal 4", latitude: 40.6413, longitude: -73.7781, type: .airport, status: .online, feedUrl: nil, city: "New York"),
        ])

        // San Francisco cameras
        allCameras.append(contentsOf: [
            CCTVCamera(id: "SF-CAM-001", name: "Golden Gate Vista", latitude: 37.8199, longitude: -122.4783, type: .publicSpace, status: .online, feedUrl: nil, city: "San Francisco"),
            CCTVCamera(id: "SF-CAM-002", name: "Embarcadero", latitude: 37.7938, longitude: -122.3949, type: .traffic, status: .online, feedUrl: nil, city: "San Francisco"),
            CCTVCamera(id: "SF-CAM-003", name: "Fisherman's Wharf", latitude: 37.8080, longitude: -122.4177, type: .publicSpace, status: .recording, feedUrl: nil, city: "San Francisco"),
            CCTVCamera(id: "SF-CAM-004", name: "SFO International", latitude: 37.6213, longitude: -122.3790, type: .airport, status: .online, feedUrl: nil, city: "San Francisco"),
            CCTVCamera(id: "SF-CAM-005", name: "Port of Oakland", latitude: 37.7955, longitude: -122.2783, type: .port, status: .online, feedUrl: nil, city: "San Francisco"),
        ])

        // London cameras
        allCameras.append(contentsOf: [
            CCTVCamera(id: "LON-CAM-001", name: "Tower Bridge", latitude: 51.5055, longitude: -0.0754, type: .infrastructure, status: .online, feedUrl: nil, city: "London"),
            CCTVCamera(id: "LON-CAM-002", name: "Trafalgar Square", latitude: 51.5080, longitude: -0.1281, type: .publicSpace, status: .recording, feedUrl: nil, city: "London"),
            CCTVCamera(id: "LON-CAM-003", name: "Westminster", latitude: 51.4994, longitude: -0.1248, type: .security, status: .recording, feedUrl: nil, city: "London"),
            CCTVCamera(id: "LON-CAM-004", name: "Heathrow T5", latitude: 51.4700, longitude: -0.4543, type: .airport, status: .online, feedUrl: nil, city: "London"),
            CCTVCamera(id: "LON-CAM-005", name: "Canary Wharf", latitude: 51.5054, longitude: -0.0235, type: .security, status: .online, feedUrl: nil, city: "London"),
        ])

        // Tokyo cameras
        allCameras.append(contentsOf: [
            CCTVCamera(id: "TYO-CAM-001", name: "Shibuya Crossing", latitude: 35.6595, longitude: 139.7004, type: .publicSpace, status: .recording, feedUrl: nil, city: "Tokyo"),
            CCTVCamera(id: "TYO-CAM-002", name: "Tokyo Station", latitude: 35.6812, longitude: 139.7671, type: .infrastructure, status: .online, feedUrl: nil, city: "Tokyo"),
            CCTVCamera(id: "TYO-CAM-003", name: "Akihabara", latitude: 35.7023, longitude: 139.7745, type: .publicSpace, status: .online, feedUrl: nil, city: "Tokyo"),
            CCTVCamera(id: "TYO-CAM-004", name: "Narita Airport", latitude: 35.7647, longitude: 140.3864, type: .airport, status: .online, feedUrl: nil, city: "Tokyo"),
            CCTVCamera(id: "TYO-CAM-005", name: "Rainbow Bridge", latitude: 35.6369, longitude: 139.7631, type: .infrastructure, status: .online, feedUrl: nil, city: "Tokyo"),
        ])

        return allCameras
    }()
}
