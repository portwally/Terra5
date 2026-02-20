//
//  WeatherLayerPicker.swift
//  Terra5
//
//  Floating picker to switch between weather layer types (rain, clouds, temperature)
//

import SwiftUI

struct WeatherLayerPicker: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 2) {
            ForEach(WeatherLayerType.allCases) { layer in
                WeatherLayerButton(
                    layer: layer,
                    isSelected: appState.selectedWeatherLayer == layer
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        NSLog("[TERRA5] WeatherLayerPicker: Switching to %@", layer.rawValue)
                        appState.selectedWeatherLayer = layer
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#00d4aa").opacity(0.5), lineWidth: 1)
                )
        )
    }
}

struct WeatherLayerButton: View {
    let layer: WeatherLayerType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: layer.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(layer.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color(hex: "#00d4aa") : Color.clear)
            )
            .foregroundColor(isSelected ? .black : Color(hex: "#00d4aa"))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map Mode Toggle (2D/3D)
struct MapModeToggle: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 2) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.is2DMapMode = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 10, weight: .medium))
                    Text("3D Globe")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(!appState.is2DMapMode ? Color(hex: "#00d4aa") : Color.clear)
                )
                .foregroundColor(!appState.is2DMapMode ? .black : Color(hex: "#00d4aa"))
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.is2DMapMode = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 10, weight: .medium))
                    Text("2D Map")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(appState.is2DMapMode ? Color(hex: "#00d4aa") : Color.clear)
                )
                .foregroundColor(appState.is2DMapMode ? .black : Color(hex: "#00d4aa"))
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#00d4aa").opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "#0a0a0a")
        VStack(spacing: 8) {
            MapModeToggle()
            WeatherLayerPicker()
        }
        .environmentObject(AppState())
    }
    .frame(width: 300, height: 150)
}
