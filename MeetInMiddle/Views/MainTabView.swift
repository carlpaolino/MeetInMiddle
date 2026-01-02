//
//  MainTabView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Home Tab
            MapHomeView(appViewModel: appViewModel)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)
            
            // New Meet Tab
            NewMeetView(appViewModel: appViewModel)
                .tabItem {
                    Label("New Meet", systemImage: "person.2.fill")
                }
                .tag(1)
            
            // Flight Finder Tab
            FlightFinderView(appViewModel: appViewModel)
                .tabItem {
                    Label("Flights", systemImage: "airplane.departure")
                }
                .tag(2)
            
            // Settings Tab
            ProfileView(appViewModel: appViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(appViewModel: AppViewModel())
}

