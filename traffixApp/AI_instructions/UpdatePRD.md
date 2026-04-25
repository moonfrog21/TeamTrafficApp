# Project Requirements Document (UpdatePRD): Map Integration & Routing Update

## 1. Project Overview & Objectives
This document outlines a significant visual and functional update to the existing GPS Telemetry Application. The core functionality—capturing user location telemetry and securely transmitting it to a dynamic ngrok endpoint—remains entirely intact. However, the user interface will undergo a major overhaul to integrate several Google Cloud API features, transforming the app into a rich, interactive map-centric experience.

## 2. Core UI Overhaul: Interactive Map Background
The main homescreen will be completely redesigned to center around a live map interface.
- **Google Maps Integration**: The primary background of the homescreen must utilize the `google_maps_flutter` library to display a full-screen, interactive Google Map.
- **Camera Tracking**: The map's camera position and angle must dynamically follow the user's current GPS location, ensuring they remain centered on the screen as they progress along any suggested path.

## 3. Telemetry Controls Simplification
The existing telemetry transmission controls will be minimized to focus the user's attention on the map.
- **Refined Start/Stop Button**: The current green/red "Start/Stop GPS Data Transmit" button must be retained but visually scaled down to be slightly smaller.
- **Text Removal**: All accompanying instructionary text on the main screen must be removed.
- **Repositioning**: The start/stop button must be repositioned to the bottom of the main page, overlaid cleanly on top of the map interface.

## 4. Address Search & Geocoding
A new destination search feature must be implemented to allow users to navigate to specific locations.
- **Search Interface**: Implement a search bar overlaid on the map interface.
- **Places Autocomplete**: Integrate the Google Places API to provide real-time autocomplete suggestions as the user types a destination.
- **Geocoding API**: Upon user selection of a suggested destination, the application must use the Google Geocoding API to resolve the place ID or address string into exact latitude and longitude coordinates. This precise coordinate pair will serve as the destination parameter for routing.

## 5. Route Calculation & Polyline Rendering
Once a destination is selected, the application must fetch and visually render the optimal route.
- **Routes API Integration**: The application must execute HTTP requests to the Google Directions API (legacy, uses HTTP GET) or the Google Routes API (newer, uses HTTP POST with JSON body), passing the user's current GPS location as the origin and the geocoded coordinate as the destination.
- **Response Parsing**: The resulting JSON response must be parsed to extract the encoded overview polyline, travel distance, and estimated travel duration.
- **Polyline Rendering**: The encoded polyline string must be decoded into a list of coordinates and rendered natively on the map as a distinct, colored path utilizing the `flutter_polyline_points` package.

## 6. Maintained Functionalities
- **Telemetry Transmission**: The underlying telemetry service must continue to POST the JSON payload (`user`, `latitude`, `longitude`, `time`) to the configured ngrok URL every 5 seconds when the tracker is active.
- **Settings Screen**: The settings menu for configuring the ngrok base URL must remain accessible from the new map-based homescreen.

## 7. Required Dependencies
To successfully implement this update, ensure the following Flutter packages are included in `pubspec.yaml`:
- **`google_maps_flutter`**: For rendering the interactive map interface as the app background.
- **`flutter_polyline_points`**: For decoding the polyline strings returned by the Google Routes API into exact map coordinates.
- **`http`**: Essential for executing manual REST API requests (GET for Directions/Geocoding, POST for Routes API) to the Google Places Autocomplete, Geocoding, and Routes/Directions APIs.
- **`geolocator`**: (Already in project) Required to supply the current GPS location for continuous camera tracking and as the origin coordinate for route calculation.
- **`uuid`**: (Highly Recommended) For generating session tokens for the Google Places Autocomplete API to optimize and group search billing.
