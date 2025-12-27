//
//  NewMeetViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class NewMeetViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var participants: [Participant] = []
    @Published var mode: TravelMode = .drive
    @Published var placeCategory: PlaceCategory = .restaurant
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var includeUser: Bool = false
    
    @Published var resolvedCoordinates: [UUID: CLLocationCoordinate2D] = [:]
    @Published var isResolvingLocations: Bool = false
    
    private var userParticipantId: UUID?
    
    let locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    func addParticipant(name: String) {
        let participant = Participant(name: name)
        participants.append(participant)
    }
    
    func removeParticipant(_ participant: Participant) {
        // Don't allow removing the user participant directly
        if participant.id == userParticipantId {
            toggleIncludeUser()
            return
        }
        participants.removeAll { $0.id == participant.id }
        resolvedCoordinates.removeValue(forKey: participant.id)
    }
    
    func toggleIncludeUser() {
        includeUser.toggle()
        
        if includeUser {
            // Add user as participant with current location
            let userParticipant = Participant(name: "You", start: .currentLocation)
            userParticipantId = userParticipant.id
            participants.insert(userParticipant, at: 0)
            
            // Automatically resolve user's location
            Task {
                do {
                    let coordinate = try await locationManager.getCurrentLocation()
                    resolvedCoordinates[userParticipant.id] = coordinate
                } catch {
                    // Location will be resolved later in resolveAllLocations
                }
            }
        } else {
            // Remove user participant
            if let userId = userParticipantId {
                participants.removeAll { $0.id == userId }
                resolvedCoordinates.removeValue(forKey: userId)
                userParticipantId = nil
            }
        }
    }
    
    func setParticipantStart(_ participant: Participant, start: StartPoint) {
        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
            participants[index].start = start
            resolvedCoordinates.removeValue(forKey: participant.id)
        }
    }
    
    func resolveAllLocations() async {
        isResolvingLocations = true
        errorMessage = nil
        
        for participant in participants {
            if resolvedCoordinates[participant.id] != nil {
                continue // Already resolved
            }
            
            do {
                let coordinate: CLLocationCoordinate2D
                
                switch participant.start {
                case .currentLocation:
                    coordinate = try await locationManager.getCurrentLocation()
                case .coordinate(let lat, let lon, _):
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                case .address(let query):
                    coordinate = try await locationManager.geocodeAddress(query)
                }
                
                resolvedCoordinates[participant.id] = coordinate
            } catch {
                errorMessage = "Failed to resolve location for \(participant.name): \(error.localizedDescription)"
            }
        }
        
        isResolvingLocations = false
    }
    
    func canProceed() -> Bool {
        guard !title.isEmpty else {
            return false
        }
        
        // Need at least 2 participants total (either 2 others, or user + 1 other)
        let minParticipants = includeUser ? 1 : 2
        guard participants.count >= minParticipants,
              participants.count <= 8 else {
            return false
        }
        
        // Check if all locations are resolved
        return participants.allSatisfy { resolvedCoordinates[$0.id] != nil }
    }
}

