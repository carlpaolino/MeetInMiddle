//
//  Meet.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation

struct Meet: Identifiable, Codable {
    var id: UUID
    var title: String
    var participants: [Participant]
    var mode: TravelMode
    var placeCategory: PlaceCategory
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, participants: [Participant], mode: TravelMode = .drive, placeCategory: PlaceCategory = .restaurant, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.participants = participants
        self.mode = mode
        self.placeCategory = placeCategory
        self.createdAt = createdAt
    }
}

