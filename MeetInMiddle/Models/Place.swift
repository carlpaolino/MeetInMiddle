//
//  Place.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import MapKit

struct Place: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let phoneNumber: String?
    let url: URL?
    let mapItem: MKMapItem
    
    init(mapItem: MKMapItem) {
        self.id = mapItem.placemark.title ?? UUID().uuidString
        self.name = mapItem.name ?? "Unknown Place"
        self.coordinate = mapItem.placemark.coordinate
        self.address = mapItem.placemark.title
        self.phoneNumber = mapItem.phoneNumber
        self.url = mapItem.url
        self.mapItem = mapItem
    }
}

struct PlaceScore: Identifiable {
    var id: String { place.id }
    let place: Place
    let travelTimes: [UUID: TimeInterval] // Participant ID -> travel time in seconds
    let fairnessScore: Double // Lower is better (max - min)
    let totalTravelTime: TimeInterval
    let profileMatch: Double // 0-100
    let combinedScore: Double // Lower is better
    
    var maxTravelTime: TimeInterval {
        travelTimes.values.max() ?? 0
    }
    
    var minTravelTime: TimeInterval {
        travelTimes.values.min() ?? 0
    }
    
    var avgTravelTime: TimeInterval {
        let sum = travelTimes.values.reduce(0, +)
        return sum / Double(travelTimes.count)
    }
}

