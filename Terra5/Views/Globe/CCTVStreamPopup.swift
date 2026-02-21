//
//  CCTVStreamPopup.swift
//  Terra5
//
//  Floating popup window for viewing CCTV camera info and live streams
//  Styled to match Terra5 dark theme aesthetic
//

import SwiftUI
import WebKit

struct CCTVStreamPopup: View {
    @EnvironmentObject var appState: AppState
    let camera: CCTVCamera

    @State private var position: CGPoint = CGPoint(x: 400, y: 350)
    @State private var isMinimized = false
    @State private var webViewFailed = false
    @State private var isLoading = true

    private let popupWidth: CGFloat = 560
    private let popupHeight: CGFloat = 500

    /// Whether this camera has a live feed URL
    private var hasLiveFeed: Bool {
        if let feedUrl = camera.feedUrl, !feedUrl.isEmpty { return true }
        return false
    }

    /// Get the effective feed URL
    private var effectiveFeedUrl: String? {
        if let feedUrl = camera.feedUrl, !feedUrl.isEmpty {
            return feedUrl
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Draggable title bar
            titleBar

            if !isMinimized {
                // Stream / info content
                streamContent

                // Info footer
                infoFooter
            }
        }
        .frame(width: popupWidth, height: isMinimized ? 36 : popupHeight)
        .background(Color(hex: "#1a1a2e"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#00d4aa").opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.8), radius: 20, x: 0, y: 10)
        .position(position)
        .onAppear {
            position = CGPoint(x: 400, y: 350)
            NSLog("[TERRA5-CCTV] Popup opened for camera: %@ (%@)", camera.id, camera.name)
            NSLog("[TERRA5-CCTV]   City: %@, Type: %@, Status: %@", camera.city, camera.type.rawValue, camera.status.rawValue)
            NSLog("[TERRA5-CCTV]   feedUrl: %@", camera.feedUrl ?? "nil")
            NSLog("[TERRA5-CCTV]   hasLiveFeed: %@, effectiveFeedUrl: %@", hasLiveFeed ? "true" : "false", effectiveFeedUrl ?? "nil")
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Title Bar (draggable)

    private var titleBar: some View {
        HStack(spacing: 8) {
            // Recording indicator
            Circle()
                .fill(hasLiveFeed ? Color.red : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill((hasLiveFeed ? Color.red : Color.gray).opacity(0.5))
                        .frame(width: 14, height: 14)
                        .opacity(0.6)
                )

            Image(systemName: "video.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#00d4aa"))

            Text(camera.name.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00d4aa"))
                .lineLimit(1)

            Spacer()

            Text(camera.statusIndicator)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: camera.status.color))

            // Minimize button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMinimized.toggle()
                }
            } label: {
                Image(systemName: isMinimized ? "chevron.down" : "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#00d4aa").opacity(0.7))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Close button
            Button {
                appState.selectedCCTVCamera = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#ff4444"))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#0d0d1a"))
        .gesture(
            DragGesture()
                .onChanged { value in
                    position = CGPoint(
                        x: position.x + value.translation.width,
                        y: position.y + value.translation.height
                    )
                }
        )
    }

    // MARK: - Stream Content

    private var streamContent: some View {
        ZStack {
            Color.black

            if hasLiveFeed {
                // Camera has a feed URL — try WKWebView with fallback
                if let feedUrl = effectiveFeedUrl {
                    if webViewFailed {
                        // WKWebView failed — show fallback with "Open in Safari" button
                        feedFailedView(feedUrl: feedUrl)
                    } else {
                        // Try WKWebView with ad blocking
                        CameraWebViewWrapper(
                            urlString: feedUrl,
                            isLoading: $isLoading,
                            didFail: $webViewFailed
                        )
                    }
                }

                // "Open in Safari" button overlay — always visible at bottom-right
                if let feedUrl = effectiveFeedUrl {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            openInBrowserButton(feedUrl: feedUrl)
                        }
                    }
                    .padding(8)
                }
            } else {
                // No feed URL — show camera info card with search option
                cameraInfoView
            }

            // Corner brackets overlay (only for non-webview content)
            if !hasLiveFeed {
                cornerBrackets
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 410)
        .clipped()
    }

    // MARK: - Open in Browser Button

    private func openInBrowserButton(feedUrl: String) -> some View {
        Button {
            if let url = URL(string: feedUrl) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "safari")
                    .font(.system(size: 11, weight: .bold))
                Text("OPEN IN SAFARI")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "#00d4aa").opacity(0.8))
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Feed Failed View (WKWebView couldn't load)

    private func feedFailedView(feedUrl: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.3))

