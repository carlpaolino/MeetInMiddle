//
//  FlightFinderView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct FlightFinderView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var viewModel: FlightFinderViewModel
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: FlightFinderViewModel(
            locationManager: appViewModel.locationManager
        ))
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Flight Finder")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .alert("Error", isPresented: errorBinding) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let error = viewModel.errorMessage {
                        Text(error)
                    }
                }
                .sheet(item: $viewModel.selectedAirport) { airport in
                    AirportDetailView(airport: airport, viewModel: viewModel)
                }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottomLeading) {
            contentStack
            addressBoxes
        }
    }
    
    private var contentStack: some View {
        VStack(spacing: 0) {
            searchSection
            Divider()
            airportsSection
        }
    }
    
    private var addressBoxes: some View {
        VStack(alignment: .leading, spacing: 8) {
            AddressBox(
                label: "Address 1",
                address: viewModel.address1 != nil
                    ? (viewModel.address1!.name ?? formatAddress(from: viewModel.address1!))
                    : "Not set",
                color: .blue,
                isSet: viewModel.address1 != nil,
                onTap: {
                    viewModel.address1 = nil
                }
            )
            
            AddressBox(
                label: "Address 2",
                address: viewModel.address2 != nil
                    ? (viewModel.address2!.name ?? formatAddress(from: viewModel.address2!))
                    : "Not set",
                color: .green,
                isSet: viewModel.address2 != nil,
                onTap: {
                    viewModel.address2 = nil
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading)
        .padding(.bottom, viewModel.selectedAirport != nil ? 0 : 20)
        .zIndex(5)
    }
    
    private func formatAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []
        
        if let name = mapItem.name {
            return name
        }
        
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        
        if components.isEmpty {
            return "Selected Location"
        }
        
        return components.joined(separator: " ")
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            searchBar
            addCurrentLocationButton
            locationsList
            midpointDisplay
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for city, airport, or address", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.updateSearchQuery("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !viewModel.searchCompletions.isEmpty {
                searchSuggestions
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var searchSuggestions: some View {
        ScrollView {
            suggestionsList
        }
        .frame(maxHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.searchCompletions.enumerated()), id: \.offset) { index, completion in
                suggestionRow(for: completion)
                if index < viewModel.searchCompletions.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
    }
    
    private func suggestionRow(for completion: MKLocalSearchCompletion) -> some View {
        Button(action: {
            Task {
                await viewModel.addLocation(from: completion)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(completion.title)
                        .foregroundColor(.primary)
                        .font(.body)
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addCurrentLocationButton: some View {
        Button(action: {
            Task {
                await viewModel.addCurrentLocation()
            }
        }) {
            HStack {
                Image(systemName: "location.fill")
                Text("Add Current Location")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var locationsList: some View {
        if !viewModel.locations.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Locations (\(viewModel.locations.count))")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.locations) { location in
                            LocationChip(location: location) {
                                viewModel.removeLocation(location)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var midpointDisplay: some View {
        if let midpoint = viewModel.midpoint {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.green)
                    Text("Midpoint")
                        .font(.headline)
                }
                Text(String(format: "%.4f, %.4f", midpoint.latitude, midpoint.longitude))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var airportsSection: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Searching airports...")
            Spacer()
        } else if !viewModel.airports.isEmpty {
            airportsList
        } else if viewModel.midpoint != nil {
            ContentUnavailableView(
                "No Airports Found",
                systemImage: "airplane.departure",
                description: Text("Try increasing the search radius or adding more locations")
            )
        } else {
            ContentUnavailableView(
                "Add Locations",
                systemImage: "mappin.and.ellipse",
                description: Text("Add at least one location to find airports in the middle")
            )
        }
    }
    
    private var airportsList: some View {
        List {
            Section {
                ForEach(viewModel.airports) { airport in
                    AirportRow(airport: airport, viewModel: viewModel)
                        .onTapGesture {
                            // Set airport as Address 1 or Address 2
                            if viewModel.address1 == nil {
                                viewModel.address1 = airport.mapItem
                            } else if viewModel.address2 == nil {
                                viewModel.address2 = airport.mapItem
                            } else {
                                // Both are set, replace Address 2
                                viewModel.address2 = airport.mapItem
                            }
                            viewModel.selectedAirport = airport
                        }
                }
            } header: {
                Text("Airports Near Midpoint (\(viewModel.airports.count))")
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            radiusMenu
        }
    }
    
    private var radiusMenu: some View {
        Menu {
            radius500Button
            radius1000Button
            radius2000Button
        } label: {
            Label("Radius", systemImage: "slider.horizontal.3")
        }
    }
    
    private var radius500Button: some View {
        Button(action: {
            viewModel.searchRadius = 500000
            Task {
                await viewModel.searchAirports()
            }
        }) {
            Label("500 km", systemImage: viewModel.searchRadius == 500000 ? "checkmark" : "")
        }
    }
    
    private var radius1000Button: some View {
        Button(action: {
            viewModel.searchRadius = 1000000
            Task {
                await viewModel.searchAirports()
            }
        }) {
            Label("1000 km", systemImage: viewModel.searchRadius == 1000000 ? "checkmark" : "")
        }
    }
    
    private var radius2000Button: some View {
        Button(action: {
            viewModel.searchRadius = 2000000
            Task {
                await viewModel.searchAirports()
            }
        }) {
            Label("2000 km", systemImage: viewModel.searchRadius == 2000000 ? "checkmark" : "")
        }
    }
}

struct LocationChip: View {
    let location: FlightLocation
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption)
            Text(location.name)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(20)
    }
}

struct AirportRow: View {
    let airport: Place
    let viewModel: FlightFinderViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(airport.name)
                    .font(.headline)
                
                if let address = airport.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let distance = viewModel.distanceFromMidpoint(to: airport) {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.caption2)
                        Text(String(format: "%.1f km from midpoint", distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AirportDetailView: View {
    let airport: Place
    let viewModel: FlightFinderViewModel
    @Environment(\.dismiss) var dismiss
    
    private var isAddress1Set: Bool {
        guard let addr1 = viewModel.address1 else { return false }
        let threshold: Double = 0.0001 // Small threshold for coordinate comparison
        return abs(addr1.placemark.coordinate.latitude - airport.coordinate.latitude) < threshold &&
               abs(addr1.placemark.coordinate.longitude - airport.coordinate.longitude) < threshold
    }
    
    private var isAddress2Set: Bool {
        guard let addr2 = viewModel.address2 else { return false }
        let threshold: Double = 0.0001 // Small threshold for coordinate comparison
        return abs(addr2.placemark.coordinate.latitude - airport.coordinate.latitude) < threshold &&
               abs(addr2.placemark.coordinate.longitude - airport.coordinate.longitude) < threshold
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text(airport.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        if let address = airport.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let distance = viewModel.distanceFromMidpoint(to: airport) {
                            HStack {
                                Image(systemName: "ruler")
                                Text(String(format: "%.1f km from midpoint", distance))
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Divider()
                    }
                    .padding()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        if let phone = airport.phoneNumber {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Link(phone, destination: URL(string: "tel:\(phone)")!)
                                    .font(.body)
                            }
                        }
                        
                        if let url = airport.url {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Link("Website", destination: url)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Set as Address 1
                        Button(action: {
                            viewModel.address1 = airport.mapItem
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            HStack {
                                Image(systemName: isAddress1Set ? "checkmark.circle.fill" : "1.circle.fill")
                                    .font(.title3)
                                Text(isAddress1Set ? "Current Address 1" : "Set as Address 1")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(isAddress1Set ? Color.gray : Color.blue)
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isAddress1Set)
                        
                        // Set as Address 2
                        Button(action: {
                            viewModel.address2 = airport.mapItem
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            HStack {
                                Image(systemName: isAddress2Set ? "checkmark.circle.fill" : "2.circle.fill")
                                    .font(.title3)
                                Text(isAddress2Set ? "Current Address 2" : "Set as Address 2")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(isAddress2Set ? Color.gray : Color.green)
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isAddress2Set)
                        
                        Button(action: {
                            viewModel.openInMaps(airport)
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Open in Apple Maps")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Airport Details")
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
    FlightFinderView(appViewModel: AppViewModel())
}

