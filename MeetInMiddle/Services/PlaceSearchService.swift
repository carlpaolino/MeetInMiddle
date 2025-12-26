//
//  PlaceSearchService.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import MapKit

class PlaceSearchService {
    static let shared = PlaceSearchService()
    
    private init() {}
    
    func searchPlaces(
        near coordinate: CLLocationCoordinate2D,
        category: PlaceCategory,
        radius: Double = 8000 // meters (about 5 miles)
    ) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.searchQuery
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // Limit to 25 results as per PRD
        let limitedResults = Array(response.mapItems.prefix(25))
        
        return limitedResults.map { Place(mapItem: $0) }
    }
    
    func searchPlaces(
        near coordinate: CLLocationCoordinate2D,
        query: String,
        radius: Double = 8000
    ) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        let limitedResults = Array(response.mapItems.prefix(25))
        
        return limitedResults.map { Place(mapItem: $0) }
    }
}