            Text("EMBEDDED STREAM UNAVAILABLE")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#ffaa00"))

            Text("This webcam blocks embedded viewing.\nOpen in Safari to watch the live stream.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: feedUrl) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "safari")
                        .font(.system(size: 14, weight: .bold))
                    Text("WATCH LIVE IN SAFARI")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color(hex: "#1a1a2e"))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(hex: "#00d4aa"))
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Camera info summary
            VStack(alignment: .leading, spacing: 4) {
                infoRow(label: "CITY", value: camera.city, icon: "building.2")
                infoRow(label: "TYPE", value: camera.type.displayName, icon: camera.type.icon)
                infoRow(label: "COORDS", value: String(format: "%.4f, %.4f", camera.latitude, camera.longitude), icon: "location")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Canvas { context, size in
                let gridSize: CGFloat = 20
                let color = Color(hex: "#00d4aa").opacity(0.03)
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
            }
        )
    }

    // MARK: - Camera Info View (for cameras without stream URL)

    private var cameraInfoView: some View {
        VStack(spacing: 16) {
            // Camera icon
            Image(systemName: "video.slash.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.3))

            Text(camera.name)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00d4aa"))

            Text("NO LIVE FEED AVAILABLE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#ffaa00").opacity(0.7))

            // Camera details grid
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "TYPE", value: camera.type.displayName, icon: camera.type.icon)
                infoRow(label: "STATUS", value: camera.statusIndicator, icon: "antenna.radiowaves.left.and.right")
                infoRow(label: "CITY", value: camera.city, icon: "building.2")
                infoRow(label: "COORDS", value: String(format: "%.4f, %.4f", camera.latitude, camera.longitude), icon: "location")
                infoRow(label: "ID", value: camera.id, icon: "number")
            }
            .padding(.horizontal, 40)

            // Search for webcam button
            Button {
                let searchQuery = "\(camera.name) \(camera.city) live webcam".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://www.google.com/search?q=\(searchQuery)") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .bold))
                    Text("SEARCH FOR LIVE WEBCAM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color(hex: "#00d4aa"))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(hex: "#00d4aa").opacity(0.15))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#00d4aa").opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Timestamp
            Text("MARKER ONLY • \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Canvas { context, size in
                let gridSize: CGFloat = 20
                let color = Color(hex: "#00d4aa").opacity(0.05)
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
            }
        )
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.5))
                .frame(width: 14)

            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))
                .frame(width: 55, alignment: .leading)

            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.8))
                .lineLimit(1)
        }
    }

    // MARK: - Corner Brackets

    private var cornerBrackets: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 20
            let color = Color(hex: "#00d4aa").opacity(0.4)

            Path { path in
                // Top-left
                path.move(to: CGPoint(x: 4, y: len + 4))
                path.addLine(to: CGPoint(x: 4, y: 4))
                path.addLine(to: CGPoint(x: len + 4, y: 4))
                // Top-right
                path.move(to: CGPoint(x: w - len - 4, y: 4))
                path.addLine(to: CGPoint(x: w - 4, y: 4))
                path.addLine(to: CGPoint(x: w - 4, y: len + 4))
                // Bottom-left
                path.move(to: CGPoint(x: 4, y: h - len - 4))
                path.addLine(to: CGPoint(x: 4, y: h - 4))
                path.addLine(to: CGPoint(x: len + 4, y: h - 4))
                // Bottom-right
                path.move(to: CGPoint(x: w - len - 4, y: h - 4))
                path.addLine(to: CGPoint(x: w - 4, y: h - 4))
                path.addLine(to: CGPoint(x: w - 4, y: h - len - 4))
            }
            .stroke(color, lineWidth: 1)
        }
    }

    // MARK: - Info Footer

    private var infoFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: camera.type.icon)
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.6))

            Text(camera.type.displayName.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#00d4aa").opacity(0.6))

            if hasLiveFeed {
                Text("● STREAM AVAILABLE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#00ff88"))
            }

            Spacer()

            Text(camera.city.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.4))

            Text(String(format: "%.4f, %.4f", camera.latitude, camera.longitude))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#0d0d1a"))
    }
}

