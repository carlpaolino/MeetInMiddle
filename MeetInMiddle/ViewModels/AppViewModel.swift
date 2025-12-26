//
//  AppViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var savedMeets: [Meet] = []
    
    let locationManager = LocationManager()
    
    init() {
        // Initialize with default profile
        self.userProfile = UserProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        userProfile = profile
        // TODO: Persist with SwiftData in Phase 2
    }
    
    func saveMeet(_ meet: Meet) {
        savedMeets.append(meet)
        // TODO: Persist with SwiftData in Phase 2
    }
}

