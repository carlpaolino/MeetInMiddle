//
//  MeetInMiddleApp.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI

@main
struct MeetInMiddleApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(appViewModel: appViewModel)
        }
    }
}
