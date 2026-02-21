//
//  InsecamService.swift
//  Terra5
//
//  Service for fetching live CCTV camera data from insecam.org
//  Scrapes public camera directory for worldwide camera locations
//

import Foundation

actor InsecamService {
    static let shared = InsecamService()

    private let baseURL = "http://www.insecam.org/en/bycountry"
    private var lastFetch: Date?
    private var cachedCameras: [CCTVCamera] = []

    // Rate limiting: insecam data changes slowly, minimum 60 seconds between fetches
    private let minInterval: TimeInterval = 60

    // Countries to fetch cameras from (ISO 2-letter codes)
    private let countryCodes = [
        "US", "GB", "JP", "DE", "FR", "IT",
        "NL", "KR", "RU", "BR", "IN", "SE",
        "NO", "ES", "CZ", "TR", "AR", "MX",
        "TW", "CH"
    ]

    // Max pages to fetch per country (each page has ~6 cameras)
    private let maxPagesPerCountry = 2

    private init() {}

    /// Fetch cameras from insecam.org across multiple countries
    func fetchCameras() async throws -> [CCTVCamera] {
        // Check rate limiting - return cache if too soon
        if let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < minInterval,
           !cachedCameras.isEmpty {
            NSLog("[TERRA5] InsecamService: returning %d cached cameras (%.0fs since last fetch)",
                  cachedCameras.count, Date().timeIntervalSince(lastFetch))
            return cachedCameras
        }

        NSLog("[TERRA5] InsecamService: fetching cameras from %d countries...", countryCodes.count)

        var allCameras: [CCTVCamera] = []

        // Fetch countries sequentially to be respectful to insecam.org
        for countryCode in countryCodes {
            do {
                let cameras = try await fetchCountryCameras(countryCode: countryCode)
                allCameras.append(contentsOf: cameras)
                NSLog("[TERRA5] InsecamService: %@ → %d cameras", countryCode, cameras.count)
            } catch {
                NSLog("[TERRA5] InsecamService: %@ failed: %@", countryCode, error.localizedDescription)
                // Continue with other countries if one fails
                continue
            }

            // Small delay between country requests to avoid hammering
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        }

        guard !allCameras.isEmpty else {
            throw InsecamError.noDataFound
        }

        lastFetch = Date()
        cachedCameras = allCameras
        NSLog("[TERRA5] InsecamService: total cameras fetched: %d", allCameras.count)
        return allCameras
    }

    /// Fetch cameras for a specific country
    private func fetchCountryCameras(countryCode: String) async throws -> [CCTVCamera] {
        var cameras: [CCTVCamera] = []

        for page in 1...maxPagesPerCountry {
            let urlString = "\(baseURL)/\(countryCode)/?page=\(page)"

            guard let url = URL(string: urlString) else {
                throw InsecamError.invalidURL
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            request.setValue(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                forHTTPHeaderField: "User-Agent"
            )
            request.setValue("text/html", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw InsecamError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                break
            case 403:
                throw InsecamError.forbidden
            case 404:
                // No more pages for this country
                break
            case 429:
                throw InsecamError.rateLimited
            default:
                throw InsecamError.httpError(httpResponse.statusCode)
            }

            guard let html = String(data: data, encoding: .utf8) else {
                throw InsecamError.parsingError
            }

            let pageCameras = parseCameraPage(html: html, countryCode: countryCode)
            cameras.append(contentsOf: pageCameras)

            // If page returned no cameras, stop paginating
            if pageCameras.isEmpty {
                break
            }

            // Small delay between pages
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        }

        return cameras
    }

    /// Parse insecam.org HTML page to extract camera data
    /// The page structure contains image thumbnails with links to individual camera views
    /// and metadata including coordinates, city, and snapshot URLs
    private func parseCameraPage(html: String, countryCode: String) -> [CCTVCamera] {
        var cameras: [CCTVCamera] = []

        // Extract camera image blocks - insecam uses img tags with camera snapshot URLs
        // Pattern: find image tags that contain camera snapshot URLs (typically from IP cameras)
        // The page contains thumbnail images linking to /en/view/{id}/ pages

        // Strategy 1: Extract camera IDs and snapshot URLs from thumbnail image links
        // Links pattern: <a href="/en/view/{id}/">
        let linkPattern = try? NSRegularExpression(
            pattern: #"<a\s+href="/en/view/(\d+)/?"[^>]*>"#,
            options: [.caseInsensitive]
        )

        // Image pattern: <img src="http://..." class="thumbnail-item__img">
        // or other img patterns containing camera snapshot URLs
        let imgPattern = try? NSRegularExpression(
            pattern: #"<img[^>]+src="(https?://[^"]+)"[^>]*class="[^"]*thumbnail[^"]*""#,
            options: [.caseInsensitive]
        )

        // Also try the reversed attribute order
        let imgPattern2 = try? NSRegularExpression(
            pattern: #"<img[^>]*class="[^"]*thumbnail[^"]*"[^>]+src="(https?://[^"]+)""#,
            options: [.caseInsensitive]
        )

        // Extract coordinates from the page - often in script tags or data attributes
        // Pattern: coordinates like "latitude":45.123,"longitude":-73.456
        let coordPattern = try? NSRegularExpression(
            pattern: #"(?:latitude|lat)['":\s]+(-?\d+\.?\d*)[^-\d]*(?:longitude|lng|lon)['":\s]+(-?\d+\.?\d*)"#,
            options: [.caseInsensitive]
        )

        // Extract camera IDs from links
        var cameraIds: [String] = []
        if let linkPattern = linkPattern {
            let range = NSRange(html.startIndex..., in: html)
            let matches = linkPattern.matches(in: html, range: range)
            for match in matches {
                if let idRange = Range(match.range(at: 1), in: html) {
                    let id = String(html[idRange])
                    if !cameraIds.contains(id) {
                        cameraIds.append(id)
                    }
                }
            }
        }

        // Extract snapshot image URLs
        var snapshotURLs: [String] = []
        for pattern in [imgPattern, imgPattern2].compactMap({ $0 }) {
            let range = NSRange(html.startIndex..., in: html)
            let matches = pattern.matches(in: html, range: range)
            for match in matches {
                if let urlRange = Range(match.range(at: 1), in: html) {
                    snapshotURLs.append(String(html[urlRange]))
                }
            }
        }

        // Also look for image URLs in a broader pattern (insecam may use various layouts)
        if snapshotURLs.isEmpty {
            let broadImgPattern = try? NSRegularExpression(
                pattern: #"<img[^>]+src="(https?://\d+\.\d+\.\d+\.\d+[^"]*)"[^>]*>"#,
                options: [.caseInsensitive]
            )
            if let broadImgPattern = broadImgPattern {
                let range = NSRange(html.startIndex..., in: html)
                let matches = broadImgPattern.matches(in: html, range: range)
                for match in matches {
                    if let urlRange = Range(match.range(at: 1), in: html) {
                        snapshotURLs.append(String(html[urlRange]))
                    }
                }
            }
        }

        // Extract coordinates if available
        var coordinates: [(Double, Double)] = []
        if let coordPattern = coordPattern {
            let range = NSRange(html.startIndex..., in: html)
            let matches = coordPattern.matches(in: html, range: range)
            for match in matches {
                if let latRange = Range(match.range(at: 1), in: html),
                   let lonRange = Range(match.range(at: 2), in: html),
                   let lat = Double(html[latRange]),
                   let lon = Double(html[lonRange]) {
                    coordinates.append((lat, lon))
                }
            }
        }

        // Extract city names - look for location text near camera entries
        let cityPattern = try? NSRegularExpression(
            pattern: #"<span[^>]*class="[^"]*city[^"]*"[^>]*>([^<]+)</span>"#,
            options: [.caseInsensitive]
        )
        var cities: [String] = []
        if let cityPattern = cityPattern {
            let range = NSRange(html.startIndex..., in: html)
            let matches = cityPattern.matches(in: html, range: range)
            for match in matches {
                if let cityRange = Range(match.range(at: 1), in: html) {
                    cities.append(String(html[cityRange]).trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        // Build camera objects from extracted data
        let countryName = countryNameForCode(countryCode)
        for (index, cameraId) in cameraIds.enumerated() {
            let snapshotURL = index < snapshotURLs.count ? snapshotURLs[index] : nil
            let coord = index < coordinates.count ? coordinates[index] : nil
            let city = index < cities.count ? cities[index] : countryName

            // Use coordinates if available, otherwise use country center as fallback
            // with some random offset to spread cameras visually
            let (lat, lon): (Double, Double)
            if let coord = coord, coord.0 != 0, coord.1 != 0 {
                lat = coord.0
                lon = coord.1
            } else {
                let center = countryCenterCoordinate(countryCode)
                lat = center.0 + Double.random(in: -3.0...3.0)
                lon = center.1 + Double.random(in: -3.0...3.0)
            }

            let camera = CCTVCamera(
                id: "INSECAM-\(cameraId)",
                name: "\(city) Camera \(cameraId)",
                latitude: lat,
                longitude: lon,
                type: .publicSpace,  // Default type for insecam cameras
                status: .online,     // Listed cameras are presumably online
                feedUrl: snapshotURL,
                city: city
            )
            cameras.append(camera)
        }

        return cameras
    }

    // MARK: - Helpers

    /// Map country code to human-readable name
    private func countryNameForCode(_ code: String) -> String {
        let names: [String: String] = [
            "US": "United States", "GB": "United Kingdom", "JP": "Japan",
            "DE": "Germany", "FR": "France", "IT": "Italy",
            "NL": "Netherlands", "KR": "South Korea", "RU": "Russia",
            "BR": "Brazil", "IN": "India", "SE": "Sweden",
            "NO": "Norway", "ES": "Spain", "CZ": "Czech Republic",
            "TR": "Turkey", "AR": "Argentina", "MX": "Mexico",
            "TW": "Taiwan", "CH": "Switzerland"
        ]
        return names[code] ?? code
    }

    /// Approximate center coordinates for each country (fallback when no coords available)
    private func countryCenterCoordinate(_ code: String) -> (Double, Double) {
        let centers: [String: (Double, Double)] = [
            "US": (39.8283, -98.5795),
            "GB": (55.3781, -3.4360),
            "JP": (36.2048, 138.2529),
            "DE": (51.1657, 10.4515),
            "FR": (46.6034, 1.8883),
            "IT": (41.8719, 12.5674),
            "NL": (52.1326, 5.2913),
            "KR": (35.9078, 127.7669),
            "RU": (61.5240, 105.3188),
            "BR": (-14.2350, -51.9253),
            "IN": (20.5937, 78.9629),
            "SE": (60.1282, 18.6435),
            "NO": (60.4720, 8.4689),
            "ES": (40.4637, -3.7492),
            "CZ": (49.8175, 15.4730),
            "TR": (38.9637, 35.2433),
            "AR": (-38.4161, -63.6167),
            "MX": (23.6345, -102.5528),
            "TW": (23.6978, 120.9605),
            "CH": (46.8182, 8.2275)
        ]
        return centers[code] ?? (0.0, 0.0)
    }

    /// Map insecam category string to CameraType
    private func mapCategoryToCameraType(_ category: String) -> CCTVCamera.CameraType {
        let lower = category.lowercased()
        switch lower {
        case "traffic", "road", "street":
            return .traffic
        case "bridge", "architecture", "construction":
            return .infrastructure
        case "port", "beach":
            return .port
        case "airport":
            return .airport
        default:
            // city, village, square, nature, mountain, river, etc.
            return .publicSpace
        }
    }
}

// MARK: - Errors

enum InsecamError: LocalizedError {
    case invalidURL
    case invalidResponse
    case forbidden
    case httpError(Int)
    case rateLimited
    case parsingError
    case noDataFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid insecam URL"
        case .invalidResponse:
            return "Invalid response from insecam.org"
        case .forbidden:
            return "Access denied by insecam.org (403)"
        case .httpError(let code):
            return "HTTP error from insecam.org: \(code)"
        case .rateLimited:
            return "Rate limited by insecam.org"
        case .parsingError:
            return "Failed to parse camera data from HTML"
        case .noDataFound:
            return "No cameras found on insecam.org"
        }
    }
}
