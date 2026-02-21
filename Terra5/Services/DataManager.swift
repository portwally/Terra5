//
//  DataManager.swift
//  Terra5
//
//  Coordinates data fetching with auto-refresh timers
//

import Foundation
import Combine

@MainActor
class DataManager {
    private weak var appState: AppState?

    private var flightTimer: Timer?
    private var satelliteTimer: Timer?
    private var earthquakeTimer: Timer?
    private var weatherTimer: Timer?
    private var cctvTimer: Timer?

    // Refresh intervals
    private let flightInterval: TimeInterval = 15 // seconds
    private let satelliteInterval: TimeInterval = 60 // seconds
    private let earthquakeInterval: TimeInterval = 300 // 5 minutes
    private let weatherInterval: TimeInterval = 300 // 5 minutes
    private let cctvInterval: TimeInterval = 600 // 10 minutes (insecam data changes slowly)

    init(appState: AppState) {
        self.appState = appState
    }

    func startRefreshing() {
        // Initial fetch
        Task {
            await fetchAllData()
        }

        // Set up timers
        flightTimer = Timer.scheduledTimer(withTimeInterval: flightInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchFlights()
            }
        }

        satelliteTimer = Timer.scheduledTimer(withTimeInterval: satelliteInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchSatellites()
            }
        }

        earthquakeTimer = Timer.scheduledTimer(withTimeInterval: earthquakeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchEarthquakes()
            }
        }

        weatherTimer = Timer.scheduledTimer(withTimeInterval: weatherInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchWeather()
            }
        }

        cctvTimer = Timer.scheduledTimer(withTimeInterval: cctvInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchCCTV()
            }
        }
    }

    func stopRefreshing() {
        flightTimer?.invalidate()
        satelliteTimer?.invalidate()
        earthquakeTimer?.invalidate()
        weatherTimer?.invalidate()
        cctvTimer?.invalidate()
        flightTimer = nil
        satelliteTimer = nil
        earthquakeTimer = nil
        weatherTimer = nil
        cctvTimer = nil
    }

    private func fetchAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchFlights() }
            group.addTask { await self.fetchSatellites() }
            group.addTask { await self.fetchEarthquakes() }
            group.addTask { await self.fetchWeather() }
            group.addTask { await self.fetchCCTV() }
        }
    }

    private func fetchFlights() async {
        guard let appState = appState,
              appState.isLayerActive(.flights) else { return }

        appState.isLoadingFlights = true
        appState.flightsError = nil

        do {
            let flights = try await OpenSkyService.shared.fetchFlights()
            appState.flights = flights
            appState.flightsLastUpdate = Date()
            print("Fetched \(flights.count) flights")
        } catch {
            appState.flightsError = error.localizedDescription
            print("Flight fetch error: \(error)")
        }

        appState.isLoadingFlights = false
    }

    private func fetchSatellites() async {
        guard let appState = appState,
              appState.isLayerActive(.satellites) else { return }

        appState.isLoadingSatellites = true
        appState.satellitesError = nil

        do {
            // Fetch a subset of satellites (stations + brightest)
            let satellites = try await CelesTrakService.shared.fetchSatellites(
                groups: [.stations, .visualSats]
            )
            appState.satellites = satellites
            appState.satellitesLastUpdate = Date()
            print("Fetched \(satellites.count) satellites")
        } catch {
            appState.satellitesError = error.localizedDescription
            print("Satellite fetch error: \(error)")
        }

        appState.isLoadingSatellites = false
    }

    private func fetchEarthquakes() async {
        guard let appState = appState,
              appState.isLayerActive(.earthquakes) else { return }

        appState.isLoadingEarthquakes = true
        appState.earthquakesError = nil

        do {
            let earthquakes = try await USGSService.shared.fetchEarthquakes(feed: .dayAll)
            appState.earthquakes = earthquakes
            appState.earthquakesLastUpdate = Date()
            print("Fetched \(earthquakes.count) earthquakes")
        } catch {
            appState.earthquakesError = error.localizedDescription
            print("Earthquake fetch error: \(error)")
        }

        appState.isLoadingEarthquakes = false
    }

    private func fetchWeather(force: Bool = false) async {
        guard let appState = appState else {
            NSLog("[TERRA5] fetchWeather: appState is nil!")
            return
        }
        guard force || appState.isLayerActive(.weather) else {
            NSLog("[TERRA5] fetchWeather: layer not active and not forced, skipping")
            return
        }

        NSLog("[TERRA5] fetchWeather: starting fetch (force=%d)...", force ? 1 : 0)
        appState.isLoadingWeather = true
        appState.weatherError = nil

        do {
            // Fetch radar timestamps for tile overlays
            let (radarFrames, satelliteFrames) = try await WeatherRadarService.shared.fetchTimestamps()
            NSLog("[TERRA5] fetchWeather: got %d radar frames, %d satellite frames", radarFrames.count, satelliteFrames.count)

            appState.weatherLastUpdate = Date()
            // Mark weather as ready (tile overlays will be shown in MapKitGlobeView)
            appState.isWeatherDataReady = true
        } catch {
            appState.weatherError = error.localizedDescription
            NSLog("[TERRA5] fetchWeather ERROR: %@", error.localizedDescription)
        }

        appState.isLoadingWeather = false
    }

    private func fetchCCTV(force: Bool = false) async {
        guard let appState = appState else {
            NSLog("[TERRA5] fetchCCTV: appState is nil!")
            return
        }
        guard force || appState.isLayerActive(.cctv) else {
            NSLog("[TERRA5] fetchCCTV: layer not active and not forced, skipping")
            return
        }

        NSLog("[TERRA5] fetchCCTV: starting fetch (force=%d)...", force ? 1 : 0)
        appState.isLoadingCCTV = true
        appState.cctvError = nil

        // Start with worldwide built-in camera database
        var cameras = CCTVCamera.sampleCameras

        // Try to supplement with live cameras from insecam.org
        do {
            let insecamCameras = try await InsecamService.shared.fetchCameras()
            if !insecamCameras.isEmpty {
                cameras.append(contentsOf: insecamCameras)
                NSLog("[TERRA5] fetchCCTV: added %d cameras from insecam.org", insecamCameras.count)
            }
        } catch {
            // insecam.org uses bot protection — built-in database still provides 200+ cameras
            NSLog("[TERRA5] fetchCCTV: insecam.org unavailable (%@), using built-in database only", error.localizedDescription)
        }

        appState.cctvCameras = cameras
        appState.cctvLastUpdate = Date()
        NSLog("[TERRA5] fetchCCTV: total %d cameras loaded", cameras.count)

        appState.isLoadingCCTV = false
    }

    // Manual refresh methods (force=true bypasses layer active check)
    func refreshFlights() async {
        await fetchFlights()
    }

    func refreshSatellites() async {
        await fetchSatellites()
    }

    func refreshEarthquakes() async {
        await fetchEarthquakes()
    }

    func refreshWeather() async {
        NSLog("[TERRA5] DataManager.refreshWeather called")
        await fetchWeather(force: true)
        NSLog("[TERRA5] DataManager.refreshWeather completed, radars: %d", appState?.weatherRadars.count ?? -1)
    }

    func refreshCCTV() async {
        NSLog("[TERRA5] DataManager.refreshCCTV called")
        await fetchCCTV(force: true)
        NSLog("[TERRA5] DataManager.refreshCCTV completed, cameras: %d", appState?.cctvCameras.count ?? -1)
    }

    func refreshAll() async {
        await fetchAllData()
    }
}
