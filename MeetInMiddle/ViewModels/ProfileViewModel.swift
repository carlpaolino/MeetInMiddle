//
//  ProfileViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String
    @Published var foodTypes: [String]
    @Published var activityTypes: [String]
    @Published var budget: BudgetRange
    @Published var vibe: [String]
    @Published var accessibilityNeeds: [String]
    
    @Published var newFoodType: String = ""
    @Published var newActivityType: String = ""
    @Published var newVibe: String = ""
    @Published var newAccessibilityNeed: String = ""
    
    private let onSave: (UserProfile) -> Void
    
    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.displayName = profile.displayName
        self.foodTypes = profile.preferences.foodTypes
        self.activityTypes = profile.preferences.activityTypes
        self.budget = profile.preferences.budget
        self.vibe = profile.preferences.vibe
        self.accessibilityNeeds = profile.preferences.accessibilityNeeds
        self.onSave = onSave
    }
    
    func save() {
        let preferences = Preferences(
            foodTypes: foodTypes,
            activityTypes: activityTypes,
            budget: budget,
            vibe: vibe,
            accessibilityNeeds: accessibilityNeeds
        )
        
        let profile = UserProfile(
            id: UUID(), // Keep existing ID if needed
            displayName: displayName,
            preferences: preferences
        )
        
        onSave(profile)
    }
    
    func addFoodType() {
        let trimmed = newFoodType.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !foodTypes.contains(trimmed) {
            foodTypes.append(trimmed)
            newFoodType = ""
        }
    }
    
    func removeFoodType(_ type: String) {
        foodTypes.removeAll { $0 == type }
    }
    
    func addActivityType() {
        let trimmed = newActivityType.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !activityTypes.contains(trimmed) {
            activityTypes.append(trimmed)
            newActivityType = ""
        }
    }
    
    func removeActivityType(_ type: String) {
        activityTypes.removeAll { $0 == type }
    }
    
    func addVibe() {
        let trimmed = newVibe.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !vibe.contains(trimmed) {
            vibe.append(trimmed)
            newVibe = ""
        }
    }
    
    func removeVibe(_ item: String) {
        vibe.removeAll { $0 == item }
    }
    
    func addAccessibilityNeed() {
        let trimmed = newAccessibilityNeed.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !accessibilityNeeds.contains(trimmed) {
            accessibilityNeeds.append(trimmed)
            newAccessibilityNeed = ""
        }
    }
    
    func removeAccessibilityNeed(_ item: String) {
        accessibilityNeeds.removeAll { $0 == item }
    }
}

