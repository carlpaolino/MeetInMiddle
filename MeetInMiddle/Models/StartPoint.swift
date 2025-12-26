//
//  StartPoint.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation

enum StartPoint: Codable, Equatable {
    case currentLocation
    case coordinate(lat: Double, lon: Double, label: String?)
    case address(query: String)
    
    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .currentLocation:
            return nil // Will be resolved via location manager
        case .coordinate(let lat, let lon, _):
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        case .address:
            return nil // Will be resolved via geocoding
        }
    }
    
    var displayLabel: String {
        switch self {
        case .currentLocation:
            return "Current Location"
        case .coordinate(_, _, let label):
            return label ?? "Custom Location"
        case .address(let query):
            return query
        }
    }
}

