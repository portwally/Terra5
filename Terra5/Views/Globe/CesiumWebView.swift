//
//  CesiumWebView.swift
//  Terra5
//
//  WKWebView wrapper for Cesium.js globe
//

import SwiftUI
import WebKit

struct CesiumWebView: NSViewRepresentable {
    @EnvironmentObject var appState: AppState

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Enable JavaScript via modern API
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // Add message handlers for Swift-JS communication
        // Use a weak proxy to avoid retain cycle: WKUserContentController -> Coordinator
        let contentController = config.userContentController
        let proxy = WeakScriptMessageHandler(delegate: context.coordinator)
        contentController.add(proxy, name: "globeReady")
        contentController.add(proxy, name: "cameraChanged")
        contentController.add(proxy, name: "entityClicked")
        contentController.add(proxy, name: "dataUpdated")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        // Store reference in coordinator
        context.coordinator.webView = webView

        // Load Cesium HTML from bundle
        loadCesiumHTML(webView: webView)

        return webView
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: CesiumCoordinator) {
        // Remove message handlers to break any remaining references
        let contentController = webView.configuration.userContentController
        contentController.removeScriptMessageHandler(forName: "globeReady")
        contentController.removeScriptMessageHandler(forName: "cameraChanged")
        contentController.removeScriptMessageHandler(forName: "entityClicked")
        contentController.removeScriptMessageHandler(forName: "dataUpdated")
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // React to state changes and send commands to JavaScript
        context.coordinator.syncState(with: appState)
    }

    func makeCoordinator() -> CesiumCoordinator {
        CesiumCoordinator(appState: appState)
    }

    private func loadCesiumHTML(webView: WKWebView) {
        // Load HTML string with HTTPS base URL to enable network requests
        print("Loading Cesium via loadHTMLString")
        let inlineHTML = createInlineHTML()
        // Use HTTPS base URL to allow network requests
        webView.loadHTMLString(inlineHTML, baseURL: URL(string: "https://cesium.com"))
    }

    private func createInlineHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Terra5 Globe</title>
            <script src="https://cesium.com/downloads/cesiumjs/releases/1.114/Build/Cesium/Cesium.js"></script>
            <link href="https://cesium.com/downloads/cesiumjs/releases/1.114/Build/Cesium/Widgets/widgets.css" rel="stylesheet">
            <style>
                * { margin: 0; padding: 0; }
                html, body, #cesiumContainer {
                    width: 100%; height: 100%;
                    background: #0a0a0a;
                    overflow: hidden;
                }
                .cesium-viewer-toolbar,
                .cesium-viewer-animationContainer,
                .cesium-viewer-timelineContainer,
                .cesium-viewer-bottom,
                .cesium-viewer-fullscreenContainer,
                .cesium-credit-logoContainer { display: none !important; }
            </style>
        </head>
        <body>
            <div id="cesiumContainer"></div>
            <script>
                const Terra5 = {
                    viewer: null,
                    dataSources: {},
                    init() {
                        this.viewer = new Cesium.Viewer('cesiumContainer', {
                            imageryProvider: new Cesium.OpenStreetMapImageryProvider({
                                url: 'https://tile.openstreetmap.org/'
                            }),
                            baseLayerPicker: false,
                            geocoder: false,
                            homeButton: false,
                            sceneModePicker: false,
                            navigationHelpButton: false,
                            animation: false,
                            timeline: false,
                            fullscreenButton: false,
                            vrButton: false,
                            selectionIndicator: false,
                            infoBox: false,
                            shouldAnimate: true,
                            skyBox: false
                        });
                        this.viewer.scene.backgroundColor = Cesium.Color.fromCssColorString('#0a0a0a');
                        this.viewer.scene.globe.baseColor = Cesium.Color.fromCssColorString('#0a0a0a');

                        this.dataSources.flights = new Cesium.CustomDataSource('flights');
                        this.dataSources.satellites = new Cesium.CustomDataSource('satellites');
                        this.dataSources.earthquakes = new Cesium.CustomDataSource('earthquakes');
                        Object.values(this.dataSources).forEach(ds => this.viewer.dataSources.add(ds));

                        this.viewer.camera.changed.addEventListener(() => this.notifyCameraChange());
                        this.viewer.camera.setView({
                            destination: Cesium.Cartesian3.fromDegrees(-77.0369, 38.9072, 10000000)
                        });
                        this.sendToSwift('globeReady', { ready: true });
                    },
                    flyTo(lat, lon, alt, duration = 2.0) {
                        this.viewer.camera.flyTo({
                            destination: Cesium.Cartesian3.fromDegrees(lon, lat, alt),
                            duration: duration
                        });
                    },
                    notifyCameraChange() {
                        const c = this.viewer.camera.positionCartographic;
                        this.sendToSwift('cameraChanged', {
                            latitude: Cesium.Math.toDegrees(c.latitude),
                            longitude: Cesium.Math.toDegrees(c.longitude),
                            altitude: c.height,
                            heading: Cesium.Math.toDegrees(this.viewer.camera.heading)
                        });
                    },
                    setVisualMode(mode) { /* Visual modes here */ },
                    updateFlights(flights) {
                        const ds = this.dataSources.flights;
                        ds.entities.removeAll();
                        flights.forEach(f => {
                            if (!f.longitude || !f.latitude) return;
                            ds.entities.add({
                                position: Cesium.Cartesian3.fromDegrees(f.longitude, f.latitude, (f.altitude||0)+100),
                                point: { pixelSize: 6, color: Cesium.Color.fromCssColorString('#00d4aa') },
                                label: {
                                    text: f.callsign || f.icao24,
                                    font: '10px Menlo',
                                    fillColor: Cesium.Color.fromCssColorString('#00d4aa'),
                                    pixelOffset: new Cesium.Cartesian2(0, -12),
                                    distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 500000)
                                }
                            });
                        });
                        this.sendToSwift('dataUpdated', { layer: 'flights', count: flights.length });
                    },
                    updateSatellites(sats) {
                        const ds = this.dataSources.satellites;
                        ds.entities.removeAll();
                        sats.forEach(s => {
                            if (!s.longitude || !s.latitude) return;
                            ds.entities.add({
                                position: Cesium.Cartesian3.fromDegrees(s.longitude, s.latitude, (s.altitude||400)*1000),
                                point: { pixelSize: 5, color: Cesium.Color.fromCssColorString('#00ffaa') },
                                label: {
                                    text: s.name,
                                    font: '9px Menlo',
                                    fillColor: Cesium.Color.fromCssColorString('#00ffaa'),
                                    pixelOffset: new Cesium.Cartesian2(8, 0),
                                    distanceDisplayCondition: new Cesium.DistanceDisplayCondition(0, 5000000)
                                }
                            });
                        });
                        this.sendToSwift('dataUpdated', { layer: 'satellites', count: sats.length });
                    },
                    setLayerVisibility(layer, visible) {
                        if (this.dataSources[layer]) this.dataSources[layer].show = visible;
                    },
                    sendToSwift(handler, data) {
                        if (window.webkit?.messageHandlers?.[handler]) {
                            window.webkit.messageHandlers[handler].postMessage(data);
                        }
                    }
                };
                document.addEventListener('DOMContentLoaded', () => Terra5.init());
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - Weak Script Message Handler
/// Prevents retain cycle: WKUserContentController strongly retains its message handlers,
/// so we use a weak proxy that forwards to the actual coordinator.
class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
