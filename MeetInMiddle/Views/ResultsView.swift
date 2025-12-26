//
//  ResultsView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit

struct ResultsView: View {
    let meet: Meet
    let resolvedCoordinates: [UUID: CLLocationCoordinate2D]
    @ObservedObject var appViewModel: AppViewModel
    
    @StateObject private var viewModel: ResultsViewModel
    @Environment(\.dismiss) var dismiss
    
    init(meet: Meet, resolvedCoordinates: [UUID: CLLocationCoordinate2D], appViewModel: AppViewModel) {
        self.meet = meet
        self.resolvedCoordinates = resolvedCoordinates
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: ResultsViewModel(
            meet: meet,
            resolvedCoordinates: resolvedCoordinates,
            userProfile: appViewModel.userProfile
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding places...")
                } else if viewModel.rankedPlaces.isEmpty && viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        "No Places Found",
                        systemImage: "mappin.slash",
                        description: Text("Try adjusting your search criteria")
                    )
                } else {
                    VStack(spacing: 0) {
                        Picker("View", selection: $viewModel.viewMode) {
                            Text("List").tag(ResultsViewModel.ViewMode.list)
                            Text("Map").tag(ResultsViewModel.ViewMode.map)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        if viewModel.viewMode == .list {
                            listView
                        } else {
                            mapView
                        }
                    }
                }
            }
            .navigationTitle(meet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.searchAndRank()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(item: $viewModel.selectedPlace) { placeScore in
                PlaceDetailView(placeScore: placeScore, meet: meet, viewModel: viewModel)
            }
        }
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel.rankedPlaces) { placeScore in
                PlaceRow(placeScore: placeScore, meet: meet, viewModel: viewModel)
                    .onTapGesture {
                        viewModel.selectedPlace = placeScore
                    }
            }
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: .constant(calculateMapRegion()), annotationItems: viewModel.rankedPlaces) { placeScore in
            MapAnnotation(coordinate: placeScore.place.coordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("#\(viewModel.rankedPlaces.firstIndex(where: { $0.id == placeScore.id })! + 1)")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.white)
                        .cornerRadius(4)
                }
                .onTapGesture {
                    viewModel.selectedPlace = placeScore
                }
            }
        }
    }
    
    private func calculateMapRegion() -> MKCoordinateRegion {
        guard !viewModel.rankedPlaces.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let coordinates = viewModel.rankedPlaces.map { $0.place.coordinate }
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.05) * 1.2,
            longitudeDelta: max(maxLon - minLon, 0.05) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

struct PlaceRow: View {
    let placeScore: PlaceScore
    let meet: Meet
    let viewModel: ResultsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(placeScore.place.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(placeScore.profileMatch))% match")
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            if let address = placeScore.place.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Fairness: \(Int(placeScore.fairnessScore / 60)) min", systemImage: "scalemass")
                    .font(.caption)
                Spacer()
                Label("Total: \(viewModel.formatTravelTime(placeScore.totalTravelTime))", systemImage: "clock")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Show travel times for each participant
            VStack(alignment: .leading, spacing: 4) {
                ForEach(meet.participants) { participant in
                    if let time = placeScore.travelTimes[participant.id] {
                        HStack {
                            Text(participant.name)
                                .font(.caption2)
                            Spacer()
                            Text(viewModel.formatTravelTime(time))
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

struct PlaceDetailView: View {
    let placeScore: PlaceScore
    let meet: Meet
    let viewModel: ResultsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Place info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(placeScore.place.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let address = placeScore.place.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let phone = placeScore.place.phoneNumber {
                            Link(phone, destination: URL(string: "tel:\(phone)")!)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Scores
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        ScoreRow(label: "Fairness Score", value: "\(Int(placeScore.fairnessScore / 60)) min difference", systemImage: "scalemass")
                        ScoreRow(label: "Total Travel Time", value: viewModel.formatTravelTime(placeScore.totalTravelTime), systemImage: "clock")
                        ScoreRow(label: "Profile Match", value: "\(Int(placeScore.profileMatch))%", systemImage: "person.fill.checkmark")
                    }
                    .padding()
                    
                    Divider()
                    
                    // Travel times by participant
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Travel Times")
                            .font(.headline)
                        
                        ForEach(meet.participants) { participant in
                            if let time = placeScore.travelTimes[participant.id] {
                                HStack {
                                    Text(participant.name)
                                    Spacer()
                                    Text(viewModel.formatTravelTime(time))
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                    
                    // Open in Maps button
                    Button(action: {
                        viewModel.openInMaps(placeScore.place)
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

struct ScoreRow: View {
    let label: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ResultsView(
        meet: Meet(title: "Test", participants: []),
        resolvedCoordinates: [:],
        appViewModel: AppViewModel()
    )
}

