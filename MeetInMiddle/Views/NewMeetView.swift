//
//  NewMeetView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import CoreLocation

struct NewMeetView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var viewModel: NewMeetViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var newParticipantName = ""
    @State private var showingLocationPicker: Participant?
    @State private var showingResults = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: NewMeetViewModel(locationManager: appViewModel.locationManager))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meet Details") {
                    TextField("Meet Title", text: $viewModel.title)
                }
                
                Section("Participants") {
                    ForEach(viewModel.participants) { participant in
                        ParticipantRow(
                            participant: participant,
                            coordinate: viewModel.resolvedCoordinates[participant.id],
                            onTap: {
                                showingLocationPicker = participant
                            },
                            onDelete: {
                                viewModel.removeParticipant(participant)
                            }
                        )
                    }
                    
                    HStack {
                        TextField("Add participant name", text: $newParticipantName)
                            .onSubmit {
                                addParticipant()
                            }
                        Button("Add") {
                            addParticipant()
                        }
                        .disabled(newParticipantName.isEmpty)
                    }
                }
                
                Section("Settings") {
                    Picker("Transport Mode", selection: $viewModel.mode) {
                        ForEach(TravelMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    Picker("Place Type", selection: $viewModel.placeCategory) {
                        ForEach(PlaceCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await resolveAndProceed()
                        }
                    }) {
                        HStack {
                            if viewModel.isResolvingLocations {
                                ProgressView()
                            }
                            Text("Find Places")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canProceed() || viewModel.isResolvingLocations)
                }
            }
            .navigationTitle("New Meet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $showingLocationPicker) { participant in
                LocationPickerView(
                    participant: participant,
                    locationManager: appViewModel.locationManager,
                    onSelect: { startPoint in
                        viewModel.setParticipantStart(participant, start: startPoint)
                        showingLocationPicker = nil
                    }
                )
            }
            .fullScreenCover(isPresented: $showingResults) {
                if viewModel.canProceed() {
                    let meet = Meet(
                        title: viewModel.title,
                        participants: viewModel.participants,
                        mode: viewModel.mode,
                        placeCategory: viewModel.placeCategory
                    )
                    ResultsView(
                        meet: meet,
                        resolvedCoordinates: viewModel.resolvedCoordinates,
                        appViewModel: appViewModel
                    )
                }
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
        }
    }
    
    private func addParticipant() {
        let trimmed = newParticipantName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addParticipant(name: trimmed)
        newParticipantName = ""
    }
    
    private func resolveAndProceed() async {
        await viewModel.resolveAllLocations()
        if viewModel.canProceed() {
            showingResults = true
        }
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let coordinate: CLLocationCoordinate2D?
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(participant.name)
                    .fontWeight(.medium)
                Text(participant.start.displayLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if coordinate != nil {
                    Text("✓ Location resolved")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("Tap to set location")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    NewMeetView(appViewModel: AppViewModel())
}

