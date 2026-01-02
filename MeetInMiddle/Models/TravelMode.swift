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
    case walk = "Walk"
    case bike = "Bike"
    case bus = "Transit"
    case flight = "Flight"
    
    var iconName: String {
        switch self {
        case .drive:
            return "car.fill"
        case .walk:
            return "figure.walk"
        case .bike:
            return "bicycle"
        case .bus:
            return "bus.fill"
        case .flight:
            return "airplane"
        }
    }
    
    var color: Color {
        switch self {
        case .drive:
            return .blue
        case .walk:
            return .green
        case .bike:
            return .mint
        case .bus:
            return .orange
        case .flight:
            return .purple
        }
    }
}

