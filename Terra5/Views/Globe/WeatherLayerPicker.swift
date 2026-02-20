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

#Preview {
    ZStack {
        Color(hex: "#0a0a0a")
        WeatherLayerPicker()
            .environmentObject(AppState())
    }
    .frame(width: 300, height: 100)
}
