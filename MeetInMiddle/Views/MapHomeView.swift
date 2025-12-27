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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var isLocationAuthorized = false
    @State private var hasInitializedLocation = false
    @State private var locationUpdateTimer: Timer?
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _locationManager = StateObject(wrappedValue: appViewModel.locationManager)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map View - Interactive and scrollable
            Map(coordinateRegion: $region, 
                showsUserLocation: true, 
                userTrackingMode: .none)
            .ignoresSafeArea(edges: .all)
            .mapStyle(.standard(elevation: .realistic))
            .onAppear {
                Task {
                    await requestLocationAndUpdate()
                }
                // Check for location updates periodically
                locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    checkLocationUpdate()
                }
            }
            .onDisappear {
                locationUpdateTimer?.invalidate()
            }
            
            // Top overlay with app branding - elegant and minimal
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Meet Me In The Middle")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            if isLocationAuthorized, let location = userLocation {
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
                
                Spacer()
            }
        }
    }
    
    private func requestLocationAndUpdate() async {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
            // Wait a moment for permission dialog
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
            do {
                if locationManager.authorizationStatus == .authorizedWhenInUse || 
                   locationManager.authorizationStatus == .authorizedAlways {
                    let location = try await locationManager.getCurrentLocation()
                    await MainActor.run {
                        userLocation = location
                        updateRegion(to: location, animated: true)
                        isLocationAuthorized = true
                        hasInitializedLocation = true
                        locationUpdateTimer?.invalidate()
                    }
                }
            } catch {
                print("Error getting location: \(error)")
            }
    }
    
    private func checkLocationUpdate() {
        if let location = locationManager.currentLocation, !hasInitializedLocation {
            userLocation = location
            updateRegion(to: location, animated: true)
            hasInitializedLocation = true
            isLocationAuthorized = true
            locationUpdateTimer?.invalidate()
        }
    }
    
    private func updateRegion(to coordinate: CLLocationCoordinate2D, animated: Bool = false) {
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        } else {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

#Preview {
    MapHomeView(appViewModel: AppViewModel())
}

