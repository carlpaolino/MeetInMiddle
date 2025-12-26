//
//  PlaceCategory.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation

enum PlaceCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurant"
    case cafe = "Cafe"
    case activity = "Activity"
    case parking = "Parking"
    
    var searchQuery: String {
        switch self {
        case .restaurant:
            return "restaurant"
        case .cafe:
            return "cafe"
        case .activity:
            return "things to do"
        case .parking:
            return "parking"
        }
    }
}

