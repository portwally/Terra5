# Changelog

All notable changes to Terra5 (WORLDVIEW) will be documented in this file.

## [1.0.0] - 2026-02-20

### Added

#### Core Architecture
- SwiftUI + MapKit hybrid architecture for native macOS performance
- `AppState` - Global observable state management with `@MainActor`
- `AppConstants` - Centralized theme colors, typography, and configuration
- Network entitlements for API access

#### Globe View
- `MapKitGlobeView` - Native MapKit globe with satellite imagery (`.satelliteFlyover`)
- 3D globe rotation, zoom, and pitch controls
- Dark appearance styling
- Camera state synchronization with HUD
- Fly-to animations for city/landmark navigation

#### Live Data Layers
- **Flights** (OpenSky Network API)
  - ~8,500 live flights worldwide
  - Custom airplane icons rotated to heading
  - Callsign, altitude, speed display
  - 15-second auto-refresh

- **Satellites** (CelesTrak TLE API)
  - ~183 satellites (ISS, CSS, brightest objects)
  - TLE parsing with line ending normalization
  - Simplified SGP4 position calculation
  - Custom satellite icon with solar panels
  - 60-second auto-refresh

- **Earthquakes** (USGS GeoJSON API)
  - ~186 earthquakes in past 24 hours
  - Magnitude-based sizing and coloring
  - Custom seismic wave icon with concentric circles
  - 5-minute auto-refresh

#### Tactical UI
- `ClassificationHeader` - "TOP SECRET // SI-TK // NOFORN" banner
- `TacticalHUDView` - Coordinates, altitude, GSD, NIIRS display
- `CoordinatesPanel` - Lat/Lon and MGRS coordinate formats
- `InfoPanel` - Recording indicator, orbital info
- `CornerBrackets` - Decorative targeting brackets
- `CrosshairView` - Center screen crosshair

#### Sidebar
- Collapsible sidebar (380px width)
- Data layer toggles with ON/OFF tactical style
- Live data counts and last update timestamps
- City preset buttons (Washington DC, Austin, San Francisco, New York, London, Tokyo, Sydney, Moscow)
- Landmark quick-jump buttons per city
- Visual mode selection grid

#### Visual Mode Overlays
- **Normal** - No overlay
- **CRT** - Green phosphor tint, scanlines, vignette, flicker animation
- **NVG** - Green monochrome, grain noise, circular scope overlay
- **FLIR** - Thermal gradient, grid lines, temperature scale UI
- **Noir** - Desaturation, high contrast, film grain, vignette
- **Snow** - Blue tint, desaturation, frost vignette
- **Anime** - Saturation boost, bloom glow, speed lines
- **AI** - Cyan tint, scanning line animation, detection boxes

#### Services
- `OpenSkyService` - Actor-based flight data fetching with rate limiting
- `CelesTrakService` - Satellite TLE fetching by group
- `USGSService` - Earthquake GeoJSON fetching with feed options
- `DataManager` - Coordinates auto-refresh timers for all data sources

#### Models
- `Flight` - ICAO24, callsign, position, altitude, velocity, heading
- `Satellite` - NORAD ID, name, TLE lines, computed position
- `Earthquake` - Magnitude, location, depth, tsunami flag

### Technical Details

#### API Endpoints
- OpenSky: `https://opensky-network.org/api/states/all`
- CelesTrak: `https://celestrak.org/NORAD/elements/gp.php`
- USGS: `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson`

#### Refresh Intervals
- Flights: 15 seconds
- Satellites: 60 seconds
- Earthquakes: 5 minutes

#### Theme Colors
- Background: `#0a0a0a`
- Accent: `#00d4aa` (cyan/teal)
- Alert: `#ff3333`
- Warning: `#ffaa00`

### Known Issues
- Cesium.js WebView approach abandoned due to macOS 26 WebContent sandbox restrictions
- Satellite positions use simplified orbital mechanics (not full SGP4)
- Visual mode overlays use SwiftUI blend modes (not GPU shaders)

### Dependencies
- macOS 26.2+
- Xcode 16+
- No external packages required

---

## Development Notes

### Architecture Decision: MapKit vs Cesium.js

Originally planned to use Cesium.js via WKWebView for the 3D globe. However, macOS 26 introduced stricter WebContent process sandbox restrictions that blocked network requests from the WebView subprocess, even with proper entitlements.

Solution: Switched to native MapKit with `.satelliteFlyover` map type, which provides similar satellite imagery without sandbox issues. Visual mode shaders were reimplemented as SwiftUI overlays using blend modes and Canvas drawing.

### TLE Parsing Fix

CelesTrak returns TLE data with Windows-style line endings (`\r\n`). Swift's `.newlines` character set caused empty lines during splitting. Fixed by normalizing all line endings to `\n` before parsing.
