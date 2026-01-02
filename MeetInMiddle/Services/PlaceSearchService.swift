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
    
    func searchAirports(
        near coordinate: CLLocationCoordinate2D,
        radius: Double = 500000 // 500km default radius for airports
    ) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "airport"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = [.pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // Filter to only airports and limit results
        let airportResults = response.mapItems.filter { mapItem in
            let name = (mapItem.name ?? "").lowercased()
            let categories = mapItem.pointOfInterestCategory
            return name.contains("airport") || 
                   name.contains("international") ||
                   categories == .airport ||
                   name.contains("airfield") ||
                   name.contains("aerodrome")
        }
        
        // Sort by distance from coordinate
        let sortedResults = airportResults.sorted { item1, item2 in
            let coord1 = item1.placemark.coordinate
            let coord2 = item2.placemark.coordinate
            let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
            let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return location1.distance(from: targetLocation) < location2.distance(from: targetLocation)
        }
        
        // Limit to 50 airports (more than regular places since airports are sparse)
        let limitedResults = Array(sortedResults.prefix(50))
        
        return limitedResults.map { Place(mapItem: $0) }
    }
}

