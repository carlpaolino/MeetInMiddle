//
//  Participant.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation

struct Participant: Identifiable, Codable {
    var id: UUID
    var name: String
    var start: StartPoint
    
    init(id: UUID = UUID(), name: String, start: StartPoint = .currentLocation) {
        self.id = id
        self.name = name
        self.start = start
    }
}

