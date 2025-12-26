//
//  Preferences.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation

enum BudgetRange: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct Preferences: Codable {
    var foodTypes: [String] = []
    var activityTypes: [String] = []
    var budget: BudgetRange = .medium
    var vibe: [String] = []
    var accessibilityNeeds: [String] = []
}

