//
//  Flight.swift
//  Terra5
//
//  Model for live flight data from OpenSky Network
//

import Foundation
import MapKit

struct Flight: Identifiable, Equatable {
    let id: String // ICAO24 transponder address
    let callsign: String?
    let originCountry: String
    let longitude: Double
    let latitude: Double
    let altitude: Double // meters
    let velocity: Double // m/s
    let heading: Double // degrees from north
    let verticalRate: Double // m/s
    let onGround: Bool
    let lastContact: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var altitudeFeet: Int {
        Int(altitude * 3.28084)
    }

    var speedKnots: Int {
        Int(velocity * 1.94384)
    }

    var displayCallsign: String {
        callsign?.trimmingCharacters(in: .whitespaces) ?? id.uppercased()
    }
}

// MARK: - OpenSky API Response
// Note: OpenSky returns state vectors as heterogeneous arrays (not objects),
// so we parse them manually via JSONSerialization in OpenSkyService.
// A Codable model is not feasible because the array elements have mixed types.

extension Flight {
    /// Parse from OpenSky state vector array
    /// [0] icao24, [1] callsign, [2] origin_country, [3] time_position,
    /// [4] last_contact, [5] longitude, [6] latitude, [7] baro_altitude,
    /// [8] on_ground, [9] velocity, [10] true_track, [11] vertical_rate,
    /// [12] sensors, [13] geo_altitude, [14] squawk, [15] spi, [16] position_source
    static func from(stateVector: [Any]) -> Flight? {
        guard stateVector.count >= 12,
              let icao24 = stateVector[0] as? String,
              let latitude = stateVector[6] as? Double,
              let longitude = stateVector[5] as? Double else {
            return nil
        }

        let callsign = stateVector[1] as? String
        let originCountry = (stateVector[2] as? String) ?? "Unknown"
        let altitude = (stateVector[7] as? Double) ?? (stateVector[13] as? Double) ?? 0
        let onGround = (stateVector[8] as? Bool) ?? false
        let velocity = (stateVector[9] as? Double) ?? 0
        let heading = (stateVector[10] as? Double) ?? 0
        let verticalRate = (stateVector[11] as? Double) ?? 0
        let lastContactTimestamp = (stateVector[4] as? Int) ?? Int(Date().timeIntervalSince1970)

        return Flight(
            id: icao24,
            callsign: callsign,
            originCountry: originCountry,
            longitude: longitude,
            latitude: latitude,
            altitude: altitude,
            velocity: velocity,
            heading: heading,
            verticalRate: verticalRate,
            onGround: onGround,
            lastContact: Date(timeIntervalSince1970: TimeInterval(lastContactTimestamp))
        )
    }
}
