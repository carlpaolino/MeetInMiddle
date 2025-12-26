//
//  ResultsViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import MapKit
import SwiftUI

@MainActor
class ResultsViewModel: ObservableObject {
    @Published var rankedPlaces: [PlaceScore] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPlace: PlaceScore?
    @Published var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list
        case map
    }
    
    let meet: Meet
    let resolvedCoordinates: [UUID: CLLocationCoordinate2D]
    let userProfile: UserProfile
    
    init(meet: Meet, resolvedCoordinates: [UUID: CLLocationCoordinate2D], userProfile: UserProfile) {
        self.meet = meet
        self.resolvedCoordinates = resolvedCoordinates
        self.userProfile = userProfile
    }
    
    func searchAndRank() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Calculate midpoint
        let coordinates = Array(resolvedCoordinates.values)
        guard !coordinates.isEmpty else {
            errorMessage = "No valid locations found"
            return
        }
        
        let midpoint = calculateMidpoint(coordinates: coordinates)
        
        // Search for places
        do {
            let places = try await PlaceSearchService.shared.searchPlaces(
                near: midpoint,
                category: meet.placeCategory,
                radius: calculateSearchRadius(coordinates: coordinates)
            )
            
            // Rank places
            let ranked = await RankingService.shared.rankPlaces(
                places: places,
                participants: meet.participants,
                resolvedCoordinates: resolvedCoordinates,
                mode: meet.mode,
                category: meet.placeCategory,
                userProfile: userProfile
            )
            
            rankedPlaces = ranked
        } catch {
            errorMessage = "Failed to search places: \(error.localizedDescription)"
        }
    }
    
    private func calculateMidpoint(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        guard !coordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        
        let sumLat = coordinates.reduce(0) { $0 + $1.latitude }
        let sumLon = coordinates.reduce(0) { $0 + $1.longitude }
        
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(coordinates.count),
            longitude: sumLon / Double(coordinates.count)
        )
    }
    
    private func calculateSearchRadius(coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 2 else {
            return 8000 // Default 5 miles
        }
        
        // Calculate max distance between any two points
        var maxDistance: Double = 0
        
        for i in 0..<coordinates.count {
            for j in (i+1)..<coordinates.count {
                let location1 = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
                let location2 = CLLocation(latitude: coordinates[j].latitude, longitude: coordinates[j].longitude)
                let distance = location1.distance(from: location2)
                maxDistance = max(maxDistance, distance)
            }
        }
        
        // Use 1.5x the max distance as search radius, with min 2 miles and max 8 miles
        let radius = maxDistance * 1.5
        return min(max(radius, 3200), 12800) // 2-8 miles
    }
    
    func openInMaps(_ place: Place) {
        place.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    func formatTravelTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

