//
//  HomeView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var showingNewMeet = false
    @State private var showingActivityFinder = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("MeetHalfway")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Find the perfect meeting spot")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(action: {
                        showingNewMeet = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("New Meet")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingActivityFinder = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Find Activities")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Profile")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("MeetHalfway")
            .sheet(isPresented: $showingNewMeet) {
                NewMeetView(appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingActivityFinder) {
                ActivityFinderView(appViewModel: appViewModel)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(appViewModel: appViewModel)
            }
        }
    }
}

#Preview {
    HomeView(appViewModel: AppViewModel())
}

