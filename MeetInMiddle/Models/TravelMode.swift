//
//  TravelMode.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import SwiftUI

enum TravelMode: String, Codable, CaseIterable {
    case drive = "Drive"
    case flight = "Flight"
    case bike = "Bike"
    case bus = "Bus"
    
    var iconName: String {
        switch self {
        case .drive:
            return "car.fill"
        case .flight:
            return "airplane"
        case .bike:
            return "bicycle"
        case .bus:
            return "bus.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .drive:
            return .blue
        case .flight:
            return .purple
        case .bike:
            return .green
        case .bus:
            return .orange
        }
    }
}