// MARK: - Camera WebView Wrapper with Ad Blocking

struct CameraWebViewWrapper: NSViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var didFail: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // Allow inline media playback without user action
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()

        // ── 1. Aggressive CSS injection to hide ads, headers, footers, banners ──
        let cleanupCSS = CameraWebViewWrapper.cleanupCSS(for: urlString)
        let cssScript = WKUserScript(
            source: cleanupCSS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(cssScript)

        // ── 2. JS to auto-dismiss cookie banners and click play buttons ──
        let autoClickJS = WKUserScript(
            source: CameraWebViewWrapper.autoClickJS(),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(autoClickJS)

        // ── 3. Periodic ad cleanup (some ads load dynamically) ──
        let periodicCleanup = WKUserScript(
            source: CameraWebViewWrapper.periodicCleanupJS(),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(periodicCleanup)

        config.userContentController = contentController

        // ── 4. Network-level ad blocking via WKContentRuleList ──
        let adBlockRules = CameraWebViewWrapper.adBlockRulesJSON()
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "terra5-adblock",
            encodedContentRuleList: adBlockRules
        ) { ruleList, error in
            if let ruleList = ruleList {
                config.userContentController.add(ruleList)
                NSLog("[TERRA5-CCTV] Ad-block rules compiled successfully")
            } else if let error = error {
                NSLog("[TERRA5-CCTV] Ad-block rules compilation failed: %@", error.localizedDescription)
            }
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator

        NSLog("[TERRA5-CCTV] WebView loading URL: %@", urlString)

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            NSLog("[TERRA5-CCTV] ERROR: Invalid URL string: %@", urlString)
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    // MARK: - Ad Block Rules (WebKit Content Rules — blocks network requests to ad domains)

    static func adBlockRulesJSON() -> String {
        // Block common ad/tracking domains at the network level
        let rules: [[String: Any]] = [
            // Google Ads
            ["trigger": ["url-filter": ".*googlesyndication\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*googleadservices\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*doubleclick\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*google-analytics\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*googletagmanager\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*pagead2\\.googlesyndication\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*adservice\\.google\\.com.*"], "action": ["type": "block"]],
            // Amazon Ads
            ["trigger": ["url-filter": ".*amazon-adsystem\\.com.*"], "action": ["type": "block"]],
            // Common ad networks
            ["trigger": ["url-filter": ".*adnxs\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*adsrvr\\.org.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*rubiconproject\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*pubmatic\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*openx\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*casalemedia\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*criteo\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*taboola\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*outbrain\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*moatads\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*quantserve\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*scorecardresearch\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*bluekai\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*exelator\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*demdex\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*krxd\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*mediavine\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*ezoic\\.net.*"], "action": ["type": "block"]],
            // Tracking
            ["trigger": ["url-filter": ".*facebook\\.net.*fbevents.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*hotjar\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*mouseflow\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*clarity\\.ms.*"], "action": ["type": "block"]],
            // Pop-ups & overlays
            ["trigger": ["url-filter": ".*popads\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*popcash\\.net.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*propellerads\\.com.*"], "action": ["type": "block"]],
            // Cookie consent services (we auto-dismiss these via JS instead)
            ["trigger": ["url-filter": ".*cookiebot\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*onetrust\\.com.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*cookielaw\\.org.*"], "action": ["type": "block"]],
            ["trigger": ["url-filter": ".*consensu\\.org.*"], "action": ["type": "block"]],
        ]

        if let data = try? JSONSerialization.data(withJSONObject: rules),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "[]"
    }

    // MARK: - Provider-specific CSS cleanup

    static func cleanupCSS(for urlString: String) -> String {
        // Base CSS that hides common ad/UI elements across all sites
        let baseCSS = """
            header, footer, nav, .navbar, .header, .footer, .nav,
            .cookie-banner, .cookie-consent, .gdpr, #cookie,
            .social-share, .share-buttons, .social-buttons,
            .sidebar, #sidebar, .aside,
            [class*="banner"], [id*="banner"],
            [class*="cookie"], [id*="cookie"],
            [class*="consent"], [id*="consent"],
            [class*="advert"], [id*="advert"],
            [class*="sponsor"], [id*="sponsor"],
            .popup, .modal-overlay, .overlay,
            ins.adsbygoogle, .ad-container, .ad-wrapper, .ad-slot,
            [class*="ad-"], [id*="ad-"],
            iframe[src*="doubleclick"], iframe[src*="googlesyndication"],
            iframe[src*="amazon-adsystem"],
            .notification-bar, .announcement-bar,
            [class*="promo"], [id*="promo"] {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                max-height: 0 !important;
                overflow: hidden !important;
            }
            body { background: #000 !important; }
        """

        // Provider-specific overrides
        var providerCSS = ""

        if urlString.contains("skylinewebcams.com") {
            providerCSS = """
                /* SkylineWebcams: hide everything except the video player */
                .topbar, .sky-header, .sky-footer, #sky-header, #sky-footer,
                .sky-nav, .sky-menu, .sky-sidebar, .sky-social,
                .sky-related, .sky-info-box, .sky-cam-info,
                .sky-premium, .sky-premium-banner,
                .sky-ads, .sky-ad, [class*="sky-ad"],
                #sky-ads, [id*="sky-ad"],
                .adv-container, .adv-box, [class*="adv-"],
                .cam-description, .cam-details, .cam-info,
                .share-container, .share-box,
                .related-cams, .similar-cams,
                .footer-links, .footer-info,
                .breadcrumb, .breadcrumbs,
                .premium-overlay, .premium-button,
                .app-download, .app-banner,
                .newsletter, .subscribe,
                .sky-logo-container,
                div[style*="z-index: 9999"],
                div[style*="z-index: 999"],
                .sky-toolbar, .cam-toolbar {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                }
                /* Make the player fill the view */
                .player-container, .cam-player, #player-container,
                .video-container, #video-container {
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                    z-index: 10000 !important;
                    margin: 0 !important;
                    padding: 0 !important;
                }
                video, .video-js {
                    width: 100% !important;
                    height: 100% !important;
                    object-fit: contain !important;
                }
            """
        } else if urlString.contains("webcamtaxi.com") {
            providerCSS = """
                /* WebcamTaxi: hide everything except video */
                .wct-header, .wct-footer, .wct-sidebar,
                .wct-nav, .wct-menu,
                .wct-ads, [class*="wct-ad"],
                .cam-desc, .cam-sidebar, .cam-info-box,
                .related-webcams, .other-webcams,
                .social-sharing, .share-buttons,
                .breadcrumb, .breadcrumbs,
                .site-header, .site-footer, .site-nav,
                .page-header, .page-footer,
                .main-nav, .main-menu, .sub-nav,
                .top-bar, .top-banner,
                .bottom-bar, .bottom-banner,
                aside, .widget, .widget-area,
                .comments, .comment-section,
                #disqus_thread,
                .wct-logo, .logo-container,
                .mobile-menu, .hamburger {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                }
                .player-container, .video-wrapper, .cam-player,
                .responsive-video, .embed-responsive {
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                    z-index: 10000 !important;
                }
                iframe {
                    width: 100% !important;
                    height: 100% !important;
                }
            """
        } else if urlString.contains("earthcam.com") {
            providerCSS = """
                /* EarthCam: aggressive cleanup */
                .ec-header, .ec-footer, .ec-nav,
                .ec-sidebar, .ec-ads, .ec-ad,
                [class*="ec-ad"], [id*="ec-ad"],
                .ec-premium, .ec-paywall,
                .ec-social, .ec-share,
                .ec-related, .ec-featured,
                .ec-menu, .ec-toolbar,
                .ec-logo, .ec-branding,
                .halloffame, .hall-of-fame,
                .ec-banner, .ec-promo,
                .archive-controls, .timelapse-controls,
                .camera-controls:not(.player-controls),
                .gallery-strip, .gallery-thumbs,
                div[style*="z-index: 9999"],
                .ec-upgrade, .upgrade-prompt {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                }
                .video-player, .ec-player, #ec-player,
                .player-container, #player-container {
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                    z-index: 10000 !important;
                }
            """
        } else if urlString.contains("earthtv.com") {
            providerCSS = """
                /* EarthTV: cleanup */
                .etv-header, .etv-footer, .etv-nav,
                .etv-sidebar, .etv-ads,
                .share-buttons, .social-links,
                .related-webcams, .other-cams,
                .breadcrumb, .breadcrumbs,
                nav, header, footer, aside,
                .site-header, .site-footer {
                    display: none !important;
                    height: 0 !important;
                }
                .player-wrapper, .video-container, .etv-player {
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                    z-index: 10000 !important;
                }
            """
        } else if urlString.contains("beachcam.meo.pt") {
            providerCSS = """
                /* MEO BeachCam: cleanup */
                .meo-header, .meo-footer, .meo-nav,
                .bc-header, .bc-footer, .bc-nav,
                .bc-sidebar, .bc-ads,
                .beach-info, .beach-details,
                .weather-widget, .surf-report,
                .social-sharing,
                nav, header, footer, aside,
                .premium-banner, .premium-overlay,
                .app-download, .app-banner,
                .bc-logo, .meo-logo,
                .breadcrumb, .breadcrumbs {
                    display: none !important;
                    height: 0 !important;
                }
                .player-container, .video-container, .bc-player {
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                    z-index: 10000 !important;
                }
            """
        }

        return """
        (function() {
            var style = document.createElement('style');
            style.setAttribute('id', 'terra5-cleanup');
            style.textContent = `\(baseCSS)\n\(providerCSS)`;
            document.head.appendChild(style);
        })();
        """
    }

    // MARK: - Auto-click cookie/play buttons

    static func autoClickJS() -> String {
        return """
        (function() {
            function clickAcceptButtons() {
                var selectors = [
                    'button[class*="accept"]', 'button[class*="agree"]',
                    'button[id*="accept"]', 'a[class*="accept"]',
                    '.accept-all', '.accept-cookies', '#accept-cookies',
                    '.cc-accept', '.cc-allow', '.cc-dismiss',
                    '[data-action="accept"]', '[aria-label*="accept"]',
                    '[aria-label*="Accept"]', '[aria-label*="agree"]',
                    'button[class*="Allow"]', 'button[class*="allow"]',
                    '.cky-btn-accept', '#cky-btn-accept',
                    '.onetrust-accept-btn-handler',
                    '#onetrust-accept-btn-handler',
                    '.fc-cta-consent', '.fc-primary-button',
                    'button[title*="Accept"]', 'button[title*="accept"]',
                    '.iubenda-cs-accept-btn',
                    'button[class*="consent"]',
                    '.qc-cmp2-summary-buttons button:first-child'
                ];
                for (var sel of selectors) {
                    try {
                        var btns = document.querySelectorAll(sel);
                        for (var btn of btns) {
                            if (btn.offsetParent !== null || btn.offsetWidth > 0) {
                                btn.click();
                                return true;
                            }
                        }
                    } catch(e) {}
                }
                return false;
            }

            function clickPlayButtons() {
                var selectors = [
                    '.play-button', '.play-btn', '[class*="play-btn"]',
                    'button[aria-label*="play"]', 'button[aria-label*="Play"]',
                    '.vjs-big-play-button', '.ytp-large-play-button',
                    '.jw-icon-display', '.mejs__overlay-play',
                    '[class*="play-overlay"]', '[class*="playOverlay"]'
                ];
                for (var sel of selectors) {
                    try {
                        var btns = document.querySelectorAll(sel);
                        for (var btn of btns) {
                            if (btn.offsetParent !== null || btn.offsetWidth > 0) {
                                btn.click();
                                return;
                            }
                        }
                    } catch(e) {}
                }
            }

            // Try accepting cookies immediately and after delays
            clickAcceptButtons();
            setTimeout(clickAcceptButtons, 1000);
            setTimeout(clickAcceptButtons, 2500);
            setTimeout(clickAcceptButtons, 5000);

            // Try clicking play buttons after page settles
            setTimeout(clickPlayButtons, 2000);
            setTimeout(clickPlayButtons, 4000);
        })();
        """
    }

    // MARK: - Periodic cleanup (catches dynamically loaded ads)

    static func periodicCleanupJS() -> String {
        return """
        (function() {
            function removeAds() {
                // Remove common ad iframes
                var iframes = document.querySelectorAll('iframe');
                for (var iframe of iframes) {
                    var src = (iframe.src || '').toLowerCase();
                    if (src.indexOf('doubleclick') !== -1 ||
                        src.indexOf('googlesyndication') !== -1 ||
                        src.indexOf('amazon-adsystem') !== -1 ||
                        src.indexOf('adnxs') !== -1 ||
                        src.indexOf('taboola') !== -1 ||
                        src.indexOf('outbrain') !== -1) {
                        iframe.remove();
                    }
                }

                // Remove Google ad containers
                var googleAds = document.querySelectorAll('ins.adsbygoogle, .adsbygoogle');
                for (var ad of googleAds) { ad.remove(); }

                // Remove elements with ad-related IDs/classes
                var adElements = document.querySelectorAll(
                    '[id*="google_ads"], [id*="ad-container"], [id*="ad_container"], ' +
                    '[class*="ad-container"], [class*="ad_container"], ' +
                    '[id*="advertisement"], [class*="advertisement"], ' +
                    'div[data-ad], div[data-ads], div[data-adunit]'
                );
                for (var el of adElements) { el.remove(); }

                // Remove high z-index overlays (popups, interstitials)
                var allDivs = document.querySelectorAll('div');
                for (var div of allDivs) {
                    var style = window.getComputedStyle(div);
                    var zIndex = parseInt(style.zIndex) || 0;
                    if (zIndex > 9000 && style.position === 'fixed') {
                        // Check if it's a video player (don't remove those)
                        if (!div.querySelector('video') &&
                            !div.classList.toString().match(/player|video/i)) {
                            div.remove();
                        }
                    }
                }
            }

            // Run immediately and every 3 seconds for 30 seconds
            removeAds();
            var count = 0;
            var timer = setInterval(function() {
                removeAds();
                count++;
                if (count >= 10) clearInterval(timer);
            }, 3000);
        })();
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CameraWebViewWrapper

        init(_ parent: CameraWebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSLog("[TERRA5-CCTV] WebView didFinish: %@", webView.url?.absoluteString ?? "unknown")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("[TERRA5-CCTV] WebView didFail: %@ — Error: %@", webView.url?.absoluteString ?? "unknown", error.localizedDescription)
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.didFail = true
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            NSLog("[TERRA5-CCTV] WebView didFailProvisionalNavigation — Error: %@", error.localizedDescription)
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.didFail = true
            }
        }

        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            NSLog("[TERRA5-CCTV] WebView redirect to: %@", webView.url?.absoluteString ?? "unknown")
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            NSLog("[TERRA5-CCTV] WebView didStart loading: %@", webView.url?.absoluteString ?? "unknown")
        }

        // Block navigation to ad URLs, allow everything else
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let urlStr = navigationAction.request.url?.absoluteString.lowercased() ?? ""

            // Block known ad/tracking redirects
            let blockedDomains = [
                "doubleclick.net", "googlesyndication.com", "googleadservices.com",
                "adnxs.com", "amazon-adsystem.com", "taboola.com", "outbrain.com",
                "criteo.com", "pubmatic.com", "rubiconproject.com", "popads.net",
                "popcash.net", "propellerads.com"
            ]

            for domain in blockedDomains {
                if urlStr.contains(domain) {
                    NSLog("[TERRA5-CCTV] BLOCKED ad navigation to: %@", urlStr)
                    decisionHandler(.cancel)
                    return
                }
            }

            // Block popup navigations (type = other with target frame == nil)
            if navigationAction.navigationType == .other && navigationAction.targetFrame == nil {
                NSLog("[TERRA5-CCTV] BLOCKED popup navigation to: %@", urlStr)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
