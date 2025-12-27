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
    
    @State private var currentStep: Int = 1
    @State private var newParticipantName = ""
    @State private var showingLocationPicker: Participant?
    @State private var showingResults = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: NewMeetViewModel(locationManager: appViewModel.locationManager))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress indicator
                    ProgressIndicator(currentStep: currentStep, totalSteps: 3)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Step content
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 1:
                            transportationSelectionStep
                        case 2:
                            meetDetailsStep
                        case 3:
                            participantsStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Navigation buttons
                    VStack(spacing: 12) {
                        if currentStep < 3 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentStep += 1
                                }
                            }) {
                                HStack {
                                    Text(currentStep == 1 ? "Continue" : "Next")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canProceedToNextStep() ? Color.accentColor : Color.gray.opacity(0.3))
                                .foregroundColor(canProceedToNextStep() ? .white : .gray)
                                .cornerRadius(12)
                            }
                            .disabled(!canProceedToNextStep())
                        } else {
                            Button(action: {
                                Task {
                                    await resolveAndProceed()
                                }
                            }) {
                                HStack {
                                    if viewModel.isResolvingLocations {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("Find Places")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.canProceed() && !viewModel.isResolvingLocations ? Color.accentColor : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.canProceed() || viewModel.isResolvingLocations)
                        }
                        
                        if currentStep > 1 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentStep -= 1
                                }
                            }) {
                                Text("Back")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("New Meet")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Step 1: Transportation Selection
    private var transportationSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Transportation")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("How will you travel to meet up?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(TravelMode.allCases, id: \.self) { mode in
                    TransportationCard(
                        mode: mode,
                        isSelected: viewModel.mode == mode
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.mode = mode
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Meet Details
    private var meetDetailsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Meet Details")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Give your meet a name and choose a place type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Meet Title")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("Enter meet title", text: $viewModel.title)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Place Type")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        PlaceTypeCard(
                            category: category,
                            isSelected: viewModel.placeCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.placeCategory = category
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Participants
    private var participantsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Participants")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add participants and their starting locations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Include yourself option
            VStack(alignment: .leading, spacing: 12) {
                Text("Are you participating?")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    // Option 1: Find place for others only
                    Button(action: {
                        if viewModel.includeUser {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.toggleIncludeUser()
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.includeUser ? "circle" : "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(viewModel.includeUser ? .gray : .accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Find place for others")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("Between 2+ other people")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.includeUser ? Color.gray.opacity(0.1) : Color.accentColor.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.includeUser ? Color.clear : Color.accentColor, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Option 2: Include yourself
                    Button(action: {
                        if !viewModel.includeUser {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.toggleIncludeUser()
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.includeUser ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(viewModel.includeUser ? .accentColor : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include yourself")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("Between you and others")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.includeUser ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.includeUser ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Add participant field
            HStack(spacing: 12) {
                TextField("Participant name", text: $newParticipantName)
                    .textFieldStyle(CustomTextFieldStyle())
                
                Button(action: addParticipant) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(newParticipantName.isEmpty ? .gray.opacity(0.3) : .accentColor)
                }
                .disabled(newParticipantName.isEmpty)
            }
            
            // Participants list
            if viewModel.participants.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                    Text(viewModel.includeUser ? "Add at least 1 other participant" : "Add at least 2 participants")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.participants) { participant in
                        ParticipantCard(
                            participant: participant,
                            coordinate: viewModel.resolvedCoordinates[participant.id],
                            isUser: participant.name == "You",
                            onTap: {
                                // Don't allow editing user's location - it's always current location
                                if participant.name != "You" {
                                    showingLocationPicker = participant
                                }
                            },
                            onDelete: {
                                withAnimation {
                                    viewModel.removeParticipant(participant)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func addParticipant() {
        let trimmed = newParticipantName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            viewModel.addParticipant(name: trimmed)
        }
        newParticipantName = ""
    }
    
    private func canProceedToNextStep() -> Bool {
        switch currentStep {
        case 1:
            return true // Transportation is always selected (has default)
        case 2:
            return !viewModel.title.isEmpty
        case 3:
            // Need at least 2 participants if not including user, or 1 other if including user
            let minParticipants = viewModel.includeUser ? 1 : 2
            return viewModel.participants.count >= minParticipants
        default:
            return false
        }
    }
    
    private func resolveAndProceed() async {
        await viewModel.resolveAllLocations()
        if viewModel.canProceed() {
            showingResults = true
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .animation(.spring(response: 0.3), value: currentStep)
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }
        }
    }
}

// MARK: - Transportation Card
struct TransportationCard: View {
    let mode: TravelMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : mode.color)
                
                Text(mode.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mode.color : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? mode.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Place Type Card
struct PlaceTypeCard: View {
    let category: PlaceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var iconName: String {
        switch category {
        case .restaurant:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer.fill"
        case .activity:
            return "figure.run"
        case .parking:
            return "parkingsign.circle.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 30)
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Participant Card
struct ParticipantCard: View {
    let participant: Participant
    let coordinate: CLLocationCoordinate2D?
    let isUser: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(isUser ? Color.accentColor.opacity(0.2) : Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Group {
                        if isUser {
                            Image(systemName: "person.fill")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        } else {
                            Text(String(participant.name.prefix(1)).uppercased())
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                    }
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(participant.name)
                        .font(.headline)
                    if isUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: coordinate != nil ? "checkmark.circle.fill" : "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(coordinate != nil ? .green : .orange)
                    
                    Text(isUser ? "Current Location" : participant.start.displayLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Delete button (hidden for user)
            if !isUser {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUser ? Color.accentColor.opacity(0.05) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUser ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isUser {
                onTap()
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

#Preview {
    NewMeetView(appViewModel: AppViewModel())
}
