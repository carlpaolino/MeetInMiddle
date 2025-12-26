//
//  UserProfile.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    var id: UUID
    var displayName: String
    var preferences: Preferences
    
    init(id: UUID = UUID(), displayName: String = "Me", preferences: Preferences = Preferences()) {
        self.id = id
        self.displayName = displayName
        self.preferences = preferences
    }
}

