//
//  Terra5App.swift
//  Terra5
//
//  WORLDVIEW Geospatial Intelligence Platform
//

import SwiftUI

@main
struct Terra5App: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1024, minHeight: 768)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            // Remove default new item
            CommandGroup(replacing: .newItem) { }

            // View menu
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Toggle PANOPTIC") {
                    NotificationCenter.default.post(name: .togglePanoptic, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Text("Visual Modes")
                    .font(.caption)

                ForEach(Array(VisualMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    Button(mode.displayName) {
                        NotificationCenter.default.post(
                            name: .setVisualMode,
                            object: mode
                        )
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command, .shift])
                }
            }

            // Data Layers menu
            CommandMenu("Data") {
                Button("Toggle Flights") {
                    NotificationCenter.default.post(name: .toggleLayer, object: DataLayerType.flights)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Toggle Satellites") {
                    NotificationCenter.default.post(name: .toggleLayer, object: DataLayerType.satellites)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Toggle Earthquakes") {
                    NotificationCenter.default.post(name: .toggleLayer, object: DataLayerType.earthquakes)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Toggle Weather Radar") {
                    NotificationCenter.default.post(name: .toggleLayer, object: DataLayerType.weather)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Toggle CCTV") {
                    NotificationCenter.default.post(name: .toggleLayer, object: DataLayerType.cctv)
                }
                .keyboardShortcut("5", modifiers: .command)

                Divider()

                Button("Refresh All Data") {
                    NotificationCenter.default.post(name: .refreshAllData, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Locations menu
            CommandMenu("Locations") {
                ForEach(Array(CityPreset.presets.prefix(8).enumerated()), id: \.element.id) { index, city in
                    Button(city.name) {
                        NotificationCenter.default.post(
                            name: .flyToCity,
                            object: city
                        )
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command, .option])
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let togglePanoptic = Notification.Name("togglePanoptic")
    static let setVisualMode = Notification.Name("setVisualMode")
    static let flyToCity = Notification.Name("flyToCity")
    static let toggleLayer = Notification.Name("toggleLayer")
    static let refreshAllData = Notification.Name("refreshAllData")
}
