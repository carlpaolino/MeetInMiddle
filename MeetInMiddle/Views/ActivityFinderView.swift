//
//  ActivityFinderView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ActivityFinderView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var viewModel: ActivityFinderViewModel
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: ActivityFinderViewModel(
            locationManager: appViewModel.locationManager,
            userProfile: appViewModel.userProfile
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Search") {
                        TextField("Search query (optional)", text: $viewModel.searchQuery)
                        
                        Picker("Category", selection: $viewModel.selectedCategory) {
                            ForEach(PlaceCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Radius: \(Int(viewModel.searchRadius / 1000)) km")
                            Slider(value: $viewModel.searchRadius, in: 1000...20000, step: 1000)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.search()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                }
                                Text("Search")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                
                if !viewModel.results.isEmpty {
                    List(viewModel.results) { place in
                        ActivityPlaceRow(place: place)
                            .onTapGesture {
                                viewModel.selectedPlace = place
                            }
                    }
                } else if !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your search")
                    )
                }
            }
            .navigationTitle("Find Activities")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(item: $viewModel.selectedPlace) { place in
                ActivityPlaceDetailView(place: place, viewModel: viewModel)
            }
        }
    }
}

struct ActivityPlaceRow: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(place.name)
                .font(.headline)
            if let address = place.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityPlaceDetailView: View {
    let place: Place
    let viewModel: ActivityFinderViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(place.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let address = place.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let phone = place.phoneNumber {
                            Link(phone, destination: URL(string: "tel:\(phone)")!)
                                .font(.subheadline)
                        }
                        
                        if let url = place.url {
                            Link("Website", destination: url)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        viewModel.openInMaps(place)
                    }) {
                        HStack {
                            Image(systemName: "map")
                            Text("Open in Apple Maps")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Place Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityFinderView(appViewModel: AppViewModel())
}

