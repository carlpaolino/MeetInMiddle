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
            
            // Find Activities Tab
            ActivityFinderView(appViewModel: appViewModel)
                .tabItem {
                    Label("Activities", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView(appViewModel: appViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView(appViewModel: AppViewModel())
}

