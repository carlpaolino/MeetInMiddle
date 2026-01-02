//
//  RoutingService.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import MapKit

class RoutingService {
    static let shared = RoutingService()
    
    private init() {}
    
    // Cache for directions to avoid redundant API calls
    private var directionsCache: [String: TimeInterval] = [:]
    
    private func cacheKey(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        "\(from.latitude),\(from.longitude)->\(to.latitude),\(to.longitude)"
    }
    
    func getTravelTime(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> TimeInterval {
        // Check cache first
        let key = cacheKey(from: start, to: destination)
        if let cached = directionsCache[key] {
            return cached
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        
        switch mode {
        case .drive:
            request.transportType = .automobile
        case .walk:
            request.transportType = .walking
        case .bike:
            // MapKit doesn't have bike routing, use walking as approximation
            request.transportType = .walking
        case .bus:
            request.transportType = .transit
        case .flight:
            // MapKit doesn't support flight routing, use automobile as fallback
            request.transportType = .automobile
        }
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RoutingError.noRouteFound
        }
        
        let travelTime = route.expectedTravelTime
        
        // Cache the result
        directionsCache[key] = travelTime
        
        return travelTime
    }
    
    func getTravelTimes(
        from starts: [CLLocationCoordinate2D],
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async -> [TimeInterval] {
        await withTaskGroup(of: TimeInterval?.self) { group in
            var results: [TimeInterval] = []
            
            for start in starts {
                group.addTask {
                    do {
                        return try await self.getTravelTime(from: start, to: destination, mode: mode)
                    } catch {
                        return nil
                    }
                }
            }
            
            for await result in group {
                if let time = result {
                    results.append(time)
                } else {
                    results.append(TimeInterval.infinity) // Failed route
                }
            }
            
            return results
        }
    }
    
    func clearCache() {
        directionsCache.removeAll()
    }
}

enum RoutingError: LocalizedError {
    case noRouteFound
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "Could not find a route"
        }
    }
}

