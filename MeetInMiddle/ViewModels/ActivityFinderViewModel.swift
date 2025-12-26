//
//  ActivityFinderViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

@MainActor
class ActivityFinderViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchRadius: Double = 5000 // meters
    @Published var selectedCategory: PlaceCategory = .activity
    @Published var results: [Place] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPlace: Place?
    
    let locationManager: LocationManager
    let userProfile: UserProfile
    
    init(locationManager: LocationManager, userProfile: UserProfile) {
        self.locationManager = locationManager
        self.userProfile = userProfile
    }
    
    func search() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let coordinate: CLLocationCoordinate2D
            
            if let current = locationManager.currentLocation {
                coordinate = current
            } else {
                coordinate = try await locationManager.getCurrentLocation()
            }
            
            let places: [Place]
            
            if searchQuery.isEmpty {
                places = try await PlaceSearchService.shared.searchPlaces(
                    near: coordinate,
                    category: selectedCategory,
                    radius: searchRadius
                )
            } else {
                places = try await PlaceSearchService.shared.searchPlaces(
                    near: coordinate,
                    query: searchQuery,
                    radius: searchRadius
                )
            }
            
            // Filter by profile preferences if applicable
            let filtered = filterByProfile(places: places)
            
            results = filtered
        } catch {
            errorMessage = "Failed to search: \(error.localizedDescription)"
        }
    }
    
    private func filterByProfile(places: [Place]) -> [Place] {
        // Simple filtering based on preferences
        // In MVP, we just return all results, but can add filtering logic here
        
        // If user has specific food preferences and searching restaurants
        if selectedCategory == .restaurant && !userProfile.preferences.foodTypes.isEmpty {
            return places.filter { place in
                let placeText = "\(place.name) \(place.address ?? "")".lowercased()
                return userProfile.preferences.foodTypes.contains { foodType in
                    placeText.contains(foodType.lowercased())
                } || userProfile.preferences.foodTypes.isEmpty
            }
        }
        
        // If user has specific activity preferences
        if selectedCategory == .activity && !userProfile.preferences.activityTypes.isEmpty {
            return places.filter { place in
                let placeText = "\(place.name) \(place.address ?? "")".lowercased()
                return userProfile.preferences.activityTypes.contains { activityType in
                    placeText.contains(activityType.lowercased())
                } || userProfile.preferences.activityTypes.isEmpty
            }
        }
        
        return places
    }
    
    func openInMaps(_ place: Place) {
        place.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

