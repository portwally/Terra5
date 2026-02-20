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
    private let cctvInterval: TimeInterval = 60 // 1 minute

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

    private func fetchWeather() async {
        guard let appState = appState,
              appState.isLayerActive(.weather) else { return }

        appState.isLoadingWeather = true
        appState.weatherError = nil

        do {
            // Fetch radar stations
            let radars = try await NOAAService.shared.fetchRadarStations()
            appState.weatherRadars = radars

            // Fetch weather alerts
            let alerts = try await NOAAService.shared.fetchWeatherAlerts()
            appState.weatherAlerts = alerts

            appState.weatherLastUpdate = Date()
            print("Fetched \(radars.count) radar stations, \(alerts.count) weather alerts")
        } catch {
            appState.weatherError = error.localizedDescription
            print("Weather fetch error: \(error)")
        }

        appState.isLoadingWeather = false
    }

    private func fetchCCTV() async {
        guard let appState = appState,
              appState.isLayerActive(.cctv) else { return }

        appState.isLoadingCCTV = true
        appState.cctvError = nil

        // Load sample CCTV cameras (static data for demo)
        appState.cctvCameras = CCTVCamera.sampleCameras
        appState.cctvLastUpdate = Date()
        print("Loaded \(appState.cctvCameras.count) CCTV cameras")

        appState.isLoadingCCTV = false
    }

    // Manual refresh methods
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
        await fetchWeather()
    }

    func refreshCCTV() async {
        await fetchCCTV()
    }

    func refreshAll() async {
        await fetchAllData()
    }
}
