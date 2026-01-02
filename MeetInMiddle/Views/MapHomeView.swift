//
//  MapHomeView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapHomeView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var locationManager: LocationManager
    @StateObject private var searchCompleter = SearchCompleterManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var isLocationAuthorized = false
    @State private var hasInitializedLocation = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var travelTimes: [TravelMode: (time: TimeInterval, distance: CLLocationDistance?)] = [:]
    @State private var isLoadingTravelTimes = false
    @State private var selectedLocationName: String?
    @State private var selectedPOI: MKMapItem?
    @State private var address1: MKMapItem?
    @State private var address2: MKMapItem?
    @State private var searchText = ""
    @State private var selectedCompletion: MKLocalSearchCompletion?
    @State private var showAddressConfirmation = false
    @State private var confirmedAddressLabel = ""
    @State private var shouldFocusSearch = false
    @State private var focusSearchCounter = 0
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _locationManager = StateObject(wrappedValue: appViewModel.locationManager)
    }
    
    var body: some View {
        ZStack {
            // Map View - Interactive and scrollable with smooth zoom (like Apple Maps)
            MapViewWrapper(
                region: $region,
                showsUserLocation: isLocationAuthorized,
                userTrackingMode: .none,
                selectedLocation: selectedLocation,
                onRegionChange: { newRegion in
                    region = newRegion
                },
                onPOISelected: { mapItem in
                    selectedPOI = mapItem
                }
            )
            .ignoresSafeArea(edges: .all)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        // Long press selects the center of the visible region
                        handleMapTap(at: region.center)
                    }
            )
            .onAppear {
                setupLocationTracking()
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
            .onReceive(locationManager.$currentLocation) { newLocation in
                if let newLocation = newLocation {
                    userLocation = newLocation
                    if !hasInitializedLocation {
                        updateRegion(to: newLocation, animated: true)
                        hasInitializedLocation = true
                        isLocationAuthorized = true
                    }
                }
            }
            .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
                if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                    isLocationAuthorized = true
                    locationManager.startUpdatingLocation()
                    
                    // If we already have a location, update the map immediately
                    if let currentLocation = locationManager.currentLocation, !hasInitializedLocation {
                        userLocation = currentLocation
                        updateRegion(to: currentLocation, animated: true)
                        hasInitializedLocation = true
                    }
                }
            }
            
            // Address boxes in bottom left - always visible
            VStack(alignment: .leading, spacing: 8) {
                AddressBox(
                    label: "Address 1",
                    address: address1 != nil 
                        ? (address1!.name ?? formatAddress(from: address1!))
                        : "Not set",
                    color: .blue,
                    isSet: address1 != nil,
                    onTap: {
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        // Clear search text first
                        searchText = ""
                        
                        // Trigger focus by incrementing counter (ensures onChange always fires)
                        focusSearchCounter += 1
                        shouldFocusSearch = true
                    }
                )
                
                AddressBox(
                    label: "Address 2",
                    address: address2 != nil 
                        ? (address2!.name ?? formatAddress(from: address2!))
                        : "Not set",
                    color: .green,
                    isSet: address2 != nil,
                    onTap: {
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        // Clear search text first
                        searchText = ""
                        
                        // Trigger focus by incrementing counter (ensures onChange always fires)
                        focusSearchCounter += 1
                        shouldFocusSearch = true
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading)
            .padding(.bottom, selectedLocation != nil || selectedPOI != nil ? 0 : 20)
            .zIndex(5)
            .animation(.easeInOut(duration: 0.3), value: selectedLocation != nil)
            .animation(.easeInOut(duration: 0.3), value: selectedPOI != nil)
            .animation(.easeInOut(duration: 0.3), value: address1 != nil)
            .animation(.easeInOut(duration: 0.3), value: address2 != nil)
            
            // Top overlay with app branding - elegant and minimal
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Meet Me In The Middle")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                if isLocationAuthorized, userLocation != nil {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text("Location active")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                    Image(systemName: "location.slash")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Location access needed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Finding location...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Show selected addresses
                            if address1 != nil || address2 != nil {
                                HStack(spacing: 8) {
                                    if let addr1 = address1 {
                                        HStack(spacing: 4) {
                                            Text("1:")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                            Text(addr1.name ?? "Address 1")
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                    
                                    if let addr2 = address2 {
                                        HStack(spacing: 4) {
                                            Text("2:")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                            Text(addr2.name ?? "Address 2")
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                    
                    // Location button to recenter map
                    if let location = userLocation {
                        Button(action: {
                            updateRegion(to: location, animated: true)
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search bar
                MapSearchBar(
                    searchText: $searchText,
                    isSearching: $searchCompleter.isSearching,
                    searchCompletions: $searchCompleter.completions,
                    selectedCompletion: $selectedCompletion,
                    shouldFocus: $shouldFocusSearch,
                    focusTrigger: focusSearchCounter,
                    onCompletionSelected: { completion in
                        handleSearchCompletion(completion)
                    },
                    onSearchSubmitted: { query in
                        handleSearchQuery(query)
                    }
                )
                .padding(.horizontal)
                .zIndex(3)
                .onChange(of: searchText) { oldValue, newValue in
                    searchCompleter.search(queryFragment: newValue)
                }
                .onAppear {
                    searchCompleter.updateRegion(region)
                }
                
                Spacer()
                
                // Travel times bottom sheet
                if let selectedLocation = selectedLocation {
                    TravelTimesSheet(
                        selectedLocation: selectedLocation,
                        userLocation: userLocation,
                        travelTimes: travelTimes,
                        isLoading: isLoadingTravelTimes,
                        locationName: selectedLocationName,
                        onDismiss: {
                            self.selectedLocation = nil
                            self.travelTimes = [:]
                            self.selectedLocationName = nil
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
                
                // POI detail sheet
                if let selectedPOI = selectedPOI {
                    PlaceDetailSheet(
                        mapItem: selectedPOI,
                        userLocation: userLocation,
                        address1: address1,
                        address2: address2,
                        onSetAsAddress1: {
                            address1 = selectedPOI
                            confirmedAddressLabel = "Address 1"
                            showAddressConfirmation = true
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Dismiss sheet after brief delay to show confirmation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.selectedPOI = nil
                            }
                        },
                        onSetAsAddress2: {
                            address2 = selectedPOI
                            confirmedAddressLabel = "Address 2"
                            showAddressConfirmation = true
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Dismiss sheet after brief delay to show confirmation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.selectedPOI = nil
                            }
                        },
                        onDismiss: {
                            self.selectedPOI = nil
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
                
                // Address confirmation toast
                if showAddressConfirmation {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("Set as \(confirmedAddressLabel)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.top, 100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showAddressConfirmation = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Handle tap/long press on map - coordinate is already in map coordinates
        
        selectedLocation = coordinate
        selectedLocationName = nil
        travelTimes = [:]
        isLoadingTravelTimes = true
        
        // Reverse geocode to get location name
        Task {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                await MainActor.run {
                    selectedLocationName = placemark.name ?? placemark.locality ?? "Selected Location"
                }
            }
            
            // Calculate travel times for all modes
            await calculateTravelTimes(to: coordinate)
        }
    }
    
    private func calculateTravelTimes(to destination: CLLocationCoordinate2D) async {
        guard let userLocation = userLocation else {
            await MainActor.run {
                isLoadingTravelTimes = false
            }
            return
        }
        
        // Calculate straight-line distance
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let destLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distance = userLoc.distance(from: destLoc)
        
        var results: [TravelMode: (time: TimeInterval, distance: CLLocationDistance?)] = [:]
        
        // Calculate times for all travel modes in parallel
        await withTaskGroup(of: (TravelMode, TimeInterval?).self) { group in
            for mode in TravelMode.allCases {
                group.addTask {
                    do {
                        let time = try await RoutingService.shared.getTravelTime(
                            from: userLocation,
                            to: destination,
                            mode: mode
                        )
                        return (mode, time)
                    } catch {
                        return (mode, nil)
                    }
                }
            }
            
            for await (mode, time) in group {
                if let time = time {
                    results[mode] = (time: time, distance: distance)
                }
            }
        }
        
        await MainActor.run {
            travelTimes = results
            isLoadingTravelTimes = false
        }
    }
    
    private func setupLocationTracking() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request permission - this will show the system dialog
            locationManager.requestLocationPermission()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, start location updates immediately
            isLocationAuthorized = true
            locationManager.startUpdatingLocation()
            
            // Also request a one-time location update to get location faster
            Task {
                do {
                    let location = try await locationManager.getCurrentLocation()
                    await MainActor.run {
                        if !hasInitializedLocation {
                            userLocation = location
                            updateRegion(to: location, animated: true)
                            hasInitializedLocation = true
                        }
                    }
                } catch {
                    // Location will be updated via continuous updates if one-time request fails
                }
            }
            
        case .denied, .restricted:
            // Permission denied - user needs to enable in Settings
            isLocationAuthorized = false
            
        @unknown default:
            break
        }
    }
    
    private func updateRegion(to coordinate: CLLocationCoordinate2D, animated: Bool = false) {
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                region = newRegion
            }
        } else {
            region = newRegion
        }
        
        // Update search completer region when map region changes
        searchCompleter.updateRegion(newRegion)
    }
    
    private func handleSearchCompletion(_ completion: MKLocalSearchCompletion) {
        // Clear search completions immediately
        searchCompleter.clearSearch()
        
        Task {
            do {
                if let mapItem = try await searchCompleter.getMapItem(for: completion) {
                    await MainActor.run {
                        let coordinate = mapItem.placemark.coordinate
                        updateRegion(to: coordinate, animated: true)
                        
                        // Optionally select this location
                        selectedPOI = mapItem
                        searchText = completion.title
                    }
                }
            } catch {
                print("Error getting location for completion: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleSearchQuery(_ query: String) {
        // Clear search completions when submitting search
        searchCompleter.clearSearch()
        
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = region
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                if let firstResult = response.mapItems.first {
                    await MainActor.run {
                        let coordinate = firstResult.placemark.coordinate
                        updateRegion(to: coordinate, animated: true)
                        selectedPOI = firstResult
                    }
                }
            } catch {
                print("Error searching for query: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        
        if components.isEmpty {
            return "Selected Location"
        }
        
        return components.joined(separator: " ")
    }
}

struct AddressBox: View {
    let label: String
    let address: String
    let color: Color
    let isSet: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isSet ? color : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(address)
                    .font(.subheadline)
                    .fontWeight(isSet ? .medium : .regular)
                    .foregroundColor(isSet ? .primary : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isSet {
                Button(action: onTap) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 200, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .opacity(isSet ? 1.0 : 0.7)
    }
}

#Preview {
    MapHomeView(appViewModel: AppViewModel())
}

