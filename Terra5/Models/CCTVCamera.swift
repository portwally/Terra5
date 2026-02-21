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

// MARK: - Worldwide Camera Database
extension CCTVCamera {

    // All feed URLs verified from real web search results — no fabricated paths.
    // Sources: skylinewebcams.com, webcamtaxi.com, earthcam.com, earthtv.com, beachcam.meo.pt

    static let sampleCameras: [CCTVCamera] = {
        var c: [CCTVCamera] = []

        // ═══════════════════════ UNITED STATES ═══════════════════════

        c.append(contentsOf: [
            // New York City
            CCTVCamera(id: "NYC-001", name: "Times Square", latitude: 40.7590, longitude: -73.9845, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/new-york/new-york/times-square.html", city: "New York"),
            CCTVCamera(id: "NYC-002", name: "New York Skyline", latitude: 40.7527, longitude: -73.9772, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/new-york/new-york/skyline-new-york.html", city: "New York"),
            CCTVCamera(id: "NYC-003", name: "Brooklyn Bridge", latitude: 40.7061, longitude: -73.9969, type: .infrastructure, status: .online, feedUrl: "https://www.webcamtaxi.com/en/usa/new-york/brooklyn-cam.html", city: "New York"),
            CCTVCamera(id: "NYC-004", name: "Statue of Liberty", latitude: 40.6892, longitude: -74.0445, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/newyork/statueofliberty/", city: "New York"),
            CCTVCamera(id: "NYC-005", name: "Times Square EarthCam", latitude: 40.7589, longitude: -73.9851, type: .publicSpace, status: .recording, feedUrl: "https://www.earthcam.com/usa/newyork/timessquare/", city: "New York"),

            // Washington DC
            CCTVCamera(id: "DC-001", name: "White House", latitude: 38.8977, longitude: -77.0365, type: .security, status: .recording, feedUrl: "https://www.earthtv.com/en/webcam/washington-white-house", city: "Washington DC"),

            // Los Angeles
            CCTVCamera(id: "LA-001", name: "Hollywood Boulevard", latitude: 34.1016, longitude: -118.3385, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/california/losangeles/hollywoodblvd/", city: "Los Angeles"),
            CCTVCamera(id: "LA-002", name: "Venice Beach", latitude: 33.9850, longitude: -118.4695, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/california/los-angeles/venice-beach.html", city: "Los Angeles"),

            // San Francisco
            CCTVCamera(id: "SF-001", name: "San Francisco City Views", latitude: 37.7749, longitude: -122.4194, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/usa/california/sanfrancisco-city-views.html", city: "San Francisco"),

            // Chicago
            CCTVCamera(id: "CHI-001", name: "Chicago EarthCam", latitude: 41.8663, longitude: -87.6170, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/illinois/chicago/field/", city: "Chicago"),

            // Miami
            CCTVCamera(id: "MIA-001", name: "Miami Beach", latitude: 25.7907, longitude: -80.1300, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/florida/miami/miami-beach.html", city: "Miami"),
            CCTVCamera(id: "MIA-002", name: "Miami & Beaches", latitude: 25.7617, longitude: -80.1918, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/florida/miamiandthebeaches/", city: "Miami"),

            // Las Vegas
            CCTVCamera(id: "LV-001", name: "Las Vegas Strip", latitude: 36.1265, longitude: -115.1708, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/nevada/las-vegas/las-vegas.html", city: "Las Vegas"),
            CCTVCamera(id: "LV-002", name: "Las Vegas Sphere", latitude: 36.1200, longitude: -115.1650, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/nevada/las-vegas/sphere.html", city: "Las Vegas"),

            // Nashville
            CCTVCamera(id: "NAS-001", name: "Nashville Broadway", latitude: 36.1627, longitude: -86.7816, type: .publicSpace, status: .recording, feedUrl: "https://www.earthcam.com/usa/tennessee/nashville/", city: "Nashville"),

            // New Orleans
            CCTVCamera(id: "NOL-001", name: "Bourbon Street", latitude: 29.9584, longitude: -90.0654, type: .publicSpace, status: .recording, feedUrl: "https://www.earthcam.com/usa/louisiana/neworleans/bourbonstreet/", city: "New Orleans"),

            // Hawaii
            CCTVCamera(id: "HI-001", name: "Honolulu", latitude: 21.3069, longitude: -157.8583, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/hawaii/honolulu/honolulu.html", city: "Honolulu"),

            // Key West
            CCTVCamera(id: "KW-001", name: "Key West", latitude: 24.5551, longitude: -81.7800, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/florida/keywest/", city: "Key West"),

            // San Diego
            CCTVCamera(id: "SD-001", name: "San Diego Rail Cam", latitude: 32.7157, longitude: -117.1611, type: .traffic, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-states/california/san-diego/railcam.html", city: "San Diego"),
        ])

        // ═══════════════════════ UNITED KINGDOM ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "LON-001", name: "Tower Bridge", latitude: 51.5055, longitude: -0.0754, type: .infrastructure, status: .online, feedUrl: "https://www.webcamtaxi.com/en/england/london/tower-bridge.html", city: "London"),
            CCTVCamera(id: "LON-002", name: "Palace of Westminster", latitude: 51.4995, longitude: -0.1248, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/england/london/palace-of-westminster.html", city: "London"),
            CCTVCamera(id: "LON-003", name: "London Panorama", latitude: 51.5074, longitude: -0.1278, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/england/london/london-panorama.html", city: "London"),
            CCTVCamera(id: "LON-004", name: "Abbey Road", latitude: 51.5320, longitude: -0.1780, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/world/england/london/abbeyroad/", city: "London"),
        ])

        // ═══════════════════════ IRELAND ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "DUB-001", name: "Temple Bar Dublin", latitude: 53.3457, longitude: -6.2639, type: .publicSpace, status: .recording, feedUrl: "https://www.earthcam.com/world/ireland/dublin/", city: "Dublin"),
        ])

        // ═══════════════════════ FRANCE ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "PAR-001", name: "Eiffel Tower", latitude: 48.8584, longitude: 2.2945, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/france/ile-de-france/paris/tour-eiffel.html", city: "Paris"),
            CCTVCamera(id: "PAR-002", name: "Paris Tour Eiffel Panorama", latitude: 48.8583, longitude: 2.2944, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/france/ile-de-france/paris/paris-tour-eiffel.html", city: "Paris"),
            CCTVCamera(id: "PAR-003", name: "View of Paris", latitude: 48.8566, longitude: 2.3522, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/france/ile-de-france/view-paris.html", city: "Paris"),
        ])

        // ═══════════════════════ ITALY ═══════════════════════

        c.append(contentsOf: [
            // Rome
            CCTVCamera(id: "ROM-001", name: "Colosseum", latitude: 41.8902, longitude: 12.4922, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/lazio/roma/colosseo.html", city: "Rome"),
            CCTVCamera(id: "ROM-002", name: "Colosseum View", latitude: 41.8903, longitude: 12.4923, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/lazio/roma/roma-colosseo.html", city: "Rome"),
            CCTVCamera(id: "ROM-003", name: "Trevi Fountain", latitude: 41.9009, longitude: 12.4833, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/lazio/roma/fontana-di-trevi.html", city: "Rome"),
            CCTVCamera(id: "ROM-004", name: "Piazza Venezia", latitude: 41.8958, longitude: 12.4823, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/lazio/roma/roma-piazza-venezia.html", city: "Rome"),

            // Milan
            CCTVCamera(id: "MIL-001", name: "Duomo di Milano", latitude: 45.4642, longitude: 9.1900, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/lombardia/milano/duomo-milano.html", city: "Milan"),

            // Venice
            CCTVCamera(id: "VEN-001", name: "Grand Canal", latitude: 45.4341, longitude: 12.3388, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/veneto/venezia/canal-grande.html", city: "Venice"),
            CCTVCamera(id: "VEN-002", name: "Rialto Bridge", latitude: 45.4380, longitude: 12.3360, type: .infrastructure, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/veneto/venezia/rialto-canal-grande.html", city: "Venice"),
            CCTVCamera(id: "VEN-003", name: "Piazza San Marco", latitude: 45.4343, longitude: 12.3388, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/veneto/venezia/piazza-san-marco.html", city: "Venice"),
            CCTVCamera(id: "VEN-004", name: "San Giorgio Island", latitude: 45.4290, longitude: 12.3430, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/veneto/venezia/san-giorgio.html", city: "Venice"),
            CCTVCamera(id: "VEN-005", name: "Calatrava Bridge", latitude: 45.4410, longitude: 12.3190, type: .infrastructure, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/veneto/venezia/ponte-di-calatrava.html", city: "Venice"),

            // Naples
            CCTVCamera(id: "NAP-001", name: "Port of Naples", latitude: 40.8365, longitude: 14.2681, type: .port, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/campania/napoli/napoli-porto.html", city: "Naples"),

            // Mount Etna
            CCTVCamera(id: "ETN-001", name: "Mount Etna South", latitude: 37.7510, longitude: 14.9934, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/italia/sicilia/catania/vulcano-etna-lato-sud.html", city: "Catania"),
        ])

        // ═══════════════════════ SPAIN ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "BCN-001", name: "Sagrada Familia", latitude: 41.4036, longitude: 2.1744, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/spain/barcelona/sagrada-familia.html", city: "Barcelona"),
        ])

        // ═══════════════════════ PORTUGAL ═══════════════════════

        c.append(contentsOf: [
            // Nazaré — famous giant waves
            CCTVCamera(id: "PT-NAZ-001", name: "Nazaré Praia do Norte", latitude: 39.6018, longitude: -9.0717, type: .publicSpace, status: .recording, feedUrl: "https://beachcam.meo.pt/livecams/nazare-norte/", city: "Nazaré"),
            // Peniche — world-class surf
            CCTVCamera(id: "PT-PEN-001", name: "Supertubos Peniche", latitude: 39.3433, longitude: -9.3756, type: .publicSpace, status: .recording, feedUrl: "https://beachcam.meo.pt/livecams/peniche-supertubos/", city: "Peniche"),
            // Algarve
            CCTVCamera(id: "PT-ALG-001", name: "Praia da Rocha", latitude: 37.1167, longitude: -8.5333, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/praia-da-rocha/", city: "Portimão"),
            CCTVCamera(id: "PT-ALG-002", name: "Praia do Amado", latitude: 37.1667, longitude: -8.9000, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/praia-do-amado/", city: "Aljezur"),
            CCTVCamera(id: "PT-ALG-003", name: "Arrifana", latitude: 37.2900, longitude: -8.8650, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/arrifana/", city: "Aljezur"),
            // Lisbon area
            CCTVCamera(id: "PT-LIS-001", name: "Costa de Caparica", latitude: 38.6347, longitude: -9.2356, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/costa-da-caparica/", city: "Almada"),
            CCTVCamera(id: "PT-LIS-002", name: "Carcavelos", latitude: 38.6770, longitude: -9.3360, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/carcavelos/", city: "Cascais"),
            // North
            CCTVCamera(id: "PT-NOR-001", name: "Matosinhos", latitude: 41.1840, longitude: -8.6900, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/matosinhos/", city: "Porto"),
            CCTVCamera(id: "PT-NOR-002", name: "Ofir", latitude: 41.5200, longitude: -8.7900, type: .publicSpace, status: .online, feedUrl: "https://beachcam.meo.pt/livecams/ofir/", city: "Esposende"),
            // Lagos / Algarve
            CCTVCamera(id: "PT-ALG-004", name: "Lagos Algarve", latitude: 37.1028, longitude: -8.6730, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/webcam/portugal/algarve/lagos/lagos-portugal.html", city: "Lagos"),
        ])

        // ═══════════════════════ GERMANY ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "BER-001", name: "Brandenburg Gate", latitude: 52.5163, longitude: 13.3777, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/deutschland/hauptstadtregion-berlin-brandenburg/berlin/brandenburg-gate.html", city: "Berlin"),
            CCTVCamera(id: "BER-002", name: "Berlin Panorama", latitude: 52.5200, longitude: 13.4050, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/deutschland/hauptstadtregion-berlin-brandenburg/berlin/panorama.html", city: "Berlin"),
            CCTVCamera(id: "BER-003", name: "Brandenburger Tor EarthTV", latitude: 52.5162, longitude: 13.3778, type: .publicSpace, status: .online, feedUrl: "https://www.earthtv.com/en/webcam/berlin-brandenburger-tor", city: "Berlin"),
            CCTVCamera(id: "BER-004", name: "Olympic Stadium", latitude: 52.5147, longitude: 13.2395, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/deutschland/hauptstadtregion-berlin-brandenburg/berlin/olympic-stadium.html", city: "Berlin"),
            CCTVCamera(id: "BER-005", name: "Tiergarten S-Bahn", latitude: 52.5140, longitude: 13.3365, type: .traffic, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/deutschland/hauptstadtregion-berlin-brandenburg/berlin/berlino-tiergarten-s-bahn.html", city: "Berlin"),
        ])

        // ═══════════════════════ NETHERLANDS ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "AMS-001", name: "Dam Square", latitude: 52.3731, longitude: 4.8932, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/amsterdam-dam-square.html", city: "Amsterdam"),
            CCTVCamera(id: "AMS-002", name: "Amsterdam Canals", latitude: 52.3676, longitude: 4.9041, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/canals.html", city: "Amsterdam"),
            CCTVCamera(id: "AMS-003", name: "Damrak Street", latitude: 52.3750, longitude: 4.8950, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/amsterdam-damrak-street.html", city: "Amsterdam"),
            CCTVCamera(id: "AMS-004", name: "Amsterdam Centraal", latitude: 52.3791, longitude: 4.9003, type: .infrastructure, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/amsterdam-centraal.html", city: "Amsterdam"),
            CCTVCamera(id: "AMS-005", name: "Streets of Amsterdam", latitude: 52.3700, longitude: 4.8900, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/streets.html", city: "Amsterdam"),
            CCTVCamera(id: "AMS-006", name: "City Center", latitude: 52.3702, longitude: 4.8952, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/netherlands/north-holland/amsterdam/city-center.html", city: "Amsterdam"),
        ])

        // ═══════════════════════ CZECH REPUBLIC ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "PRG-001", name: "Old Town Square", latitude: 50.0874, longitude: 14.4213, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/czech-republic/prague/old-town-square.html", city: "Prague"),
            CCTVCamera(id: "PRG-002", name: "Historical Old Town", latitude: 50.0865, longitude: 14.4200, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/czech-republic/prague/historical-old-town.html", city: "Prague"),
        ])

        // ═══════════════════════ GREECE ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "SAN-001", name: "Santorini", latitude: 36.3932, longitude: 25.4615, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/ellada/naigaio/kyklades/santorini.html", city: "Santorini"),
            CCTVCamera(id: "ATH-001", name: "Athens Acropolis", latitude: 37.9715, longitude: 23.7267, type: .publicSpace, status: .recording, feedUrl: "https://www.earthtv.com/en/webcam/athens-acropolis", city: "Athens"),
        ])

        // ═══════════════════════ CROATIA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "DBV-001", name: "Dubrovnik Fortress Revelin", latitude: 42.6419, longitude: 18.1104, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/hrvatska/dubrovacko-neretvanska/dubrovnik/dubrovnik-fortress-revelin.html", city: "Dubrovnik"),
        ])

        // ═══════════════════════ MALTA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "MLT-001", name: "Gżira Malta", latitude: 35.9056, longitude: 14.4967, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/malta/malta/gzira/gzira.html", city: "Gżira"),
        ])

        // ═══════════════════════ ICELAND ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "REK-001", name: "Hallgrímskirkja Church", latitude: 64.1420, longitude: -21.9268, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/iceland/greater-reykjavik/reykjavik/hallgrimskirkja-church.html", city: "Reykjavík"),
        ])

        // ═══════════════════════ SWEDEN ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "STO-001", name: "Stockholm Panorama", latitude: 59.3258, longitude: 18.0710, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/svezia/svealand/stockholm/panorama.html", city: "Stockholm"),
            CCTVCamera(id: "STO-002", name: "Solna Train Station", latitude: 59.3600, longitude: 18.0000, type: .traffic, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/svezia/svealand/stockholm/solna-train-station.html", city: "Stockholm"),
        ])

        // ═══════════════════════ JAPAN ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "TYO-001", name: "Shibuya Scramble Crossing", latitude: 35.6595, longitude: 139.7004, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/japan/kanto/tokyo/tokyo-shibuya-scramble-crossing.html", city: "Tokyo"),
            CCTVCamera(id: "TYO-002", name: "Shibuya Crossing", latitude: 35.6594, longitude: 139.7005, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/japan/tokyo/shibuya-crossing.html", city: "Tokyo"),
            CCTVCamera(id: "OSA-001", name: "Dotonbori Live", latitude: 34.6687, longitude: 135.5013, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/japan/osaka-prefecture/dotonbori-live.html", city: "Osaka"),
            CCTVCamera(id: "OSA-002", name: "Dotonbori Glico Sign", latitude: 34.6688, longitude: 135.5010, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/japan/osaka-prefecture/dotonbori-glico-sign-cam.html", city: "Osaka"),
            CCTVCamera(id: "OSA-003", name: "Osaka Expo 2025", latitude: 34.6500, longitude: 135.4100, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/japan/kansai/osaka/expo-2025.html", city: "Osaka"),
        ])

        // ═══════════════════════ SOUTH KOREA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "SEL-001", name: "Seoul Banpo Bridge", latitude: 37.5665, longitude: 126.9780, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/south-korea/seoul-capital/seoul/seoul.html", city: "Seoul"),
        ])

        // ═══════════════════════ CHINA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "HKG-001", name: "Hong Kong Skyline", latitude: 22.2936, longitude: 114.1685, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/china/hong-kong/hong-kong/china-hong-kong.html", city: "Hong Kong"),
            CCTVCamera(id: "HKG-002", name: "Hong Kong Island", latitude: 22.2800, longitude: 114.1580, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/china/hong-kong/hong-kong/hong-kong-island.html", city: "Hong Kong"),
            CCTVCamera(id: "MAC-001", name: "Macau Ruins of St. Paul's", latitude: 22.1975, longitude: 113.5408, type: .publicSpace, status: .online, feedUrl: "https://www.earthtv.com/en/webcam/macau-sar-ruins-of-st-pauls", city: "Macau"),
        ])

        // ═══════════════════════ UAE ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "DXB-001", name: "Burj Khalifa Lake", latitude: 25.1972, longitude: 55.2744, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/united-arab-emirates/dubai/burj-khalifa-lake-dubai.html", city: "Dubai"),
            CCTVCamera(id: "DXB-002", name: "Dubai Skyline", latitude: 25.2048, longitude: 55.2708, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-arab-emirates/dubai/dubai/dubai.html", city: "Dubai"),
            CCTVCamera(id: "DXB-003", name: "Dubai Marina", latitude: 25.0802, longitude: 55.1396, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-arab-emirates/dubai/dubai/dubai-marina.html", city: "Dubai"),
            CCTVCamera(id: "DXB-004", name: "The Palm Dubai", latitude: 25.1124, longitude: 55.1390, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/united-arab-emirates/dubai/dubai/fairmont-the-palm.html", city: "Dubai"),
        ])

        // ═══════════════════════ SINGAPORE ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "SIN-001", name: "Singapore Marina Bay", latitude: 1.2834, longitude: 103.8607, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/republic-of-singapore/singapore/singapore/singapore-marina.html", city: "Singapore"),
            CCTVCamera(id: "SIN-002", name: "Downtown Singapore", latitude: 1.2800, longitude: 103.8500, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/republic-of-singapore/singapore/singapore/downtown-singapore.html", city: "Singapore"),
            CCTVCamera(id: "SIN-003", name: "Singapore Harbor", latitude: 1.2650, longitude: 103.8200, type: .port, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/republic-of-singapore/singapore/singapore/singapore.html", city: "Singapore"),
        ])

        // ═══════════════════════ THAILAND ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "BKK-001", name: "Bangkok River", latitude: 13.7563, longitude: 100.5018, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/thailand/bangkok.html", city: "Bangkok"),
        ])

        // ═══════════════════════ PHILIPPINES ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "CEB-001", name: "Cebu Mactan Island Beach", latitude: 10.3157, longitude: 123.8854, type: .publicSpace, status: .online, feedUrl: "https://www.earthtv.com/en/webcam/cebu-mactan-island-beach", city: "Cebu"),
        ])

        // ═══════════════════════ TURKEY ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "IST-001", name: "Anadolu Hisar", latitude: 41.0850, longitude: 29.0670, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/turkey/istanbul/anadolu-hisar-cam.html", city: "Istanbul"),
        ])

        // ═══════════════════════ ISRAEL ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "JER-001", name: "Western Wall", latitude: 31.7767, longitude: 35.2345, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/israel/jerusalem-district/jerusalem/western-wall.html", city: "Jerusalem"),
            CCTVCamera(id: "JER-002", name: "Temple Mount", latitude: 31.7781, longitude: 35.2354, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/israel/jerusalem-district/jerusalem/temple-mount.html", city: "Jerusalem"),
            CCTVCamera(id: "JER-003", name: "Panorama of Jerusalem", latitude: 31.7750, longitude: 35.2340, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/israel/jerusalem-district/jerusalem/panorama.html", city: "Jerusalem"),
            CCTVCamera(id: "JER-004", name: "Mount of Olives", latitude: 31.7795, longitude: 35.2440, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/israel/jerusalem-district/jerusalem/mount-of-olives.html", city: "Jerusalem"),
        ])

        // ═══════════════════════ BRAZIL ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "RIO-001", name: "Copacabana Beach", latitude: -22.9711, longitude: -43.1826, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/brasil/rio-de-janeiro/rio-de-janeiro/copacabana-beach.html", city: "Rio de Janeiro"),
            CCTVCamera(id: "RIO-002", name: "Copacabana", latitude: -22.9700, longitude: -43.1830, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/brasil/rio-de-janeiro/rio-de-janeiro/copacabana.html", city: "Rio de Janeiro"),
            CCTVCamera(id: "RIO-003", name: "Rio Panorama", latitude: -22.9519, longitude: -43.2105, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/brasil/rio-de-janeiro/rio-de-janeiro/panorama.html", city: "Rio de Janeiro"),
            CCTVCamera(id: "RIO-004", name: "Copacabana EarthTV", latitude: -22.9720, longitude: -43.1800, type: .publicSpace, status: .online, feedUrl: "https://www.earthtv.com/en/webcam/rio-de-janeiro-copacabana", city: "Rio de Janeiro"),
        ])

        // ═══════════════════════ EGYPT ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "CAI-001", name: "Great Pyramid of Giza", latitude: 29.9792, longitude: 31.1342, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/egypt/cairo/cairo/great-pyramid-of-giza.html", city: "Cairo"),
            CCTVCamera(id: "CAI-002", name: "Pyramids and Sphinx", latitude: 29.9753, longitude: 31.1376, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/egypt/cairo/cairo/pyramids-giza-sphinx.html", city: "Cairo"),
            CCTVCamera(id: "CAI-003", name: "Pyramid of Cheops & Khafre", latitude: 29.9773, longitude: 31.1325, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/egypt/cairo/cairo/pyramid-of-cheops-and-khafre.html", city: "Cairo"),
        ])

        // ═══════════════════════ SOUTH AFRICA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "CPT-001", name: "Table Mountain", latitude: -33.9575, longitude: 18.4034, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/south-africa/western-cape/cape-town/table-mountain.html", city: "Cape Town"),
            CCTVCamera(id: "CPT-002", name: "Clifton Beach", latitude: -33.9440, longitude: 18.3770, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/south-africa/western-cape/cape-town/cape-town-clifton-beach.html", city: "Cape Town"),
            CCTVCamera(id: "CPT-003", name: "Cape Town Panorama", latitude: -33.9580, longitude: 18.4030, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/south-africa/western-cape/cape-town/cape-town.html", city: "Cape Town"),
            CCTVCamera(id: "CPT-004", name: "Kalk Bay", latitude: -34.1290, longitude: 18.4500, type: .port, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/south-africa/western-cape/cape-town/kalk-bay.html", city: "Cape Town"),
        ])

        // ═══════════════════════ AUSTRALIA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "SYD-001", name: "Sydney", latitude: -33.8568, longitude: 151.2153, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/australia/new-south-wales/sydney/sydney.html", city: "Sydney"),
        ])

        // ═══════════════════════ CANADA ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "TOR-001", name: "Niagara Falls", latitude: 43.0896, longitude: -79.0849, type: .publicSpace, status: .recording, feedUrl: "https://www.skylinewebcams.com/en/webcam/canada/ontario/niagara-falls/niagara-falls.html", city: "Niagara Falls"),
            CCTVCamera(id: "TOR-002", name: "Niagara Falls Ontario", latitude: 43.0830, longitude: -79.0780, type: .publicSpace, status: .online, feedUrl: "https://www.skylinewebcams.com/en/webcam/canada/ontario/niagara-falls/niagara.html", city: "Niagara Falls"),
        ])

        // ═══════════════════════ MEXICO ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "MEX-001", name: "Zócalo Mexico City", latitude: 19.4326, longitude: -99.1332, type: .publicSpace, status: .recording, feedUrl: "https://www.webcamtaxi.com/en/mexico/mexico-city/zocalo.html", city: "Mexico City"),
        ])

        // ═══════════════════════ CARIBBEAN ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "CUR-001", name: "Mambo Beach Curaçao", latitude: 12.0847, longitude: -68.8823, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/curacao/willemstad/mambo-beach-cam.html", city: "Willemstad"),
            CCTVCamera(id: "BON-001", name: "Bonaire Coral Reef", latitude: 12.1696, longitude: -68.2385, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/netherlands/bonaire/harbourvillage-coralreef.html", city: "Bonaire"),
            CCTVCamera(id: "ROA-001", name: "West Bay Beach Roatán", latitude: 16.2915, longitude: -86.5922, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/honduras/roatan/west-bay-beach-lasrocasresort.html", city: "Roatán"),
            CCTVCamera(id: "ROA-002", name: "West End Roatán", latitude: 16.2972, longitude: -86.5959, type: .publicSpace, status: .online, feedUrl: "https://www.webcamtaxi.com/en/honduras/roatan/west-end-beach-house.html", city: "Roatán"),
            CCTVCamera(id: "ROA-003", name: "Roatán EarthCam", latitude: 16.2960, longitude: -86.5945, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/world/honduras/roatanbayislands/", city: "Roatán"),
            CCTVCamera(id: "STT-001", name: "St. Thomas USVI", latitude: 18.3358, longitude: -64.9307, type: .publicSpace, status: .online, feedUrl: "https://www.earthcam.com/usa/virginislands/stthomas/", city: "St. Thomas"),
        ])

        // ═══════════════════════ USA (Texas) ═══════════════════════

        c.append(contentsOf: [
            CCTVCamera(id: "TX-001", name: "Corpus Christi Coastline", latitude: 27.8006, longitude: -97.3964, type: .publicSpace, status: .online, feedUrl: "https://www.earthtv.com/en/webcam/corpus-christi-coastline", city: "Corpus Christi"),
        ])

        return c
    }()
}
