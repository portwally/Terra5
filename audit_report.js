const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
        ShadingType, PageNumber, LevelFormat } = require("docx");

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const cellMargins = { top: 80, bottom: 80, left: 120, right: 120 };

function heading(text, level) {
  return new Paragraph({ heading: level, children: [new TextRun(text)] });
}

function para(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120 },
    ...opts,
    children: Array.isArray(text) ? text : [new TextRun(text)]
  });
}

function bold(text) { return new TextRun({ text, bold: true }); }
function code(text) { return new TextRun({ text, font: "Menlo", size: 18, color: "C7254E" }); }

function issueRow(severity, file, description) {
  const sevColor = severity === "BUG" ? "D32F2F" : severity === "WARN" ? "F57C00" : "1976D2";
  return new TableRow({
    children: [
      new TableCell({
        borders, width: { size: 900, type: WidthType.DXA }, margins: cellMargins,
        shading: { fill: sevColor, type: ShadingType.CLEAR },
        children: [new Paragraph({ children: [new TextRun({ text: severity, bold: true, color: "FFFFFF", font: "Arial", size: 18 })] })]
      }),
      new TableCell({
        borders, width: { size: 2200, type: WidthType.DXA }, margins: cellMargins,
        children: [new Paragraph({ children: [new TextRun({ text: file, font: "Menlo", size: 16 })] })]
      }),
      new TableCell({
        borders, width: { size: 6260, type: WidthType.DXA }, margins: cellMargins,
        children: [new Paragraph({ children: [new TextRun({ text: description, size: 20 })] })]
      }),
    ]
  });
}

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: "1A237E" },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: "283593" },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: "37474F" },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({ children: [new Paragraph({
        children: [
          new TextRun({ text: "Terra5 Project Audit", font: "Arial", size: 16, color: "999999" }),
          new TextRun({ text: "\tFebruary 20, 2026", font: "Arial", size: 16, color: "999999" }),
        ],
        tabStops: [{ type: "right", position: 9360 }],
        border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: "CCCCCC", space: 4 } }
      })] })
    },
    footers: {
      default: new Footer({ children: [new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: "Page ", size: 16, color: "999999" }), new TextRun({ children: [PageNumber.CURRENT], size: 16, color: "999999" })]
      })] })
    },
    children: [
      // Title
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 80 },
        children: [new TextRun({ text: "TERRA5 PROJECT AUDIT", bold: true, size: 40, font: "Arial", color: "1A237E" })]
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 400 },
        children: [new TextRun({ text: "Full Code Review \u2014 Bugs, Quality, Security & Best Practices", size: 24, color: "666666" })]
      }),

      // Executive Summary
      heading("Executive Summary", HeadingLevel.HEADING_1),
      para("Terra5 is a well-structured macOS geospatial intelligence visualization app built with SwiftUI and MapKit. The codebase is generally clean with good separation of concerns. However, the audit identified 7 bugs, 10 warnings, and 8 informational findings across the project."),
      para("The most critical issues involve potential data races in the DataManager timer callbacks, a force-unwrap crash risk in WeatherTileOverlay, and an unused OpenSkyResponse model that will cause JSON decoding failures if used."),

      // Issues Table
      heading("Issues Summary", HeadingLevel.HEADING_1),

      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [900, 2200, 6260],
        rows: [
          new TableRow({
            children: [
              new TableCell({ borders, width: { size: 900, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "37474F", type: ShadingType.CLEAR },
                children: [new Paragraph({ children: [new TextRun({ text: "Level", bold: true, color: "FFFFFF", size: 18 })] })] }),
              new TableCell({ borders, width: { size: 2200, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "37474F", type: ShadingType.CLEAR },
                children: [new Paragraph({ children: [new TextRun({ text: "File", bold: true, color: "FFFFFF", size: 18 })] })] }),
              new TableCell({ borders, width: { size: 6260, type: WidthType.DXA }, margins: cellMargins, shading: { fill: "37474F", type: ShadingType.CLEAR },
                children: [new Paragraph({ children: [new TextRun({ text: "Description", bold: true, color: "FFFFFF", size: 18 })] })] }),
            ]
          }),

          // BUGS
          issueRow("BUG", "WeatherOverlay.swift", "Force-unwrap crash: URL(string: urlString)! on line 313 will crash if the URL string is malformed. Use guard let or a fallback URL."),
          issueRow("BUG", "Flight.swift", "OpenSkyResponse struct is broken. OpenSkyState is an empty struct with no properties, so Codable decoding of [[OpenSkyState]] would fail. The actual parsing uses JSONSerialization instead, making this struct dead code that will mislead anyone who tries to use it."),
          issueRow("BUG", "DataManager.swift", "Potential data race: Timer callbacks capture [weak self] but then dispatch to @MainActor via Task. Between the timer fire and the MainActor hop, the DataManager could be deallocated, and the weak self guard only protects the outer closure, not the inner async call."),
          issueRow("BUG", "AppState.swift", "saveSettings() is called from didSet on activeLayers, visualMode, isSidebarExpanded, and currentCity. During loadSettings(), setting these properties triggers saveSettings() which overwrites UserDefaults with partially-loaded state. This can corrupt saved preferences on launch."),
          issueRow("BUG", "AppState.swift", "CityPreset uses UUID() for id, generated fresh each time. The firstIndex(where:) comparison in saveSettings will never match across app launches because IDs are regenerated. City persistence is silently broken."),
          issueRow("BUG", "CesiumWebView.swift", "WKWebView message handlers (userContentController.add) create strong references to the coordinator. Since the coordinator holds a weak reference to webView but the webView\u2019s config retains the coordinator, this creates a retain cycle that leaks memory."),
          issueRow("BUG", "MainView.swift", "AITargetingBrackets uses CGFloat.random() inside a ForEach body. SwiftUI re-evaluates the body on every state change, causing detection boxes to jump to random positions on every render. This should use seeded/stable random positions."),

          // WARNINGS
          issueRow("WARN", "DataManager.swift", "fetchAllData() uses withTaskGroup and calls self.fetchFlights() etc. inside child tasks. Since DataManager is @MainActor, these child tasks also run on the main actor, negating the concurrency benefit of TaskGroup."),
          issueRow("WARN", "Satellite.swift", "updatePosition() is a simplified position estimator that ignores Earth\u2019s rotation (sidereal time / GMST). The longitude calculation will be significantly wrong because it doesn\u2019t account for the Earth rotating under the orbit. The comment says \u201Cnot accurate\u201D but the error is large enough to place satellites on the wrong continent."),
          issueRow("WARN", "NOAAService.swift", "fetchWeatherAlerts() silently returns an empty array on parsing errors (line 106). Errors are logged but the caller has no way to distinguish \u201Cno alerts\u201D from \u201Cfailed to parse.\u201D Consider propagating the error or using a Result type."),
          issueRow("WARN", "AppConstants.swift", "Color(hex:) default case returns (a=1, r=1, g=1, b=0) which produces a nearly-transparent dark color. This is likely a mistake \u2014 the default should probably be a visible fallback color like black or clear."),
          issueRow("WARN", "CesiumWebView.swift", "preferences.javaScriptEnabled is deprecated in recent WebKit versions. Use WKWebpagePreferences.allowsContentJavaScript instead."),
          issueRow("WARN", "CesiumWebView.swift", "preferences.setValue(true, forKey: \u201CallowFileAccessFromFileURLs\u201D) uses a private API key. This may cause App Store rejection and could be a security risk."),
          issueRow("WARN", "WeatherOverlay.swift", "WeatherTileManager.shared initializes timestamps with current Unix time, which is not a valid RainViewer timestamp. Tiles requested before fetchTimestamps() completes will use invalid timestamps and return 404s."),
          issueRow("WARN", "MapKitGlobeView.swift", "Annotation views use lockFocus/unlockFocus for image drawing, which is deprecated in macOS 10.14+. Use NSImage(size:flipped:drawingHandler:) or draw into a CGContext instead."),
          issueRow("WARN", "WeatherOverlay.swift", "WeatherTileManager.shared is not thread-safe. It\u2019s a plain class accessed from multiple contexts (main thread and async tasks). updateTimestamps() and createOverlay() could race."),
          issueRow("WARN", "DataManager.swift", "The weather data source label in AppConstants says \u201CNOAA NEXRAD\u201D but the actual implementation uses RainViewer and NASA GIBS. This mismatch is confusing to users."),

          // INFO
          issueRow("INFO", "ContentView.swift", "ContentView.swift is a legacy wrapper that just forwards to MainView. Terra5App.swift already uses MainView directly. This file is dead code and can be removed."),
          issueRow("INFO", "index.html", "The bundled Cesium HTML file (Resources/Web/cesium/index.html) appears unused. CesiumWebView generates inline HTML instead of loading this file. Consider removing it to reduce bundle size."),
          issueRow("INFO", "PANOPTICService.swift", "Mixes service logic with SwiftUI views in the same file. DetectionOverlayView, DetectionBox, CornerBracketsSmall, and ScanningLine should be in their own View file."),
          issueRow("INFO", "AppState.swift", "The traffic layer (DataLayerType.traffic) has a toggle in the UI but no implementation. fetchLayerData just logs \u201Cnot implemented.\u201D Either implement it or remove it from the enum to avoid user confusion."),
          issueRow("INFO", "NOAAService.swift", "The User-Agent header uses a placeholder email (contact@example.com). NOAA\u2019s API terms require a valid contact. This should be updated before production use."),
          issueRow("INFO", "CelesTrakService.swift", "fetchSatellites(groups:) fetches groups sequentially. Since each request is independent, using withTaskGroup for concurrent fetches would significantly reduce total load time."),
          issueRow("INFO", "Multiple files", "Excessive debug logging with print() and NSLog() throughout the codebase. Consider using a unified logging framework (os.Logger) with configurable log levels for production."),
          issueRow("INFO", "AppConstants.swift", "CityPreset conforms to Hashable, but since id is a UUID generated at init time, two CityPresets with identical data will never be equal. Consider using a stable identifier (like the city name) instead."),
        ]
      }),

      // Detailed sections
      heading("Detailed Findings", HeadingLevel.HEADING_1),

      heading("1. Critical Bugs", HeadingLevel.HEADING_2),

      heading("Force-Unwrap Crash in WeatherTileOverlay", HeadingLevel.HEADING_3),
      para([new TextRun("In "), code("WeatherOverlay.swift"), new TextRun(" line 313, "), code("URL(string: urlString)!"), new TextRun(" will crash the app if the URL string contains invalid characters. This is especially risky because the URL incorporates dynamic values (timestamps, tile coordinates) that could theoretically produce malformed strings.")]),
      para([bold("Fix: "), new TextRun("Replace with "), code("guard let url = URL(string: urlString) else { return URL(string: \"about:blank\")! }"), new TextRun(" or a transparent placeholder tile URL.")]),

      heading("Broken OpenSkyResponse Model", HeadingLevel.HEADING_3),
      para([new TextRun("The "), code("OpenSkyResponse"), new TextRun(" struct in "), code("Flight.swift"), new TextRun(" declares "), code("states: [[OpenSkyState]]?"), new TextRun(" where "), code("OpenSkyState"), new TextRun(" is an empty struct. This model is unusable for Codable decoding. The actual parsing in "), code("OpenSkyService.swift"), new TextRun(" correctly uses "), code("JSONSerialization"), new TextRun(", but the dead model will confuse future developers.")]),
      para([bold("Fix: "), new TextRun("Either remove the struct or implement it properly with the actual OpenSky state vector fields.")]),

      heading("Settings Corruption on Launch", HeadingLevel.HEADING_3),
      para([new TextRun("In "), code("AppState.swift"), new TextRun(", the "), code("loadSettings()"), new TextRun(" method sets published properties (visualMode, activeLayers, etc.) whose "), code("didSet"), new TextRun(" observers call "), code("saveSettings()"), new TextRun(". This means mid-load, partially-initialized state gets written back to UserDefaults, potentially overwriting valid saved data.")]),
      para([bold("Fix: "), new TextRun("Add a "), code("private var isLoading = true"), new TextRun(" flag and guard saveSettings() with "), code("guard !isLoading else { return }"), new TextRun(". Set "), code("isLoading = false"), new TextRun(" at the end of loadSettings().")]),

      heading("CityPreset ID Instability", HeadingLevel.HEADING_3),
      para([new TextRun("CityPreset uses "), code("let id = UUID()"), new TextRun(" which generates a new UUID every time the struct is created. Since presets are recreated on every launch, the "), code("firstIndex(where: { $0.id == currentCity.id })"), new TextRun(" comparison in saveSettings() will never find a match from a previous session. The saved city index defaults to 0.")]),
      para([bold("Fix: "), new TextRun("Use a stable identifier, such as the city name string, as the id property.")]),

      heading("2. Security & Privacy Concerns", HeadingLevel.HEADING_2),
      para([new TextRun("The use of "), code("allowFileAccessFromFileURLs"), new TextRun(" in CesiumWebView is a private WebKit API that grants the loaded HTML access to local file URLs. Since the WebView loads content with an HTTPS base URL (cesium.com), this combination could theoretically be exploited if the Cesium CDN were compromised. Additionally, this will likely cause App Store review rejection.")]),
      para([new TextRun("The app\u2019s entitlements correctly sandbox and restrict to network client only, which is good. No API keys are hardcoded in the source.")]),

      heading("3. Performance Considerations", HeadingLevel.HEADING_2),
      para([new TextRun("The annotation update logic in "), code("MapKitGlobeView.swift"), new TextRun(" removes all annotations of a type and re-adds them whenever the ID set changes. For flights (which update every 15 seconds), this means removing and re-creating potentially thousands of annotation views. A diff-based approach that only adds/removes changed annotations would be significantly more performant.")]),
      para([new TextRun("The NVGNoise Canvas view generates random pixels on every frame, which is GPU-intensive. Consider pre-rendering the noise texture once and displaying it as a static image, or using a Metal shader.")]),
      para([new TextRun("CelesTrak satellite group fetching is sequential. Fetching the two default groups (stations + visual) in parallel with TaskGroup would cut the load time roughly in half.")]),

      heading("4. Architecture Notes", HeadingLevel.HEADING_2),
      para("The project has a clean separation between Models, Services, Views, and App-level code. The use of actors for network services (CelesTrakService, NOAAService, etc.) is appropriate for thread safety."),
      para("However, communication between the app entry point (Terra5App) and views relies on NotificationCenter, which bypasses SwiftUI\u2019s data flow. This makes the code harder to reason about and test. Consider using @Environment or a dedicated action/event system."),
      para([new TextRun("The CesiumWebView and its coordinator appear to be legacy code that\u2019s been replaced by MapKitGlobeView. The Cesium path is still wired up but the app uses MapKit exclusively. Consider removing the Cesium code path to reduce maintenance burden, or add a feature flag to switch between them.")]),

      heading("Recommendations Summary", HeadingLevel.HEADING_1),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Fix the 7 bugs identified above, prioritizing the force-unwrap crash and settings corruption")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Remove dead code: ContentView.swift, unused index.html, empty OpenSkyResponse model")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Replace deprecated APIs: lockFocus/unlockFocus, javaScriptEnabled, allowFileAccessFromFileURLs")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Implement diff-based annotation updates for better MapKit performance")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Either implement or remove the traffic layer to avoid confusing users")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Replace print()/NSLog() with os.Logger for structured, level-based logging")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Update NOAA User-Agent with a real contact email before deploying")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun("Fix the weather data source label mismatch (says NOAA NEXRAD, actually uses RainViewer)")] }),
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/sessions/loving-beautiful-brahmagupta/mnt/Terra5/Terra5_Audit_Report.docx", buffer);
  console.log("Audit report generated successfully");
});
